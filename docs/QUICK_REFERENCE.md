# Quick Reference Card

## 🚀 Common Commands

```bash
# Development
flutter run                          # Run app
flutter run -d <device>              # Run on specific device
flutter analyze                      # Analyze code
flutter format lib/                  # Format code

# Testing
flutter test                         # Run all tests
flutter test --coverage              # With coverage
flutter test test/path/file_test.dart # Specific test

# Building
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android Bundle
flutter build ios --release          # iOS

# Maintenance
flutter pub get                      # Get dependencies
flutter pub upgrade                  # Upgrade dependencies
flutter clean                        # Clean build
flutter doctor                       # Check setup

# Code Generation
flutter pub run build_runner build   # Generate code
flutter pub run build_runner watch   # Watch mode
```

## 📁 File Locations

```
Project Root
├── .kiro/
│   ├── steering/          # AI guidance documents
│   └── hooks/             # Automated workflows
├── docs/                  # Documentation
├── lib/
│   ├── core/              # Core functionality
│   ├── data/              # Data layer
│   │   ├── models/        # Data models
│   │   └── repositories/  # Data access
│   ├── features/          # Feature modules
│   │   ├── religious/
│   │   ├── financial/
│   │   ├── habits/
│   │   ├── sports/
│   │   ├── health/
│   │   ├── notes/
│   │   ├── calendar/
│   │   ├── security/
│   │   └── dashboard/
│   └── shared/            # Shared components
└── test/                  # Tests mirror lib/
```

## 🎯 Creating New Features

### 1. Create Directories
```bash
mkdir -p lib/features/my_feature/{screens,widgets,services}
mkdir -p lib/data/models/my_feature
mkdir -p test/features/my_feature
```

### 2. Create Model
```dart
// lib/data/models/my_feature/my_model.dart
class MyModel extends BaseModel {
  // Fields
  // Constructor
  // toJson()
  // fromJson()
  // copyWith()
}
```

### 3. Create Repository
```dart
// lib/data/repositories/my_repository.dart
abstract class MyRepository {
  Future<Result<T, Error>> method();
}

class MyRepositoryImpl implements MyRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  // Implementation
}
```

### 4. Create Service
```dart
// lib/features/my_feature/services/my_service.dart
class MyService {
  final MyRepository _repository;
  final LoggerService _logger;
  // Business logic
}
```

### 5. Create Screen
```dart
// lib/features/my_feature/screens/my_screen.dart
class MyScreen extends StatelessWidget {
  // UI implementation
}
```

## 📦 abdalsalam_logic_flutter Quick Reference

### Initialization
```dart
// main.dart
final logger = LoggerServiceImpl();
final appStateManager = AppStateManagerImpl.create(logger, config: config);
await appStateManager.initialize();
await StorageGateway.instance.initialize();
```

### Storage
```dart
// Save
await StorageGateway.instance.save(
  key: 'key',
  value: data,
  storageType: StorageType.sqlite,
);

// Get
final data = await StorageGateway.instance.get<T>('key');

// Query
final results = await StorageGateway.instance.query(
  table: 'table_name',
  where: 'field = ?',
  whereArgs: [value],
);
```

### Logging
```dart
final logger = LoggerServiceImpl();
logger.info('Info message');
logger.error('Error', error: e, stackTrace: st);
logger.debug('Debug info');
logger.warning('Warning');
```

### HTTP Client
```dart
final client = ApiClientImpl(logger);
final response = await client.get('/api/endpoint');
final cached = await client.getCached('/api/endpoint');
```

### App State
```dart
StreamBuilder<AppStateInfo>(
  stream: appStateManager.stateStream,
  builder: (context, snapshot) {
    final state = snapshot.data;
    final isOffline = state?.isOffline ?? false;
    final lowBattery = state?.batteryInfo?.isLowBattery ?? false;
    // Use state
  },
)
```

## 🎨 UI Components

### Module Card
```dart
ModuleCard(
  icon: Icons.icon_name,
  title: 'Module Name',
  color: Colors.color,
  stats: [
    Stat('Label', 'Value'),
  ],
  onTap: () => navigate(),
)
```

### List Item with Swipe
```dart
Dismissible(
  key: Key(item.id),
  background: EditBackground(),
  secondaryBackground: DeleteBackground(),
  onDismissed: (direction) {
    if (direction == DismissDirection.startToEnd) {
      // Edit
    } else {
      // Delete
    }
  },
  child: ListTile(...),
)
```

### Form Field
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Label',
    hintText: 'Hint',
    errorText: error,
  ),
  validator: (value) => validate(value),
  onSaved: (value) => save(value),
)
```

## 🔐 Security

### Biometric Auth
```dart
final auth = LocalAuthentication();
final canAuth = await auth.canCheckBiometrics;
if (canAuth) {
  final authenticated = await auth.authenticate(
    localizedReason: 'Reason',
    options: AuthenticationOptions(
      stickyAuth: true,
      biometricOnly: true,
    ),
  );
}
```

### Secure Storage
```dart
final storage = FlutterSecureStorage();
await storage.write(key: 'key', value: 'value');
final value = await storage.read(key: 'key');
await storage.delete(key: 'key');
```

## 📊 Data Export

```dart
class ExportService {
  Future<void> exportData() async {
    final data = {
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'modules': {
        'religious': await _exportReligious(),
        'financial': await _exportFinancial(),
        // ... other modules
      },
    };
    
    final json = jsonEncode(data);
    final file = await FileOperations.saveFile(
      json,
      'export_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await FileOperations.shareFile(file.path);
  }
}
```

## 🧪 Testing

### Unit Test Template
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('MyService', () {
    late MyService service;
    late MockRepository mockRepo;
    
    setUp(() {
      mockRepo = MockRepository();
      service = MyService(mockRepo);
    });
    
    test('should do something', () async {
      // Arrange
      when(mockRepo.method()).thenAnswer((_) async => result);
      
      // Act
      final result = await service.method();
      
      // Assert
      expect(result, expected);
      verify(mockRepo.method()).called(1);
    });
  });
}
```

### Widget Test Template
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyWidget should display text', (tester) async {
    // Build widget
    await tester.pumpWidget(
      MaterialApp(home: MyWidget()),
    );
    
    // Find elements
    expect(find.text('Expected Text'), findsOneWidget);
    
    // Interact
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    
    // Verify
    expect(find.text('Result'), findsOneWidget);
  });
}
```

## 🎯 Git Commit Format

```
type(scope): subject

body (optional)

footer (optional)
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Tests
- `chore`: Maintenance

### Examples
```
feat(religious): add prayer time calculation
fix(financial): correct category total calculation
docs(readme): update setup instructions
refactor(habits): extract habit card widget
test(sports): add workout service tests
```

## 📞 Getting Help

1. Check `.kiro/steering/` documents
2. Review `docs/` folder
3. Search code for examples
4. Check package docs: https://pub.dev/packages/abdalsalam_logic_flutter
5. Email: abed.alsalam.jodalah@gmail.com

## 🔗 Important Links

- **Package**: https://pub.dev/packages/abdalsalam_logic_flutter
- **Flutter**: https://flutter.dev/docs
- **Dart**: https://dart.dev/guides
- **Firebase**: https://firebase.google.com/docs
- **Material Design**: https://material.io/design

## 💡 Pro Tips

1. Use `const` constructors everywhere possible
2. Always log errors with LoggerService
3. Test business logic, not UI
4. Keep widgets small and focused
5. Use StorageGateway for all persistence
6. Leverage app state for smart features
7. Follow the steering documents
8. Write tests as you code
9. Format before committing
10. Document public APIs
