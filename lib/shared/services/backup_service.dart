import 'dart:convert';
import 'dart:async';

import 'package:crypto/crypto.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../infrastructure/storage_gateway.dart';
import '../infrastructure/file_operations.dart';
import '../infrastructure/logger_service.dart';

class BackupService {
  final StorageGateway storage;
  final LoggerService logger;
  Timer? _backupTimer;

  BackupService(this.storage, this.logger);

  Future<Result<Map<String, dynamic>, AppError>> createFullBackup({
    required List<String> tables,
    List<String>? onlyModules,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final payload = <String, dynamic>{};
      for (final table in tables) {
        if (onlyModules != null && onlyModules.isNotEmpty && !onlyModules.contains(table)) {
          continue;
        }
        var records = await storage.getAllRecords(table: table);
        if (start != null || end != null) {
          records = records.where((record) {
            final updatedAtRaw = record['updatedAt'] as String?;
            if (updatedAtRaw == null) {
              return true;
            }
            final ts = DateTime.tryParse(updatedAtRaw);
            if (ts == null) {
              return true;
            }
            final afterStart = start == null || !ts.isBefore(start);
            final beforeEnd = end == null || !ts.isAfter(end);
            return afterStart && beforeEnd;
          }).toList(growable: false);
        }
        payload[table] = records;
      }

      final checksum = _checksum(payload);
      final backup = <String, dynamic>{
        'metadata': <String, dynamic>{
          'version': '1.0.0',
          'createdAt': DateTime.now().toIso8601String(),
          'tables': payload.keys.toList(growable: false),
          'checksum': checksum,
        },
        'data': payload,
      };
      logger.info('[BackupService] full backup created tables=${payload.keys.length}');
      return Success(backup);
    } catch (e) {
      logger.error('[BackupService] full backup failed', error: e);
      return Failure(ExportError('Backup failed: $e'));
    }
  }

  Future<Result<String, AppError>> createCompressedBackup({
    required List<String> tables,
    List<String>? onlyModules,
    DateTime? start,
    DateTime? end,
  }) async {
    final backup = await createFullBackup(
      tables: tables,
      onlyModules: onlyModules,
      start: start,
      end: end,
    );
    if (backup.isFailure) {
      return Failure(backup.error!);
    }

    final json = jsonEncode(backup.data);
    final bytes = utf8.encode(json);
    logger.info('[BackupService] compressed backup created bytes=${bytes.length}');
    return Success(base64Encode(bytes));
  }

  Future<Result<String, AppError>> saveBackupToDevice({
    required String content,
    String fileName = 'abdalsalam-backup.json',
  }) async {
    try {
      final file = await FileOperations.saveFile(content, fileName);
      logger.info('[BackupService] backup saved path=${file.path}');
      return Success(file.path);
    } catch (e) {
      logger.error('[BackupService] save backup failed', error: e);
      return Failure(ExportError('Failed to save backup: $e'));
    }
  }

  Future<Result<void, AppError>> shareBackup(String filePath) async {
    try {
      await FileOperations.shareFile(filePath);
      logger.info('[BackupService] backup shared path=$filePath');
      return const Success(null);
    } catch (e) {
      logger.error('[BackupService] share backup failed', error: e);
      return Failure(ServiceError('Failed to share backup: $e'));
    }
  }

  void scheduleAutomaticBackups({
    required Duration frequency,
    required Future<void> Function() onRun,
  }) {
    _backupTimer?.cancel();
    _backupTimer = Timer.periodic(frequency, (_) async {
      logger.info('[BackupService] scheduled backup triggered');
      await onRun();
    });
    logger.info('[BackupService] automatic backup scheduled every ${frequency.inMinutes} minutes');
  }

  void cancelAutomaticBackups() {
    _backupTimer?.cancel();
    _backupTimer = null;
    logger.info('[BackupService] automatic backup cancelled');
  }

  Future<Result<void, AppError>> restore({
    required Map<String, dynamic> backup,
    bool replace = false,
  }) async {
    try {
      final currentTables = (backup['metadata'] as Map<String, dynamic>?)?['tables'];
      if (currentTables is List) {
        final preBackup = await createCompressedBackup(
          tables: currentTables.map((item) => item.toString()).toList(growable: false),
        );
        if (preBackup.isSuccess) {
          await saveBackupToDevice(
            content: preBackup.data!,
            fileName: 'abdalsalam-pre-restore-${DateTime.now().millisecondsSinceEpoch}.b64',
          );
        }
      }

      final metadata = backup['metadata'] as Map<String, dynamic>?;
      final data = backup['data'] as Map<String, dynamic>?;
      if (metadata == null || data == null) {
        return Failure(ImportError('Invalid backup structure'));
      }

      final checksum = metadata['checksum'] as String?;
      final calculated = _checksum(data);
      if (checksum == null || checksum != calculated) {
        logger.warning('[BackupService] restore checksum mismatch');
        return Failure(ImportError('Backup checksum mismatch'));
      }

      if ((metadata['version'] as String?) != '1.0.0') {
        logger.warning('[BackupService] restore unsupported version=${metadata['version']}');
        return Failure(ImportError('Unsupported backup version'));
      }

      for (final entry in data.entries) {
        final table = entry.key;
        final list = (entry.value as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);

        if (replace) {
          await storage.clearTable(table);
        }

        for (final row in list) {
          final id = row['id'] as String?;
          if (id == null) {
            continue;
          }
          await storage.upsertRecord(
            table: table,
            id: id,
            record: row,
            userId: row['userId'] as String?,
          );
        }
      }

      logger.info('[BackupService] restore completed tables=${data.keys.length} replace=$replace');
      return const Success(null);
    } catch (e) {
      logger.error('[BackupService] restore failed', error: e);
      return Failure(ImportError('Restore failed: $e'));
    }
  }

  String _checksum(Map<String, dynamic> data) {
    final bytes = utf8.encode(jsonEncode(data));
    return sha256.convert(bytes).toString();
  }
}
