# Abdalsalam - Personal Life Management App

A comprehensive Flutter application for managing all aspects of daily life through data-driven insights. Built as a personal all-in-one solution for tracking religious practices, finances, habits, health, and more.

## 🎯 Vision

Personal productivity and life tracking app that puts data first. Everything is logged, structured, and exportable for future AI-driven insights and analysis.

## ✨ Features

### 📿 Religious Tracking
- 5 daily prayer logging with on-time tracking
- Quran reading progress
- Spiritual progress monitoring
- Automated reminders

### 💰 Financial Management
- Expense and income tracking
- Category-based budgeting
- Financial insights and reports
- Export for analysis

### 🎯 Habits & Daily Events
- Habit tracking with streaks
- Daily journaling
- Mood tracking
- Pattern analysis

### 🏃 Sports & Fitness
- Workout logging
- Exercise tracking
- Progress visualization
- Workout schedules

### 🏥 Health Management
- Medication reminders
- Vitamin tracking
- Blood test scheduling
- Health metrics logging

### 📝 Notes & Tasks
- Rich text notes
- Todo lists with priorities
- Categories and tags
- Search functionality

### 📅 Calendar Integration
- Built-in calendar
- Google Calendar sync
- Event management
- Unified reminders

### 🔐 Security Vault
- Biometric-protected password manager
- Encrypted credential storage
- Password generator
- Secure export

### 📊 Dashboard & Analytics
- Module overview cards
- Statistics and trends
- Progress tracking
- Visual analytics

## 🚀 Tech Stack

- **Framework**: Flutter (Dart 3.11.1+)
- **Core Package**: [abdalsalam_logic_flutter](https://pub.dev/packages/abdalsalam_logic_flutter)
- **State Management**: Riverpod (recommended)
- **Storage**: StorageGateway (SQLite + Hive + SharedPreferences)
- **Authentication**: Firebase Auth
- **Notifications**: FCM + flutter_local_notifications
- **Security**: flutter_secure_storage + biometric auth

## 📁 Project Structure

```
lib/
├── core/           # Core functionality (theme, router, constants)
├── data/           # Data layer (models, repositories)
├── features/       # Feature modules (religious, financial, etc.)
└── shared/         # Shared components and services
```

## 🏗️ Architecture

- **Clean Architecture** with feature-based organization
- **Offline-First**: All functionality works without internet
- **Data-First**: Everything is logged and exportable
- **Modular**: Easy to add/remove features
- **Secure**: Encryption and biometric authentication

### 🎯 Baseline Requirements (MANDATORY)

**ALL implementations MUST follow the baseline:**
- **Models** → Extend `BaseModel`
- **Repositories** → Implement `BaseRepository<T>` (24 methods)
- **Services** → Implement `BaseService<T>` (29 methods)
- **Operations** → Return `Result<T, Error>`
- **Export/Import** → Full metadata support
- **Logging** → Comprehensive operation logging
- **Validation** → All inputs validated
- **State Awareness** → Online/offline, battery-aware

📖 **See [BASELINE_REQUIREMENTS.md](docs/BASELINE_REQUIREMENTS.md) for complete details**

## 📚 Documentation

- **[Baseline Requirements](docs/BASELINE_REQUIREMENTS.md)** - ⚠️ MANDATORY for all implementations
- **[Getting Started](docs/GETTING_STARTED.md)** - Setup and development guide
- **[Project Overview](docs/PROJECT_OVERVIEW.md)** - Detailed feature documentation
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Command cheat sheet
- **[Steering Summary](docs/STEERING_SUMMARY.md)** - Overview of all steering docs
- **Steering Documents** (`.kiro/steering/`):
  - `base-classes.md` - ⭐ Base class definitions (CRITICAL)
  - `service-baseline.md` - ⭐ Service requirements (CRITICAL)
  - `implementation-checklist.md` - ⭐ Step-by-step guide (CRITICAL)
  - `product.md` - Product vision and modules
  - `architecture.md` - Architecture guidelines
  - `coding-standards.md` - Code style and best practices
  - `data-models.md` - Data schema guidelines
  - `ui-ux-guidelines.md` - UI/UX patterns
  - `dependencies.md` - Package management
  - `abdalsalam-package.md` - Core package integration
  - `tech.md` - Tech stack and commands
  - `structure.md` - Project organization

## 🛠️ Quick Start

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Build for release
flutter build apk --release
```

## 🔧 Development

### Code Quality
```bash
flutter analyze          # Analyze code
flutter format lib/      # Format code
flutter test --coverage  # Run tests with coverage
```

### Hooks
Automated workflows in `.kiro/hooks/`:
- `analyze-on-save.json` - Run analyzer on file save
- `format-on-save.json` - Auto-format on save
- `review-data-models.json` - Review model changes
- `security-check.json` - Security validation
- `test-reminder.json` - Remind to write tests

## 🎨 Design Philosophy

- **Personal & Functional**: Clean, minimal interface
- **Data Visualization**: Charts and insights
- **Quick Access**: Efficient workflows for daily logging
- **Dashboard-First**: Overview with module deep-dives

## 🔮 Future Roadmap

1. **Phase 1**: Core features and local storage ✅
2. **Phase 2**: Enhanced analytics and visualizations
3. **Phase 3**: AI-driven insights and suggestions
4. **Phase 4**: Server integration and cloud sync

## 📄 License

Personal project - All rights reserved

## 👤 Author

Abdalsalam
- Email: abed.alsalam.jodalah@gmail.com
- Package: [abdalsalam_logic_flutter](https://pub.dev/packages/abdalsalam_logic_flutter)

## 🙏 Acknowledgments

Built with Flutter and powered by `abdalsalam_logic_flutter` - a comprehensive logic package with 20+ reusable modules.
