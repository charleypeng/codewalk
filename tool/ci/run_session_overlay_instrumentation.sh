#!/usr/bin/env bash
set -euo pipefail

api_level="${1:?API level is required}"
results_dir="build/session-overlay-test-results"
output="$results_dir/instrumentation-api-$api_level.txt"
parsed_output="$results_dir/instrumentation-api-$api_level.normalized.txt"

mkdir -p "$results_dir"
: > "$output"

collect_diagnostics() {
  diagnostic_status=$?
  trap - EXIT
  printf 'workflow_exit_status=%s\n' "$diagnostic_status" \
    > "$results_dir/status-api-$api_level.txt"
  timeout 30s adb logcat -d -v threadtime \
    > "$results_dir/logcat-api-$api_level.txt" 2>&1 || true
  timeout 30s adb logcat -d -b crash -v threadtime \
    > "$results_dir/logcat-crash-api-$api_level.txt" 2>&1 || true
  timeout 30s adb shell dumpsys activity exit-info com.verseles.codewalk \
    > "$results_dir/exit-info-api-$api_level.txt" 2>&1 || true
  exit "$diagnostic_status"
}
trap collect_diagnostics EXIT

timeout --kill-after=15s 2m \
  adb install --no-streaming -r build/app/outputs/flutter-apk/app-debug.apk
timeout --kill-after=15s 2m \
  adb install --no-streaming -r \
    build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
timeout 30s adb logcat -c

set +e
timeout --kill-after=30s 15m \
  adb shell am instrument -w -r \
    com.verseles.codewalk.test/androidx.test.runner.AndroidJUnitRunner \
  > "$output" 2>&1
status=$?
set -e

cat "$output"
tr -d '\r' < "$output" > "$parsed_output"
final_code="$(grep '^INSTRUMENTATION_CODE:' "$parsed_output" | tail -n 1 || true)"

if [[ "$status" -ne 0 ]] \
  || ! grep -Eq '^OK \([1-9][0-9]* tests?\)' "$parsed_output" \
  || [[ "$final_code" != 'INSTRUMENTATION_CODE: -1' ]] \
  || grep -Eq '^INSTRUMENTATION_STATUS_CODE: (-1|-2)$' "$parsed_output" \
  || grep -Eq '^(INSTRUMENTATION_FAILED:|INSTRUMENTATION_ABORTED:|Error:|Process crashed\.)|shortMsg=' "$parsed_output"; then
  status=1
fi

exit "$status"
