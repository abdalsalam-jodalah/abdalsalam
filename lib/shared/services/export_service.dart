import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../infrastructure/file_operations.dart';
import '../infrastructure/logger_service.dart';

class ExportService {
  final LoggerService logger;

  const ExportService(this.logger);

  Future<Result<Map<String, dynamic>, AppError>> exportWithMetadata({
    required String serviceName,
    required String version,
    required List<Map<String, dynamic>> data,
    String exportedBy = 'local-user',
    DateTime? start,
    DateTime? end,
    Map<String, dynamic>? statistics,
  }) async {
    try {
      final checksum = _checksum(data);
      final payload = <String, dynamic>{
        'metadata': <String, dynamic>{
          'serviceName': serviceName,
          'version': version,
          'exportedAt': DateTime.now().toIso8601String(),
          'exportedBy': exportedBy,
          'recordCount': data.length,
          'dateRange': <String, dynamic>{
            'start': start?.toIso8601String(),
            'end': end?.toIso8601String(),
          },
          'checksum': checksum,
        },
        'data': data,
        'statistics': statistics ?? <String, dynamic>{},
      };
      logger.info('[ExportService] exported records=${data.length}');
      return Success(payload);
    } catch (e, st) {
      logger.error('[ExportService] exportWithMetadata failed', error: e, stackTrace: st);
      return Failure(ExportError(e.toString()));
    }
  }

  List<Map<String, dynamic>> selectiveExport(
    List<Map<String, dynamic>> rows, {
    DateTime? start,
    DateTime? end,
    Map<String, dynamic> filters = const <String, dynamic>{},
  }) {
    return rows.where((row) {
      if (start != null || end != null) {
        final rawDate = row['createdAt'] ?? row['date'] ?? row['performedAt'];
        final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
        if (date != null) {
          if (start != null && date.isBefore(start)) {
            return false;
          }
          if (end != null && date.isAfter(end)) {
            return false;
          }
        }
      }

      for (final entry in filters.entries) {
        if (row[entry.key] != entry.value) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  Future<Result<Map<String, dynamic>, AppError>> exportUnified({
    required String version,
    required Map<String, List<Map<String, dynamic>>> modules,
    String exportedBy = 'local-user',
  }) async {
    try {
      final allRows = modules.values.expand((rows) => rows).toList(growable: false);
      final checksum = _checksum(allRows);
      final payload = <String, dynamic>{
        'metadata': <String, dynamic>{
          'serviceName': 'UnifiedExport',
          'version': version,
          'exportedAt': DateTime.now().toIso8601String(),
          'exportedBy': exportedBy,
          'recordCount': allRows.length,
          'moduleCount': modules.length,
          'checksum': checksum,
        },
        'modules': modules,
      };
      logger.info('[ExportService] unified export modules=${modules.length} rows=${allRows.length}');
      return Success(payload);
    } catch (e, st) {
      logger.error('[ExportService] exportUnified failed', error: e, stackTrace: st);
      return Failure(ExportError(e.toString()));
    }
  }

  Future<Result<String, AppError>> saveExportToFile({
    required Map<String, dynamic> payload,
    String? fileName,
  }) async {
    try {
      final jsonString = jsonEncode(payload);
      final resolvedName = fileName ?? 'abdalsalam_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = await FileOperations.saveFile(jsonString, resolvedName);
      logger.info('[ExportService] file saved path=${file.path}');
      return Success(file.path);
    } catch (e, st) {
      logger.error('[ExportService] saveExportToFile failed', error: e, stackTrace: st);
      return Failure(ExportError(e.toString()));
    }
  }

  Future<Result<void, AppError>> shareExport(String filePath) async {
    try {
      await FileOperations.shareFile(filePath);
      logger.info('[ExportService] file shared path=$filePath');
      return const Success(null);
    } catch (e, st) {
      logger.error('[ExportService] shareExport failed', error: e, stackTrace: st);
      return Failure(ExportError(e.toString()));
    }
  }

  String _checksum(List<dynamic> data) {
    final bytes = utf8.encode(jsonEncode(data));
    return sha256.convert(bytes).toString();
  }
}
