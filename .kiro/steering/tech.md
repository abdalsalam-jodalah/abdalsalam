# Tech Stack

## Framework & Language
- Flutter SDK (Dart 3.11.1+)
- Material Design UI components

## Dependencies
- `flutter`: Core Flutter SDK
- `flutter_test`: Testing framework (dev)
- `flutter_lints`: Linting rules (v6.0.0+)

## Code Quality
- Analysis options: Uses `package:flutter_lints/flutter.yaml` for standard Flutter linting rules
- Follows Flutter's recommended code style and best practices

## Common Commands

### Development
```bash
# Run the app in debug mode
flutter run

# Run on specific device
flutter run -d <device_id>

# Hot reload (press 'r' in terminal while app is running)
# Hot restart (press 'R' in terminal while app is running)
```

### Building
```bash
# Build APK (Android)
flutter build apk

# Build iOS (requires macOS)
flutter build ios

# Build for release
flutter build apk --release
flutter build ios --release
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format lib/

# Check formatting without changes
flutter format --set-exit-if-changed lib/
```

### Maintenance
```bash
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Clean build artifacts
flutter clean

# Check Flutter installation
flutter doctor
```
