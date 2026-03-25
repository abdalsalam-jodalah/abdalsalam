# Baseline Requirements - MANDATORY FOR ALL IMPLEMENTATIONS

## 🎯 Purpose

This document defines the **non-negotiable baseline** that ALL implementations in this project MUST follow. These are not suggestions - they are requirements.

## 📜 Core Principle

**Every service, repository, and model MUST follow the same baseline to ensure:**
- Consistency across all modules
- Maintainability and scalability
- Data export/import capability
- Comprehensive logging and error handling
- OOP best practices
- Testability

## 🏗️ The Three Pillars

### 1. Base Model (ALL models MUST extend)

```dart
abstract class BaseModel extends Equatable {
  final String id;              // UUID
  final DateTime createdAt;     // Creation timestamp
  final DateTime updatedAt;     // Last update timestamp
  final DateTime? deletedAt;    // Soft delete timestamp
  
  Map<String, dynamic> toJson();  // REQUIRED
  // fromJson() factory           // REQUIRED
  // copyWith()                   // REQUIRED
}
```

**Why?**
- Ensures all data is timestamped
- Supports soft deletes (data preservation)
- Guarantees exportability (toJson)
- Enables data tracking and auditing

### 2. Base Repository (ALL repositories MUST implement)

```dart
abstract class BaseRepository<T extends BaseModel> {
  // CRUD Operations (9 methods)
  Future<Result<T, Error>> create(T entity);
  Future<Result<T?, Error>> getById(String id);
  Future<Result<List<T>, Error>> getAll();
  Future<Result<List<T>, Error>> getActive();
  Future<Result<List<T>, Error>> getDeleted();
  Future<Result<void, Error>> update(T entity);
  Future<Result<void, Error>> delete(String id);
  Future<Result<void, Error>> softDelete(String id);
  Future<Result<void, Error>> restore(String id);
  
  // Bulk Operations (3 methods)
  Future<Result<List<T>, Error>> createBulk(List<T> entities);
  Future<Result<void, Error>> updateBulk(List<T> entities);
  Future<Result<void, Error>> deleteBulk(List<String> ids);
  
  // Query Operations (4 methods)
  Future<Result<List<T>, Error>> getByDateRange(DateTime start, DateTime end);
  Future<Result<List<T>, Error>> getByUserId(String userId);
  Future<Result<List<T>, Error>> query(Map<String, dynamic> filters);
  Future<Result<List<T>, Error>> search(String searchTerm);
  
  // Count Operations (3 methods)
  Future<Result<int, Error>> count();
  Future<Result<int, Error>> countActive();
  Future<Result<int, Error>> countDeleted();
  
  // Utility Operations (2 methods)
  Future<Result<void, Error>> deleteAll();
  Future<Result<void, Error>> vacuum();
}
```

**Total: 24 required methods**

**Why?**
- Standardizes data access patterns
- Supports bulk operations for efficiency
- Enables flexible querying
- Provides statistics capabilities
- Maintains data integrity

### 3. Base Service (ALL services MUST implement)

```dart
abstract class BaseService<T extends BaseModel> {
  // Metadata (2 getters)
  String get serviceName;
  String get version;
  
  // CRUD Operations (8 methods)
  Future<Result<T, Error>> create(T entity);
  Future<Result<T?, Error>> getById(String id);
  Future<Result<List<T>, Error>> getAll();
  Future<Result<List<T>, Error>> getActive();
  Future<Result<List<T>, Error>> getByDateRange(DateTime start, DateTime end);
  Future<Result<void, Error>> update(T entity);
  Future<Result<void, Error>> delete(String id);
  Future<Result<void, Error>> softDelete(String id);
  
  // Bulk Operations (3 methods)
  Future<Result<List<T>, Error>> createBulk(List<T> entities);
  Future<Result<void, Error>> updateBulk(List<T> entities);
  Future<Result<void, Error>> deleteBulk(List<String> ids);
  
  // Search & Filter (2 methods)
  Future<Result<List<T>, Error>> search(String query);
  Future<Result<List<T>, Error>> filter(Map<String, dynamic> filters);
  
  // Export & Import (4 methods) - CRITICAL
  Future<Result<String, Error>> exportToJson();
  Future<Result<Map<String, dynamic>, Error>> exportWithMetadata();
  Future<Result<void, Error>> importFromJson(String json);
  Future<Result<void, Error>> importWithValidation(Map<String, dynamic> data);
  
  // Statistics & Analytics (4 methods)
  Future<Result<int, Error>> count();
  Future<Result<Map<String, dynamic>, Error>> getStatistics();
  Future<Result<Map<String, dynamic>, Error>> getMetadata();
  Future<Result<List<T>, Error>> getRecent(int limit);
  
  // Validation (2 methods)
  Result<void, Error> validate(T entity);
  Result<void, Error> validateBulk(List<T> entities);
  
  // Backup & Restore (2 methods)
  Future<Result<String, Error>> backup();
  Future<Result<void, Error>> restore(String backupData);
}
```

**Total: 27 required methods + 2 getters**

**Why?**
- Enforces business logic layer
- Guarantees export/import capability (data portability)
- Provides analytics out of the box
- Ensures validation is always present
- Supports backup and restore
- Enables future AI processing of data

## 🔒 Non-Negotiable Features

### 1. Export with Metadata

**EVERY service MUST support exporting data with complete metadata:**

```json
{
  "metadata": {
    "serviceName": "PrayerService",
    "version": "1.0.0",
    "exportedAt": "2026-03-25T10:00:00Z",
    "exportedBy": "user_id",
    "recordCount": 100,
    "dateRange": {
      "start": "2026-01-01T00:00:00Z",
      "end": "2026-03-25T23:59:59Z"
    },
    "checksum": "sha256_hash"
  },
  "data": [ /* array of records */ ],
  "statistics": { /* service stats */ }
}
```

**Why?**
- Enables data portability
- Supports future server integration
- Allows AI agent processing
- Provides data integrity verification
- Facilitates backup and migration

### 2. Import with Validation

**EVERY service MUST validate imported data:**

- Metadata validation
- Version compatibility check
- Checksum verification
- Data structure validation
- Business rule validation
- Duplicate detection

**Why?**
- Prevents data corruption
- Ensures data integrity
- Maintains consistency
- Protects against malformed imports

### 3. Comprehensive Logging

**EVERY operation MUST be logged:**

```dart
logger.info('[$serviceName] Operation started: $operationName');
logger.error('[$serviceName] Operation failed', error: e, stackTrace: st);
logger.debug('[$serviceName] Debug info: $details');
```

**Why?**
- Debugging and troubleshooting
- Audit trail
- Performance monitoring
- Error tracking

### 4. Error Handling

**ALL operations MUST return Result<T, Error>:**

```dart
try {
  // Operation
  return Success(result);
} catch (e, st) {
  logger.error('Failed', error: e, stackTrace: st);
  return Failure(ServiceError(e.toString()));
}
```

**Why?**
- Explicit error handling
- No uncaught exceptions
- Type-safe error propagation
- Better error messages

### 5. Data Validation

**ALL services MUST validate data before operations:**

```dart
Result<void, Error> validate(T entity) {
  final errors = <String>[];
  
  // Validation logic
  if (errors.isNotEmpty) {
    return Failure(ValidationError(errors.join(', ')));
  }
  
  return Success(null);
}
```

**Why?**
- Data integrity
- Prevents invalid data
- Clear error messages
- Business rule enforcement

### 6. State Awareness

**ALL services MUST be aware of app state:**

```dart
// Check connectivity
final state = await appState.stateStream.first;
if (state.isOffline) {
  return Failure(NetworkError('Device is offline'));
}

// Check battery
if (state.batteryInfo?.isLowBattery == true) {
  logger.warning('Low battery, deferring operation');
}
```

**Why?**
- Smart resource management
- Better user experience
- Battery optimization
- Offline support

### 7. User Isolation

**ALL data operations MUST respect user isolation:**

```dart
final userId = authService.currentUser?.id;
if (userId == null) {
  return Failure(AuthError('User not authenticated'));
}

await storage.saveForUser(
  userId: userId,
  key: key,
  value: value,
);
```

**Why?**
- Data privacy
- Multi-user support (future)
- Security
- Data segregation

## 📋 Implementation Checklist

Before considering ANY feature complete, verify:

### Critical Requirements
- [ ] Model extends BaseModel
- [ ] Repository implements BaseRepository (24 methods)
- [ ] Service implements BaseService (29 methods)
- [ ] All operations return Result<T, Error>
- [ ] Export with metadata works
- [ ] Import with validation works
- [ ] Statistics implemented
- [ ] Logging comprehensive
- [ ] Error handling complete
- [ ] Validation implemented
- [ ] State awareness implemented
- [ ] User isolation respected

### Quality Requirements
- [ ] Unit tests written (>80% coverage)
- [ ] Widget tests written
- [ ] Documentation complete
- [ ] Follows coding standards
- [ ] Follows OOP principles
- [ ] No hardcoded values
- [ ] No security issues
- [ ] Performance acceptable

## 🚫 Common Violations

### ❌ WRONG: Skipping Base Classes

```dart
// WRONG - Does not extend BaseModel
class MyModel {
  final String id;
  final String name;
}

// WRONG - Does not implement BaseRepository
class MyRepository {
  Future<MyModel> create(MyModel model) async {
    // Implementation
  }
}
```

### ✅ CORRECT: Following Baseline

```dart
// CORRECT - Extends BaseModel
class MyModel extends BaseModel {
  final String name;
  
  const MyModel({
    required String id,
    required this.name,
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
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };
}

// CORRECT - Implements BaseRepository
class MyRepositoryImpl extends BaseRepositoryImpl<MyModel> {
  @override
  String get tableName => 'my_table';
  
  @override
  MyModel fromJson(Map<String, dynamic> json) => MyModel.fromJson(json);
  
  // All 24 methods implemented
}
```

## 📚 Reference Documents

For detailed implementation guidance, see:

1. **base-classes.md** - Complete base class definitions
2. **service-baseline.md** - Service requirements and patterns
3. **implementation-checklist.md** - Step-by-step implementation guide
4. **coding-standards.md** - Code style and best practices
5. **architecture.md** - Architecture patterns and decisions

## 🎓 Learning Path

### For New Developers

1. Read this document first
2. Study base-classes.md
3. Review service-baseline.md
4. Follow implementation-checklist.md
5. Look at existing implementations as examples

### For Code Reviewers

1. Verify baseline compliance first
2. Check implementation-checklist.md
3. Ensure all required methods present
4. Verify export/import works
5. Check tests exist and pass

## ⚖️ Enforcement

These requirements are enforced through:

1. **Code Review** - Baseline compliance is mandatory
2. **Hooks** - Automated checks on file save
3. **Tests** - Base functionality must be tested
4. **Documentation** - Must follow standards

## 🔄 Updates

This baseline may evolve, but changes will be:
- Documented with version numbers
- Backward compatible when possible
- Communicated clearly
- Reflected in all steering documents

## ❓ FAQ

**Q: Can I skip a base method if I don't need it?**
A: No. Implement it even if it's simple. Future features may need it.

**Q: Can I add custom methods?**
A: Yes! Add as many as needed, but base methods are mandatory.

**Q: What if my feature doesn't need export?**
A: All features need export. It's for data portability and future AI processing.

**Q: Can I use a different error handling pattern?**
A: No. Result<T, Error> is mandatory for consistency.

**Q: Do I really need all 24 repository methods?**
A: Yes. They provide a complete data access layer.

**Q: What about performance?**
A: Base methods are optimized. Add caching if needed via mixins.

## 🎯 Remember

**The baseline exists to ensure:**
- Every module works the same way
- Data is always exportable
- Code is maintainable
- Future features are possible
- AI integration is ready
- Quality is consistent

**When in doubt, follow the baseline!**
