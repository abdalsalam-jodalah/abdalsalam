# Getting Started with Abdalsalam App

## Quick Start

### Prerequisites
- Flutter SDK 3.11.1 or higher
- Dart 3.11.1 or higher
- Android Studio / Xcode (for mobile development)
- Firebase account (for auth and FCM)

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd abdalsalam
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
- Create a Firebase project at https://console.firebase.google.com
- Add Android and iOS apps to your Firebase project
- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Place them in the appropriate directories:
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`

4. Run the app
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── app.dart                       # Root widget
├── core/                          # Core functionality
│   ├── constants/                 # App-wide constants
│   ├── theme/                     # Theme and styling
│   ├── router/                    # Navigation
│   └── utils/                     # Helper functions
├── data/                          # Data layer
│   ├── models/                    # Data models
│   ├── repositories/              # Data access
│   └── local/                     # Local storage
├── features/                      # Feature modules
│   ├── religious/                 # Religious tracking
│   ├── financial/                 # Money management
│   ├── habits/                    # Habits & events
│   ├── sports/                    # Fitness tracking
│   ├── health/                    # Health management
│   ├── notes/                     # Notes & todos
│   ├── calendar/                  # Calendar
│   ├── security/                  # Password vault
│   └── dashboard/                 # Main dashboard
└── shared/                        # Shared components
    ├── widgets/                   # Reusable widgets
    ├── services/                  # Shared services
    └── extensions/                # Dart extensions
```

## Core Concepts

### 1. abdalsalam_logic_flutter Package
This app is built on top of the `abdalsalam_logic_flutter` package, which provides:
- Smart app state management
- Unified storage gateway
- Offline-first HTTP client
- Firebase authentication
- Logging and error handling
- File operations
- FCM messaging

See `.kiro/steering/abdalsalam-package.md` for detailed integration guide.

### 2. Feature Modules
Each feature is self-contained with:
- Screens (UI)
- Widgets (feature-specific components)
- Services (business logic)
- Models (if not in data/)

### 3. Data Layer
- Models: Domain entities with toJson/fromJson
- Repositories: Data access abstraction
- StorageGateway: Unified storage interface

### 4. State Management
- App state: AppStateManager (from abdalsalam_logic_flutter)
- UI state: Riverpod (recommended) or Bloc/Provider

## Development Workflow

### Adding a New Feature

1. Create feature directory
```bash
mkdir -p lib/features/my_feature/{screens,widgets,services}
```

2. Create models
```bash
mkdir -p lib/data/models/my_feature
```

3. Implement repository
```bash
mkdir -p lib/data/repositories
```

4. Add routes
```dart
// lib/core/router/app_router.dart
```

5. Update dashboard
```dart
// lib/features/dashboard/screens/dashboard_screen.dart
```

### Creating a Data Model

```dart
// lib/data/models/my_feature/my_model.dart
import 'package:abdalsalam/data/models/base_model.dart';

class MyModel extends BaseModel {
  final String userId;
  final String name;
  
  const MyModel({
    required String id,
    required this.userId,
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
    'userId': userId,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };
  
  factory MyModel.fromJson(Map<String, dynamic> json) => MyModel(
    id: json['id'],
    userId: json['userId'],
    name: json['name'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    deletedAt: json['deletedAt'] != null 
        ? DateTime.parse(json['deletedAt']) 
        : null,
  );
  
  MyModel copyWith({
    String? name,
    DateTime? updatedAt,
  }) => MyModel(
    id: id,
    userId: userId,
    name: name ?? this.name,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt,
  );
}
```

### Creating a Repository

```dart
// lib/data/repositories/my_repository.dart
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

abstract class MyRepository {
  Future<Result<MyModel, Error>> create(MyModel model);
  Future<Result<List<MyModel>, Error>> getAll();
  Future<Result<MyModel, Error>> getById(String id);
  Future<Result<void, Error>> update(MyModel model);
  Future<Result<void, Error>> delete(String id);
}

class MyRepositoryImpl implements MyRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  
  const MyRepositoryImpl(this._storage, this._logger);
  
  @override
  Future<Result<MyModel, Error>> create(MyModel model) async {
    try {
      await _storage.save(
        key: 'my_model_${model.id}',
        value: model.toJson(),
        storageType: StorageType.sqlite,
      );
      _logger.info('Model created: ${model.id}');
      return Success(model);
    } catch (e, st) {
      _logger.error('Failed to create model', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
  
  // Implement other methods...
}
```

### Creating a Service

```dart
// lib/features/my_feature/services/my_service.dart
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

class MyService {
  final MyRepository _repository;
  final LoggerService _logger;
  
  const MyService(this._repository, this._logger);
  
  Future<Result<MyModel, Error>> createItem(String name) async {
    try {
      final model = MyModel(
        id: Uuid().v4(),
        userId: 'current_user_id', // Get from auth
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      return await _repository.create(model);
    } catch (e, st) {
      _logger.error('Service error', error: e, stackTrace: st);
      return Failure(ServiceError(e.toString()));
    }
  }
}
```

## Common Commands

### Development
```bash
# Run app
flutter run

# Run on specific device
flutter run -d <device_id>

# Hot reload (press 'r' in terminal)
# Hot restart (press 'R' in terminal)
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Building
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Code Generation
```bash
# Run build_runner (for JSON serialization, etc.)
flutter pub run build_runner build

# Watch mode
flutter pub run build_runner watch
```

## Debugging

### Enable Logging
```dart
// Set log level in main.dart
final logger = LoggerServiceImpl(level: LogLevel.debug);
```

### View Logs
- Android: `adb logcat`
- iOS: Xcode console
- Flutter: DevTools

### Common Issues

1. **Firebase not initialized**
   - Ensure Firebase.initializeApp() is called in main()
   - Check google-services.json / GoogleService-Info.plist

2. **Storage errors**
   - Ensure StorageGateway.instance.initialize() is called
   - Check permissions for file access

3. **Build errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Delete build folders

## Next Steps

1. Review steering documents in `.kiro/steering/`
2. Check out example implementations in `lib/features/`
3. Read package documentation: https://pub.dev/packages/abdalsalam_logic_flutter
4. Set up your development environment
5. Start building features!

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [abdalsalam_logic_flutter Package](https://pub.dev/packages/abdalsalam_logic_flutter)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Material Design Guidelines](https://material.io/design)

## Support

For issues or questions:
- Check `.kiro/steering/` documentation
- Review `docs/PROJECT_OVERVIEW.md`
- Contact: abed.alsalam.jodalah@gmail.com
