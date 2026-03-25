import 'dart:convert';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../shared/infrastructure/logger_service.dart';
import '../models/base_model.dart';
import 'base_repository.dart';

abstract class BaseRepositoryImpl<T extends BaseModel>
    implements BaseRepository<T> {
  static final Map<String, Map<String, Map<String, dynamic>>> _tables =
      <String, Map<String, Map<String, dynamic>>>{};

  final LoggerService logger;

  String get tableName;
  T fromJson(Map<String, dynamic> json);

  const BaseRepositoryImpl(this.logger);

  Map<String, Map<String, dynamic>> get _table {
    return _tables.putIfAbsent(tableName, () => <String, Map<String, dynamic>>{});
  }

  @override
  Future<Result<T, AppError>> create(T entity) async {
    try {
      _table[entity.id] = entity.toJson();
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
        _table[entity.id] = entity.toJson();
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
      _table.remove(id);
      return const Success(null);
    } catch (e, st) {
      logger.error('[$tableName] delete failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> deleteAll() async {
    try {
      _table.clear();
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
        _table.remove(id);
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
      final list = _table.values
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
      final list = _table.values.map(fromJson).toList(growable: false);
      return Success(_sortByCreatedDesc(list));
    } catch (e, st) {
      logger.error('[$tableName] getAll failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<T?, AppError>> getById(String id) async {
    try {
      final value = _table[id];
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
      final list = _table.values
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
      final list = _table.values
          .where((row) => row['userId'] == userId)
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
    return Success(_table.length);
  }

  @override
  Future<Result<int, AppError>> countActive() async {
    final active = _table.values
        .map(fromJson)
        .where((item) => item.isActive)
        .length;
    return Success(active);
  }

  @override
  Future<Result<int, AppError>> countDeleted() async {
    final deleted = _table.values
        .map(fromJson)
        .where((item) => item.isDeleted)
        .length;
    return Success(deleted);
  }

  @override
  Future<Result<List<T>, AppError>> getDeleted() async {
    try {
      final list = _table.values
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
      final list = _table.values.where((row) {
        for (final entry in filters.entries) {
          if (row[entry.key] != entry.value) {
            return false;
          }
        }
        return true;
      }).map(fromJson).toList(growable: false);
      return Success(_sortByCreatedDesc(list));
    } catch (e, st) {
      logger.error('[$tableName] query failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> restore(String id) async {
    try {
      final current = _table[id];
      if (current == null) {
        return Failure(NotFoundError('Entity not found: $id'));
      }
      current['deletedAt'] = null;
      _table[id] = current;
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
      final list = _table.values.where((row) {
        final content = jsonEncode(row).toLowerCase();
        return content.contains(lowerTerm);
      }).map(fromJson).toList(growable: false);
      return Success(_sortByCreatedDesc(list));
    } catch (e, st) {
      logger.error('[$tableName] search failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> softDelete(String id) async {
    try {
      final current = _table[id];
      if (current == null) {
        return Failure(NotFoundError('Entity not found: $id'));
      }
      current['deletedAt'] = DateTime.now().toIso8601String();
      _table[id] = current;
      return const Success(null);
    } catch (e, st) {
      logger.error('[$tableName] softDelete failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> update(T entity) async {
    try {
      if (!_table.containsKey(entity.id)) {
        return Failure(NotFoundError('Entity not found: ${entity.id}'));
      }
      _table[entity.id] = entity.toJson();
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
        _table[entity.id] = entity.toJson();
      }
      return const Success(null);
    } catch (e, st) {
      logger.error('[$tableName] updateBulk failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> vacuum() async {
    return const Success(null);
  }

  List<T> _sortByCreatedDesc(List<T> items) {
    final sorted = [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
}
