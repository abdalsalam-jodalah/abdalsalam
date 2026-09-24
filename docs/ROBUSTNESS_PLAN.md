# Robustness & Reliability Hardening Plan

## Progress Tracker

| Phase | Scope | Status | Commit |
|---|---|---|---|
| 0 | Measurable baseline — `tool/robustness_audit.sh` | ✅ Done | `1d1ec00` |
| 1 | Core foundation — Result helpers, AppError cause/stack, ErrorHandler, JsonReader, test DB isolation | ✅ Done | `b7b2245` |
| 2 | Infrastructure — StorageGateway hardening, schema tables, crash log | ✅ Done | `5262db5` |
| 3 | Bootstrap & global error handlers | ✅ Done | `a09c87d` |
| 4 | Data layer — tolerant row parsing, 46 models → JsonReader, financial error unification | ✅ Done | `7f90c6b` |
| 5 | Services — handled Results, bug fixes, planning/sports services | ✅ Done | `f100e36` |
| 6 | Providers — no masking, AsyncValue.guard, autoDispose | ✅ Done | `57480a4` |
| 7 | UI — shared error/feedback widgets, mounted guards, form validation | ✅ Done | `0aefc58` |
| 8 | Backup / restore / import / sync queue | ⬜ Todo | |
| 9 | Strict analysis — lints on, `flutter analyze` = 0 | ⬜ Todo | |
| 10 | Tests & final scorecard — all ✓ | ⬜ Todo | |

Legend: ⬜ Todo · 🔄 In progress · ✅ Done. Each phase is marked Done only after `flutter analyze`, `flutter test`, and `./tool/robustness_audit.sh` pass for its scope, and it's committed.

## Scorecard History

| Metric | Baseline (P0) | P1 | P2 | P3 | P4 | P5 | P6 | P7 |
|---|---|---|---|---|---|---|---|---|
| Raw exception text used as error message | 70 | 68 | 68 | 68 | 24 | 7 | 7 | 7 |
| Unlogged catch blocks | 10 | 10 | 10 | 10 | 10 | 9 | 8 | 1 |
| Providers masking failures (`?? []`) | 63 | 63 | 63 | 63 | 63 | 63 | 0 | 0 |
| Ignored write results (heuristic) | 126 | 126 | 127 | 127 | 121 | 67 | 67 | 60 |
| `DateTime.parse` in models | 186 | 186 | 186 | 186 | 0 | 0 | 0 | 0 |
| `byName` without fallback | 23 | 23 | 23 | 23 | 0 | 0 | 0 | 0 |
| Hard casts in models | 413 | 413 | 413 | 413 | 0 | 0 | 0 | 0 |
| Error branches without shared view | 93 | 93 | 93 | 93 | 93 | 93 | 93 | 3 |
| Raw error text in UI | 90 | 90 | 90 | 89 | 66 | 68 | 68 | 4 |
| Unguarded UI after `await` (heuristic) | 114 | 114 | 114 | 114 | 114 | 92 | 92 | 2 |
| Raw `TextField` | 40 | 40 | 40 | 40 | 40 | 40 | 40 | 22 |
| Silent `?? 0` coercion | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 2 |
| `TextFormField` without validator | 27 | 27 | 27 | 27 | 27 | 27 | 27 | 19 |
| App-wide checks passing | 0 / 15 | 1 / 15 | 1 / 15 | 8 / 15 | 8 / 15 | 8 / 15 | 8 / 15 | 8 / 15 |
| `flutter analyze` issues | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 0 |
| `flutter test` | 70 total · 8 fail in parallel, all pass with `-j 1` | 113 · all pass in parallel | 129 · all pass | 137 · all pass | 461 · all pass | 792 · all pass | 959 · all pass | 1007 · all pass |

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
- **What was done.** Every model reads its JSON through `JsonReader`.
  - Required fields: `id`, `createdAt`, and fields where a default would silently corrupt meaning (money amounts and direction, foreign keys, dose and prayer times, measured values).
  - `userId` is always lenient (`''`) because this is a single-user app.
  - `updatedAt` falls back to `createdAt`.
  - The duplicate financial `DatabaseError`, `NotFoundError` and `ValidationError` classes were deleted rather than renamed; financial code now uses the shared ones. Financial repositories share `RepositoryOperationGuard` with `BaseRepositoryImpl`.
  - The weather cache round trip is fixed, and the hourly forecast is now cached too.
  - A medication with an unknown weekday is now reported as corrupt instead of being scheduled on Monday.
- **Follow-ups found in Phase 4.**
  - Phase 5: `financial_service.dart` and `recurring_transaction_generator.dart` still build `FinancialError(e.toString())`; `weather_service.dart` still uses `DateTime.parse` and hard casts on API data.
  - Phase 7: `habitColorFromHex` (`habit_style_picker.dart`) uses `int.parse` on stored colour strings.

### Phase 5 — Services (every `lib/features/*/services/`)
- Every ignored `Result` handled; every catch logs; no `e.toString()` as message — use `ErrorHandler`.
- Bug fixes: recurring generator (advance date only on success, distinguish lookup failure from not-found), medication rollover (mark done only on success), medication service (propagate update/create failures), Quran legacy import, `Currency.firstWhere` `orElse`, fallback exchange rates surfaced via `wasFallback` to UI, weather `isStale` flag, raw-value services (`weather`, `currency*`, `prayer_time*`, `athkar_content_loader`, `health_report`) → return `Result`.
- New services for **planning** and **sports** (extending `BaseServiceImpl`) so UI stops writing to repositories directly and validation runs; wire existing `NotesService`.
- **Done.** All 17 screens and widgets that wrote straight to repositories now go through services and check the returned results.
  - Financial: the recurring generator no longer loses or duplicates transactions; unknown currencies return a typed failure; fallback exchange rates are flagged with `isFallback`/`wasFallback` and logged.
  - Health: medication writes propagate failures; rollovers mark themselves done only after succeeding; attachment cleanup happens after the save.
  - Religious: the Quran legacy import is atomic and can be re-run safely.
  - Weather: data is parsed defensively and cached data is flagged `isStale`.
  - Reminders: `rescheduleAll` isolates each reminder and returns counts.
  - `NotificationService` and `AttachmentStorageService` return `Result`.
- **Follow-ups found in Phase 5.**
  - `ReminderService.schedule`/`cancel` still throw a mapped `AppError`, and about 10 callers catch it. Converting them to `Result` means touching every caller in one go.
  - `HabitsService.scheduleHabitReminder` fires at `now` instead of `reminderTime` (a logic bug).
  - `habit_form_screen.dart` ignores the reminder result and uses `int.parse` on the stored time (Phase 7).
  - `EnhancedCurrencyService.getRateForDate` falls back to an ILS-based rate for other source currencies (no callers yet).
  - `seedAll` still throws for `dev_tools_overlay` (Phase 7).
  - `religious_tracker_service.dart` is about 540 lines and should be split.
  - One tracker test depends on the time of day, so it needs an injected clock (Phase 10).

### Phase 6 — Providers
- Replace every `result.data ?? []` with `result.getOrThrow()` so failures become `AsyncError`.
- AsyncNotifiers: mutations use `AsyncValue.guard`, keep previous data on refresh (`copyWithPrevious`), return `AppError` (not string) so `fieldErrors` reach forms.
- `.autoDispose` on the 18 family providers; await `dashboard` init; `StreamProvider`s handle errors.
- **Done.**
  - All 63 masking sites now call `getOrThrow()`, so a failure shows up as `AsyncError`. Money figures no longer fall back to 0 or `initialBalance`. `lifePlanProvider` no longer confuses "no plan" with a storage failure.
  - 6 AsyncNotifiers (10 mutations) return a typed `AppError?` and refresh with `AsyncValue.guard`. Their call sites show the mapped message.
  - The Quran legacy import shows how many rows were imported and skipped.
  - 24 unbounded families are now `autoDispose`. The two enum-keyed religious families were left as they are.
  - Kept on purpose: `financialStartupTasksProvider` logs and continues, because it's background maintenance.
- **Follow-up (Phase 7):** show an "estimated rate" indicator where totals rely on fallback exchange rates.

### Phase 7 — UI (every screen)
- New shared widgets in `lib/shared/widgets/`: `AsyncErrorView` (mapped message + Retry → `ref.invalidate`), use existing `LoadingSkeleton` + `EmptyState`; `AppFeedback.showError/showSuccess` (single SnackBar style, correct colors).
- Replace all 47 raw `$error` renders and 55 ad-hoc SnackBars.
- Every write: `await` → on `Failure` show mapped error, no optimistic update without rollback (e.g. `medication_list_screen.dart:97`), fix silent delete in `transaction_form_screen.dart:923`.
- `mounted` guards: backup/restore, medication list, planning, food/sleep/health lists.
- Forms: `Form` + `ValidationUtils` validators for religious raw `TextField`s, `log_habit_sheet`, `reviews_screen`, `sleep_log_form_screen`; `fieldErrors` shown inline; remove silent `?? 0` coercions.
- Work fanned out to subagents, one module each.
- **Done.**
  - Every primary `.when(error:)` uses `AsyncErrorView` with Retry. Every SnackBar goes through `AppFeedback`, and success SnackBars are no longer red.
  - Writes check their `Result` and are guarded by `mounted`. Add, edit and delete dialogs save before closing and stay open on failure.
  - Optimistic updates on the medication list are rolled back when the save fails.
  - Forms validate input: Quran surah/ayah ranges, positive numbers, coordinates, and sleep end after start. Silent `?? 0` coercions of user input were removed.
  - Weather shows an offline/stale hint. The 12 settings screens report save failures instead of failing silently.
  - Other fixes: `habitColorFromHex` is tolerant of bad values; habit reminders fire at `reminderTime`, not `now`; the sports dashboard no longer rebuilds its providers every frame (its date-range keys used `DateTime.now()`).
  - `flutter analyze`: 0 issues.
- **Kept on purpose.** Small decorative badges (streaks, weekly page count, category labels) still hide their errors behind a placeholder.
- **Follow-ups found in Phase 7.**
  - An "estimated rate" UI needs `FinancialService` summaries to carry the fallback flag.
  - The 12 settings screens duplicate the same `_load`/`_update` code, which could become a shared helper.
  - `settings_service` still throws instead of returning `Result`.
  - The habit model and the feature layer each define the same default colour and icon constants.
  - `medication_list_screen` has no widget test yet (Phase 10).

### Phase 8 — Backup / restore / import / sync queue
- Fix `.b64` save vs raw-JSON restore (restore decodes base64, accepts both).
- Validate (structure, version, checksum) **before** anything; pre-restore backup mandatory (abort if it fails); restore inside `runInTransaction`; preserve timestamps; report skipped rows.
- `backupTablesProvider` derived from `DatabaseSchemaInitializer.tables` (single source); include SharedPreferences settings.
- `SyncQueueService`: serialize read-modify-write with an async lock; tolerant per-entry parsing; catch processor errors.
- **Done.**
  - `BackupCodec` accepts both raw JSON and base64. The restore screen can pick a backup file or take pasted content, and shows a report of what was restored.
  - `BackupValidator` checks the backup version (1.0.0 or 1.1.0), both checksums, the table list and each row before anything is changed.
  - A safety backup of every known table is mandatory; if it can't be saved, the restore is cancelled.
  - Table writes run in a single `runInTransaction` and roll back if anything fails. Timestamps are preserved via `isPreservingUpdatedAt`.
  - Settings (SharedPreferences) are now backed up and restored. They are written after the table commit, and each one is isolated so one failure doesn't stop the rest.
  - `backupTablesProvider` comes from `DatabaseSchemaInitializer.tables`. The automatic-backup timer's `onRun` is now guarded.
  - `SyncQueueService` runs every operation through a `SerialTaskQueue`. It skips and reports corrupt entries, and keeps an item queued when its processor fails or throws.
  - The connectivity processor no longer drains the queue while there is no backend.

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
