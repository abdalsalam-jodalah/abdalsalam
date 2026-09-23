#!/usr/bin/env bash
# tool/robustness_audit.sh — prints the robustness scorecard (per-section violation counts + app-wide checks).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

SECTIONS="core data shared app analytics calendar dashboard financial food habits health notes planning religious security settings sleep sports weather"

section_dirs() {
  case "$1" in
    core) echo "lib/core" ;;
    data) echo "lib/data/models/base_model.dart lib/data/repositories/base_repository.dart lib/data/repositories/base_repository_impl.dart" ;;
    shared) echo "lib/shared" ;;
    app) echo "lib/main.dart lib/providers lib/app" ;;
    *) echo "lib/features/$1 lib/data/models/$1 lib/data/repositories/$1" ;;
  esac
}

existing_paths() {
  for path in "$@"; do
    [ -e "$path" ] && echo "$path"
  done
}

dart_files() {
  local paths
  paths=$(existing_paths "$@")
  [ -z "$paths" ] && return 0
  find $paths -name '*.dart' -type f 2>/dev/null
}

files_matching_dir() {
  local pattern="$1"
  shift
  dart_files "$@" | grep -E "$pattern" || true
}

count_regex() {
  local regex="$1"
  shift
  local files
  files=$(cat)
  [ -z "$files" ] && { echo 0; return; }
  echo "$files" | xargs grep -hE "$regex" 2>/dev/null | wc -l | tr -d ' '
}

count_unlogged_catch() {
  local files
  files=$(cat)
  [ -z "$files" ] && { echo 0; return; }
  echo "$files" | xargs awk '
    FNR == 1 { pending = 0 }
    pending > 0 {
      if ($0 ~ /log|rethrow|throw |Failure\(|[Ee]rrorHandler|mapException|mapCaught|report[A-Z]|onError/) { pending = 0 }
      else if (--pending == 0) { total++ }
    }
    /catch *\(/ { pending = 4 }
    END { print total + 0 }
  ' 2>/dev/null
}

count_hard_casts() {
  local files
  files=$(cat)
  [ -z "$files" ] && { echo 0; return; }
  echo "$files" | xargs perl -ne '
    1 while s/<[^<>]*>//g;
    while (/\bas\s+(?:String|int|double|bool|num|List|Map)\b(?!\?)/g) { $total++ }
    END { print(($total // 0) . "\n") }
  ' 2>/dev/null
}

count_ignored_writes() {
  local files
  files=$(cat)
  [ -z "$files" ] && { echo 0; return; }
  echo "$files" | xargs grep -hE '^\s*(await\s+)?[A-Za-z_][^=;]*\.(create|update|delete|softDelete|restore|upsert|save)[A-Za-z]*\(' 2>/dev/null \
    | grep -vE '^\s*(return|if|final|var|const|\/\/)' | wc -l | tr -d ' '
}

count_unguarded_async_ui() {
  local files
  files=$(cat)
  [ -z "$files" ] && { echo 0; return; }
  echo "$files" | xargs awk '
    FNR == 1 { afterAwait = 0 }
    /^  [A-Za-z_<>?, ]+ [A-Za-z_]+\(.*\).*(async )?\{ *$/ { afterAwait = 0 }
    /mounted/ { afterAwait = 0 }
    /(setState\(|Navigator\.of\(context\)|Navigator\.pop\(context|ScaffoldMessenger\.of\(context\)|ref\.invalidate\()/ {
      if (afterAwait) { total++ }
    }
    /await / { afterAwait = 1 }
    END { print total + 0 }
  ' 2>/dev/null
}

count_unvalidated_form_fields() {
  local files
  files=$(cat)
  [ -z "$files" ] && { echo 0; return; }
  echo "$files" | xargs awk '
    FNR == 1 { lookahead = 0 }
    lookahead > 0 {
      if ($0 ~ /validator/) { lookahead = 0 }
      else if (--lookahead == 0) { total++ }
    }
    /TextFormField\(/ { lookahead = 15 }
    END { print total + 0 }
  ' 2>/dev/null
}

count_error_branches_without_view() {
  local files
  files=$(cat)
  [ -z "$files" ] && { echo 0; return; }
  echo "$files" | xargs awk '
    FNR == 1 { lookahead = 0 }
    lookahead > 0 {
      if ($0 ~ /AsyncErrorView/) { lookahead = 0 }
      else if (--lookahead == 0) { total++ }
    }
    /error: *\(?[A-Za-z_]+, *[A-Za-z_]+\)? *(=>|\{)/ {
      if ($0 ~ /AsyncErrorView/) { lookahead = 0 } else { lookahead = 3 }
    }
    END { print total + 0 }
  ' 2>/dev/null
}

test_file_count() {
  local section="$1"
  [ -d "test/$section" ] || { echo 0; return; }
  find "test/$section" -name '*_test.dart' -type f | wc -l | tr -d ' '
}

UI_DIRS='/(screens|widgets)/|lib/main.dart|lib/app/.*_(app|screen|banner|widget)\.dart'
PROVIDER_DIRS='/providers/|lib/providers/'
LOGIC_DIRS='/(services|repositories|infrastructure)/|lib/data/repositories/|base_repository'
MODEL_DIRS='lib/data/models/'

print_row() {
  local section="$1"
  local dirs
  dirs=$(section_dirs "$section")

  local unlogged masking ignored errstr_logic parse_date by_name hard_casts
  local error_branches raw_error_ui async_ui raw_textfield coercion unvalidated tests

  unlogged=$(dart_files $dirs | count_unlogged_catch)
  masking=$(files_matching_dir "$PROVIDER_DIRS" $dirs | count_regex '\.data *\?\?')
  ignored=$(dart_files $dirs | count_ignored_writes)
  errstr_logic=$(files_matching_dir "$LOGIC_DIRS" $dirs | grep -v 'error_handler.dart' | count_regex '(\be|error|err)\.toString\(\)')
  parse_date=$(files_matching_dir "$MODEL_DIRS" $dirs | count_regex 'DateTime\.parse\(')
  by_name=$(files_matching_dir "$MODEL_DIRS" $dirs | count_regex '\.byName\(')
  hard_casts=$(files_matching_dir "$MODEL_DIRS" $dirs | count_hard_casts)
  error_branches=$(files_matching_dir "$UI_DIRS" $dirs | count_error_branches_without_view)
  raw_error_ui=$(files_matching_dir "$UI_DIRS|$PROVIDER_DIRS" $dirs | count_regex '\$\{[A-Za-z_.!?]*\b(error|err|e)\b|\$(error|err|e)\b|(\be|error|err)\.toString\(\)|error[!?]?\.message')
  async_ui=$(files_matching_dir "$UI_DIRS" $dirs | count_unguarded_async_ui)
  raw_textfield=$(files_matching_dir "$UI_DIRS" $dirs | count_regex '[^A-Za-z]TextField\(')
  coercion=$(files_matching_dir "$UI_DIRS" $dirs | count_regex 'tryParse\([^;]*\) *\?\? *0')
  unvalidated=$(files_matching_dir "$UI_DIRS" $dirs | count_unvalidated_form_fields)
  tests=$(test_file_count "$section")

  printf '| %-10s | %3s | %3s | %3s | %3s | %3s | %3s | %3s | %3s | %3s | %3s | %3s | %3s | %3s | %3s |\n' \
    "$section" "$errstr_logic" "$unlogged" "$masking" "$ignored" "$parse_date" "$by_name" "$hard_casts" \
    "$error_branches" "$raw_error_ui" "$async_ui" "$raw_textfield" "$coercion" "$unvalidated" "$tests"
}

check() {
  local label="$1"
  local command="$2"
  if eval "$command" >/dev/null 2>&1; then
    printf '| %-44s | PASS |\n' "$label"
  else
    printf '| %-44s | FAIL |\n' "$label"
  fi
}

echo "## Per-section violation counts (target: 0, except tests)"
echo
echo "| Section    | C2 errStr | C3 unlogged | C3 masking | C3 ignoredWrites | C4 DateTime.parse | C4 byName | C4 hardCast | C5 errBranch | C6 rawErrUI | C7 asyncUI | C8 TextField | C8 coercion | C8 noValidator | C12 tests |"
echo "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"
for section in $SECTIONS; do
  print_row "$section"
done

echo
echo "## App-wide checks"
echo
echo "| Check | Result |"
echo "|---|---|"
check "C1 runZonedGuarded" "grep -rq 'runZonedGuarded' lib"
check "C1 FlutterError.onError" "grep -rq 'FlutterError.onError' lib"
check "C1 PlatformDispatcher.instance.onError" "grep -rq 'PlatformDispatcher.instance.onError' lib"
check "C1 ErrorWidget.builder" "grep -rq 'ErrorWidget.builder' lib"
check "C1 ProviderObserver" "grep -rq 'extends ProviderObserver' lib"
check "C9 strict-casts" "grep -q 'strict-casts: true' analysis_options.yaml"
check "C9 strict-inference" "grep -q 'strict-inference: true' analysis_options.yaml"
check "C9 strict-raw-types" "grep -q 'strict-raw-types: true' analysis_options.yaml"
check "C9 unawaited_futures" "grep -q 'unawaited_futures' analysis_options.yaml"
check "C9 discarded_futures" "grep -q 'discarded_futures' analysis_options.yaml"
check "C9 avoid_dynamic_calls" "grep -q 'avoid_dynamic_calls' analysis_options.yaml"
check "C10 bootstrap step isolation" "grep -rq 'class BootstrapStep' lib"
check "C10 startup recovery screen" "grep -rq 'class StartupRecoveryScreen' lib"
check "C11 restore runs in a transaction" "grep -q 'runInTransaction' lib/shared/services/backup_service.dart"
check "C4 JsonReader exists" "grep -rq 'class JsonReader' lib/core"

if [ "${1:-}" = "--analyze" ]; then
  echo
  echo "## flutter analyze"
  echo
  issues=$(flutter analyze --no-fatal-infos --no-fatal-warnings 2>/dev/null | grep -cE '^\s*(info|warning|error) •')
  echo "Issues: $issues"
fi
