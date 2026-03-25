# Recommended Dependencies

## Core Package (REQUIRED)
```yaml
# Abdalsalam's comprehensive logic package
abdalsalam_logic_flutter: ^1.0.0  # 20+ modules for state, networking, storage, auth
```

This package provides:
- Smart app state management (21+ domains: battery, connectivity, storage, etc.)
- Offline-first HTTP client with caching
- Unified storage gateway (SQLite + Hive + SharedPreferences)
- Firebase Auth integration
- Structured logging and error handling
- File operations and sharing
- FCM messaging
- Native app restart
- Cross-platform utilities

## State Management
```yaml
# Choose ONE based on preference (or use abdalsalam_logic_flutter's built-in state)
flutter_riverpod: ^2.5.0  # Recommended for UI state
# OR
flutter_bloc: ^8.1.0
# OR  
provider: ^6.1.0
```

## Data Persistence
```yaml
# NOTE: abdalsalam_logic_flutter provides unified storage gateway
# Additional packages only if needed for specific use cases

# Secure Storage (for passwords - not in abdalsalam_logic_flutter)
flutter_secure_storage: ^9.0.0  # For password vault encryption
```

## UI Components
```yaml
# Icons
flutter_svg: ^2.0.0
cupertino_icons: ^1.0.0

# Charts & Graphs
fl_chart: ^0.68.0

# Animations
lottie: ^3.1.0

# Image Handling
cached_network_image: ^3.3.0
image_picker: ^1.0.0
```

## Functionality
```yaml
# Date & Time
intl: ^0.19.0  # Already included in abdalsalam_logic_flutter

# Notifications (FCM included in abdalsalam_logic_flutter)
flutter_local_notifications: ^17.0.0  # For local reminders

# Biometric Authentication
local_auth: ^2.2.0

# Calendar Integration
device_calendar: ^4.3.0
googleapis: ^13.0.0  # For Google Calendar API
google_sign_in: ^6.2.0

# File Handling (basic operations in abdalsalam_logic_flutter)
file_picker: ^8.0.0  # For advanced file picking

# Permissions (included in abdalsalam_logic_flutter)
# permission_handler: ^11.0.0  # Already in abdalsalam_logic_flutter

# UUID Generation
uuid: ^4.3.0

# Encryption
encrypt: ^5.0.0
crypto: ^3.0.0
```

## Utilities
```yaml
# NOTE: Many utilities included in abdalsalam_logic_flutter:
# - Logging (LoggerService)
# - Error handling
# - File operations
# - Storage gateway

# Functional Programming
dartz: ^0.10.0  # For Result/Either pattern (if not using package's error handling)

# JSON Serialization
json_annotation: ^4.8.0
json_serializable: ^6.7.0  # dev_dependency

# Code Generation
build_runner: ^2.4.0  # dev_dependency
freezed: ^2.4.0  # dev_dependency (optional, for immutable models)
freezed_annotation: ^2.4.0

# HTTP (dio included in abdalsalam_logic_flutter)
# dio: ^5.4.0  # Already in abdalsalam_logic_flutter
```

## Testing
```yaml
# dev_dependencies
mockito: ^5.4.0
build_runner: ^2.4.0
faker: ^2.1.0  # For generating test data
integration_test:
  sdk: flutter
```

## Development Tools
```yaml
# dev_dependencies
flutter_lints: ^6.0.0  # Already included
flutter_launcher_icons: ^0.13.0  # Custom app icons
flutter_native_splash: ^2.3.0  # Splash screen
```

## Priority Installation Order

### Phase 1: Core Infrastructure (CRITICAL)
1. **abdalsalam_logic_flutter** - Core package with state, storage, networking, auth
2. State management for UI (riverpod/bloc/provider)
3. Secure storage (flutter_secure_storage) for password vault
4. UUID generation
5. Local notifications

### Phase 2: Essential Features
1. Local auth (biometric)
2. Encryption packages
3. JSON serialization tools

### Phase 3: UI Enhancement
1. FL Chart
2. Flutter SVG
3. Lottie
4. Image picker

### Phase 4: Advanced Features
1. Device calendar
2. Google APIs
3. File picker

## Package Usage Guidelines

### abdalsalam_logic_flutter (Core Package)

#### Initialization
```dart
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

// Configure features (zero-impact bundling)
final config = AppStateConfig(
  enableConnectivity: true,
  enableDeviceInfo: true,
  enableBattery: true,
  enableStorage: true,
);

// Initialize app state manager
final appStateManager = AppStateManagerImpl.create(
  LoggerServiceImpl(), 
  config: config,
);
await appStateManager.initialize();
```

#### Storage Gateway (SQLite + Hive + SharedPreferences)
```dart
// Unified storage access
await StorageGateway.instance.saveUser(user);
final userData = await StorageGateway.instance.getUser(userId);

// Automatic sync and conflict resolution
await StorageGateway.instance.syncData();
```

#### HTTP Client with Offline Support
```dart
final apiClient = ApiClientImpl(LoggerServiceImpl());
final response = await apiClient.get('/api/data');

// Automatic caching for offline access
final cachedData = await apiClient.getCached('/api/data');
```

#### Authentication (Firebase)
```dart
final authService = AuthServiceImpl(
  LoggerServiceImpl(), 
  StorageGateway.instance,
);
final result = await authService.signIn(email, password);

// User isolation for all data operations
final currentUser = authService.currentUser;
```

#### App State Monitoring
```dart
// Reactive state monitoring
StreamBuilder<AppStateInfo>(
  stream: appStateManager.stateStream,
  builder: (context, snapshot) {
    final state = snapshot.data;
    if (state?.isOffline == true) {
      return OfflineBanner();
    }
    return YourMainWidget();
  },
);

// Battery-aware operations
appStateManager.batteryStream
  .where((b) => !b.isLowBattery)
  .listen((_) => enableBackgroundSync());

// Network-aware sync
appStateManager.stateStream
  .where((s) => s.isOnline)
  .listen((_) => syncData());
```

#### Logging & Error Handling
```dart
final logger = LoggerServiceImpl();
logger.info('Operation started');
logger.error('Error occurred', error: e, stackTrace: st);

// Centralized error handling
try {
  await riskyOperation();
} catch (e) {
  ErrorHandler.handle(e);
}
```

#### Native App Restart
```dart
// Restart app (useful for settings changes)
await AppControl.instance.restartApp();
```

#### File Operations
```dart
// Built-in file utilities
await FileOperations.saveFile(data, 'filename.json');
final content = await FileOperations.readFile('filename.json');
await FileOperations.shareFile('path/to/file');
```

### Drift (Database) - OPTIONAL (use StorageGateway instead)
```dart
// Define tables with type safety
@DataClassName('PrayerLog')
class PrayerLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get prayerType => intEnum<PrayerType>()();
  DateTimeColumn get performedAt => dateTime()();
  BoolColumn get onTime => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### Riverpod (State Management)
```dart
// Repository provider
final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PrayerRepositoryImpl(db);
});

// State provider
final prayersProvider = FutureProvider.family<List<PrayerLog>, DateRange>((ref, range) {
  final repo = ref.watch(prayerRepositoryProvider);
  return repo.getByDateRange(range.start, range.end);
});
```

### Flutter Local Notifications
```dart
// Initialize with channels for each module
final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
final iosSettings = DarwinInitializationSettings();
await notifications.initialize(
  InitializationSettings(android: androidSettings, iOS: iosSettings),
);

// Create notification channels
const prayerChannel = AndroidNotificationChannel(
  'prayers',
  'Prayer Reminders',
  importance: Importance.high,
);
```

### Local Auth (Biometric)
```dart
final auth = LocalAuthentication();
final canAuth = await auth.canCheckBiometrics;
final availableBiometrics = await auth.getAvailableBiometrics();

if (canAuth) {
  final authenticated = await auth.authenticate(
    localizedReason: 'Authenticate to access password vault',
    options: const AuthenticationOptions(
      stickyAuth: true,
      biometricOnly: true,
    ),
  );
}
```

### FL Chart
```dart
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: dataPoints,
        isCurved: true,
        color: Colors.blue,
      ),
    ],
  ),
)
```

## Version Management

- Lock versions in `pubspec.yaml` for stability
- Test updates in separate branch
- Document breaking changes
- Keep dependencies up to date quarterly
