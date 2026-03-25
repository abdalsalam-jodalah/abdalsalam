import 'dart:convert';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../shared/infrastructure/logger_service.dart';
import '../../shared/infrastructure/storage_gateway.dart';
import '../models/base_model.dart';
import 'base_repository.dart';

abstract class BaseRepositoryImpl<T extends BaseModel>
    implements BaseRepository<T> {
  final LoggerService logger;
  final StorageGateway storage;

  String get tableName;
  T fromJson(Map<String, dynamic> json);

  const BaseRepositoryImpl(this.storage, this.logger);

  @override
  Future<Result<T, AppError>> create(T entity) async {
    try {
      await storage.upsertRecord(
        table: tableName,
        id: entity.id,
        record: entity.toJson(),
        userId: entity.toJson()['userId'] as String?,
      );
      logger.info('[$tableName] created ${entity.id}');
      return Success(entity);
    } catch (e, st) {
      logger.error('[$tableName] create failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<T>, AppError>> createBulk(List<T> entities) async {
    try {
      for (final entity in entities) {
        await storage.upsertRecord(
          table: tableName,
          id: entity.id,
          record: entity.toJson(),
          userId: entity.toJson()['userId'] as String?,
        );
      }
      logger.info('[$tableName] created bulk count=${entities.length}');
      return Success(entities);
    } catch (e, st) {
      logger.error('[$tableName] createBulk failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> delete(String id) async {
    try {
      await storage.deleteRecord(table: tableName, id: id);
      return const Success(null);
    } catch (e, st) {
      logger.error('[$tableName] delete failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> deleteAll() async {
    try {
      await storage.clearTable(tableName);
      return const Success(null);
    } catch (e, st) {
      logger.error('[$tableName] deleteAll failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> deleteBulk(List<String> ids) async {
    try {
      for (final id in ids) {
        await storage.deleteRecord(table: tableName, id: id);
      }
      return const Success(null);
    } catch (e, st) {
      logger.error('[$tableName] deleteBulk failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<T>, AppError>> getActive() async {
    try {
      final list = (await storage.getAllRecords(table: tableName))
          .map(fromJson)
          .where((item) => item.isActive)
          .toList(growable: false);
      return Success(_sortByCreatedDesc(list));
    } catch (e, st) {
      logger.error('[$tableName] getActive failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<T>, AppError>> getAll() async {
    try {
      final list = (await storage.getAllRecords(table: tableName))
          .map(fromJson)
          .toList(growable: false);
      return Success(_sortByCreatedDesc(list));
    } catch (e, st) {
      logger.error('[$tableName] getAll failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<T?, AppError>> getById(String id) async {
    try {
      final value = await storage.getRecord(table: tableName, id: id);
      if (value == null) {
        return const Success(null);
      }
      return Success(fromJson(value));
    } catch (e, st) {
      logger.error('[$tableName] getById failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<T>, AppError>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final list = (await storage.getAllRecords(table: tableName))
          .map(fromJson)
          .where(
            (item) =>
                !item.createdAt.isBefore(start) && !item.createdAt.isAfter(end),
          )
          .toList(growable: false);
      return Success(_sortByCreatedDesc(list));
    } catch (e, st) {
      logger.error('[$tableName] getByDateRange failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<T>, AppError>> getByUserId(String userId) async {
    try {
      final list = (await storage.getAllRecords(table: tableName, userId: userId))
          .map(fromJson)
          .toList(growable: false);
      return Success(_sortByCreatedDesc(list));
    } catch (e, st) {
      logger.error('[$tableName] getByUserId failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<int, AppError>> count() async {
    final rows = await storage.getAllRecords(table: tableName);
    return Success(rows.length);
  }

  @override
  Future<Result<int, AppError>> countActive() async {
    final active = (await storage.getAllRecords(table: tableName))
        .map(fromJson)
        .where((item) => item.isActive)
        .length;
    return Success(active);
  }

  @override
  Future<Result<int, AppError>> countDeleted() async {
    final deleted = (await storage.getAllRecords(table: tableName))
        .map(fromJson)
        .where((item) => item.isDeleted)
        .length;
    return Success(deleted);
  }

  @override
  Future<Result<List<T>, AppError>> getDeleted() async {
    try {
      final list = (await storage.getAllRecords(table: tableName))
          .map(fromJson)
          .where((item) => item.isDeleted)
          .toList(growable: false);
      return Success(_sortByCreatedDesc(list));
    } catch (e, st) {
      logger.error('[$tableName] getDeleted failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<T>, AppError>> query(Map<String, dynamic> filters) async {
    try {
      final list = (await storage.query(table: tableName, filters: filters))
          .map(fromJson)
          .toList(growable: false);
      return Success(_sortByCreatedDesc(list));
    } catch (e, st) {
      logger.error('[$tableName] query failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> restore(String id) async {
    try {
      final current = await storage.getRecord(table: tableName, id: id);
      if (current == null) {
        return Failure(NotFoundError('Entity not found: $id'));
      }
      current['deletedAt'] = null;
      await storage.upsertRecord(table: tableName, id: id, record: current);
      return const Success(null);
    } catch (e, st) {
      logger.error('[$tableName] restore failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<T>, AppError>> search(String searchTerm) async {
    try {
      final lowerTerm = searchTerm.toLowerCase();
      final list = (await storage.getAllRecords(table: tableName)).where((row) {
        final content = jsonEncode(row).toLowerCase();
        return content.contains(lowerTerm);
      }).map(fromJson).toList(growable: false);
      return Success(_sortByCreatedDesc(list));
    } catch (e, st) {
      logger.error('[$tableName] search failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  Future<Result<List<T>, AppError>> getPage({
    int page = 1,
    int pageSize = 20,
    String? userId,
  }) async {
    try {
      final all = await getAllRecordsForPagination(userId: userId);
      final start = (page - 1) * pageSize;
      if (start >= all.length) {
        return Success(<T>[]);
      }
      final end = ((start + pageSize).clamp(0, all.length) as num).toInt();
      return Success(all.sublist(start, end));
    } catch (e, st) {
      logger.error('[$tableName] getPage failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  Future<List<T>> getAllRecordsForPagination({String? userId}) async {
    final rows = await storage.getAllRecords(table: tableName, userId: userId);
    final items = rows.map(fromJson).toList(growable: false);
    return _sortByCreatedDesc(items);
  }

  @override
  Future<Result<void, AppError>> softDelete(String id) async {
    try {
      final current = await storage.getRecord(table: tableName, id: id);
      if (current == null) {
        return Failure(NotFoundError('Entity not found: $id'));
      }
      current['deletedAt'] = DateTime.now().toIso8601String();
      await storage.upsertRecord(table: tableName, id: id, record: current);
      return const Success(null);
    } catch (e, st) {
      logger.error('[$tableName] softDelete failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> update(T entity) async {
    try {
      final existing = await storage.getRecord(table: tableName, id: entity.id);
      if (existing == null) {
        return Failure(NotFoundError('Entity not found: ${entity.id}'));
      }
      await storage.upsertRecord(
        table: tableName,
        id: entity.id,
        record: entity.toJson(),
        userId: entity.toJson()['userId'] as String?,
      );
      return const Success(null);
    } catch (e, st) {
      logger.error('[$tableName] update failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> updateBulk(List<T> entities) async {
    try {
      for (final entity in entities) {
        await storage.upsertRecord(
          table: tableName,
          id: entity.id,
          record: entity.toJson(),
          userId: entity.toJson()['userId'] as String?,
        );
      }
      return const Success(null);
    } catch (e, st) {
      logger.error('[$tableName] updateBulk failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> vacuum() async {
    await storage.vacuum();
    return const Success(null);
  }

  List<T> _sortByCreatedDesc(List<T> items) {
    final sorted = [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
}
