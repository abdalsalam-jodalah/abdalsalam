# Abdalsalam - Personal Life Management App

## Overview
A comprehensive Flutter application for managing all aspects of daily life through data-driven insights. Built as a personal tool by Abdalsalam for tracking religious practices, finances, habits, health, and more.

## Philosophy
- **Data-First**: Everything is logged, structured, and exportable
- **Privacy-First**: All data stored locally on device
- **Offline-First**: Full functionality without internet
- **Future-Ready**: Designed for AI agent integration and server-side processing

## Core Modules

### 1. Religious Tracking
Track spiritual journey with comprehensive logging:
- 5 daily prayer times with on-time tracking
- Quran reading progress (surah, ayah, duration)
- Good deeds and bad habits monitoring
- Spiritual progress reflections
- Automated prayer reminders

### 2. Financial Management
Replace Google Sheets with integrated expense tracking:
- Income and expense logging
- Category-based organization
- Budget management and alerts
- Financial reports and insights
- Export for external analysis

### 3. Habits & Daily Events
Personal notebook for life tracking:
- Habit tracking with streaks
- Daily event logging
- Mood tracking
- Pattern analysis
- Future AI-driven insights

### 4. Sports & Fitness
Complete workout management:
- Exercise logging (sets, reps, weight)
- Activity tracking
- Workout schedules
- Progress visualization
- Rest timers

### 5. Health Management
Medical and wellness tracking:
- Medication reminders
- Vitamin/supplement schedules
- Blood test tracking
- Health metrics logging
- Test results storage

### 6. Notes & Tasks
Organized note-taking system:
- Rich text notes
- Todo lists with priorities
- Categories and tags
- Search functionality
- Pin important items

### 7. Calendar Integration
Unified calendar experience:
- Built-in calendar
- Google Calendar sync
- Event management
- Multi-module reminders

### 8. Security Vault
Biometric-protected password manager:
- Encrypted credential storage
- Password strength analysis
- Quick copy with auto-clear
- Password generator
- Secure export

### 9. Dashboard & Analytics
Central hub for insights:
- Module overview cards
- Statistics and trends
- Progress tracking
- Visual analytics
- Quick actions

## Technical Stack

### Framework
- Flutter (Dart 3.11.1+)
- Material Design

### State Management
- Riverpod (recommended)

### Data Persistence
- Drift (SQLite) for structured data
- Hive for settings
- flutter_secure_storage for passwords

### Key Features
- Local notifications
- Biometric authentication
- Calendar integration
- Data export/import
- Charts and visualizations

## Project Structure

```
lib/
├── main.dart                      # Entry point
├── app.dart                       # Root widget
├── core/                          # Core functionality
│   ├── constants/
│   ├── theme/
│   ├── router/
│   └── utils/
├── data/                          # Data layer
│   ├── models/                    # Domain models
│   ├── repositories/              # Data access
│   └── local/                     # Local storage
├── features/                      # Feature modules
│   ├── religious/
│   ├── financial/
│   ├── habits/
│   ├── sports/
│   ├── health/
│   ├── notes/
│   ├── calendar/
│   ├── security/
│   └── dashboard/
└── shared/                        # Shared components
    ├── widgets/
    ├── services/
    └── extensions/
```

## Development Workflow

### Setup
```bash
# Get dependencies
flutter pub get

# Run code generation (for Drift, JSON serialization)
flutter pub run build_runner build

# Run the app
flutter run
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Run tests
flutter test
```

### Building
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## Data Export Format

All data can be exported in JSON format:
```json
{
  "version": "1.0.0",
  "exportedAt": "2026-03-25T10:00:00Z",
  "userId": "user_id",
  "modules": {
    "religious": {...},
    "financial": {...},
    "habits": {...},
    "sports": {...},
    "health": {...},
    "notes": {...},
    "calendar": {...},
    "security": {...}
  }
}
```

## Future Roadmap

### Phase 1: Core Features (Current)
- Basic module implementation
- Local data storage
- Essential UI/UX

### Phase 2: Enhanced Features
- Advanced analytics
- Data visualization
- Export/import functionality
- Backup system

### Phase 3: Intelligence
- Pattern recognition
- Insights and suggestions
- Predictive features
- AI agent integration

### Phase 4: Connectivity
- Server-side processing
- Cloud backup
- Cross-device sync
- Third-party integrations

## Contributing

This is a personal project, but the architecture is designed to be:
- Modular (easy to add/remove features)
- Extensible (new modules follow same pattern)
- Maintainable (clear separation of concerns)
- Testable (business logic isolated from UI)

## License

Personal project - All rights reserved
