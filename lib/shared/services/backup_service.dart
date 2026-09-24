import 'dart:async';

import '../../core/errors/app_error.dart';
import '../../core/json/json_reader.dart';
import '../../core/result/result.dart';
import '../infrastructure/crash_log_recorder.dart';
import '../infrastructure/database_schema_initializer.dart';
import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';
import 'backup_codec.dart';
import 'backup_file_store.dart';
import 'backup_keys.dart';
import 'backup_validator.dart';
import 'error_handler.dart';
import 'restore_report.dart';

class BackupService {
  static const String _backupFileExtension = '.b64';
  static const String _backupFilePrefix = 'abdalsalam-backup-';
  static const String _safetyBackupFilePrefix = 'abdalsalam-pre-restore-';
  static const Set<String> _excludedPreferenceKeys = <String>{CrashLogRecorder.storageKey};

  final StorageGateway storage;
  final LoggerService logger;
  final BackupFileStore fileStore;
  final List<String> knownTables;
  final BackupCodec _codec = const BackupCodec();
  Timer? _backupTimer;

  BackupService(
    this.storage,
    this.logger, {
    this.fileStore = const BackupFileStore(),
    this.knownTables = DatabaseSchemaInitializer.tables,
  });

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  static String backupFileName(DateTime now) => '$_backupFilePrefix${now.millisecondsSinceEpoch}$_backupFileExtension';

  Future<Result<Map<String, dynamic>, AppError>> createFullBackup({
    required List<String> tables,
    List<String>? onlyModules,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final data = <String, dynamic>{};
      for (final table in tables) {
        if (onlyModules != null && onlyModules.isNotEmpty && !onlyModules.contains(table)) {
          continue;
        }
        final records = await storage.getAllRecords(table: table);
        data[table] = records.where((record) => _isWithinRange(record, start, end)).toList(growable: false);
      }
      final preferences = await _readPreferences();
      final backup = <String, dynamic>{
        BackupKeys.metadata: <String, dynamic>{
          BackupKeys.version: BackupKeys.currentVersion,
          BackupKeys.createdAt: DateTime.now().toIso8601String(),
          BackupKeys.tables: data.keys.toList(growable: false),
          BackupKeys.checksum: _codec.checksum(data),
          BackupKeys.preferencesChecksum: _codec.checksum(preferences),
        },
        BackupKeys.data: data,
        BackupKeys.preferences: preferences,
      };
      logger.info('[BackupService] full backup created tables=${data.length} preferences=${preferences.length}');
      return Success(backup);
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(error, context: 'BackupService.createFullBackup', stackTrace: stackTrace);
      return Failure(ExportError('Backup failed', cause: mapped, causeStackTrace: stackTrace));
    }
  }

  Future<Result<String, AppError>> createCompressedBackup({
    required List<String> tables,
    List<String>? onlyModules,
    DateTime? start,
    DateTime? end,
  }) async {
    final backup = await createFullBackup(tables: tables, onlyModules: onlyModules, start: start, end: end);
    return backup.map(_codec.encode);
  }

  Future<Result<String, AppError>> saveBackupToDevice({
    required String content,
    String fileName = 'abdalsalam-backup.b64',
  }) async {
    try {
      final path = await fileStore.save(content: content, fileName: fileName);
      logger.info('[BackupService] backup saved path=$path');
      return Success(path);
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(error, context: 'BackupService.saveBackupToDevice', stackTrace: stackTrace);
      return Failure(ExportError('Failed to save backup', cause: mapped, causeStackTrace: stackTrace));
    }
  }

  Future<Result<String, AppError>> readBackupFile(String filePath) async {
    try {
      return Success(await fileStore.read(filePath));
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(error, context: 'BackupService.readBackupFile', stackTrace: stackTrace);
      return Failure(ImportError('Failed to read backup file', cause: mapped, causeStackTrace: stackTrace));
    }
  }

  Future<Result<void, AppError>> shareBackup(String filePath) async {
    try {
      await fileStore.share(filePath);
      logger.info('[BackupService] backup shared path=$filePath');
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

    try {
      await storage.runInTransaction(() async {
        for (final entry in plan.rowsByTable.entries) {
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
      restoredTableCount: plan.rowsByTable.length,
      restoredRowCount: plan.rowsByTable.values.fold<int>(0, (total, rows) => total + rows.length),
      skippedRowCount: plan.skippedRowCount,
      restoredPreferenceCount: restoredPreferenceCount,
      skippedUnknownTables: plan.unknownTables,
      safetyBackupPath: safetyBackup.data!,
    );
    logger.info(
      '[BackupService] restore completed tables=${report.restoredTableCount} rows=${report.restoredRowCount} '
      'skippedRows=${report.skippedRowCount} preferences=${report.restoredPreferenceCount} replace=$replace',
    );
    return Success(report);
  }

  Future<Result<String, AppError>> _createSafetyBackup() async {
    final backup = await createCompressedBackup(tables: knownTables);
    if (backup.isFailure) {
      return Failure(backup.error!);
    }
    return saveBackupToDevice(
      content: backup.data!,
      fileName: '$_safetyBackupFilePrefix${DateTime.now().millisecondsSinceEpoch}$_backupFileExtension',
    );
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
