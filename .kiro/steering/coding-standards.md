# Coding Standards

## Dart/Flutter Best Practices

### Naming Conventions
- Classes: `UpperCamelCase` (e.g., `PrayerLogModel`, `FinancialRepository`)
- Variables/Functions: `lowerCamelCase` (e.g., `prayerTime`, `calculateTotal()`)
- Constants: `lowerCamelCase` with `const` (e.g., `const maxRetries = 3`)
- Private members: prefix with `_` (e.g., `_privateMethod()`)
- Files: `snake_case` (e.g., `prayer_log_model.dart`)

### Code Organization
```dart
// Order within a class:
1. Static constants
2. Static variables
3. Instance variables (public then private)
4. Constructors
5. Static methods
6. Instance methods (public then private)
7. Overridden methods
```

### Widget Guidelines
- Prefer `const` constructors whenever possible
- Extract complex widgets into separate classes
- Keep `build()` methods under 50 lines
- Use `StatelessWidget` unless state is needed
- Name widgets descriptively: `PrayerTimeCard`, `ExpenseListItem`

### State Management Rules
- Keep business logic out of widgets
- Use services/repositories for data operations
- Separate UI state from domain state
- Dispose controllers and streams properly

### Error Handling
```dart
// Use Result/Either pattern for operations that can fail
Result<T, Error> performOperation() {
  try {
    // operation
    return Success(data);
  } catch (e) {
    return Failure(Error(e.toString()));
  }
}

// Handle errors at appropriate levels
// Show user-friendly messages in UI
```

### Async/Await
- Always use `async`/`await` over raw Futures
- Handle errors with try-catch
- Use `FutureBuilder` or `StreamBuilder` in widgets
- Cancel streams in `dispose()`

### Comments & Documentation
```dart
/// Public APIs must have doc comments
/// 
/// Explains what the function does, parameters, and return value
/// Use triple slash for documentation
String formatPrayerTime(DateTime time) {
  // Implementation comments use double slash
  return time.toString();
}
```

## CRITICAL: Base Classes Requirements

**ALL implementations MUST follow the baseline defined in `base-classes.md` and `service-baseline.md`**

### Mandatory Base Classes
1. **ALL models** → Extend `BaseModel`
2. **ALL repositories** → Implement `BaseRepository<T>`
3. **ALL services** → Implement `BaseService<T>`
4. **ALL operations** → Return `Result<T, Error>`
5. **ALL errors** → Extend `AppError`

### Non-Negotiable Features
Every service MUST support:
- CRUD operations (create, read, update, delete)
- Bulk operations (createBulk, updateBulk, deleteBulk)
- Export with metadata (exportWithMetadata)
- Import with validation (importWithValidation)
- Statistics and analytics (getStatistics, getMetadata)
- Search and filter capabilities
- Soft delete support
- Comprehensive logging
- Data validation

## Data Layer Standards

### Models
```dart
class PrayerLog extends BaseModel {
  final String userId;
  final PrayerType type;
  final DateTime performedAt;
  final bool onTime;
  
  const PrayerLog({
    required String id,
    required this.userId,
    required this.type,
    required this.performedAt,
    required this.onTime,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt);
  
  // Always implement toJson/fromJson
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'performedAt': performedAt.toIso8601String(),
    'onTime': onTime,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };
  
  factory PrayerLog.fromJson(Map<String, dynamic> json) => PrayerLog(
    id: json['id'],
    userId: json['userId'],
    type: PrayerType.values.byName(json['type']),
    performedAt: DateTime.parse(json['performedAt']),
    onTime: json['onTime'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
  );
  
  // Implement copyWith for immutability
  PrayerLog copyWith({...}) => PrayerLog(...);
  
  // Override equality
  @override
  bool operator ==(Object other) => ...;
  
  @override
  int get hashCode => ...;
}
```

### Repositories (MUST extend BaseRepositoryImpl)

**CRITICAL**: All repositories MUST extend `BaseRepositoryImpl<T>` and implement all required methods.
```dart
abstract class PrayerRepository {
  Future<Result<PrayerLog, Error>> create(PrayerLog prayer);
  Future<Result<List<PrayerLog>, Error>> getByDateRange(DateTime start, DateTime end);
  Future<Result<void, Error>> update(PrayerLog prayer);
  Future<Result<void, Error>> delete(String id);
}

class PrayerRepositoryImpl implements PrayerRepository {
  final Database _db;
  
  const PrayerRepositoryImpl(this._db);
  
  @override
  Future<Result<PrayerLog, Error>> create(PrayerLog prayer) async {
    try {
      await _db.insert('prayers', prayer.toJson());
      return Success(prayer);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }
}
```

## UI Standards

### Responsive Design
- Use `MediaQuery` for screen dimensions
- Support both portrait and landscape
- Test on different screen sizes
- Use `LayoutBuilder` for adaptive layouts

### Accessibility
- Provide `Semantics` widgets for screen readers
- Use sufficient color contrast
- Support text scaling
- Add meaningful labels to interactive elements

### Theme & Styling
- Define colors in theme
- Use consistent spacing (8px grid)
- Extract text styles to theme
- Support dark mode from the start

### Performance
- Use `const` constructors
- Avoid rebuilding entire trees
- Use `ListView.builder` for long lists
- Implement pagination for large datasets
- Profile with DevTools before optimizing

## Security Standards

### Sensitive Data
- Never log passwords or tokens
- Use `flutter_secure_storage` for credentials
- Encrypt data at rest for security module
- Clear sensitive data from memory after use

### Biometric Authentication
```dart
// Check availability before using
final canAuthenticate = await auth.canCheckBiometrics;
if (canAuthenticate) {
  final authenticated = await auth.authenticate(
    localizedReason: 'Access password vault',
  );
}
```

### Data Export
- Sanitize data before export
- Warn user about sensitive data in exports
- Support encrypted exports
- Validate import data thoroughly

## Testing Standards

### Unit Tests
- Test all business logic
- Mock external dependencies
- Test edge cases and error conditions
- Aim for >80% coverage on services/repositories

### Widget Tests
- Test user interactions
- Verify UI state changes
- Test navigation flows
- Mock data sources

### Integration Tests
- Test critical user journeys
- Test data persistence
- Test reminder system
- Test export/import functionality

## Git Commit Standards

```
type(scope): subject

body (optional)

footer (optional)
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
- `feat(religious): add prayer time calculation`
- `fix(financial): correct category total calculation`
- `docs(readme): update setup instructions`
