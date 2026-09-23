# Robustness & Reliability Hardening Plan

## Progress Tracker

| Phase | Scope | Status | Commit |
|---|---|---|---|
| 0 | Measurable baseline — `tool/robustness_audit.sh` | ✅ Done | `1d1ec00` |
| 1 | Core foundation — Result helpers, AppError cause/stack, ErrorHandler, JsonReader, test DB isolation | ✅ Done | `b7b2245` |
| 2 | Infrastructure — StorageGateway hardening, schema tables, crash log | ✅ Done | `5262db5` |
| 3 | Bootstrap & global error handlers | ⬜ Todo | |
| 4 | Data layer — tolerant row parsing, 46 models → JsonReader, financial error unification | ⬜ Todo | |
| 5 | Services — handled Results, bug fixes, planning/sports services | ⬜ Todo | |
| 6 | Providers — no masking, AsyncValue.guard, autoDispose | ⬜ Todo | |
| 7 | UI — shared error/feedback widgets, mounted guards, form validation | ⬜ Todo | |
| 8 | Backup / restore / import / sync queue | ⬜ Todo | |
| 9 | Strict analysis — lints on, `flutter analyze` = 0 | ⬜ Todo | |
| 10 | Tests & final scorecard — all ✓ | ⬜ Todo | |

Legend: ⬜ Todo · 🔄 In progress · ✅ Done. Each phase is marked Done only after `flutter analyze`, `flutter test`, and `./tool/robustness_audit.sh` pass for its scope, and it's committed.

## Scorecard History

| Metric | Baseline (P0) | P1 | P2 |
|---|---|---|---|
| Raw exception text used as error message | 70 | 68 | 68 |
| Unlogged catch blocks | 10 | 10 | 10 |
| Providers masking failures (`?? []`) | 63 | 63 | 63 |
| Ignored write results (heuristic) | 126 | 126 | 127 |
| `DateTime.parse` in models | 186 | 186 | 186 |
| `byName` without fallback | 23 | 23 | 23 |
| Hard casts in models | 413 | 413 | 413 |
| Error branches without shared view | 93 | 93 | 93 |
| Raw error text in UI | 90 | 90 | 90 |
| Unguarded UI after `await` (heuristic) | 114 | 114 | 114 |
| Raw `TextField` | 40 | 40 | 40 |
| Silent `?? 0` coercion | 9 | 9 | 9 |
| `TextFormField` without validator | 27 | 27 | 27 |
| App-wide checks passing | 0 / 15 | 1 / 15 | 1 / 15 |
| `flutter analyze` issues | 8 | 8 | 8 |
| `flutter test` | 70 total · 8 fail in parallel, all pass with `-j 1` | 113 · all pass in parallel | 129 · all pass |

## Context
Goal: fewer bugs, fewer crashes, every failure caught → logged → shown to the user as a clear, actionable message, and no silent data loss. Covers **every section** (core, shared, all 14 feature modules). Judged against the measurable scorecard below: baseline now, re-scored after every phase, done when every cell is ✓.

Audit headline findings:
- No global error capture at all; bootstrap is all-or-nothing (a failing notification/reminder step locks the user out of all data).
- 63 providers turn failures into `[]`/`0`, so 93 UI error branches are dead code; ~62 write `Result`s are ignored (data loss / duplicates).
- 46 `fromJson` factories: 367 hard `as String`, 186 `DateTime.parse`, 0 `tryParse`, 23 `byName` without fallback → one bad row fails a whole table.
- The storage package (`abdalsalam_logic_flutter/sqlite_storage.dart`) swallows read errors as `null`/`[]`; no transactions; restore is non-atomic and resets `createdAt`.
- Existing helpers with **zero call sites**: `ErrorHandler`, `ValidationUtils`, `LoadingSkeleton`.
- Real bugs found: backup `.b64` vs restore `jsonDecode` mismatch; 3 financial tables missing from `DatabaseSchemaInitializer`; weather cache `toJson`/`fromJson` mismatch; Quran legacy import always fails (`surahNumber: 0`); recurring-transaction generator advances due date on failed create; medication rollover marks itself done after failing; `Currency.values.firstWhere` without `orElse`.

## Judging Criteria (Robustness Scorecard)

| # | Criterion | How judged | Target |
|---|---|---|---|
| C1 | No unhandled exception escapes | `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError` + `ErrorWidget.builder` + `ProviderObserver`, all → logger + persisted crash log | Installed + tested |
| C2 | Data/service layer never throws | Every public repo/service method returns `Result`; no un-wrapped storage call outside try | 0 |
| C3 | No silent failures | No unlogged `catch`; no ignored `Result` from a write; no `?? []` masking in providers | 0 |
| C4 | Parsing survives bad data | Every model parses via `JsonReader`; tests with missing/wrong-type/bad-date/unknown-enum input; corrupt rows skipped + counted, not table-fatal | 46/46 models |
| C5 | UI handles every state | Every `AsyncValue` → loading + error(with retry) + empty via shared widgets | 0 violations |
| C6 | No raw errors reach user | 0 `$error` / `.toString()` / `.message` in SnackBars/Text; all via `UserErrorMessageMapper` | 0 |
| C7 | Async-safe widgets | No `setState`/`context`/`ref` after `await` without `mounted` | 0 |
| C8 | Input validated | Every form field has a `ValidationUtils` validator; no silent `tryParse(...) ?? 0` coercion | 0 |
| C9 | Strict analysis | `strict-casts`, `strict-inference`, `strict-raw-types` + `unawaited_futures`, `discarded_futures`, `avoid_dynamic_calls`, `cancel_subscriptions`, `close_sinks`, `only_throw_errors`; `flutter analyze` | 0 issues |
| C10 | Startup resilience | Non-critical init failure → app opens + banner; critical failure → recovery screen with retry + export logs | Tested |
| C11 | Backup/restore atomic | Bad/partial file → existing data unchanged, typed error, pre-restore backup mandatory | Tested |
| C12 | Failure paths tested | Every repo + service: happy / error / edge tests; `flutter test` green | 100% |

C1, C9, C10, C11 are app-wide. The rest are scored per section.

## Per-Section Baseline (✗ fail · ◐ partial · ✓ pass · — n/a)

| Section | C2 | C3 | C4 | C5 | C6 | C7 | C8 | C12 |
|---|---|---|---|---|---|---|---|---|
| core / shared infra | ✗ gateway throws raw | ✗ package swallows | ✗ | — | — | — | — | ✗ |
| shared services (backup/import/sync) | ◐ | ✗ | ✗ | — | ✗ | ✗ | — | ✗ |
| religious | ◐ | ✗ legacy import | ✗ | ◐ | ✗ 11 toString | ✓ | ✗ 21 raw fields | ◐ |
| financial | ◐ own hierarchy | ✗ recurring gen, 5 unlogged | ✗ | ✗ 12 mask | ✗ | ◐ | ◐ manual | ◐ |
| habits | ◐ | ◐ | ✗ | ◐ | ✗ | ◐ | ✗ log sheet | ◐ |
| health | ✗ medication | ✗ rollover, 5 ignored | ✗ | ✗ 9 mask | ✗ 10 raw | ✗ | ◐ | ✗ |
| food / sleep | ◐ | ✗ ignored deletes | ✗ | ✗ | ✗ | ✗ | ✗ sleep form | ◐ |
| notes | ✗ service unused | ✗ 6 ignored | ✗ | ✗ | ✗ | ◐ | ◐ | ✗ |
| planning | ✗ no service layer | ✗ 12 ignored | ✗ | ✗ 8 mask | ✗ | ✗ | ✗ reviews | ✗ |
| sports | ✗ no service layer | ✗ 15 ignored | ✗ | ✗ 12 mask | ✗ | ✓ | ◐ | ◐ |
| weather | ✗ throws | ✗ cache never loads | ✗ | ◐ stale flag | ✗ | — | — | ✗ |
| dashboard / analytics | ◐ | ✗ unawaited init | ✗ | ◐ | ✗ | — | — | ✗ |
| settings | ◐ | ✗ | ✗ bootstrap cast | ✗ | ✗ | ✗ backup/restore | — | ◐ |
| calendar / security | mock UI only — models (C4) + existing services only; full wiring is separate feature work |

Phase 0 converts this into exact counts via a repeatable audit script.

### Phase 0 measured baseline (`tool/robustness_audit.sh`, commit 1d1ec00)
Totals: errStr 70 · unlogged catch 10 · provider masking 63 · ignored writes 126 (heuristic, includes some false positives) · DateTime.parse 186 · byName 23 · hard casts 413 · error branches without shared view 93 · raw error in UI 90 · async-UI unguarded 114 (heuristic) · raw TextField 40 · silent `?? 0` 9 · TextFormField without validator 27 · all 15 app-wide checks FAIL.
`flutter analyze`: 8 issues. `flutter test`: 70 tests, **8 fail when run in parallel, all pass with `-j 1`**, because every test file shares the on-disk `test_abdalsalam.db`. Fix in Phase 1: a unique DB name per test file.

## Approach — phased, one commit per phase, each gated by `flutter analyze` + `flutter test` + scorecard re-run

### Phase 0 — Measurable baseline
- `tool/robustness_audit.sh`: grep-based counters per `lib/features/<module>` for each criterion (unlogged catch, `?? []` in providers, `$error` in UI, `DateTime.parse(`, `as String,`, `byName(`, `.toString()` in SnackBars, ignored write results, `setState` after `await`). Prints the scorecard table. Baseline output committed into the plan section above.

### Phase 1 — Core foundation (`lib/core/`)
- `result/result.dart`: add `map`, `flatMap`, `fold`, `getOrElse`, `getOrThrow`, and `Result.guard` / `Result.guardAsync` (catch → `ErrorHandler.mapException`). Keep existing API; no call-site churn.
- `errors/app_error.dart`: add optional `cause` + `stackTrace`; add `CorruptDataError`, `StorageUnavailableError`.
- `shared/services/error_handler.dart`: replace string-matching with type-based mapping (`DatabaseException`, `FormatException`, `TypeError`, `TimeoutException`, `SocketException`, `FileSystemException`, `AppError` passthrough). Split user messages into `UserErrorMessageMapper` (one concept per file). Singleton via provider.
- New `core/json/json_reader.dart`: typed safe reads — `requireString`, `optionalString`, `readDate` (tryParse), `readEnum(values, fallback)`, `readInt`/`readDouble` (accept any `num`), `readList<T>`, `readMap`. Required-field miss → throws `CorruptDataError(field)`; optional → default.
- Tests for all of the above.

### Phase 2 — Infrastructure (`lib/shared/infrastructure/` + storage package)
- `StorageGateway`: memoized init `Future` (fixes init/store-open races); guarded `jsonDecode` → `CorruptDataError`; `upsertRecord` preserves incoming `createdAt`; add `runInTransaction`; `vacuum` once per DB file.
- Storage package is **not modified**. Its `get`/`getAll`/`count`/`getPage` swallow errors (`sqlite_storage.dart:174,188,292,384`), and `upsert` → `contains` → swallowing `get` means a corrupt row triggers an insert and a UNIQUE failure. Workaround inside `StorageGateway` only: use the exposed `SqliteStorageImpl.database` getter for reads (`query` → per-row guarded decode of the `data` blob → `CorruptDataError` per bad row), counts (`COUNT(*)`), and upsert (`INSERT … ON CONFLICT(id) DO UPDATE`, preserving `createdAt`). Package writes (`create`/`update`/`delete`) already rethrow, so they stay. `runInTransaction` wraps `database.transaction`. Feature code still never touches sqflite.
- `DatabaseSchemaInitializer`: add `accounts`, `exchange_rates`, `financial_activity_log`. Root cause of the missing tables: the package only runs `CREATE TABLE` in `onCreate` (first DB open), so `StorageGateway` now runs `CREATE TABLE IF NOT EXISTS` for every table on first use. The `onUpgrade` hook was dropped because the package fixes the DB version at 1. Records are JSON blobs, so tolerant parsing (`JsonReader`) is the migration strategy.
- `LoggerService`: environment from `kReleaseMode`/`kProfileMode`. Every `error()` is also persisted by `CrashLogRecorder` (last 200 entries, stored in SharedPreferences so it works on web too). The **Saved Errors** toggle in `log_viewer_screen.dart` shows them.

### Phase 3 — Bootstrap & global handlers (`lib/main.dart` → split)
- `lib/app/bootstrap/`: `AppBootstrapper` running `BootstrapStep`s, each `critical` or `nonCritical`, isolated try/catch, timed, logged → `StartupReport`.
- Critical: logger, storage, schema. Non-critical: settings (fallback defaults), notifications, reminders (per-reminder isolation), medication/wellness rollovers, `markTakenStream` listener (with `onError`).
- `main()` in `runZonedGuarded`; `FlutterError.onError`, `PlatformDispatcher.onError`, friendly `ErrorWidget.builder`, `AppProviderObserver` (`providerDidFail` → logger).
- Critical failure → `StartupRecoveryScreen` (retry, copy error details + recent saved errors). Non-critical → dismissible `StartupStatusBanner` listing degraded features. Corrupt settings no longer need a manual reset: `SettingsService` falls back to defaults and reports it, and the next save repairs the value.
- Optional steps that take longer than 10s keep running in the background, so startup isn't blocked. Found on macOS: the notification permission prompt held the splash screen until it was answered. A late failure is still logged.

### Phase 4 — Data layer
- `BaseRepositoryImpl`: `_parseRows` parses row-by-row. A corrupt row is **skipped, logged with table + id + field, and left untouched in the DB**. Skips are counted into a `DataIntegrityReporter` (shared service + provider) that the UI shows as a small "N records couldn't be read" notice (tap → log viewer). wrap `count*`, `vacuum`, `getAllRecordsForPagination` in try; `DatabaseError` carries cause + stack. Fixes all 34 subclass repositories at once.
- All 46 models migrate `fromJson` to `JsonReader` — one module per commit, with a `fromJson` robustness test per model (missing field, wrong type, `3.0` for int, bad date, unknown enum).
- Fix `weather_model.dart` `toJson`/`fromJson` symmetry (+ `hourlyForecast`).
- Financial error unification: `FinancialError extends AppError`; the clashing classes become `FinancialDatabaseError`, `FinancialNotFoundError`, `FinancialValidationError`; `enhanced_currency_service.dart:71` `StateError` → `FinancialError`; all 6 financial repositories and financial services/providers move from `Result<T, Error>` to `Result<T, AppError>`; same row-tolerant parsing as `BaseRepositoryImpl`. Update `test/financial/fakes.dart` + financial tests.
- Once financial is unified, tighten `Result<T, E extends Error>` → `E extends AppError`.

### Phase 5 — Services (every `lib/features/*/services/`)
- Every ignored `Result` handled; every catch logs; no `e.toString()` as message — use `ErrorHandler`.
- Bug fixes: recurring generator (advance date only on success, distinguish lookup failure from not-found), medication rollover (mark done only on success), medication service (propagate update/create failures), Quran legacy import, `Currency.firstWhere` `orElse`, fallback exchange rates surfaced via `wasFallback` to UI, weather `isStale` flag, raw-value services (`weather`, `currency*`, `prayer_time*`, `athkar_content_loader`, `health_report`) → return `Result`.
- New services for **planning** and **sports** (extending `BaseServiceImpl`) so UI stops writing to repositories directly and validation runs; wire existing `NotesService`.

### Phase 6 — Providers
- Replace every `result.data ?? []` with `result.getOrThrow()` so failures become `AsyncError`.
- AsyncNotifiers: mutations use `AsyncValue.guard`, keep previous data on refresh (`copyWithPrevious`), return `AppError` (not string) so `fieldErrors` reach forms.
- `.autoDispose` on the 18 family providers; await `dashboard` init; `StreamProvider`s handle errors.

### Phase 7 — UI (every screen)
- New shared widgets in `lib/shared/widgets/`: `AsyncErrorView` (mapped message + Retry → `ref.invalidate`), use existing `LoadingSkeleton` + `EmptyState`; `AppFeedback.showError/showSuccess` (single SnackBar style, correct colors).
- Replace all 47 raw `$error` renders and 55 ad-hoc SnackBars.
- Every write: `await` → on `Failure` show mapped error, no optimistic update without rollback (e.g. `medication_list_screen.dart:97`), fix silent delete in `transaction_form_screen.dart:923`.
- `mounted` guards: backup/restore, medication list, planning, food/sleep/health lists.
- Forms: `Form` + `ValidationUtils` validators for religious raw `TextField`s, `log_habit_sheet`, `reviews_screen`, `sleep_log_form_screen`; `fieldErrors` shown inline; remove silent `?? 0` coercions.
- Work fanned out to subagents, one module each.

### Phase 8 — Backup / restore / import / sync queue
- Fix `.b64` save vs raw-JSON restore (restore decodes base64, accepts both).
- Validate (structure, version, checksum) **before** anything; pre-restore backup mandatory (abort if it fails); restore inside `runInTransaction`; preserve timestamps; report skipped rows.
- `backupTablesProvider` derived from `DatabaseSchemaInitializer.tables` (single source); include SharedPreferences settings.
- `SyncQueueService`: serialize read-modify-write with an async lock; tolerant per-entry parsing; catch processor errors.

### Phase 9 — Strict analysis
- Enable C9 language modes + lint rules in `analysis_options.yaml`; fix all findings (subagents per module); `flutter analyze` = 0.

### Phase 10 — Tests & final scorecard
- Fill remaining C12 gaps: `StorageGateway` + `BaseRepositoryImpl` corrupt-data tests, backup/restore atomicity, sync queue concurrency, bootstrap step failure, provider → `AsyncError`, `AsyncErrorView` widget test. Hand-written fakes following `test/financial/fakes.dart` (no new mocking dependency).
- Re-run audit script; every cell ✓.

## Critical files
`lib/core/result/result.dart`, `lib/core/errors/app_error.dart`, `lib/core/errors/financial_errors.dart`, `lib/shared/services/error_handler.dart`, `lib/shared/infrastructure/storage_gateway.dart`, `lib/shared/infrastructure/database_schema_initializer.dart`, `lib/shared/infrastructure/logger_service.dart`, `lib/data/repositories/base_repository_impl.dart`, `lib/main.dart`, `lib/shared/services/backup_service.dart`, `lib/shared/services/sync_queue_service.dart`, `lib/providers/app_providers.dart`, all `lib/data/models/**` `fromJson`, all `lib/features/*/{services,providers,screens}`, `analysis_options.yaml`, `../abdalsalam_logic_flutter/lib/src/storage/sqlite_storage.dart`.

## Reused, not reinvented
`Result`/`AppError`, `ErrorHandler`, `ValidationUtils`/`ValidationErrorMessages`, `LoadingSkeleton`, `EmptyState`, `BaseRepositoryImpl`, `BaseServiceImpl`, `LoggerService`, `FileOperations`, `log_viewer_screen.dart`, package `beginTransaction()`, `test/financial/fakes.dart`.

## Verification
- Per phase: `flutter analyze` (0 new issues; 0 total after Phase 9), `flutter test` green, `tool/robustness_audit.sh` shows the targeted cells flipped to ✓.
- Fault injection (manual, `flutter run` on macOS): write a corrupt JSON value into settings, a corrupt row into `transactions`, force notification init to throw, import a truncated backup → app launches, shows banner/skipped-row notice, existing data intact, crash log has entries.
- End: scorecard all ✓, full manual pass through every module's add/edit/delete flow.

## Decisions (confirmed)
- Storage package: work around it in `StorageGateway`; the package is not touched (it has uncommitted local changes).
- Error types: unify financial into `AppError`.
- Corrupt rows: skip + log + report; the row stays in the DB.
- Cadence: phase by phase. After each phase: analyze + test + audit scorecard → commit → report the score → wait for approval before starting the next phase. Multi-module phases (4–7, 9) fan out to subagents, one module each, briefed with both CLAUDE.md paths.
