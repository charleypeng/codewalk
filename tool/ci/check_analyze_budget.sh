#!/usr/bin/env bash
set -euo pipefail

ANALYZE_LOG="${1:-/tmp/flutter_analyze.log}"
MAX_ISSUES="${2:-186}"

if [[ ! -f "$ANALYZE_LOG" ]]; then
  echo "Analyze log not found: $ANALYZE_LOG"
  exit 1
fi

# Fail immediately on actual errors regardless of budget
error_count=$(grep -cE 'error •' "$ANALYZE_LOG" || true)
error_count=${error_count:-0}
if (( error_count > 0 )); then
  echo "::error::Found $error_count analysis errors"
  grep -E 'error •' "$ANALYZE_LOG"
  exit 1
fi

# Count info + warning issues against budget
issues_line=$(grep -Eo '[0-9]+ issues found\.?' "$ANALYZE_LOG" | tail -n1 || true)
if [[ -z "$issues_line" ]]; then
  if grep -q "No issues found" "$ANALYZE_LOG"; then
    issues_count=0
  else
    echo "Unable to parse issue count from analyze log."
    exit 1
  fi
else
  issues_count=$(echo "$issues_line" | grep -Eo '^[0-9]+')
fi

echo "Analyze issues: $issues_count (budget: <= $MAX_ISSUES)"

if (( issues_count > MAX_ISSUES )); then
  echo "::error::Analyze budget exceeded: $issues_count > $MAX_ISSUES"
  grep -E '(info|warning) •' "$ANALYZE_LOG" | tail -20
  exit 1
fi

echo "Analyze budget check passed."
