# UI Enhancement Plan: modern soft-glass, customizable, reusable

## Progress Tracker

| Phase | Scope | Status | Commit |
|---|---|---|---|
| 0 | Plan doc + `tool/ui_audit.sh` baseline | ✅ Done | `7c9adc4` |
| 1 | Design system foundation — tokens, theme builder, fonts | 🔄 In progress | |
| 2 | Live appearance customization — Settings → Appearance | ⬜ Todo | |
| 3 | Shared component library + gallery + goldens | ⬜ Todo | |
| 4 | App shell + dashboard | ⬜ Todo | |
| 5 | Financial module | ⬜ Todo | |
| 6 | Religious + Health + Sleep + Food | ⬜ Todo | |
| 7 | Sports + Planning + Habits + Notes | ⬜ Todo | |
| 8 | Settings, Calendar, Security, Analytics, Weather, dev screens | ⬜ Todo | |
| 9 | Motion & polish | ⬜ Todo | |
| 10 | Verification & final scorecard | ⬜ Todo | |

Legend: ⬜ Todo · 🔄 In progress · ✅ Done. A phase is Done only after `flutter analyze` = 0, `flutter test` green, `tool/ui_audit.sh` targets met for its scope, and `tool/robustness_audit.sh` still at 0 — and it's committed.

## Scorecard History

| Metric | Baseline (P0) | P0 |
|---|---|---|
| U1 Hardcoded colors | 207 | 207 |
| U2 Literal radii | 79 | 79 |
| U3 fontSize literals | 109 | 109 |
| U3 TextStyle literals | 147 | 147 |
| U4 Literal spacing | 857 | 857 |
| U5 Redundant input borders | 119 | 119 |
| U6 Duplicated UI (private stat/date widgets, raw dialogs/sheets) | 48 | 48 |
| U10 Direct fl_chart imports | 4 | 4 |
| Design-system checks passing | 1 / 10 | 1 / 10 |
| `flutter analyze` issues | 0 | 0 |
| `flutter test` | 1019 · all pass | 1019 · all pass |

## Context
The app works and is robust (the previous hardening plan is done), but the UI is inconsistent, dated and hard to maintain:
- The theme is barely used: seed colour, 5 text styles and a card radius of 16. There are no button, input, chip, dialog, sheet, snackbar, navigation or transition themes.
- About 240 hardcoded colours (financial has half of them), 5+ different corner radii, 9 spacing values, 10+ font sizes, and 108 redundant `OutlineInputBorder()`s.
- Patterns are copy-pasted instead of shared: 5 stat-tile classes, 4 date fields, about 22 add/edit dialogs, 8 confirm dialogs, 7 unstyled bottom sheets, 6 identical module tab shells, 15 custom progress bars, and charts with hardcoded colours.
- Customization bugs: `themeMode` only applies after a restart (`appSettingsProvider` is never invalidated), `dashboardCardOrder`/`dashboardHiddenCards` are ignored, and `ModuleColors` is unused.
- There's almost no motion: no page transitions, no `AnimatedSwitcher`.

The goal is a modern, simple UI in a **soft glass / gradient** style (user's choice): gentle gradient backgrounds, frosted translucent cards, large smooth corners and no sharp edges. It should be **fully customizable** (accent colour, theme mode, corner roundness, text size, density and surface style) with changes applied live, and built from a **small reusable component library** so every screen looks and behaves the same.

The plan and a phase tracker will live at `docs/UI_ENHANCEMENT_PLAN.md`, updated with ✅ and a commit hash per phase, the same as `docs/ROBUSTNESS_PLAN.md`.

## Decisions (confirmed)
- **Style:** glass / gradient, kept restrained and simple:
  - Real `BackdropFilter` blur is used only on a few large surfaces (app bar, sidebar, nav bar, hero/summary cards).
  - List cards get the glass look without blur (translucent tint, soft 1px light border, soft shadow), for performance.
  - A **Solid** surface option turns glass off completely.
- **Customizable** in Settings → Appearance: accent colour, corner roundness, text size, density, plus theme mode and surface style (glass / solid). Everything applies live.
- **Font:** bundled Inter (Latin) + IBM Plex Sans Arabic (Arabic fallback), as static TTFs with OFL licenses in `assets/fonts/`.

## Judging Criteria (UI Scorecard)
`tool/ui_audit.sh` reports these per module, in the same format as `tool/robustness_audit.sh`.

| # | Criterion | How judged | Target |
|---|---|---|---|
| U1 | Colours come from the theme | `Colors.<name>` / `Color(0x…)` in `lib/features/**` UI, excluding `Colors.transparent` | 0 |
| U2 | Radii come from tokens | `BorderRadius.circular(<number>)` / `Radius.circular(<number>)` in features | 0 |
| U3 | Typography comes from `textTheme` | `fontSize:` and `TextStyle(` literals in features (`copyWith` on theme styles is allowed) | 0 |
| U4 | Spacing comes from tokens | `EdgeInsets.*(<number>)` and `SizedBox(height/width: <number>)` in features | 0 |
| U5 | No redundant decoration | `OutlineInputBorder()` / `border:` in `InputDecoration` inside features | 0 |
| U6 | Shared components used | Remaining private duplicates (`_StatTile`, `_StatCard`, `_DateField`, raw `showModalBottomSheet`, hand-built confirm `AlertDialog`) | 0 |
| U7 | Customization works live | Widget tests: changing each appearance option rebuilds the theme with no restart | 6/6 options tested |
| U8 | Accessible | Key screens render at text scale 1.3 with no overflow; tap targets ≥ 48; contrast of on-glass text meets AA (checked in a token test) | Tested |
| U9 | Performant glass | Blur only in `GlassSurface` with `isBlurred: true` (grep count ≤ 6 call sites); Solid mode has 0 blur | Checked |
| U10 | Consistent charts | `fl_chart` used only inside `lib/shared/widgets/charts/`; chart colours come from the theme | 0 direct uses in features |
| U11 | Smooth motion | `pageTransitionsTheme` set; `AsyncSection` animates state changes; reduce-motion (`MediaQuery.disableAnimations`) respected | Tested |
| U12 | Quality gate | `flutter analyze` 0, all tests green, golden tests for core components in light/dark × glass/solid | Green |

Baselines, measured in Phase 0 from exploration: U1 about 240, U2 about 70, U3 about 110 fontSize / 150 TextStyle, U4 about 1,100, U5 108, U6 about 45.

## Approach: phased, one commit per phase, each gated by analyze + tests + `ui_audit.sh`

### Phase 0: Plan doc and UI audit baseline
- Write `docs/UI_ENHANCEMENT_PLAN.md` (plan, criteria, tracker, scorecard history).
- Add `tool/ui_audit.sh` (U1–U6, U9, U10 counters per module) and record the baseline.

### Phase 1: Design system foundation (`lib/core/theme/`)
- `app_spacing.dart`: `AppSpacing` scale xs 4 / sm 8 / md 12 / lg 16 / xl 24 / xxl 32, scaled by density.
- `app_radius.dart`: `AppRadius` sm / md / lg / xl / pill, computed from the roundness setting (soft 12/16/20/28, round 14/20/26/32, extra 16/24/32/40).
- `app_motion.dart`: durations (fast 150, normal 250, slow 400) and curves (`easeOutCubic`, `emphasized`).
- `app_theme_tokens.dart`: a `ThemeExtension<AppThemeTokens>` with:
  - semantic colours: success, warning, danger, info, income, expense, muted
  - module accents (absorbing `lib/core/constants/module_colors.dart`)
  - gradient stops for the background
  - glass parameters: tint opacity, border opacity, blur sigma, shadow
  - spacing and radius instances
- `appearance.dart`: an immutable `Appearance` model (accent preset, `ThemeMode`, `CornerStyle`, `TextSizeOption`, `DensityOption`, `SurfaceStyle`) with `JsonReader`-based parsing and defaults.
- `accent_palette.dart`: 10 curated accent presets. The current cyan `0xFF00B8D4` stays the default.
- `app_theme_builder.dart`: `buildTheme(Appearance, Brightness)`, one builder for light and dark that replaces the duplicated getters in `app_theme.dart`. It sets:
  - `ColorScheme.fromSeed`, the bundled `fontFamily` and a full `textTheme`
  - `visualDensity` from density
  - component themes for FilledButton, OutlinedButton, TextButton, IconButton, InputDecoration (filled, borderless, rounded, soft focus ring), Chip, SegmentedButton, ListTile, Switch, Checkbox, Radio, NavigationBar, NavigationRail, TabBar, Dialog, BottomSheet (with drag handle), SnackBar (floating, rounded), Tooltip, ProgressIndicator, FAB, Card, Divider and AppBar (transparent, for glass)
  - `pageTransitionsTheme` (fade-through on all platforms)
- Fonts: download static Inter and IBM Plex Sans Arabic (Regular 400, Medium 500, SemiBold 600, Bold 700) into `assets/fonts/` with their OFL licenses, and declare them in `pubspec.yaml`, with Arabic as a `fontFamilyFallback`.
- Tests: token tests (radius and spacing scaling per option, contrast of text on the glass tint meets AA) and builder tests (each option changes the `ThemeData`).

### Phase 2: Live appearance customization
- `appearanceProvider`: a Riverpod `Notifier<Appearance>` (in `lib/providers/app_providers.dart`, or `lib/features/settings/providers/`). It loads from `SettingsService` through the new settings keys `appearanceAccent`, `appearanceCorners`, `appearanceTextSize`, `appearanceDensity` and `appearanceSurface`, plus the existing `themeMode`. It persists on change and handles the save failure (keeping the previous value and reporting it).
- `lib/app.dart`: the `MaterialApp` watches `appearanceProvider` and builds `theme`/`darkTheme` through `buildTheme`. A `MediaQuery` text-scaler override applies the text size. This fixes the "theme only changes after restart" bug.
- Add an `AppearanceSettingsScreen` at `/settings/appearance`, first entry in `settings_hub_screen.dart`, with a route in `AppRouter`. It has:
  - a live preview card
  - accent swatches (reuse the swatch layout from `habit_style_picker.dart`)
  - `SegmentedButton`s for mode, corners, text size, density and surface
  - a "Reset appearance" button
- Theme mode moves out of `general_settings_screen.dart:97-108`.
- Tests:
  - each option updates the theme live (U7)
  - persistence round trip
  - corrupt stored values fall back to defaults

### Phase 3: Shared component library (`lib/shared/widgets/ui/`, one widget per file)
Reuse or upgrade the existing `AsyncErrorView`, `AppFeedback`, `EmptyState`, `LoadingSkeleton`, `SectionHeader`, and `PickerListTile` (moved from settings to shared).
- `AppBackground`: the soft gradient from tokens. `AppScaffold` wraps Scaffold + AppBackground + a transparent glass AppBar.
- `GlassSurface`: the single place for glass.
  - It takes `isBlurred` and falls back to solid when `SurfaceStyle.solid` or reduce-transparency is on.
  - `AppCard` is built on it: padding from tokens, optional `onTap` with a ripple, optional accent colour.
- `SectionHeader` v2 (title, optional subtitle and action) replaces `SettingsSectionHeader` and the 63 inline title blocks.
- `AsyncSection<T>`: title + `AsyncValue` → skeleton, compact `AsyncErrorView` or content, with an `AnimatedSwitcher`.
- `StatTile` + `StatGrid` (icon, value, label, optional trend/accent) replace the 5 stat classes and the inline stats.
- `EntityTile` (leading icon/avatar in a tinted rounded square, title, subtitle, trailing, `onTap`) replaces the card+ListTile combos and the ~15 custom list cards.
- `ProgressBar` + `ProgressRing` (animated, colour from tokens).
- `FilterBar` (segmented or chips).
- `DateTimeField` (date, time or both; one formatter).
- `showConfirmDialog()`, `showFormDialog()` and `showAppBottomSheet()` (handle, title, safe padding; used as a sheet on narrow screens).
- `ModuleHubScaffold`: replaces the 6 `IndexedStack` + `NavigationBar` shells and the embedded "Dashboard" headers. It keeps `NavigationBar`, which `health_home_screen_test` relies on.
- Charts in `lib/shared/widgets/charts/` (`AppLineChart`, `AppBarChart`, `AppPieChart`) use theme colours, rounded bars and smooth curves, and show a tooltip and an empty state. They replace `chart_widgets.dart` and the direct `fl_chart` charts.
- `ColorSwatchPicker` / `IconPicker` (from `habit_style_picker.dart`) and `MonthHeatmap` (unifying the 4 month grids).
- A dev-only `ComponentGalleryScreen` (route `/dev/gallery`, reachable from `DevToolsOverlay`) showing every component. It's used to review appearance options.
- Tests: widget tests per component, plus golden tests for AppCard, StatTile, EntityTile, AsyncSection and ProgressRing in light/dark × glass/solid.

### Phase 4: App shell and dashboard
- `app_shell_screen.dart`:
  - The sidebar becomes a glass panel with rounded, pill-shaped selected items and module-accent icons.
  - The gradient background shows behind every page.
  - Its behaviour (3 modes, drag, reorder, quick-log FAB) stays the same; the FAB is restyled.
  - It picks up Settings changes to `sidebarOrder` without a restart.
- `dashboard_screen.dart`:
  - Greeting header, a `StatGrid` for today, glass cards for weather, currency, prayers, agenda and goals.
  - It honours `dashboardCardOrder` and `dashboardHiddenCards`, fixing the ignored-settings bug. The card ids get aligned with the settings screen, and `dashboard_settings_screen.dart` shows readable labels instead of raw keys.
  - It keeps the texts pinned by `test/app_smoke_test.dart` and `dashboard_screen_test.dart`, or updates those tests deliberately.

### Phases 5–8: Module migrations (one agent per group; each applies the same rules)
Migration rules per screen:
- Replace the hand-built pieces with the shared components.
- Colours come from `colorScheme` or `AppThemeTokens`. Income/expense and success/danger colours become semantic tokens.
- Spacing and radii come from tokens, and text uses `textTheme` (`copyWith` allowed).
- Remove the redundant `OutlineInputBorder`s.
- Dialogs and sheets go through the shared helpers.
- Behaviour, texts pinned by tests, and the Phase 7 robustness guarantees (mounted guards, `AppFeedback`, `AsyncErrorView`) must stay intact.

Groups:
- **Phase 5, Financial** (the worst: 122 colours, 1,098-line dashboard). Also splits the two largest files into widgets where the redesign naturally extracts them, and the currency symbol (typed out 18 times) becomes a constant or formatter.
- **Phase 6, Religious + Health + Sleep + Food.**
- **Phase 7, Sports + Planning + Habits + Notes.**
- **Phase 8, Settings (all 15 screens), Calendar, Security, Analytics, Weather, and the shared dev screens** (log viewer, database viewer, dev tools overlay).

### Phase 9: Motion and polish
- Page transitions via the theme.
- `AnimatedSwitcher` in `AsyncSection`.
- Implicit animations on progress, stat values and selection.
- A subtle staggered fade-in on list sections.
- `Hero` from list tile to detail where a detail screen exists (habit, transaction).
- Every animation respects `MediaQuery.disableAnimations`.

### Phase 10: Verification and final scorecard
- `ui_audit.sh` reports 0 for U1–U6 and U10 in every module.
- Text-scale 1.3 overflow tests on the key screens (dashboard, the financial dashboard, religious home, health home, forms).
- Goldens green, analyze 0, all tests green.
- Manual check: run on macOS and cycle every appearance option. The user reviews it, since `screencapture` needs screen-recording permission that this session doesn't have.

## Critical files
- `lib/core/theme/*` (new tokens, builder, extension, appearance; `app_theme.dart` replaced by the builder)
- `lib/core/constants/module_colors.dart` (absorbed into the tokens)
- `lib/app.dart`
- `lib/providers/app_providers.dart`
- `lib/shared/services/settings_service.dart` (new keys)
- `lib/features/settings/screens/settings_hub_screen.dart` and `general_settings_screen.dart`
- `lib/features/dashboard/screens/app_shell_screen.dart` and `dashboard_screen.dart`
- `lib/shared/widgets/ui/**` and `lib/shared/widgets/charts/**` (new)
- `pubspec.yaml` (fonts)
- every screen and widget under `lib/features/*/{screens,widgets}`

## Reused, not reinvented
`AsyncErrorView`, `AppFeedback`, `EmptyState`, `LoadingSkeleton`, `SectionHeader`, `PickerListTile`, `ModuleColors`, the swatch picker in `habit_style_picker.dart`, `JsonReader`, `SettingsService`, `fl_chart` (only behind the wrappers), and the phase tracker script pattern.

## Verification
- **Per phase:** `flutter analyze` (0), `flutter test` (green), `./tool/ui_audit.sh` (the targeted module's counts go to 0) and `./tool/robustness_audit.sh` (stays at 0, so no robustness regressions).
- **Phase 2+:** widget tests prove each appearance option applies live.
- **Phase 3+:** golden tests for the components.
- **End:** `flutter run -d macos`, then visit every module in light and dark, glass and solid, the 3 corner styles, and text sizes S/M/L.

## Execution cadence
Same as last time: run through all phases, commit per phase, mark ✅ with the commit hash in `docs/UI_ENHANCEMENT_PLAN.md`, and report the score after each phase. Module phases fan out to Sonnet agents, one per module group, briefed with both CLAUDE.md paths and the shared component API.
