import 'dart:convert';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../shared/infrastructure/logger_service.dart';
import '../../shared/infrastructure/storage_gateway.dart';
import '../models/base_model.dart';
import 'base_repository.dart';
import 'record_parser.dart';
import 'repository_operation_guard.dart';

abstract class BaseRepositoryImpl<T extends BaseModel>
    implements BaseRepository<T> {
  final LoggerService logger;
  final StorageGateway storage;

  String get tableName;
  T fromJson(Map<String, dynamic> json);

  const BaseRepositoryImpl(this.storage, this.logger);

  RecordParser<T> get recordParser => RecordParser<T>(
        table: tableName,
        fromJson: fromJson,
        integrityReporter: storage.integrityReporter,
      );

  List<T> parseRecords(Iterable<Map<String, dynamic>> rows) => recordParser.parseAll(rows);

  Future<Result<R, AppError>> guardStorage<R>(String operation, Future<R> Function() body) {
    return RepositoryOperationGuard(table: tableName, logger: logger).run(operation, body);
  }

  @override
  Future<Result<T, AppError>> create(T entity) {
    return guardStorage('create', () async {
      await _write(entity);
      logger.info('[$tableName] created ${entity.id}');
      return entity;
    });
  }

  @override
  Future<Result<List<T>, AppError>> createBulk(List<T> entities) {
    return guardStorage('createBulk', () async {
      await storage.runInTransaction(() async {
        for (final entity in entities) {
          await _write(entity);
        }
      });
      logger.info('[$tableName] created bulk count=${entities.length}');
      return entities;
    });
  }

  @override
  Future<Result<void, AppError>> delete(String id) {
    return guardStorage('delete', () => storage.deleteRecord(table: tableName, id: id));
  }

  @override
  Future<Result<void, AppError>> deleteAll() {
    return guardStorage('deleteAll', () => storage.clearTable(tableName));
  }

  @override
  Future<Result<void, AppError>> deleteBulk(List<String> ids) {
    return guardStorage('deleteBulk', () async {
      await storage.runInTransaction(() async {
        for (final id in ids) {
          await storage.deleteRecord(table: tableName, id: id);
        }
      });
    });
  }

  @override
  Future<Result<List<T>, AppError>> getActive() {
    return guardStorage('getActive', () async {
      final items = await _readAll();
      return _sortByCreatedDesc(items.where((item) => item.isActive));
    });
  }

  @override
  Future<Result<List<T>, AppError>> getAll() {
    return guardStorage('getAll', () async => _sortByCreatedDesc(await _readAll()));
  }

  @override
  Future<Result<T?, AppError>> getById(String id) {
    return guardStorage('getById', () async {
      final value = await storage.getRecord(table: tableName, id: id);
      if (value == null) {
        return null;
      }
      return recordParser.parseOne(value);
    });
  }

  @override
  Future<Result<List<T>, AppError>> getByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return guardStorage('getByDateRange', () async {
      final items = await _readAll();
      return _sortByCreatedDesc(
        items.where((item) => !item.createdAt.isBefore(start) && !item.createdAt.isAfter(end)),
      );
    });
  }

  @override
  Future<Result<List<T>, AppError>> getByUserId(String userId) {
    return guardStorage('getByUserId', () async {
      final rows = await storage.getAllRecords(table: tableName, userId: userId);
      return _sortByCreatedDesc(parseRecords(rows));
    });
  }

  @override
  Future<Result<int, AppError>> count() {
    return guardStorage('count', () => storage.countRecords(table: tableName));
  }

  @override
  Future<Result<int, AppError>> countActive() {
    return guardStorage('countActive', () async => (await _readAll()).where((item) => item.isActive).length);
  }

  @override
  Future<Result<int, AppError>> countDeleted() {
    return guardStorage('countDeleted', () async => (await _readAll()).where((item) => item.isDeleted).length);
  }

  @override
  Future<Result<List<T>, AppError>> getDeleted() {
    return guardStorage('getDeleted', () async {
      final items = await _readAll();
      return _sortByCreatedDesc(items.where((item) => item.isDeleted));
    });
  }

  @override
  Future<Result<List<T>, AppError>> query(Map<String, dynamic> filters) {
    return guardStorage('query', () async {
      final rows = await storage.query(table: tableName, filters: filters);
      return _sortByCreatedDesc(parseRecords(rows));
    });
  }

  @override
  Future<Result<void, AppError>> restore(String id) {
    return _setDeletedAt('restore', id, null);
  }

  @override
  Future<Result<List<T>, AppError>> search(String searchTerm) {
    return guardStorage('search', () async {
      final lowerTerm = searchTerm.toLowerCase();
      final rows = await storage.getAllRecords(table: tableName);
      final matches = rows.where((row) => jsonEncode(row).toLowerCase().contains(lowerTerm));
      return _sortByCreatedDesc(parseRecords(matches));
    });
  }

  Future<Result<List<T>, AppError>> getPage({
    int page = 1,
    int pageSize = 20,
    String? userId,
  }) {
    return guardStorage('getPage', () async {
      final all = await getAllRecordsForPagination(userId: userId);
      final start = (page - 1) * pageSize;
      if (start < 0 || start >= all.length) {
        return <T>[];
      }
      final end = (start + pageSize).clamp(0, all.length);
      return all.sublist(start, end);
    });
  }

  Future<List<T>> getAllRecordsForPagination({String? userId}) async {
    final rows = await storage.getAllRecords(table: tableName, userId: userId);
    return _sortByCreatedDesc(parseRecords(rows));
  }

  @override
  Future<Result<void, AppError>> softDelete(String id) {
    return _setDeletedAt('softDelete', id, DateTime.now().toIso8601String());
  }

  @override
  Future<Result<void, AppError>> update(T entity) async {
    final existing = await guardStorage(
      'update',
      () => storage.getRecord(table: tableName, id: entity.id),
    );
    if (existing.isFailure) {
      return Failure(existing.error!);
    }
    if (existing.data == null) {
      return Failure(NotFoundError('Entity not found: ${entity.id}'));
    }
    return guardStorage('update', () => _write(entity));
  }

  @override
  Future<Result<void, AppError>> updateBulk(List<T> entities) {
    return guardStorage('updateBulk', () async {
      await storage.runInTransaction(() async {
        for (final entity in entities) {
          await _write(entity);
        }
      });
    });
  }

  @override
  Future<Result<void, AppError>> vacuum() {
    return guardStorage('vacuum', storage.vacuum);
  }

  Future<List<T>> _readAll() async {
    return parseRecords(await storage.getAllRecords(table: tableName));
  }

  Future<void> _write(T entity) async {
    final record = entity.toJson();
    await storage.upsertRecord(
      table: tableName,
      id: entity.id,
      record: record,
      userId: record['userId'] as String?,
    );
  }

  Future<Result<void, AppError>> _setDeletedAt(String operation, String id, String? deletedAt) async {
    final current = await guardStorage(operation, () => storage.getRecord(table: tableName, id: id));
    if (current.isFailure) {
      return Failure(current.error!);
    }
    final record = current.data;
    if (record == null) {
      return Failure(NotFoundError('Entity not found: $id'));
    }
    record['deletedAt'] = deletedAt;
    return guardStorage(operation, () => storage.upsertRecord(table: tableName, id: id, record: record));
  }

  List<T> _sortByCreatedDesc(Iterable<T> items) {
    return items.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
