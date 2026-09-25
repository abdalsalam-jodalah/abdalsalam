#!/usr/bin/env bash
# tool/ui_audit.sh — prints the UI scorecard (hardcoded styling and duplicated UI per module + app-wide design-system checks).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

MODULES="$(ls lib/features) shared app"

module_files() {
  case "$1" in
    shared) find lib/shared/widgets -name '*.dart' -not -path '*/ui/*' -not -path '*/charts/*' 2>/dev/null ;;
    app) find lib/app lib/app.dart -name '*.dart' 2>/dev/null ;;
    *) find "lib/features/$1" -name '*.dart' \( -path '*/screens/*' -o -path '*/widgets/*' \) 2>/dev/null ;;
  esac
}

count() {
  local regex="$1"
  local files
  files=$(cat)
  [ -z "$files" ] && { echo 0; return; }
  echo "$files" | xargs grep -hoE "$regex" 2>/dev/null | wc -l | tr -d ' '
}

count_colors() {
  local files
  files=$(cat)
  [ -z "$files" ] && { echo 0; return; }
  echo "$files" | xargs grep -hoE 'Colors\.[a-zA-Z]+|Color\(0x' 2>/dev/null | grep -v 'Colors.transparent' | wc -l | tr -d ' '
}

print_row() {
  local module="$1"
  local files
  files=$(module_files "$module")
  local colors radii font_sizes text_styles spacing input_borders duplicates charts
  colors=$(echo "$files" | count_colors)
  radii=$(echo "$files" | count '(BorderRadius|Radius)\.circular\([0-9]')
  font_sizes=$(echo "$files" | count 'fontSize: *[0-9]')
  text_styles=$(echo "$files" | count '[^.a-zA-Z]TextStyle\(')
  spacing=$(echo "$files" | count 'EdgeInsets\.[a-zA-Z]+\([^)]*[0-9]|SizedBox\((height|width): *[0-9]')
  input_borders=$(echo "$files" | count 'OutlineInputBorder\(')
  duplicates=$(echo "$files" | count 'class _Stat(Tile|Card|Chip)|class _Date(Time)?Field|showModalBottomSheet|AlertDialog\(')
  charts=$(echo "$files" | count "package:fl_chart")
  printf '| %-10s | %4s | %4s | %4s | %4s | %5s | %4s | %4s | %4s |\n' \
    "$module" "$colors" "$radii" "$font_sizes" "$text_styles" "$spacing" "$input_borders" "$duplicates" "$charts"
}

check() {
  local label="$1"
  local command="$2"
  if eval "$command" >/dev/null 2>&1; then
    printf '| %-46s | PASS |\n' "$label"
  else
    printf '| %-46s | FAIL |\n' "$label"
  fi
}

echo "## Per-module styling debt (target: 0)"
echo
echo "| Module     | U1 colors | U2 radii | U3 fontSize | U3 TextStyle | U4 spacing | U5 inputBorder | U6 duplicates | U10 fl_chart |"
echo "|---|---|---|---|---|---|---|---|---|"
for module in $MODULES; do
  print_row "$module"
done

blur_sites=$(grep -rlE 'BackdropFilter|ImageFilter\.blur' lib 2>/dev/null | wc -l | tr -d ' ')

echo
echo "## App-wide design-system checks"
echo
echo "| Check | Result |"
echo "|---|---|"
check "Design tokens ThemeExtension (AppThemeTokens)" "grep -rq 'extends ThemeExtension<AppThemeTokens>' lib/core/theme"
check "Single theme builder" "grep -rq 'ThemeData buildAppTheme' lib/core/theme"
check "Page transitions themed" "grep -rq 'pageTransitionsTheme' lib/core/theme"
check "Bundled fonts declared" "grep -q 'family: Inter' pubspec.yaml"
check "Appearance settings screen" "grep -rq 'class AppearanceSettingsScreen' lib/features/settings"
check "Live appearance provider" "grep -rq 'appearanceProvider' lib/app.dart"
check "Shared UI component library" "test -d lib/shared/widgets/ui"
check "Shared chart wrappers" "test -d lib/shared/widgets/charts"
check "Blur confined to GlassSurface (files <= 1)" "test $blur_sites -le 1"
check "Reduce-motion respected" "grep -rqi 'disableAnimations' lib/shared/widgets/ui"
