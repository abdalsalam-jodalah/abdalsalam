import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../infrastructure/file_operations.dart';
import '../infrastructure/logger_service.dart';

enum DuplicateResolutionStrategy { skip, replace, merge }

class ImportService {
  final LoggerService logger;

  const ImportService(this.logger);

  Future<Result<Map<String, dynamic>, AppError>> loadImportFromFile(String filePath) async {
    try {
      final content = await FileOperations.readFile(filePath);
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return Failure(ImportError('Invalid import file format'));
      }
      return Success(decoded);
    } catch (e, st) {
      logger.error('[ImportService] loadImportFromFile failed', error: e, stackTrace: st);
      return Failure(ImportError(e.toString()));
    }
  }

  Result<void, AppError> validateMetadata(
    Map<String, dynamic> payload, {
    required String expectedService,
    required String supportedVersion,
  }) {
    final metadata = payload['metadata'];
    final data = payload['data'];

    if (metadata is! Map<String, dynamic> || data is! List<dynamic>) {
      return Failure(ImportError('Missing metadata or data fields'));
    }

    final serviceName = metadata['serviceName'] as String?;
    if (serviceName == null || serviceName != expectedService) {
      return Failure(ImportError('Unsupported service: $serviceName'));
    }

    final version = metadata['version'] as String?;
    if (version == null || version != supportedVersion) {
      return Failure(ImportError('Incompatible version: $version'));
    }

    final checksum = metadata['checksum'] as String?;
    final computed = sha256.convert(utf8.encode(jsonEncode(data))).toString();
    if (checksum == null || checksum != computed) {
      return Failure(ImportError('Checksum verification failed'));
    }

    return const Success(null);
  }

  List<Map<String, dynamic>> resolveDuplicates({
    required List<Map<String, dynamic>> incoming,
    required List<Map<String, dynamic>> existing,
    required DuplicateResolutionStrategy strategy,
  }) {
    final existingById = <String, Map<String, dynamic>>{
      for (final item in existing)
        if (item['id'] != null) item['id'].toString(): item,
    };

    final resolved = <Map<String, dynamic>>[];

    for (final record in incoming) {
      final id = record['id']?.toString();
      if (id == null || !existingById.containsKey(id)) {
        resolved.add(record);
        continue;
      }

      switch (strategy) {
        case DuplicateResolutionStrategy.skip:
          break;
        case DuplicateResolutionStrategy.replace:
          resolved.add(record);
        case DuplicateResolutionStrategy.merge:
          resolved.add(<String, dynamic>{...existingById[id]!, ...record});
      }
    }

    return resolved;
  }

  Result<void, AppError> validateRecords(
    List<Map<String, dynamic>> records,
    String? Function(Map<String, dynamic> record) validator,
  ) {
    for (var i = 0; i < records.length; i++) {
      final error = validator(records[i]);
      if (error != null) {
        return Failure(ValidationError('Record $i failed validation: $error'));
      }
    }
    return const Success(null);
  }
}
