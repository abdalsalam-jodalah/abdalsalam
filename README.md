# Abdalsalam - My Life, In One App

A personal Flutter app that manages everything in my life in one place, in a customizable way that I can keep refining over time.

## 📖 The Story

This app is **for me, and only me**. That is why it carries my name: *Abdalsalam*.

I did not want ten apps that each hold a slice of my life and never talk to each other. I wanted one place where my prayers, money, habits, health, plans, notes, and days all live together, shaped exactly around how I actually live. Nothing here is built for a crowd. There are no accounts, no multi-user concerns, and no public release. Every decision serves one person's real workflow.

It is not meant to be finished on day one. It is meant to **grow with me**: every screen, card, and setting is customizable, and I refine it as my life changes. The data is logged, structured, and fully exportable, so the app can eventually reason about my life, not just record it.

The journey goes like this:

1. **Today**: it runs on all my devices and keeps working offline. Everything is stored locally, and phone and computer stay in step through backup/restore and device sync.
2. **Next**: it becomes a comprehensive platform with its own **backend**, stable and always available, still just for me.
3. **Later**: it runs natively and persistently on my Mac, then gains AI that understands my data, then connects to the outside tools I use.

There is a second purpose too: **this app is how I learn**. I use it to pick up new concepts, patterns, and technologies by building real things I actually use, instead of toy examples. Clean Architecture, Riverpod, offline-first sync, notifications and timezones, backup formats, and eventually backend and AI work all get learned here, in a codebase that matters to me.

## ✨ Features

### 🏠 Dashboard
- Personal hero greeting with the date and time of day
- Quote of the day (can be switched off in settings)
- "My age" card tracking life progress
- Today at a glance: prayers (with voluntary prayers shown as "for God"), Quran pages, goals, and tasks
- Live "Today's tasks" card that you can tick off directly from the dashboard
- Weather and exchange-rate cards
- Responsive multi-column layout on wide screens
- Cards can be reordered and hidden from Dashboard settings

### 📿 Religious Tracking
- Five daily prayer logging with on-time tracking against calculated prayer times
- Voluntary prayers ("for God") logged separately, without affecting daily completion or streaks
- Quran reading progress
- Streaks, completion rate, and on-time statistics
- Prayer reminders

### 🗓️ Planning
- **Day planning board**: list and column views, custom day ranges, an unassigned-tasks panel, and drag and drop between days with auto-scroll
- **Task categories**: colored categories you create and manage, assigned to tasks (a task can have several)
- Goals, reviews, life plan topics, and achievements

### 💰 Financial Management
- Expense and income tracking
- Category-based budgeting
- Interactive exchange rates (USD and JOD against ILS) with a 30-day chart and per-currency toggles
- Financial insights and exports

### 🎯 Habits & Daily Events
- Habit tracking with streaks
- Daily journaling and mood tracking

### 🏃 Sports, 🏥 Health, 🍽️ Food & 😴 Sleep
- Workout and exercise logging
- Medications, vitamins, and health metrics
- Food and sleep tracking

### 📝 Notes & Tasks
- Notes with categories
- Todo lists

### 📅 Calendar
- Built-in calendar and event management
- Unified reminders

### 🌦️ Weather
- Live conditions and hourly forecast from Open-Meteo
- Day/night aware icons and a redesigned, expandable weather card

### 🔐 Security Vault
- Biometric-protected password manager
- Encrypted credential storage

### 💾 Data Ownership
- Zip backups with attachments, restore (replace or merge), and backup reminders
- Readable per-module JSON and CSV export
- Device sync between phone and Mac over USB
- Notification and reminder diagnostics to verify delivery on the device

### 🧩 App Enhancements
- A built-in place to capture ideas for improving the app itself

## 🚀 Tech Stack

- **Framework**: Flutter (Dart 3.11.1+)
- **Core Package**: [abdalsalam_logic_flutter](https://pub.dev/packages/abdalsalam_logic_flutter)
- **State Management**: Riverpod
- **Storage**: `StorageGateway` (SQLite-backed key/value + SharedPreferences), local-first
- **Notifications**: flutter_local_notifications with timezone-aware scheduling
- **Security**: flutter_secure_storage, local_auth, encrypt
- **Prayer Times**: adhan
- **Charts**: fl_chart
- **Weather**: Open-Meteo API
- **Backup & Export**: archive (zip), pdf, printing

## 📁 Project Structure

```
lib/
├── core/           # Theme, router, constants, errors, result, formatting
├── data/           # Models and repositories, grouped by domain
├── features/       # Feature modules (religious, financial, planning, dashboard, ...)
├── providers/      # App-wide Riverpod providers
└── shared/         # Infrastructure, cross-feature services and widgets
```

## 🏗️ Architecture

- **Clean Architecture** with feature-based organization
- **Offline-First**: all functionality works without internet
- **Data-First**: everything is logged and exportable
- **Modular**: easy to add or remove features
- **Customizable**: dashboard, sidebar, and per-module settings are all adjustable

### 🎯 Baseline Requirements (MANDATORY)

**ALL implementations MUST follow the baseline:**
- **Models** → Extend `BaseModel`
- **Repositories** → Implement `BaseRepository<T>`
- **Services** → Implement `BaseService<T>`
- **Operations** → Return `Result<T, AppError>`
- **Export/Import** → Full metadata support
- **Logging** → Comprehensive operation logging
- **Validation** → All inputs validated

📖 **See [BASELINE_REQUIREMENTS.md](docs/BASELINE_REQUIREMENTS.md) for complete details**

## 📚 Documentation

- **[Baseline Requirements](docs/BASELINE_REQUIREMENTS.md)** - ⚠️ MANDATORY for all implementations
- **[Getting Started](docs/GETTING_STARTED.md)** - Setup and development guide
- **[Project Overview](docs/PROJECT_OVERVIEW.md)** - Detailed feature documentation
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Command cheat sheet
- **[Robustness Plan](docs/ROBUSTNESS_PLAN.md)** - Hardening standards and backlog
- **[Steering Summary](docs/STEERING_SUMMARY.md)** - Overview of all steering docs
- **Steering Documents** (`.kiro/steering/`) describe intended architecture and standards. Treat them as intent and verify against the code in `lib/`.

## 🛠️ Quick Start

```bash
flutter pub get
flutter run
flutter test
flutter build apk --release
```

## 🔧 Development

```bash
flutter analyze          # Analyze code
flutter format lib/      # Format code
flutter test --coverage  # Run tests with coverage
```

## 🎨 Design Philosophy

- **Personal & Functional**: clean, minimal interface built around one person
- **Refinable**: easy to adjust as my life and needs change
- **Quick Access**: efficient workflows for daily logging
- **Dashboard-First**: overview with module deep-dives

## 🔮 Roadmap

1. **Phase 1 (current)**: finish every existing module to a solid, cohesive state, running on all my devices
2. **Phase 2**: replace local-only storage with a simple custom backend, stable and still single-user
3. **Phase 3**: native macOS app on my own device, running persistently ("always live")
4. **Phase 4**: AI that understands my data
5. **Phase 5**: integrate with external services and tools as needed

## 📄 License

Personal project - All rights reserved

## 👤 Author

Abdalsalam
- Email: abed.alsalam.jodalah@gmail.com
- Package: [abdalsalam_logic_flutter](https://pub.dev/packages/abdalsalam_logic_flutter)
