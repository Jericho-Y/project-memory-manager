#!/usr/bin/env bash
# Purpose: Report whether project-local task memory contains an active or retryable task.
# Read when: Building or debugging automatic recovery and heartbeat behavior.
# Skip when: No interrupted task recovery is involved.
set -euo pipefail

repo_root="${1:-}"
if [[ -z "$repo_root" ]]; then
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

ledger="$repo_root/docs/00-project-memory/task-ledger.md"
agents="$repo_root/AGENTS.md"
current_state="$repo_root/docs/00-project-memory/current-state.md"
recovery_rules="$repo_root/docs/00-project-memory/recovery-rules.md"
change_log="$repo_root/docs/07-decisions/change-log.md"
tmp_file="$(mktemp "${TMPDIR:-/tmp}/pmm-recovery-status.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

[[ -f "$agents" ]] || fail "missing AGENTS.md"
[[ -f "$ledger" ]] || fail "missing docs/00-project-memory/task-ledger.md"

if rg -n --pcre2 '(?i)status:\s*(active|failed-retryable)\b' "$ledger" >"$tmp_file"; then
  printf 'RECOVERY_NEEDED\n'
  printf 'Read these files before resuming:\n'
  printf -- '- %s\n' "$agents"
  [[ -f "$current_state" ]] && printf -- '- %s\n' "$current_state"
  printf -- '- %s\n' "$ledger"
  [[ -f "$recovery_rules" ]] && printf -- '- %s\n' "$recovery_rules"
  [[ -f "$change_log" ]] && printf -- '- %s\n' "$change_log"
  printf '\nMatching task status lines:\n'
  cat "$tmp_file"
else
  printf 'NO_ACTIVE_RECOVERABLE_TASK\n'
fi
