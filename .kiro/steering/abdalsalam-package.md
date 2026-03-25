# abdalsalam_logic_flutter Package Integration

## Overview
This project uses `abdalsalam_logic_flutter` as the core foundation package. It provides 20+ modules following SOLID principles with modular, opt-in architecture.

**Package Link**: https://pub.dev/packages/abdalsalam_logic_flutter

## Core Features Provided

### 1. Smart App State Management (21+ Domains)
- Real-time device monitoring (battery, connectivity, storage)
- Responsive breakpoint detection & platform awareness
- Modular architecture - only bundle what you enable

### 2. Networking
- Offline-first HTTP client with intelligent caching
- Automatic retry and error handling
- Request/response interceptors

### 3. Storage Gateway
- Unified storage interface (SQLite + Hive + SharedPreferences)
- Automatic data synchronization
- Conflict resolution
- User isolation for all data operations

### 4. Authentication
- Firebase Auth integration with token management
- User isolation for all data operations
- Role-based permissions and access control

### 5. Runtime Control
- Native app restart functionality
- Custom domain registration system
- Dynamic UI tree management (refresh, rebuild, recreate)

### 6. Utilities
- Structured logging with caller tracking
- Centralized error handling and classification
- Comprehensive file operations and sharing
- Calendar and contacts native access
- Firebase Cloud Messaging (FCM)
- Cross-platform utilities (Android, iOS, Web, Desktop)

## Integration Guidelines

### Initial Setup

```dart
// main.dart
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (required for auth and FCM)
  await Firebase.initializeApp();
  
  // Configure app state features
  final config = AppStateConfig(
    enableConnectivity: true,
    enableDeviceInfo: true,
    enableBattery: true,
    enableStorage: true,
  );
  
  // Initialize logger
  final logger = LoggerServiceImpl();
  
  // Initialize app state manager
  final appStateManager = AppStateManagerImpl.create(
    logger,
    config: config,
  );
  await appStateManager.initialize();
  
  // Initialize storage gateway
  await StorageGateway.instance.initialize();
  
  runApp(MyApp(
    appStateManager: appStateManager,
    logger: logger,
  ));
}
```

### Storage Layer Integration

Use StorageGateway for all data persistence:

```dart
// Save data
await StorageGateway.instance.save(
  key: 'prayer_logs',
  value: prayerLogs,
  storageType: StorageType.sqlite, // or hive, sharedPreferences
);

// Retrieve data
final logs = await StorageGateway.instance.get<List<PrayerLog>>(
  key: 'prayer_logs',
  storageType: StorageType.sqlite,
);

// User-isolated storage
await StorageGateway.instance.saveForUser(
  userId: currentUser.id,
  key: 'user_preferences',
  value: preferences,
);
```

### Repository Pattern with StorageGateway

```dart
class PrayerRepositoryImpl implements PrayerRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  
  const PrayerRepositoryImpl(this._storage, this._logger);
  
  @override
  Future<Result<PrayerLog, Error>> create(PrayerLog prayer) async {
    try {
      await _storage.save(
        key: 'prayer_${prayer.id}',
        value: prayer.toJson(),
        storageType: StorageType.sqlite,
      );
      _logger.info('Prayer log created: ${prayer.id}');
      return Success(prayer);
    } catch (e, st) {
      _logger.error('Failed to create prayer log', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
  
  @override
  Future<Result<List<PrayerLog>, Error>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final data = await _storage.query(
        table: 'prayers',
        where: 'performedAt BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );
      final logs = data.map((json) => PrayerLog.fromJson(json)).toList();
      return Success(logs);
    } catch (e, st) {
      _logger.error('Failed to query prayers', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
}
```

### HTTP Client for Future Server Integration

```dart
class ApiService {
  final ApiClient _client;
  final LoggerService _logger;
  
  ApiService(this._logger) : _client = ApiClientImpl(_logger);
  
  Future<Result<List<PrayerLog>, Error>> syncPrayers() async {
    try {
      final response = await _client.get('/api/prayers/sync');
      if (response.statusCode == 200) {
        final logs = (response.data as List)
            .map((json) => PrayerLog.fromJson(json))
            .toList();
        return Success(logs);
      }
      return Failure(ApiError('Sync failed: ${response.statusCode}'));
    } catch (e, st) {
      _logger.error('Prayer sync failed', error: e, stackTrace: st);
      return Failure(NetworkError(e.toString()));
    }
  }
  
  // Offline-first approach
  Future<Result<List<PrayerLog>, Error>> getPrayers() async {
    try {
      // Try network first
      final response = await _client.get('/api/prayers');
      return Success(parsePrayers(response.data));
    } catch (e) {
      // Fall back to cached data
      _logger.info('Using cached prayers due to network error');
      final cached = await _client.getCached('/api/prayers');
      if (cached != null) {
        return Success(parsePrayers(cached));
      }
      return Failure(NetworkError('No cached data available'));
    }
  }
}
```

### App State Monitoring

```dart
// In your root widget or dashboard
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateManager = ref.watch(appStateManagerProvider);
    
    return StreamBuilder<AppStateInfo>(
      stream: appStateManager.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Dashboard'),
            actions: [
              // Show connectivity status
              if (state?.isOffline == true)
                Icon(Icons.cloud_off, color: Colors.red),
              // Show battery status
              if (state?.batteryInfo?.isLowBattery == true)
                Icon(Icons.battery_alert, color: Colors.orange),
            ],
          ),
          body: Column(
            children: [
              // Show offline banner
              if (state?.isOffline == true)
                OfflineBanner(),
              // Main content
              Expanded(child: DashboardContent()),
            ],
          ),
        );
      },
    );
  }
}
```

### Smart Background Operations

```dart
class DataSyncService {
  final AppStateManager _appState;
  final ApiService _api;
  final LoggerService _logger;
  
  StreamSubscription? _syncSubscription;
  
  void startSmartSync() {
    // Only sync when online and battery is not low
    _syncSubscription = _appState.stateStream
        .where((state) => 
            state.isOnline && 
            !(state.batteryInfo?.isLowBattery ?? false))
        .listen((_) async {
      _logger.info('Starting smart sync');
      await _syncAllModules();
    });
  }
  
  Future<void> _syncAllModules() async {
    // Sync religious data
    await _api.syncPrayers();
    // Sync financial data
    await _api.syncTransactions();
    // ... other modules
  }
  
  void dispose() {
    _syncSubscription?.cancel();
  }
}
```

### Authentication Integration

```dart
class AuthenticationService {
  final AuthService _auth;
  final StorageGateway _storage;
  final LoggerService _logger;
  
  AuthenticationService(this._logger, this._storage)
      : _auth = AuthServiceImpl(_logger, _storage);
  
  Future<Result<User, Error>> signIn(String email, String password) async {
    try {
      final result = await _auth.signIn(email, password);
      if (result.isSuccess) {
        _logger.info('User signed in: ${result.data.id}');
        // All subsequent storage operations will be user-isolated
        return Success(result.data);
      }
      return Failure(AuthError(result.error.message));
    } catch (e, st) {
      _logger.error('Sign in failed', error: e, stackTrace: st);
      return Failure(AuthError(e.toString()));
    }
  }
  
  User? get currentUser => _auth.currentUser;
  
  Future<void> signOut() async {
    await _auth.signOut();
    _logger.info('User signed out');
  }
}
```

### FCM Push Notifications

```dart
class NotificationService {
  final LoggerService _logger;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permission
    final settings = await _fcm.requestPermission();
    _logger.info('FCM permission: ${settings.authorizationStatus}');
    
    // Get FCM token
    final token = await _fcm.getToken();
    _logger.info('FCM token: $token');
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _logger.info('Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }
  
  void _showLocalNotification(RemoteMessage message) {
    // Use flutter_local_notifications for display
  }
}

Future<void> _backgroundHandler(RemoteMessage message) async {
  // Handle background messages
}
```

### File Operations

```dart
class ExportService {
  final LoggerService _logger;
  
  Future<void> exportAllData() async {
    try {
      final data = await _collectAllData();
      final json = jsonEncode(data);
      
      // Save to file
      final file = await FileOperations.saveFile(
        json,
        'abdalsalam_export_${DateTime.now().toIso8601String()}.json',
      );
      
      _logger.info('Data exported to: ${file.path}');
      
      // Share file
      await FileOperations.shareFile(file.path);
    } catch (e, st) {
      _logger.error('Export failed', error: e, stackTrace: st);
    }
  }
}
```

## Best Practices

### 1. Use Dependency Injection
```dart
// Use get_it or riverpod for DI
final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerSingleton<LoggerService>(LoggerServiceImpl());
  getIt.registerSingleton<StorageGateway>(StorageGateway.instance);
  getIt.registerFactory<PrayerRepository>(
    () => PrayerRepositoryImpl(getIt(), getIt()),
  );
}
```

### 2. Leverage App State for Smart Features
- Disable background sync when battery is low
- Queue operations when offline, execute when online
- Adjust UI based on device capabilities
- Use responsive breakpoints for adaptive layouts

### 3. Centralized Logging
- Use LoggerService throughout the app
- Log important events, errors, and user actions
- Helps with debugging and analytics

### 4. Error Handling
- Use the package's error handling utilities
- Classify errors appropriately
- Show user-friendly messages in UI

### 5. Offline-First Approach
- Always assume network might be unavailable
- Cache data locally
- Sync when connection is restored
- Use StorageGateway for seamless offline support

## Migration Notes

If migrating from other packages:
- Replace custom HTTP clients with ApiClient
- Replace direct SQLite/Hive usage with StorageGateway
- Replace custom logging with LoggerService
- Leverage built-in app state instead of custom solutions
- Use built-in file operations instead of path_provider + custom code
