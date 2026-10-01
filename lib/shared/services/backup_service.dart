import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../core/errors/app_error.dart';
import '../../core/json/json_reader.dart';
import '../../core/result/result.dart';
import '../infrastructure/crash_log_recorder.dart';
import '../infrastructure/database_schema_initializer.dart';
import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';
import 'backup_archive.dart';
import 'backup_archive_codec.dart';
import 'backup_attachment_bundler.dart';
import 'backup_codec.dart';
import 'backup_file_store.dart';
import 'backup_keys.dart';
import 'backup_package.dart';
import 'backup_status_service.dart';
import 'backup_validator.dart';
import 'error_handler.dart';
import 'restore_report.dart';

class BackupService {
  static const String _backupFileExtension = '.zip';
  static const String _backupFilePrefix = 'abdalsalam-backup-';
  static const String _safetyBackupFilePrefix = 'abdalsalam-pre-restore-';
  static const String _automaticBackupFilePrefix = 'abdalsalam-auto-';
  static const int automaticBackupKeepCount = 5;
  static final Set<String> _excludedPreferenceKeys = <String>{
    CrashLogRecorder.storageKey,
    ...BackupKeys.transientPreferenceKeys,
  };

  final StorageGateway storage;
  final LoggerService logger;
  final BackupFileStore fileStore;
  final List<String> knownTables;
  final BackupAttachmentBundler attachmentBundler;
  final BackupStatusService backupStatus;
  final BackupCodec _codec = const BackupCodec();
  final BackupArchiveCodec _archiveCodec = const BackupArchiveCodec();
  Timer? _backupTimer;

  BackupService(
    this.storage,
    this.logger, {
    this.fileStore = const BackupFileStore(),
    this.knownTables = DatabaseSchemaInitializer.tables,
    this.attachmentBundler = const BackupAttachmentBundler(<AttachmentBinding>[]),
    BackupStatusService? backupStatus,
  }) : backupStatus = backupStatus ?? BackupStatusService(storage);

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  static String backupFileName(DateTime now) => '$_backupFilePrefix${now.millisecondsSinceEpoch}$_backupFileExtension';

  Future<Result<BackupPackage, AppError>> createBackupPackage({
    required List<String> tables,
    List<String>? onlyModules,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final rowsByTable = <String, List<Map<String, dynamic>>>{};
      for (final table in tables) {
        if (onlyModules != null && onlyModules.isNotEmpty && !onlyModules.contains(table)) {
          continue;
        }
        final records = await storage.getAllRecords(table: table);
        rowsByTable[table] = records.where((record) => _isWithinRange(record, start, end)).toList(growable: false);
      }
      final bundle = await attachmentBundler.bundle(rowsByTable);
      final data = <String, dynamic>{...bundle.rows};
      final preferences = await _readPreferences();
      final envelope = <String, dynamic>{
        BackupKeys.metadata: <String, dynamic>{
          BackupKeys.version: BackupKeys.currentVersion,
          BackupKeys.createdAt: DateTime.now().toIso8601String(),
          BackupKeys.tables: data.keys.toList(growable: false),
          BackupKeys.attachmentCount: bundle.files.length,
          BackupKeys.checksum: _codec.checksum(data),
          BackupKeys.preferencesChecksum: _codec.checksum(preferences),
        },
        BackupKeys.data: data,
        BackupKeys.preferences: preferences,
      };
      logger.info(
        '[BackupService] backup created tables=${data.length} preferences=${preferences.length} '
        'attachments=${bundle.files.length} missingAttachments=${bundle.missingCount}',
      );
      return Success(BackupPackage(
        envelope: envelope,
        attachments: bundle.files,
        missingAttachmentCount: bundle.missingCount,
      ));
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(error, context: 'BackupService.createBackupPackage', stackTrace: stackTrace);
      return Failure(ExportError('Backup failed', cause: mapped, causeStackTrace: stackTrace));
    }
  }

  Future<Result<BackupArchive, AppError>> createBackupArchive({
    required List<String> tables,
    List<String>? onlyModules,
    DateTime? start,
    DateTime? end,
  }) async {
    final backup = await createBackupPackage(tables: tables, onlyModules: onlyModules, start: start, end: end);
    return backup.map(
      (package) => BackupArchive(
        bytes: _archiveCodec.encode(envelope: package.envelope, attachments: package.attachments),
        attachmentCount: package.attachments.length,
        missingAttachmentCount: package.missingAttachmentCount,
      ),
    );
  }

  Future<Result<String, AppError>> saveBackupToDevice({
    required Uint8List bytes,
    String fileName = 'abdalsalam-backup.zip',
  }) async {
    try {
      final path = await fileStore.saveBytes(bytes: bytes, fileName: fileName);
      logger.info('[BackupService] backup saved path=$path');
      return Success(path);
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(error, context: 'BackupService.saveBackupToDevice', stackTrace: stackTrace);
      return Failure(ExportError('Failed to save backup', cause: mapped, causeStackTrace: stackTrace));
    }
  }

  Future<Result<String?, AppError>> saveBackupAs({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final path = await fileStore.saveBytesAs(bytes: bytes, fileName: fileName);
      logger.info('[BackupService] backup saved as path=$path');
      if (path != null) {
        await _recordExported();
      }
      return Success(path);
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(error, context: 'BackupService.saveBackupAs', stackTrace: stackTrace);
      return Failure(ExportError('Failed to save backup', cause: mapped, causeStackTrace: stackTrace));
    }
  }

  Future<Result<String, AppError>> createAutomaticBackup() async {
    final archive = await createBackupArchive(tables: knownTables);
    if (archive.isFailure) {
      return Failure(archive.error!);
    }
    final saved = await saveBackupToDevice(
      bytes: archive.data!.bytes,
      fileName: '$_automaticBackupFilePrefix${DateTime.now().millisecondsSinceEpoch}$_backupFileExtension',
    );
    if (saved.isFailure) {
      return saved;
    }
    try {
      await fileStore.keepNewest(prefix: _automaticBackupFilePrefix, count: automaticBackupKeepCount);
    } catch (error, stackTrace) {
      _errorHandler.mapException(error, context: 'BackupService.pruneAutomaticBackups', stackTrace: stackTrace);
    }
    return saved;
  }

  Future<Result<Uint8List, AppError>> readBackupFile(String filePath) async {
    try {
      return Success(await fileStore.readBytes(filePath));
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(error, context: 'BackupService.readBackupFile', stackTrace: stackTrace);
      return Failure(ImportError('Failed to read backup file', cause: mapped, causeStackTrace: stackTrace));
    }
  }

  Future<Result<void, AppError>> shareBackup(String filePath) async {
    try {
      await fileStore.share(filePath);
      logger.info('[BackupService] backup shared path=$filePath');
      await _recordExported();
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(_errorHandler.mapException(error, context: 'BackupService.shareBackup', stackTrace: stackTrace));
    }
  }

  void scheduleAutomaticBackups({
    required Duration frequency,
    required Future<void> Function() onRun,
  }) {
    _backupTimer?.cancel();
    _backupTimer = Timer.periodic(frequency, (_) async {
      logger.info('[BackupService] scheduled backup triggered');
      try {
        await onRun();
      } catch (error, stackTrace) {
        _errorHandler.mapException(error, context: 'BackupService.scheduledBackup', stackTrace: stackTrace);
      }
    });
    logger.info('[BackupService] automatic backup scheduled every ${frequency.inMinutes} minutes');
  }

  void cancelAutomaticBackups() {
    _backupTimer?.cancel();
    _backupTimer = null;
    logger.info('[BackupService] automatic backup cancelled');
  }

  Future<Result<RestoreReport, AppError>> restoreFromBytes(Uint8List bytes, {bool replace = false}) async {
    if (!BackupArchiveCodec.isArchive(bytes)) {
      return restoreFromText(utf8.decode(bytes, allowMalformed: true), replace: replace);
    }
    final decoded = _archiveCodec.decode(bytes);
    if (decoded.isFailure) {
      logger.warning('[BackupService] restore rejected: ${decoded.error!.message}');
      return Failure(decoded.error!);
    }
    return restore(backup: decoded.data!.envelope, attachments: decoded.data!.attachments, replace: replace);
  }

  Future<Result<RestoreReport, AppError>> restoreFromText(String content, {bool replace = false}) async {
    final decoded = _codec.decode(content);
    if (decoded.isFailure) {
      logger.warning('[BackupService] restore rejected: ${decoded.error!.message}');
      return Failure(decoded.error!);
    }
    return restore(backup: decoded.data!, replace: replace);
  }

  Future<Result<RestoreReport, AppError>> restore({
    required Map<String, dynamic> backup,
    Map<String, Uint8List> attachments = const <String, Uint8List>{},
    bool replace = false,
  }) async {
    final validated = BackupValidator(codec: _codec, knownTables: knownTables, logger: logger).validate(backup);
    if (validated.isFailure) {
      logger.warning('[BackupService] restore rejected: ${validated.error!.message}');
      return Failure(validated.error!);
    }
    final plan = validated.data!;

    final safetyBackup = await _createSafetyBackup();
    if (safetyBackup.isFailure) {
      return Failure(ImportError(
        'Could not create a safety backup; restore cancelled',
        cause: safetyBackup.error,
      ));
    }

    final attachmentOutcome = await attachmentBundler.restore(plan.rowsByTable, attachments);
    final rowsByTable = attachmentOutcome.rows;

    try {
      await storage.runInTransaction(() async {
        for (final entry in rowsByTable.entries) {
          if (replace) {
            await storage.clearTable(entry.key);
          }
          for (final row in entry.value) {
            await storage.upsertRecord(
              table: entry.key,
              id: row['id'] as String,
              record: row,
              userId: JsonReader(row, source: entry.key).optionalString('userId'),
              isPreservingUpdatedAt: true,
            );
          }
        }
      });
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(error, context: 'BackupService.restore', stackTrace: stackTrace);
      return Failure(ImportError('Restore failed; no data was changed', cause: mapped, causeStackTrace: stackTrace));
    }

    final restoredPreferenceCount = await _restorePreferences(plan.preferences);
    final report = RestoreReport(
      restoredTableCount: rowsByTable.length,
      restoredRowCount: rowsByTable.values.fold<int>(0, (total, rows) => total + rows.length),
      skippedRowCount: plan.skippedRowCount,
      restoredPreferenceCount: restoredPreferenceCount,
      skippedUnknownTables: plan.unknownTables,
      safetyBackupPath: safetyBackup.data!,
      restoredAttachmentCount: attachmentOutcome.restoredCount,
      missingAttachmentCount: attachmentOutcome.missingCount,
    );
    logger.info(
      '[BackupService] restore completed tables=${report.restoredTableCount} rows=${report.restoredRowCount} '
      'skippedRows=${report.skippedRowCount} preferences=${report.restoredPreferenceCount} '
      'attachments=${report.restoredAttachmentCount} missingAttachments=${report.missingAttachmentCount} replace=$replace',
    );
    return Success(report);
  }

  Future<Result<String, AppError>> _createSafetyBackup() async {
    final backup = await createBackupArchive(tables: knownTables);
    if (backup.isFailure) {
      return Failure(backup.error!);
    }
    return saveBackupToDevice(
      bytes: backup.data!.bytes,
      fileName: '$_safetyBackupFilePrefix${DateTime.now().millisecondsSinceEpoch}$_backupFileExtension',
    );
  }

  Future<void> _recordExported() async {
    try {
      await backupStatus.recordExported();
    } catch (error, stackTrace) {
      _errorHandler.mapException(error, context: 'BackupService.recordExported', stackTrace: stackTrace);
    }
  }

  Future<Map<String, dynamic>> _readPreferences() async {
    final preferences = <String, dynamic>{};
    for (final key in await storage.getAllKeys()) {
      if (_excludedPreferenceKeys.contains(key)) {
        continue;
      }
      try {
        final value = await storage.get<Object>(key);
        if (value != null) {
          preferences[key] = value;
        }
      } on CorruptDataError catch (error, stackTrace) {
        storage.integrityReporter.reportCorruptRecord(
          table: BackupKeys.preferences,
          recordId: key,
          reason: error,
          stackTrace: stackTrace,
        );
      }
    }
    return preferences;
  }

  Future<int> _restorePreferences(Map<String, dynamic> preferences) async {
    var restoredCount = 0;
    for (final entry in preferences.entries) {
      try {
        await storage.save(key: entry.key, value: entry.value);
        restoredCount++;
      } catch (error, stackTrace) {
        _errorHandler.mapException(error, context: 'BackupService.restorePreference(${entry.key})', stackTrace: stackTrace);
      }
    }
    return restoredCount;
  }

  bool _isWithinRange(Map<String, dynamic> record, DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return true;
    }
    final updatedAt = JsonReader(record, source: 'BackupRecord').optionalDate('updatedAt');
    if (updatedAt == null) {
      return true;
    }
    final isAfterStart = start == null || !updatedAt.isBefore(start);
    final isBeforeEnd = end == null || !updatedAt.isAfter(end);
    return isAfterStart && isBeforeEnd;
  }
}
