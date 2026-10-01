// lib/shared/services/module_export_service.dart — builds a readable per-module JSON + CSV export for analysis.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';
import 'backup_file_store.dart';
import 'csv_encoder.dart';
import 'error_handler.dart';
import 'export_row_enricher.dart';
import 'module_export.dart';
import 'module_table_registry.dart';

class ModuleExportService {
  static const String _filePrefix = 'abdalsalam-export-';
  static const String _fileExtension = '.zip';
  static const String _fileTimestampPattern = 'yyyyMMdd-HHmm';
  static const String _manifestEntry = 'manifest.json';
  static const String _deletedAtField = 'deletedAt';
  static const List<int> _utf8ByteOrderMark = <int>[0xEF, 0xBB, 0xBF];
  static const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

  final StorageGateway storage;
  final LoggerService logger;
  final List<ExportRowEnricher> enrichers;
  final BackupFileStore fileStore;
  final CsvEncoder _csv = const CsvEncoder();

  ModuleExportService(
    this.storage,
    this.logger, {
    this.enrichers = const <ExportRowEnricher>[],
    this.fileStore = const BackupFileStore(),
  });

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  static String fileName(DateTime now) => '$_filePrefix${DateFormat(_fileTimestampPattern).format(now)}$_fileExtension';

  Future<Map<DataModule, int>> countRecordsByModule() async {
    final counts = <DataModule, int>{};
    for (final module in DataModule.values) {
      var total = 0;
      for (final table in module.tables) {
        total += await storage.countRecords(table: table);
      }
      counts[module] = total;
    }
    return counts;
  }

  Future<Result<ModuleExport, AppError>> export({
    required Set<DataModule> modules,
    bool includeDeleted = false,
  }) async {
    try {
      final now = DateTime.now();
      final archive = Archive();
      final recordCountByModule = <DataModule, int>{};
      final manifestModules = <String, dynamic>{};

      for (final module in DataModule.values.where(modules.contains)) {
        final rowsByTable = await _readRows(module, includeDeleted: includeDeleted);
        recordCountByModule[module] = rowsByTable.values.fold<int>(0, (total, rows) => total + rows.length);
        manifestModules[module.name] = <String, int>{
          for (final entry in rowsByTable.entries) entry.key: entry.value.length,
        };
        _addModuleFiles(archive, module, rowsByTable, exportedAt: now, includeDeleted: includeDeleted);
      }

      archive.addFile(ArchiveFile.string(
        _manifestEntry,
        _prettyJson.convert(<String, dynamic>{
          'exportedAt': now.toIso8601String(),
          'includeDeleted': includeDeleted,
          'modules': manifestModules,
        }),
      ));
      final export = ModuleExport(
        bytes: ZipEncoder().encodeBytes(archive),
        fileName: fileName(now),
        recordCountByModule: recordCountByModule,
      );
      logger.info('[ModuleExportService] export built modules=${recordCountByModule.length} includeDeleted=$includeDeleted');
      return Success(export);
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(error, context: 'ModuleExportService.export', stackTrace: stackTrace);
      return Failure(ExportError('Export failed', cause: mapped, causeStackTrace: stackTrace));
    }
  }

  Future<Result<String?, AppError>> saveExportAs(ModuleExport export) async {
    try {
      return Success(await fileStore.saveBytesAs(bytes: export.bytes, fileName: export.fileName));
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(error, context: 'ModuleExportService.saveExportAs', stackTrace: stackTrace);
      return Failure(ExportError('Failed to save export', cause: mapped, causeStackTrace: stackTrace));
    }
  }

  Future<Result<void, AppError>> shareExport(ModuleExport export) async {
    try {
      final path = await fileStore.saveBytes(bytes: export.bytes, fileName: export.fileName);
      await fileStore.share(path);
      return const Success(null);
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(error, context: 'ModuleExportService.shareExport', stackTrace: stackTrace);
      return Failure(ExportError('Failed to share export', cause: mapped, causeStackTrace: stackTrace));
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _readRows(DataModule module, {required bool includeDeleted}) async {
    var rowsByTable = <String, List<Map<String, dynamic>>>{
      for (final table in ModuleTableRegistry.readableExportTablesFor(module))
        table: await storage.getAllRecords(table: table),
    };
    for (final enricher in enrichers) {
      rowsByTable = enricher.enrich(rowsByTable);
    }
    if (includeDeleted) {
      return rowsByTable;
    }
    return <String, List<Map<String, dynamic>>>{
      for (final entry in rowsByTable.entries)
        entry.key: entry.value.where((row) => row[_deletedAtField] == null).toList(growable: false),
    };
  }

  void _addModuleFiles(
    Archive archive,
    DataModule module,
    Map<String, List<Map<String, dynamic>>> rowsByTable, {
    required DateTime exportedAt,
    required bool includeDeleted,
  }) {
    archive.addFile(ArchiveFile.string(
      '${module.name}/${module.name}.json',
      _prettyJson.convert(<String, dynamic>{
        'metadata': <String, dynamic>{
          'module': module.name,
          'exportedAt': exportedAt.toIso8601String(),
          'includeDeleted': includeDeleted,
        },
        'tables': rowsByTable,
      }),
    ));
    for (final entry in rowsByTable.entries) {
      if (entry.value.isEmpty) {
        continue;
      }
      final csvBytes = Uint8List.fromList(<int>[..._utf8ByteOrderMark, ...utf8.encode(_csv.encode(entry.value))]);
      archive.addFile(ArchiveFile.bytes('${module.name}/${entry.key}.csv', csvBytes));
    }
  }
}
