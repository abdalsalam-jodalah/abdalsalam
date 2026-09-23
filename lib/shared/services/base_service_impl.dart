import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../data/models/base_model.dart';
import '../../data/repositories/base_repository.dart';
import '../infrastructure/logger_service.dart';
import 'base_service.dart';

abstract class BaseServiceImpl<T extends BaseModel> implements BaseService<T> {
  final BaseRepository<T> repository;
  final LoggerService logger;

  const BaseServiceImpl(this.repository, this.logger);

  T fromJson(Map<String, dynamic> json);

  @override
  Future<Result<T, AppError>> create(T entity) async {
    logger.info('[$serviceName] create started id=${entity.id}');
    final validation = validate(entity);
    if (validation.isFailure) {
      logger.warning('[$serviceName] create validation failed: ${validation.error}');
      return Failure(validation.error!);
    }
    final result = await repository.create(entity);
    if (result.isFailure) {
      logger.warning('[$serviceName] create failed: ${result.error}');
    }
    return result;
  }

  @override
  Future<Result<List<T>, AppError>> createBulk(List<T> entities) async {
    logger.info('[$serviceName] createBulk started count=${entities.length}');
    final validation = validateBulk(entities);
    if (validation.isFailure) {
      logger.warning('[$serviceName] createBulk validation failed: ${validation.error}');
      return Failure(validation.error!);
    }
    final result = await repository.createBulk(entities);
    if (result.isFailure) {
      logger.warning('[$serviceName] createBulk failed: ${result.error}');
    }
    return result;
  }

  @override
  Future<Result<void, AppError>> delete(String id) {
    logger.info('[$serviceName] delete started id=$id');
    return repository.delete(id);
  }

  @override
  Future<Result<void, AppError>> deleteBulk(List<String> ids) {
    logger.info('[$serviceName] deleteBulk started count=${ids.length}');
    return repository.deleteBulk(ids);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> exportWithMetadata() async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }

      final records = allResult.data!;
      final stats = await getStatistics();
      if (stats.isFailure) {
        return Failure(stats.error!);
      }

      final dataJson = records.map((item) => item.toJson()).toList(growable: false);
      final checksum = _calculateChecksum(dataJson);

      final export = <String, dynamic>{
        'metadata': <String, dynamic>{
          'serviceName': serviceName,
          'version': version,
          'exportedAt': DateTime.now().toIso8601String(),
          'recordCount': records.length,
          'checksum': checksum,
        },
        'data': dataJson,
        'statistics': stats.data,
      };

      return Success(export);
    } catch (e, st) {
      logger.error('[$serviceName] exportWithMetadata failed', error: e, stackTrace: st);
      return Failure(ExportError('$serviceName export failed', cause: e, causeStackTrace: st));
    }
  }

  @override
  Future<Result<String, AppError>> exportToJson() async {
    final result = await exportWithMetadata();
    if (result.isFailure) {
      return Failure(result.error!);
    }
    return Success(jsonEncode(result.data));
  }

  @override
  Future<Result<List<T>, AppError>> filter(Map<String, dynamic> filters) {
    return repository.query(filters);
  }

  @override
  Future<Result<List<T>, AppError>> getActive() {
    return repository.getActive();
  }

  @override
  Future<Result<List<T>, AppError>> getAll() {
    return repository.getAll();
  }

  @override
  Future<Result<T?, AppError>> getById(String id) {
    return repository.getById(id);
  }

  @override
  Future<Result<List<T>, AppError>> getByDateRange(DateTime start, DateTime end) {
    return repository.getByDateRange(start, end);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getMetadata() async {
    final counts = await count();
    if (counts.isFailure) {
      return Failure(counts.error!);
    }

    return Success(<String, dynamic>{
      'serviceName': serviceName,
      'version': version,
      'totalRecords': counts.data,
    });
  }

  @override
  Future<Result<List<T>, AppError>> getRecent(int limit) async {
    final all = await getAll();
    if (all.isFailure) {
      return Failure(all.error!);
    }
    final items = all.data!;
    return Success(items.take(limit).toList(growable: false));
  }

  @override
  Future<Result<void, AppError>> importFromJson(String json) async {
    try {
      final dynamic decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) {
        return Failure(ValidationError('Invalid import payload'));
      }
      return importWithValidation(decoded);
    } catch (e, st) {
      logger.error('[$serviceName] importFromJson failed', error: e, stackTrace: st);
      return Failure(ImportError('$serviceName import failed', cause: e, causeStackTrace: st));
    }
  }

  @override
  Future<Result<void, AppError>> importWithValidation(
    Map<String, dynamic> data,
  ) async {
    try {
      final metadata = data['metadata'];
      final rawData = data['data'];

      if (metadata is! Map<String, dynamic> || rawData is! List<dynamic>) {
        return Failure(ValidationError('Missing metadata or data section'));
      }

      final expectedChecksum = metadata['checksum'] as String?;
      final actualChecksum = _calculateChecksum(rawData);
      if (expectedChecksum == null || expectedChecksum != actualChecksum) {
        return Failure(ValidationError('Checksum mismatch'));
      }

      final records = rawData
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false);

      final create = await createBulk(records);
      if (create.isFailure) {
        return Failure(create.error!);
      }

      return const Success(null);
    } catch (e, st) {
      logger.error('[$serviceName] importWithValidation failed', error: e, stackTrace: st);
      return Failure(ImportError('$serviceName import failed', cause: e, causeStackTrace: st));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics();

  @override
  Future<Result<String, AppError>> backup() {
    return exportToJson();
  }

  @override
  Future<Result<void, AppError>> restore(String backupData) {
    return importFromJson(backupData);
  }

  @override
  Future<Result<void, AppError>> softDelete(String id) {
    return repository.softDelete(id);
  }

  @override
  Future<Result<List<T>, AppError>> search(String query) {
    return repository.search(query);
  }

  @override
  Future<Result<void, AppError>> update(T entity) async {
    logger.info('[$serviceName] update started id=${entity.id}');
    final validation = validate(entity);
    if (validation.isFailure) {
      logger.warning('[$serviceName] update validation failed: ${validation.error}');
      return Failure(validation.error!);
    }
    final result = await repository.update(entity);
    if (result.isFailure) {
      logger.warning('[$serviceName] update failed: ${result.error}');
    }
    return result;
  }

  @override
  Future<Result<void, AppError>> updateBulk(List<T> entities) async {
    logger.info('[$serviceName] updateBulk started count=${entities.length}');
    final validation = validateBulk(entities);
    if (validation.isFailure) {
      logger.warning('[$serviceName] updateBulk validation failed: ${validation.error}');
      return Failure(validation.error!);
    }
    final result = await repository.updateBulk(entities);
    if (result.isFailure) {
      logger.warning('[$serviceName] updateBulk failed: ${result.error}');
    }
    return result;
  }

  @override
  Future<Result<int, AppError>> count() {
    return repository.count();
  }

  @override
  Result<void, AppError> validateBulk(List<T> entities) {
    for (final item in entities) {
      final validation = validate(item);
      if (validation.isFailure) {
        return Failure(validation.error!);
      }
    }
    return const Success(null);
  }

  String _calculateChecksum(List<dynamic> records) {
    final bytes = utf8.encode(jsonEncode(records));
    return sha256.convert(bytes).toString();
  }
}
