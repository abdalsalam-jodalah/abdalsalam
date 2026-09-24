import '../../core/errors/app_error.dart';
import '../../core/json/json_reader.dart';
import '../../core/result/result.dart';
import '../infrastructure/logger_service.dart';
import 'backup_codec.dart';
import 'backup_keys.dart';
import 'restore_plan.dart';

class BackupValidator {
  final BackupCodec codec;
  final List<String> knownTables;
  final LoggerService logger;

  const BackupValidator({required this.codec, required this.knownTables, required this.logger});

  Result<RestorePlan, AppError> validate(Map<String, dynamic> backup) {
    final reader = JsonReader(backup, source: 'Backup');
    final metadata = reader.optionalMap(BackupKeys.metadata);
    final data = reader.optionalMap(BackupKeys.data);
    if (metadata == null || data == null) {
      return Failure(ImportError('Invalid backup structure'));
    }
    final metadataReader = JsonReader(metadata, source: 'BackupMetadata');
    final version = metadataReader.optionalString(BackupKeys.version);
    if (!BackupKeys.supportedVersions.contains(version)) {
      return Failure(ImportError('Unsupported backup version $version'));
    }
    final checksum = metadataReader.optionalString(BackupKeys.checksum);
    if (checksum == null || checksum != codec.checksum(data)) {
      return Failure(ImportError('Backup checksum mismatch'));
    }
    final preferences = reader.readMap(BackupKeys.preferences);
    if (version == BackupKeys.currentVersion &&
        metadataReader.optionalString(BackupKeys.preferencesChecksum) != codec.checksum(preferences)) {
      return Failure(ImportError('Backup settings checksum mismatch'));
    }

    final rowsByTable = <String, List<Map<String, dynamic>>>{};
    final unknownTables = <String>[];
    var skippedRowCount = 0;
    for (final entry in data.entries) {
      if (!knownTables.contains(entry.key)) {
        unknownTables.add(entry.key);
        continue;
      }
      final rows = entry.value;
      if (rows is! List) {
        return Failure(ImportError('Backup table ${entry.key} is not a list'));
      }
      final validRows = <Map<String, dynamic>>[];
      for (final row in rows) {
        if (row is Map<String, dynamic> && row['id'] is String && (row['id'] as String).isNotEmpty) {
          validRows.add(row);
        } else {
          skippedRowCount++;
        }
      }
      rowsByTable[entry.key] = validRows;
    }
    if (skippedRowCount > 0) {
      logger.warning('[BackupService] restore will skip $skippedRowCount rows without a valid id');
    }
    if (unknownTables.isNotEmpty) {
      logger.warning('[BackupService] restore will skip unknown tables: ${unknownTables.join(', ')}');
    }
    return Success(RestorePlan(
      rowsByTable: rowsByTable,
      preferences: preferences,
      skippedRowCount: skippedRowCount,
      unknownTables: unknownTables,
    ));
  }
}
