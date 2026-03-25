# Project Structure

## Root Directory Layout

```
abdalsalam/
├── lib/                    # Dart source code
├── android/                # Android-specific code and configuration
├── ios/                    # iOS-specific code and configuration
├── test/                   # Unit and widget tests (create when needed)
├── .kiro/                  # Kiro AI assistant configuration
│   └── steering/           # AI guidance documents
├── pubspec.yaml            # Project dependencies and metadata
└── analysis_options.yaml   # Linting and analysis configuration
```

## Source Code Organization (lib/)

```
lib/
├── main.dart                      # App entry point
├── core/                          # Core functionality
│   ├── constants/                 # App-wide constants
│   ├── theme/                     # Theme and styling
│   ├── router/                    # Navigation and routing
│   └── utils/                     # Helper functions
├── data/                          # Data layer
│   ├── models/                    # Data models
│   │   ├── religious/             # Prayer, Quran models
│   │   ├── financial/             # Expense, income models
│   │   ├── health/                # Medicine, fitness models
│   │   ├── notes/                 # Note, todo models
│   │   └── security/              # Password vault models
│   ├── repositories/              # Data access layer
│   └── local/                     # Local storage (SQLite, Hive, etc.)
├── features/                      # Feature modules
│   ├── religious/                 # Religious tracking
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── services/
│   ├── financial/                 # Money management
│   ├── habits/                    # Habits & daily events
│   ├── sports/                    # Fitness tracking
│   ├── health/                    # Health management
│   ├── notes/                     # Notes & todos
│   ├── calendar/                  # Calendar & events
│   ├── security/                  # Password vault
│   └── dashboard/                 # Main dashboard
├── shared/                        # Shared across features
│   ├── widgets/                   # Reusable UI components
│   ├── services/                  # Shared services
│   └── extensions/                # Dart extensions
└── app.dart                       # Root app widget
```

## Platform-Specific Code

- `android/` - Android native code (Kotlin), Gradle build files, and manifests
- `ios/` - iOS native code (Swift), Xcode project, and Info.plist

## Conventions

- Use `const` constructors where possible for performance
- Follow Flutter naming conventions: `UpperCamelCase` for classes, `lowerCamelCase` for variables
- Keep widgets focused and composable
- Prefer `StatelessWidget` over `StatefulWidget` when state is not needed
