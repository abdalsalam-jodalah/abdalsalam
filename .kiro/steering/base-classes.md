# Base Classes - Foundation for All Implementations

## Overview
These base classes provide the foundation for all models, repositories, and services in the application.

## Base Model

ALL data models MUST extend this base class:

```dart
// lib/data/models/base_model.dart
import 'package:equatable/equatable.dart';

abstract class BaseModel extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  
  const BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  
  /// Convert model to JSON
  Map<String, dynamic> toJson();
  
  /// Check if model is soft deleted
  bool get isDeleted => deletedAt != null;
  
  /// Check if model is active
  bool get isActive => deletedAt == null;
  
  /// Base equality comparison (id only)
  @override
  List<Object?> get props => [id];
  
  /// String representation
  @override
  String toString() => '$runtimeType(id: $id)';
}
```

## Base Repository Interface

ALL repositories MUST implement this interface:

```dart
// lib/data/repositories/base_repository.dart
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

abstract class BaseRepository<T extends BaseModel> {
  // CRUD Operations
  Future<Result<T, Error>> create(T entity);
  Future<Result<T?, Error>> getById(String id);
  Future<Result<List<T>, Error>> getAll();
  Future<Result<List<T>, Error>> getActive();
  Future<Result<List<T>, Error>> getDeleted();
  Future<Result<void, Error>> update(T entity);
  Future<Result<void, Error>> delete(String id);
  Future<Result<void, Error>> softDelete(String id);
  Future<Result<void, Error>> restore(String id);
  
  // Bulk Operations
  Future<Result<List<T>, Error>> createBulk(List<T> entities);
  Future<Result<void, Error>> updateBulk(List<T> entities);
  Future<Result<void, Error>> deleteBulk(List<String> ids);
  
  // Query Operations
  Future<Result<List<T>, Error>> getByDateRange(DateTime start, DateTime end);
  Future<Result<List<T>, Error>> getByUserId(String userId);
  Future<Result<List<T>, Error>> query(Map<String, dynamic> filters);
  Future<Result<List<T>, Error>> search(String searchTerm);
  
  // Count Operations
  Future<Result<int, Error>> count();
  Future<Result<int, Error>> countActive();
  Future<Result<int, Error>> countDeleted();
  
  // Utility Operations
  Future<Result<void, Error>> deleteAll();
  Future<Result<void, Error>> vacuum();
}
```

## Base Repository Implementation

```dart
// lib/data/repositories/base_repository_impl.dart
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

abstract class BaseRepositoryImpl<T extends BaseModel> 
    implements BaseRepository<T> {
  final StorageGateway storage;
  final LoggerService logger;
  
  /// Table name in database
  String get tableName;
  
  /// Convert JSON to model
  T fromJson(Map<String, dynamic> json);
  
  const BaseRepositoryImpl(this.storage, this.logger);
  
  @override
  Future<Result<T, Error>> create(T entity) async {
    try {
      await storage.save(
        key: '${tableName}_${entity.id}',
        value: entity.toJson(),
        storageType: StorageType.sqlite,
      );
      logger.info('[$tableName] Created: ${entity.id}');
      return Success(entity);
    } catch (e, st) {
      logger.error('[$tableName] Create failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
  
  @override
  Future<Result<T?, Error>> getById(String id) async {
    try {
      final data = await storage.get<Map<String, dynamic>>(
        '${tableName}_$id',
      );
      if (data == null) {
        return Success(null);
      }
      return Success(fromJson(data));
    } catch (e, st) {
      logger.error('[$tableName] GetById failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
  
  @override
  Future<Result<List<T>, Error>> getAll() async {
    try {
      final results = await storage.query(
        table: tableName,
        orderBy: 'createdAt DESC',
      );
      final entities = results.map((json) => fromJson(json)).toList();
      return Success(entities);
    } catch (e, st) {
      logger.error('[$tableName] GetAll failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
  
  @override
  Future<Result<List<T>, Error>> getActive() async {
    try {
      final results = await storage.query(
        table: tableName,
        where: 'deletedAt IS NULL',
        orderBy: 'createdAt DESC',
      );
      final entities = results.map((json) => fromJson(json)).toList();
      return Success(entities);
    } catch (e, st) {
      logger.error('[$tableName] GetActive failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
  
  @override
  Future<Result<void, Error>> softDelete(String id) async {
    try {
      final result = await getById(id);
      if (result.isFailure || result.data == null) {
        return Failure(NotFoundError('Entity not found'));
      }
      
      await storage.update(
        table: tableName,
        values: {'deletedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      logger.info('[$tableName] Soft deleted: $id');
      return Success(null);
    } catch (e, st) {
      logger.error('[$tableName] SoftDelete failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
  
  // Implement other methods following same pattern...
}
```

## Base Service Interface

```dart
// lib/shared/services/base_service.dart
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

abstract class BaseService<T extends BaseModel> {
  // Service metadata
  String get serviceName;
  String get version;
  
  // CRUD Operations
  Future<Result<T, Error>> create(T entity);
  Future<Result<T?, Error>> getById(String id);
  Future<Result<List<T>, Error>> getAll();
  Future<Result<List<T>, Error>> getActive();
  Future<Result<List<T>, Error>> getByDateRange(DateTime start, DateTime end);
  Future<Result<void, Error>> update(T entity);
  Future<Result<void, Error>> delete(String id);
  Future<Result<void, Error>> softDelete(String id);
  
  // Bulk Operations
  Future<Result<List<T>, Error>> createBulk(List<T> entities);
  Future<Result<void, Error>> updateBulk(List<T> entities);
  Future<Result<void, Error>> deleteBulk(List<String> ids);
  
  // Search & Filter
  Future<Result<List<T>, Error>> search(String query);
  Future<Result<List<T>, Error>> filter(Map<String, dynamic> filters);
  
  // Export & Import
  Future<Result<String, Error>> exportToJson();
  Future<Result<Map<String, dynamic>, Error>> exportWithMetadata();
  Future<Result<void, Error>> importFromJson(String json);
  Future<Result<void, Error>> importWithValidation(Map<String, dynamic> data);
  
  // Statistics & Analytics
  Future<Result<int, Error>> count();
  Future<Result<Map<String, dynamic>, Error>> getStatistics();
  Future<Result<Map<String, dynamic>, Error>> getMetadata();
  Future<Result<List<T>, Error>> getRecent(int limit);
  
  // Validation
  Result<void, Error> validate(T entity);
  Result<void, Error> validateBulk(List<T> entities);
  
  // Backup & Restore
  Future<Result<String, Error>> backup();
  Future<Result<void, Error>> restore(String backupData);
}
```

## Base Service Implementation

```dart
// lib/shared/services/base_service_impl.dart
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

abstract class BaseServiceImpl<T extends BaseModel> implements BaseService<T> {
  final BaseRepository<T> repository;
  final LoggerService logger;
  final StorageGateway storage;
  final AppStateManager appState;
  
  const BaseServiceImpl({
    required this.repository,
    required this.logger,
    required this.storage,
    required this.appState,
  });
  
  @override
  Future<Result<T, Error>> create(T entity) async {
    try {
      // Validate
      final validation = validate(entity);
      if (validation.isFailure) {
        return Failure(validation.error);
      }
      
      // Create
      final result = await repository.create(entity);
      
      if (result.isSuccess) {
        logger.info('[$serviceName] Created entity: ${entity.id}');
      }
      
      return result;
    } catch (e, st) {
      logger.error('[$serviceName] Create failed', error: e, stackTrace: st);
      return Failure(ServiceError(e.toString()));
    }
  }
  
  @override
  Future<Result<Map<String, dynamic>, Error>> exportWithMetadata() async {
    try {
      final allData = await repository.getAll();
      if (allData.isFailure) {
        return Failure(allData.error);
      }
      
      final stats = await getStatistics();
      final metadata = await getMetadata();
      
      final dataList = allData.data!.map((e) => e.toJson()).toList();
      final checksum = _calculateChecksum(dataList);
      
      final export = {
        'metadata': {
          ...metadata.data!,
          'exportedAt': DateTime.now().toIso8601String(),
          'recordCount': dataList.length,
          'checksum': checksum,
        },
        'data': dataList,
        'statistics': stats.data ?? {},
      };
      
      logger.info('[$serviceName] Exported ${dataList.length} records');
      return Success(export);
    } catch (e, st) {
      logger.error('[$serviceName] Export failed', error: e, stackTrace: st);
      return Failure(ExportError(e.toString()));
    }
  }
  
  @override
  Future<Result<Map<String, dynamic>, Error>> getMetadata() async {
    try {
      final countResult = await repository.count();
      final activeResult = await repository.countActive();
      final deletedResult = await repository.countDeleted();
      
      final metadata = {
        'serviceName': serviceName,
        'version': version,
        'totalRecords': countResult.data ?? 0,
        'activeRecords': activeResult.data ?? 0,
        'deletedRecords': deletedResult.data ?? 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      return Success(metadata);
    } catch (e, st) {
      logger.error('[$serviceName] GetMetadata failed', error: e, stackTrace: st);
      return Failure(ServiceError(e.toString()));
    }
  }
  
  String _calculateChecksum(List<Map<String, dynamic>> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Implement other common methods...
}
```

## Error Types

```dart
// lib/core/errors/app_errors.dart

abstract class AppError {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const AppError(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'AppError: $message${code != null ? ' ($code)' : ''}';
}

class DatabaseError extends AppError {
  const DatabaseError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class ValidationError extends AppError {
  const ValidationError(String message, {String? code})
      : super(message, code: code);
}

class ServiceError extends AppError {
  const ServiceError(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class NotFoundError extends AppError {
  const NotFoundError(String message) : super(message, code: 'NOT_FOUND');
}

class ExportError extends AppError {
  const ExportError(String message) : super(message, code: 'EXPORT_ERROR');
}

class ImportError extends AppError {
  const ImportError(String message) : super(message, code: 'IMPORT_ERROR');
}

class NetworkError extends AppError {
  const NetworkError(String message) : super(message, code: 'NETWORK_ERROR');
}

class AuthError extends AppError {
  const AuthError(String message) : super(message, code: 'AUTH_ERROR');
}
```

## Result Type

```dart
// lib/core/types/result.dart

abstract class Result<T, E> {
  const Result();
  
  bool get isSuccess;
  bool get isFailure;
  
  T? get data;
  E? get error;
}

class Success<T, E> extends Result<T, E> {
  final T _data;
  
  const Success(this._data);
  
  @override
  bool get isSuccess => true;
  
  @override
  bool get isFailure => false;
  
  @override
  T get data => _data;
  
  @override
  E? get error => null;
}

class Failure<T, E> extends Result<T, E> {
  final E _error;
  
  const Failure(this._error);
  
  @override
  bool get isSuccess => false;
  
  @override
  bool get isFailure => true;
  
  @override
  T? get data => null;
  
  @override
  E get error => _error;
}
```

## CRITICAL IMPLEMENTATION RULES

1. **ALL models MUST extend BaseModel**
2. **ALL repositories MUST implement BaseRepository**
3. **ALL services MUST implement BaseService**
4. **ALL operations MUST return Result<T, Error>**
5. **ALL errors MUST extend AppError**
6. **ALL implementations MUST log operations**
7. **ALL public methods MUST be documented**
8. **ALL base methods MUST be implemented (no empty stubs)**

## Usage Example

```dart
// Model
class PrayerLog extends BaseModel {
  final String userId;
  final PrayerType type;
  
  const PrayerLog({
    required String id,
    required this.userId,
    required this.type,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };
  
  factory PrayerLog.fromJson(Map<String, dynamic> json) => PrayerLog(
    id: json['id'],
    userId: json['userId'],
    type: PrayerType.values.byName(json['type']),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    deletedAt: json['deletedAt'] != null 
        ? DateTime.parse(json['deletedAt']) 
        : null,
  );
}

// Repository
class PrayerRepositoryImpl extends BaseRepositoryImpl<PrayerLog> {
  @override
  String get tableName => 'prayers';
  
  const PrayerRepositoryImpl(StorageGateway storage, LoggerService logger)
      : super(storage, logger);
  
  @override
  PrayerLog fromJson(Map<String, dynamic> json) => PrayerLog.fromJson(json);
}

// Service
class PrayerService extends BaseServiceImpl<PrayerLog> {
  @override
  String get serviceName => 'PrayerService';
  
  @override
  String get version => '1.0.0';
  
  const PrayerService({
    required PrayerRepository repository,
    required LoggerService logger,
    required StorageGateway storage,
    required AppStateManager appState,
  }) : super(
    repository: repository,
    logger: logger,
    storage: storage,
    appState: appState,
  );
  
  @override
  Result<void, Error> validate(PrayerLog entity) {
    if (entity.userId.isEmpty) {
      return Failure(ValidationError('User ID is required'));
    }
    return Success(null);
  }
  
  @override
  Future<Result<Map<String, dynamic>, Error>> getStatistics() async {
    // Custom statistics for prayer service
    final baseStats = await super.getStatistics();
    // Add prayer-specific stats
    return baseStats;
  }
}
```

This baseline ensures ALL services have consistent behavior, proper OOP design, and comprehensive functionality!
