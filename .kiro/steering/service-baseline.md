# Service Baseline - Standard Operations & OOP Principles

## Overview
All services in this project MUST follow this baseline to ensure consistency, maintainability, and common functionality across all modules.

## Base Service Interface

Every service MUST implement these core operations:

```dart
abstract class BaseService<T extends BaseModel> {
  // CRUD Operations
  Future<Result<T, Error>> create(T entity);
  Future<Result<T?, Error>> getById(String id);
  Future<Result<List<T>, Error>> getAll();
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
  Future<Result<List<T>, Error>> getRecent(int limit);
  
  // Sync & Backup
  Future<Result<void, Error>> syncWithServer();
  Future<Result<String, Error>> backup();
  Future<Result<void, Error>> restore(String backupData);
  
  // Validation
  Result<void, Error> validate(T entity);
  Result<void, Error> validateBulk(List<T> entities);
}
```

## Implementation Template

```dart
class MyFeatureService extends BaseService<MyModel> {
  final MyRepository _repository;
  final LoggerService _logger;
  final StorageGateway _storage;
  final AppStateManager _appState;
  
  // Metadata
  static const String serviceName = 'MyFeatureService';
  static const String version = '1.0.0';
  
  const MyFeatureService(
    this._repository,
    this._logger,
    this._storage,
    this._appState,
  );
  
  // Implement all base methods...
}
```

## Required Metadata

Every service MUST track and provide:

```dart
class ServiceMetadata {
  final String serviceName;
  final String version;
  final DateTime lastSync;
  final int totalRecords;
  final int activeRecords;
  final int deletedRecords;
  final DateTime oldestRecord;
  final DateTime newestRecord;
  final Map<String, dynamic> customMetrics;
  
  Map<String, dynamic> toJson();
}
```

## Export Format Standard

All services MUST export data in this format:

```dart
{
  "metadata": {
    "serviceName": "MyFeatureService",
    "version": "1.0.0",
    "exportedAt": "2026-03-25T10:00:00Z",
    "exportedBy": "user_id",
    "recordCount": 100,
    "dateRange": {
      "start": "2026-01-01T00:00:00Z",
      "end": "2026-03-25T23:59:59Z"
    },
    "filters": {},
    "checksum": "sha256_hash"
  },
  "data": [
    // Array of model JSON objects
  ],
  "statistics": {
    // Service-specific statistics
  }
}
```

## Common Functionality Requirements

### 1. Logging
```dart
// Log all operations
_logger.info('[$serviceName] Operation started: $operationName');
_logger.error('[$serviceName] Operation failed', error: e, stackTrace: st);
```

### 2. Error Handling
```dart
try {
  // Operation
  _logger.info('Success');
  return Success(result);
} catch (e, st) {
  _logger.error('Failed', error: e, stackTrace: st);
  return Failure(ServiceError(
    message: 'Operation failed',
    code: 'ERROR_CODE',
    originalError: e,
  ));
}
```

### 3. Validation
```dart
@override
Result<void, Error> validate(MyModel entity) {
  final errors = <String>[];
  
  if (entity.field.isEmpty) {
    errors.add('Field is required');
  }
  
  if (errors.isNotEmpty) {
    return Failure(ValidationError(errors.join(', ')));
  }
  
  return Success(null);
}
```

### 4. State Awareness
```dart
// Check connectivity before sync
final state = await _appState.stateStream.first;
if (state.isOffline) {
  return Failure(NetworkError('Device is offline'));
}

// Check battery before heavy operations
if (state.batteryInfo?.isLowBattery == true) {
  _logger.warning('Low battery, deferring operation');
  // Queue for later
}
```

### 5. User Isolation
```dart
// All operations must respect current user
final userId = _authService.currentUser?.id;
if (userId == null) {
  return Failure(AuthError('User not authenticated'));
}

// Use user-isolated storage
await _storage.saveForUser(
  userId: userId,
  key: key,
  value: value,
);
```

## Standard Methods Implementation

### Export with Metadata
```dart
@override
Future<Result<Map<String, dynamic>, Error>> exportWithMetadata() async {
  try {
    final data = await _repository.getAll();
    final stats = await getStatistics();
    final metadata = await _getServiceMetadata();
    
    final export = {
      'metadata': {
        'serviceName': serviceName,
        'version': version,
        'exportedAt': DateTime.now().toIso8601String(),
        'recordCount': data.length,
        'checksum': _calculateChecksum(data),
      },
      'data': data.map((e) => e.toJson()).toList(),
      'statistics': stats,
    };
    
    _logger.info('[$serviceName] Exported ${data.length} records');
    return Success(export);
  } catch (e, st) {
    _logger.error('[$serviceName] Export failed', error: e, stackTrace: st);
    return Failure(ExportError(e.toString()));
  }
}
```

### Import with Validation
```dart
@override
Future<Result<void, Error>> importWithValidation(
  Map<String, dynamic> data,
) async {
  try {
    // Validate metadata
    final metadata = data['metadata'] as Map<String, dynamic>?;
    if (metadata == null) {
      return Failure(ValidationError('Missing metadata'));
    }
    
    // Validate version compatibility
    final importVersion = metadata['version'] as String?;
    if (!_isVersionCompatible(importVersion)) {
      return Failure(ValidationError('Incompatible version'));
    }
    
    // Validate checksum
    final dataList = data['data'] as List;
    final expectedChecksum = metadata['checksum'] as String;
    final actualChecksum = _calculateChecksum(dataList);
    if (expectedChecksum != actualChecksum) {
      return Failure(ValidationError('Checksum mismatch'));
    }
    
    // Parse and validate entities
    final entities = <MyModel>[];
    for (final json in dataList) {
      final entity = MyModel.fromJson(json);
      final validation = validate(entity);
      if (validation.isFailure) {
        return validation;
      }
      entities.add(entity);
    }
    
    // Import
    await createBulk(entities);
    
    _logger.info('[$serviceName] Imported ${entities.length} records');
    return Success(null);
  } catch (e, st) {
    _logger.error('[$serviceName] Import failed', error: e, stackTrace: st);
    return Failure(ImportError(e.toString()));
  }
}
```

### Get Statistics
```dart
@override
Future<Result<Map<String, dynamic>, Error>> getStatistics() async {
  try {
    final all = await _repository.getAll();
    final active = all.where((e) => e.deletedAt == null).toList();
    final deleted = all.where((e) => e.deletedAt != null).toList();
    
    final stats = {
      'total': all.length,
      'active': active.length,
      'deleted': deleted.length,
      'oldest': active.isEmpty ? null : active
          .reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b)
          .createdAt.toIso8601String(),
      'newest': active.isEmpty ? null : active
          .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
          .createdAt.toIso8601String(),
      // Add service-specific metrics
      ...await _getCustomStatistics(),
    };
    
    return Success(stats);
  } catch (e, st) {
    _logger.error('[$serviceName] Stats failed', error: e, stackTrace: st);
    return Failure(ServiceError(e.toString()));
  }
}
```

## OOP Principles to Follow

### 1. Single Responsibility
Each service handles ONE feature module only.

### 2. Open/Closed Principle
Services are open for extension but closed for modification.
Use inheritance or composition to extend functionality.

### 3. Liskov Substitution
Any service can be replaced with its subtype without breaking the app.

### 4. Interface Segregation
Services implement only the interfaces they need.
Use mixins for optional functionality.

### 5. Dependency Inversion
Services depend on abstractions (interfaces), not concrete implementations.

## Optional Mixins for Extended Functionality

### Sync Mixin
```dart
mixin SyncMixin<T extends BaseModel> on BaseService<T> {
  Future<Result<void, Error>> syncWithServer() async {
    // Sync implementation
  }
  
  Future<Result<void, Error>> pushChanges() async {
    // Push local changes to server
  }
  
  Future<Result<void, Error>> pullChanges() async {
    // Pull server changes to local
  }
}
```

### Cache Mixin
```dart
mixin CacheMixin<T extends BaseModel> on BaseService<T> {
  final Map<String, T> _cache = {};
  
  Future<Result<T?, Error>> getCached(String id) async {
    if (_cache.containsKey(id)) {
      return Success(_cache[id]);
    }
    final result = await getById(id);
    if (result.isSuccess && result.data != null) {
      _cache[id] = result.data!;
    }
    return result;
  }
  
  void clearCache() => _cache.clear();
}
```

### Analytics Mixin
```dart
mixin AnalyticsMixin<T extends BaseModel> on BaseService<T> {
  Future<Result<Map<String, dynamic>, Error>> getTrends() async {
    // Trend analysis
  }
  
  Future<Result<List<Insight>, Error>> getInsights() async {
    // AI-driven insights
  }
}
```

## Service Registration Pattern

```dart
// Use dependency injection
final getIt = GetIt.instance;

void registerServices() {
  // Register core services
  getIt.registerSingleton<LoggerService>(LoggerServiceImpl());
  getIt.registerSingleton<StorageGateway>(StorageGateway.instance);
  getIt.registerSingleton<AppStateManager>(appStateManager);
  
  // Register repositories
  getIt.registerFactory<MyRepository>(
    () => MyRepositoryImpl(getIt(), getIt()),
  );
  
  // Register services
  getIt.registerFactory<MyFeatureService>(
    () => MyFeatureService(getIt(), getIt(), getIt(), getIt()),
  );
}
```

## Testing Requirements

Every service MUST have:

1. Unit tests for all public methods
2. Mock dependencies
3. Test edge cases
4. Test error handling
5. Test validation logic
6. Test export/import functionality

```dart
void main() {
  group('MyFeatureService', () {
    late MyFeatureService service;
    late MockRepository mockRepo;
    late MockLogger mockLogger;
    
    setUp(() {
      mockRepo = MockRepository();
      mockLogger = MockLogger();
      service = MyFeatureService(mockRepo, mockLogger, ...);
    });
    
    test('create should save entity', () async {
      // Test implementation
    });
    
    test('exportWithMetadata should include all fields', () async {
      // Test implementation
    });
    
    // More tests...
  });
}
```

## CRITICAL RULES

1. **ALL services MUST extend or implement BaseService**
2. **ALL services MUST support export with metadata**
3. **ALL services MUST validate data before operations**
4. **ALL services MUST log operations**
5. **ALL services MUST handle errors gracefully**
6. **ALL services MUST respect user isolation**
7. **ALL services MUST be state-aware (online/offline, battery)**
8. **ALL services MUST have comprehensive tests**
9. **ALL services MUST follow OOP principles**
10. **ALL services MUST be documented**

## Service Checklist

Before considering a service complete, verify:

- [ ] Extends/implements BaseService
- [ ] All CRUD operations implemented
- [ ] Bulk operations supported
- [ ] Export with metadata works
- [ ] Import with validation works
- [ ] Statistics method implemented
- [ ] Validation logic present
- [ ] Error handling comprehensive
- [ ] Logging on all operations
- [ ] User isolation respected
- [ ] State awareness implemented
- [ ] Unit tests written (>80% coverage)
- [ ] Documentation complete
- [ ] Follows OOP principles
- [ ] Registered in DI container
