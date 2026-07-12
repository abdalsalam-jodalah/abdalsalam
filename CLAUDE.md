# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app (Dart 3.11.1+) — a personal all-in-one life management app: religious tracking (prayers, Quran),
financial management, habits, sports, health, notes/todos, calendar, security vault (biometric password manager),
life/day planning, and a dashboard. Everything is local-first and designed to be fully exportable for future
AI-driven analysis. No backend/Firebase is currently wired up despite some steering docs describing it — check
`lib/main.dart` and `lib/shared/infrastructure/` for what's actually implemented before assuming a package feature exists.

**This is a single-user personal app for Abdalsalam Jodalah only.** It is not published and not built for
multi-tenancy — do not add user-account systems, multi-user data isolation, or public-facing concerns unless
explicitly asked. Optimize for one person's actual workflow, not general-purpose product concerns.

### Roadmap

1. **Current phase** — complete the app's existing features (finish out each domain module to a solid, cohesive
   state) before moving to later phases.
2. Replace local-only storage with a simple custom backend (still single-user, not multi-tenant).
3. Extend to macOS as a native app on the user's own device, running persistently ("always live").
4. Integrate AI.
5. Integrate with external services/tools as needed.

Stay focused on phase 1 work unless the user asks to start on a later phase.

## Commands

```bash
flutter pub get                      # install dependencies
flutter run                          # run in debug mode
flutter analyze                      # static analysis (flutter_lints via analysis_options.yaml)
flutter test                         # run all tests
flutter test test/religious/prayer_service_test.dart   # run a single test file
flutter format lib/                  # format code
flutter build apk --release          # release build (Android)
```

## Architecture

Clean Architecture, feature-first, organized under `lib/`:

- `lib/data/models/<domain>/` — data models grouped by domain (financial, religious, habits, health, notes,
  planning, calendar, security, sports, weather)
- `lib/data/repositories/<domain>/` — data access layer, one subfolder per domain
- `lib/features/<domain>/{screens,widgets,services,providers}/` — UI and business logic per feature module
- `lib/shared/` — cross-feature code: `infrastructure/` (StorageGateway, logging, file ops, DB schema init),
  `services/` (backup/export/import, notifications, sync queue, analytics engine), `widgets/` (reusable UI)
- `lib/core/` — `router/` (single `AppRouter.onGenerateRoute` switch, screens expose a static `routeName`),
  `theme/`, `errors/`, `result/`, `validation/`, `constants/`
- State management: Riverpod (`flutter_riverpod`) — providers live in each feature's `providers/` folder plus
  `lib/providers/app_providers.dart` for app-wide providers.

### Baseline pattern (mandatory for new domain code)

This is the load-bearing convention across the whole codebase — new models/repositories/services must follow it:

- **Models** extend `BaseModel` (`lib/data/models/base_model.dart`): `id`, `createdAt`, `updatedAt`, `deletedAt`
  (soft delete), `toJson()`, equality via `Equatable` on `id`.
- **Repositories** implement `BaseRepository<T>` (`lib/data/repositories/base_repository.dart`): full CRUD, bulk
  ops, soft delete/restore, date-range/user-id/filter queries, count variants, `deleteAll`/`vacuum`. Not every
  concrete repository fully implements every method yet — check the existing repository for the domain you're
  touching (e.g. `lib/data/repositories/financial/transaction_repository.dart`) before assuming coverage.
- **Errors**: results are `Result<T, AppError>` (`lib/core/result/result.dart`, `lib/core/errors/app_error.dart`).
  Some older modules (e.g. financial) define their own domain-specific error hierarchy
  (`lib/core/errors/financial_errors.dart`, extending `Error` not `AppError`) instead of the shared one — match
  whatever pattern the domain you're editing already uses rather than introducing a third variant.
- **Storage**: all persistence goes through `StorageGateway` (`lib/shared/infrastructure/storage_gateway.dart`),
  a singleton (`StorageGateway.instance`) unifying SQLite-backed key/value storage and SharedPreferences. Don't
  reach for `sqflite`/`shared_preferences` directly from feature code.
- **Services**: business logic lives in feature `services/`, not in widgets. Screens/widgets should stay
  presentation-only and call into services/repositories via Riverpod providers.

### Routing

Every screen exposes a `static const routeName`, and `AppRouter.onGenerateRoute` (`lib/core/router/app_router.dart`)
is a single big switch mapping route names to `MaterialPageRoute`s. Add new screens by adding a case there, not
by introducing a second routing mechanism.

## Implementation status (check before assuming a module is "done")

Many screens exist in the router and navigate fine, but are not backed by real data. Before building on top of a
screen, check which category it falls in:

- **Fully wired** (real repository/service + Riverpod provider + persistence via `StorageGateway`): religious
  (prayer logging, Quran progress), most of financial (transactions/budgets/categories — but see the delete-TODO
  below), core habits tracking, notes core, planning (goals/reviews/life-plan/achievements via
  `planning_providers.dart`), weather (`weather_service.dart` calls the real Open-Meteo API, not mock data).
- **Placeholder-only** (rendered via `lib/shared/widgets/section_placeholder_screen.dart` — fake metrics, a local
  checklist, and a "quick add" list that isn't persisted or read from any repository): habits' daily events/habit
  detail/mood tracker, health's blood tests/health metrics, notes' categories/todo list, religious's spiritual
  progress, sports' exercise library/progress charts/workout list.
- **Mock UI with no backing service at all** (hardcoded sample data, not even a stubbed repository): the entire
  **calendar** module (grid, agenda, unified timeline, Google Calendar sync toggle) and the entire **security**
  module (vault status, credential list/categories, and `biometric_lock_screen.dart`'s "Use Biometrics" button,
  which just pops the route instead of calling `local_auth`). The analytics screen is the same except its
  achievements list, which does read from a real provider.
- **Known bug, not a missing feature**: `financial/screens/transactions_page.dart` has a delete button that
  doesn't actually delete the transaction from storage yet (see the `TODO` around line 430).

## `.kiro/` steering docs

`.kiro/steering/*.md` contains detailed (sometimes aspirational) architecture docs written for the Kiro assistant
covering base classes, data models per domain, dependency choices, and coding standards. They're a useful deep
reference, but treat them as intent, not ground truth — verify against the actual code in `lib/` (e.g. the real
`StorageGateway` is far simpler than the one described there, and Firebase/FCM described in
`abdalsalam-package.md` isn't currently integrated).
