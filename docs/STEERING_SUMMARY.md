# Steering & Documentation Summary

This document provides a quick reference to all steering documents and project documentation.

## 📋 Quick Reference

### Core Documents

| Document | Purpose | Location |
|----------|---------|----------|
| README | Project overview and quick start | `README.md` |
| Getting Started | Setup and development guide | `docs/GETTING_STARTED.md` |
| Project Overview | Detailed feature documentation | `docs/PROJECT_OVERVIEW.md` |

### Steering Documents (`.kiro/steering/`)

| Document | Purpose | Key Topics |
|----------|---------|------------|
| `product.md` | Product vision and modules | Vision, core modules, roadmap |
| `tech.md` | Tech stack and commands | Flutter commands, build process |
| `structure.md` | Project organization | Folder structure, conventions |
| `architecture.md` | Architecture guidelines | Design principles, patterns, decisions |
| `coding-standards.md` | Code style and practices | Naming, patterns, testing |
| `data-models.md` | Data schema guidelines | Model structure, relationships, export |
| `ui-ux-guidelines.md` | UI/UX patterns | Design system, interactions, accessibility |
| `dependencies.md` | Package management | Required packages, usage examples |
| `abdalsalam-package.md` | Core package integration | abdalsalam_logic_flutter usage |

### Hooks (`.kiro/hooks/`)

| Hook | Trigger | Action |
|------|---------|--------|
| `analyze-on-save.json` | File edited (*.dart) | Run flutter analyze |
| `format-on-save.json` | File edited (*.dart) | Auto-format code |
| `review-data-models.json` | Model file edited | Review model standards |
| `security-check.json` | Security file edited | Security validation |
| `test-reminder.json` | Service/repo created | Remind to write tests |

## 🎯 Key Principles

### 1. Data-First Architecture
- Everything is logged and structured
- All models support JSON export
- Designed for future AI analysis
- Data integrity is paramount

### 2. Offline-First
- All features work without internet
- Local storage is primary
- Sync prepared for future
- Graceful conflict resolution

### 3. Modular Design
- Self-contained feature modules
- Well-defined interfaces
- Easy to add/remove features
- Shared functionality centralized

### 4. Security by Design
- Encrypted sensitive data
- Biometric authentication
- No hardcoded credentials
- Secure export mechanisms

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  (Screens, Widgets, State Management)   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           Business Logic Layer          │
│     (Services, Use Cases, Validators)   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│            Data Layer                   │
│  (Repositories, Models, StorageGateway) │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      abdalsalam_logic_flutter           │
│  (Storage, Networking, Auth, Logging)   │
└─────────────────────────────────────────┘
```

## 📦 Core Package Features

### abdalsalam_logic_flutter provides:

1. **App State Management** (21+ domains)
   - Battery, connectivity, storage monitoring
   - Responsive breakpoints
   - Platform awareness

2. **Storage Gateway**
   - Unified SQLite + Hive + SharedPreferences
   - User isolation
   - Auto sync and conflict resolution

3. **Networking**
   - Offline-first HTTP client
   - Intelligent caching
   - Auto retry

4. **Authentication**
   - Firebase Auth integration
   - Token management
   - User isolation

5. **Utilities**
   - Structured logging
   - Error handling
   - File operations
   - FCM messaging

## 🎨 UI/UX Guidelines

### Navigation
- Bottom nav: Dashboard, Quick Add, Calendar, More
- Module cards on dashboard
- Consistent module structure

### Color System
- Religious: Purple/Indigo
- Financial: Green
- Habits: Blue
- Sports: Orange
- Health: Red/Pink
- Notes: Yellow
- Calendar: Teal
- Security: Dark Blue/Gray

### Typography
- Headline: 24sp Bold
- Title: 20sp SemiBold
- Subtitle: 16sp Medium
- Body: 14sp Regular
- Caption: 12sp Regular

## 📊 Data Models

### Base Model Structure
```dart
abstract class BaseModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  
  Map<String, dynamic> toJson();
}
```

### Key Principles
1. All models extend BaseModel
2. Implement toJson/fromJson
3. Include timestamps
4. Soft deletes (deletedAt)
5. UUID identifiers

## 🔐 Security Standards

### Password Vault
- Biometric authentication required
- flutter_secure_storage for encryption
- Auto-clear clipboard
- Password strength indicator

### Data Export
- Warn about sensitive data
- Support encrypted exports
- Validate imports
- Sanitize before export

## 🧪 Testing Strategy

### Unit Tests
- All business logic
- Mock dependencies
- Edge cases
- >80% coverage goal

### Widget Tests
- User interactions
- State changes
- Navigation flows

### Integration Tests
- Critical user journeys
- Data persistence
- Reminder system
- Export/import

## 📝 Coding Standards

### Naming Conventions
- Classes: `UpperCamelCase`
- Variables/Functions: `lowerCamelCase`
- Constants: `lowerCamelCase` with `const`
- Private: prefix with `_`
- Files: `snake_case`

### Widget Guidelines
- Prefer `const` constructors
- Extract complex widgets
- Keep build() under 50 lines
- Use StatelessWidget when possible

### Error Handling
- Use Result/Either pattern
- Handle at appropriate levels
- User-friendly messages
- Log all errors

## 🚀 Development Workflow

### Adding a Feature
1. Create feature directory in `lib/features/`
2. Create models in `lib/data/models/`
3. Implement repository in `lib/data/repositories/`
4. Create service in feature's `services/`
5. Build UI in feature's `screens/` and `widgets/`
6. Add routes in `core/router/`
7. Update dashboard

### Code Quality Checklist
- [ ] Follows naming conventions
- [ ] Includes documentation
- [ ] Has unit tests
- [ ] Passes flutter analyze
- [ ] Formatted with flutter format
- [ ] Models have toJson/fromJson
- [ ] Errors handled properly
- [ ] Logging implemented

## 📚 Learning Resources

### Internal Documentation
- `.kiro/steering/` - All steering documents
- `docs/` - Project documentation
- Code examples in steering docs

### External Resources
- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev/guides)
- [abdalsalam_logic_flutter](https://pub.dev/packages/abdalsalam_logic_flutter)
- [Firebase Docs](https://firebase.google.com/docs)

## 🎯 Next Steps for Development

### Phase 1: Foundation (Current)
1. Set up project structure ✅
2. Configure abdalsalam_logic_flutter
3. Implement base models
4. Create core services
5. Build dashboard skeleton

### Phase 2: Core Features
1. Religious module
2. Financial module
3. Habits module
4. Notes module

### Phase 3: Advanced Features
1. Sports module
2. Health module
3. Calendar integration
4. Security vault

### Phase 4: Polish
1. Analytics and charts
2. Data export/import
3. Backup system
4. Performance optimization

## 💡 Tips for AI Assistants

When working on this project:

1. **Always check steering documents first** - They contain project-specific guidelines
2. **Use abdalsalam_logic_flutter** - Don't reinvent what the package provides
3. **Follow the architecture** - Clean architecture with feature modules
4. **Data models must be exportable** - toJson/fromJson required
5. **Security is critical** - Especially for password vault
6. **Offline-first** - Assume no network
7. **Log everything** - Use LoggerService
8. **Test business logic** - Unit tests are important
9. **Consistent UI** - Follow ui-ux-guidelines.md
10. **Document code** - Public APIs need doc comments

## 🔄 Keeping Documentation Updated

When making changes:
- Update relevant steering documents
- Keep README.md current
- Update GETTING_STARTED.md for new setup steps
- Document breaking changes
- Update hooks if workflows change

## 📞 Contact

For questions or clarifications:
- Email: abed.alsalam.jodalah@gmail.com
- Package: https://pub.dev/packages/abdalsalam_logic_flutter
