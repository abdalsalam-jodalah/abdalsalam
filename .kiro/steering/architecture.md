# Architecture Guidelines

## Design Principles

### 1. Data-First Architecture
- All features must support comprehensive data logging
- Data models should be exportable (JSON, CSV)
- Design for future data analysis and AI processing
- Maintain data integrity and consistency

### 2. Offline-First
- All functionality works without internet
- Local storage is primary data source
- Sync capabilities prepared for future implementation
- Handle data conflicts gracefully

### 3. Modular Feature Design
- Each feature module is self-contained
- Features communicate through well-defined interfaces
- Shared functionality in `shared/` directory
- Easy to add/remove features

### 4. Security by Design
- Sensitive data encrypted at rest
- Biometric authentication for security vault
- No hardcoded credentials
- Secure data export mechanisms

## Recommended Architecture Pattern

Use **Clean Architecture** with feature-based organization:

```
Feature Module Structure:
feature/
├── screens/          # UI layer
├── widgets/          # Feature-specific widgets
├── services/         # Business logic
└── models/           # Feature models (if not in data/)
```

### State Management
- App State: Use `abdalsalam_logic_flutter`'s AppStateManager for device/system state
- UI State: Use Riverpod, Bloc, or Provider for UI-specific state
- Keep state management consistent across features
- Separate UI state from business logic

### Data Persistence
- Primary: `abdalsalam_logic_flutter`'s StorageGateway (unified SQLite + Hive + SharedPreferences)
- Secure storage: flutter_secure_storage for password vault encryption
- User isolation: Leverage StorageGateway's built-in user isolation
- Automatic sync and conflict resolution included

## Key Technical Decisions

### Core Package Integration
- Use `abdalsalam_logic_flutter` as foundation
- Leverage StorageGateway for all data persistence
- Use ApiClient for future server communication
- Utilize LoggerService for centralized logging
- Leverage AppStateManager for smart features (battery-aware, connectivity-aware)

### Database Schema Design
- Normalize data for integrity
- Use StorageGateway's SQLite layer for structured data
- Index frequently queried fields
- Support data versioning for migrations
- User isolation handled automatically

### Export Format
- JSON for structured data export
- Include metadata (version, export date)
- Support selective exports by module
- Maintain backward compatibility
- Use FileOperations from abdalsalam_logic_flutter

### Reminder System
- Use flutter_local_notifications for local reminders
- Use FCM (included in abdalsalam_logic_flutter) for push notifications
- Support multiple reminder types per feature
- Allow customization per user preference
- Handle notification permissions properly

### Calendar Integration
- Use device_calendar or google_calendar packages
- Request permissions explicitly
- Handle sync conflicts
- Support offline event creation

## Performance Considerations

- Lazy load data in lists
- Paginate large datasets
- Cache frequently accessed data
- Optimize database queries
- Use const constructors for widgets
- Minimize rebuilds with proper state management

## Testing Strategy

- Unit tests for business logic and models
- Widget tests for UI components
- Integration tests for critical flows
- Mock external dependencies (calendar, notifications)
- Test data export/import functionality

## Code Organization Rules

1. One feature = one directory in `features/`
2. Models in `data/models/` organized by domain
3. Shared widgets in `shared/widgets/`
4. Constants in `core/constants/`
5. Routes defined in `core/router/`
6. Theme in `core/theme/`
