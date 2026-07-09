#!/usr/bin/env bash
# Purpose: Check whether a project uses the lightweight pmm runtime contract coherently.
# Read when: Validating a project Core Pack, active task, adapters, or hot-path size.
# Skip when: The repository task is unrelated to generated project memory.
set -euo pipefail

project_root="${1:-}"
if [[ -z "$project_root" ]]; then
  project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

project_root="$(cd "$project_root" && pwd)"
agents="$project_root/AGENTS.md"
memory_dir="$project_root/docs/00-project-memory"
current_state="$memory_dir/current-state.md"
active_task="$memory_dir/active-task.md"
verifier_map="$memory_dir/verifier-map.md"
change_log="$project_root/docs/07-decisions/change-log.md"

failures=0
warnings=0

info() {
  printf 'INFO: %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf 'WARN: %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'FAIL: %s\n' "$1"
}

require_file() {
  local file="$1"
  local label="$2"

  if [[ ! -f "$file" ]]; then
    fail "missing $label: ${file#$project_root/}"
  fi
}

warn_if_over_lines() {
  local file="$1"
  local max_lines="$2"
  local label="$3"
  local lines

  [[ -f "$file" ]] || return 0
  lines="$(wc -l < "$file" | tr -d '[:space:]')"
  if (( lines > max_lines )); then
    warn "$label has $lines lines; keep hot-path files compact (target <= $max_lines)"
  fi
}

check_adapter() {
  local file="$1"
  local rel="${file#$project_root/}"
  local lines

  [[ -f "$file" ]] || return 0

  lines="$(wc -l < "$file" | tr -d '[:space:]')"
  if (( lines > 80 )); then
    warn "$rel has $lines lines; adapters should stay pointer-only"
  fi

  if rg -n --pcre2 '(?i)(retry count:|current checkpoint:|full project rules|complete project docs|task history)' "$file" >/dev/null; then
    fail "$rel appears to contain copied project state instead of a short pointer"
  fi
}

printf 'Running pmm doctor for %s\n' "$project_root"

if [[ ! -f "$agents" ]]; then
  fail "missing canonical entrypoint: AGENTS.md"
else
  info "found AGENTS.md"
fi

core_files_present=0
for file in "$current_state" "$active_task" "$verifier_map" "$change_log"; do
  if [[ -f "$file" ]]; then
    core_files_present=$((core_files_present + 1))
  fi
done

if (( core_files_present == 0 )); then
  warn "Core Pack files are absent; this is acceptable only for No PMM or very small Pulse work"
elif (( core_files_present < 4 )); then
  require_file "$current_state" "current state"
  require_file "$active_task" "active task"
  require_file "$verifier_map" "verifier map"
  require_file "$change_log" "change log"
else
  info "Core Pack hot-path files are present"
fi

if [[ -f "$active_task" ]]; then
  if ! rg -q '^## Verifier$' "$active_task"; then
    fail "active-task.md is missing a Verifier section"
  fi

  if ! rg -q --pcre2 '(?i)(Required Checks|Verifier:|Manual Acceptance|Evidence Needed)' "$active_task"; then
    fail "active-task.md does not define verifier evidence"
  fi

  if rg -q --pcre2 '(?i)^- Status:\s*done\b' "$active_task" &&
    rg -q --pcre2 '(?i)^- Verification Evidence:\s*(pending|none|n/a)?\s*$' "$active_task"; then
    fail "active-task.md is marked done without verification evidence"
  fi
fi

if [[ -f "$verifier_map" ]] && ! rg -q --pcre2 '(?i)(False-Pass|false pass|skipped checks|mock)' "$verifier_map"; then
  warn "verifier-map.md has no visible false-pass guard"
fi

warn_if_over_lines "$agents" 220 "AGENTS.md"
warn_if_over_lines "$current_state" 180 "current-state.md"
warn_if_over_lines "$active_task" 120 "active-task.md"
warn_if_over_lines "$verifier_map" 120 "verifier-map.md"

check_adapter "$project_root/CLAUDE.md"
check_adapter "$project_root/HERMES.md"
check_adapter "$project_root/.hermes.md"
check_adapter "$project_root/openclaw-project-card.md"

if (( failures > 0 )); then
  printf 'PMM_DOCTOR_FAIL failures=%s warnings=%s\n' "$failures" "$warnings"
  exit 1
fi

printf 'PMM_DOCTOR_PASS failures=0 warnings=%s\n' "$warnings"
