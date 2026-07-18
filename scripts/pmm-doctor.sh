#!/usr/bin/env bash
# Purpose: Validate pmm Core Pack, structured task state, evidence freshness, adapters, and hot-path size.
# Read when: Validating a project runtime, migration, recovery, or release.
# Skip when: The repository task is unrelated to generated project memory.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/pmm-state.sh
source "$script_dir/lib/pmm-state.sh"

json=0
project_root=""
for arg in "$@"; do
  case "$arg" in
    --json) json=1 ;;
    -h | --help)
      printf 'Usage: pmm-doctor.sh [--json] [PROJECT_ROOT]\n'
      exit 0
      ;;
    *)
      [[ -z "$project_root" ]] || {
        printf 'ERROR: only one PROJECT_ROOT is allowed\n' >&2
        exit 2
      }
      project_root="$arg"
      ;;
  esac
done

if [[ -z "$project_root" ]]; then
  project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
project_root="$(cd "$project_root" && pwd)"

agents="$project_root/AGENTS.md"
memory_dir="$project_root/docs/00-project-memory"
current_state="$memory_dir/current-state.md"
active_task="$memory_dir/active-task.md"
work_items_dir="$memory_dir/work-items"
verifier_map="$memory_dir/verifier-map.md"
change_log="$project_root/docs/07-decisions/change-log.md"

failures=0
warnings=0
messages=()

record() {
  local level="$1"
  local message="$2"
  messages+=("$level|$message")
  if (( json == 0 )); then
    printf '%s: %s\n' "$level" "$message"
  fi
}

info() {
  record INFO "$1"
}

warn() {
  warnings=$((warnings + 1))
  record WARN "$1"
}

fail() {
  failures=$((failures + 1))
  record FAIL "$1"
}

require_file() {
  local file="$1"
  local label="$2"
  [[ -f "$file" ]] || fail "missing $label: ${file#$project_root/}"
}

warn_if_over_lines() {
  local file="$1"
  local max_lines="$2"
  local label="$3"
  local lines
  [[ -f "$file" ]] || return 0
  lines="$(wc -l <"$file" | tr -d '[:space:]')"
  if (( lines > max_lines )); then
    warn "$label has $lines lines; keep hot-path files compact (target <= $max_lines)"
  fi
}

check_adapter() {
  local file="$1"
  local rel="${file#$project_root/}"
  local lines
  [[ -f "$file" ]] || return 0
  lines="$(wc -l <"$file" | tr -d '[:space:]')"
  (( lines <= 80 )) || warn "$rel has $lines lines; adapters should stay pointer-only"
  if rg -n --pcre2 '(?i)(retry count:|current checkpoint:|full project rules|complete project docs|task history)' "$file" >/dev/null; then
    fail "$rel appears to contain copied project state instead of a short pointer"
  fi
}

check_structured_task() {
  local file="$1"
  local rel="${file#$project_root/}"
  local expected_kind="$2"
  local task_id parent_id execution verification delivery kind owner branch revision current_branch key count section

  for key in pmm_schema task_id parent_task_id task_kind execution_status verification_status delivery_status owner branch base_sha revision verification_head verification_source_hash verified_at updated_at; do
    count="$(rg -c "^${key}:" "$file" || true)"
    if [[ "$count" != '1' ]]; then
      fail "$rel must contain exactly one $key field"
    fi
  done

  task_id="$(pmm_frontmatter_value "$file" task_id 2>/dev/null || true)"
  parent_id="$(pmm_frontmatter_value "$file" parent_task_id 2>/dev/null || true)"
  execution="$(pmm_frontmatter_value "$file" execution_status 2>/dev/null || true)"
  verification="$(pmm_frontmatter_value "$file" verification_status 2>/dev/null || true)"
  delivery="$(pmm_frontmatter_value "$file" delivery_status 2>/dev/null || true)"
  kind="$(pmm_frontmatter_value "$file" task_kind 2>/dev/null || true)"
  owner="$(pmm_frontmatter_value "$file" owner 2>/dev/null || true)"
  branch="$(pmm_frontmatter_value "$file" branch 2>/dev/null || true)"
  revision="$(pmm_frontmatter_value "$file" revision 2>/dev/null || true)"
  current_branch="$(pmm_git_branch "$project_root")"

  pmm_execution_status_valid "$execution" || fail "$rel has invalid execution_status: $execution"
  pmm_verification_status_valid "$verification" || fail "$rel has invalid verification_status: $verification"
  pmm_delivery_status_valid "$delivery" || fail "$rel has invalid delivery_status: $delivery"
  [[ "$kind" == "$expected_kind" ]] || fail "$rel task_kind must be $expected_kind"
  [[ "$revision" =~ ^[0-9]+$ ]] || fail "$rel revision must be a non-negative integer"
  if [[ "$expected_kind" == 'primary' ]]; then
    [[ "$parent_id" == 'none' ]] || fail "$rel primary task must use parent_task_id: none"
  else
    pmm_validate_id "$parent_id" || fail "$rel has invalid parent_task_id: $parent_id"
    [[ "$parent_id" != "$task_id" ]] || fail "$rel work item cannot be its own parent"
  fi

  if [[ "$execution" == 'idle' ]]; then
    [[ "$task_id" == 'none' ]] || fail "$rel idle state must use task_id: none"
    [[ "$verification" == 'not-required' ]] || fail "$rel idle state must use verification_status: not-required"
    [[ "$owner" == 'none' ]] || fail "$rel idle state must use owner: none"
  else
    pmm_validate_id "$task_id" || fail "$rel has invalid task_id: $task_id"
    pmm_validate_id "$owner" || fail "$rel has invalid owner: $owner"
    for section in Task Harness Verifier Repair Record; do
      rg -q "^## ${section}$" "$file" || fail "$rel is missing required section: $section"
    done
    rg -q --pcre2 '^- Required Checks:\s*\S' "$file" || fail "$rel does not define non-empty verifier checks"
  fi

  if [[ "$execution" == 'done' && "$verification" != 'passed' ]]; then
    fail "$rel is done without passed verification"
  fi

  if [[ "$verification" == 'passed' ]]; then
    if [[ "$kind" == 'work-item' && "$execution" == 'ready-to-integrate' && "$branch" != "$current_branch" ]]; then
      pmm_ready_evidence_is_fresh_on_branch "$project_root" "$file" || \
        fail "$rel ready-to-integrate evidence is stale on branch $branch"
    elif ! pmm_evidence_is_fresh "$project_root" "$file"; then
      fail "$rel verification evidence is stale for the current HEAD or source state"
    fi
  fi

  if [[ "$execution" == 'done' ]]; then
    warn "$rel is done; archive it so the active runtime stays current"
  fi

  if [[ "$execution" != 'idle' && "$branch" != 'none' && "$branch" != "$current_branch" ]]; then
    warn "$rel belongs to branch $branch while the current branch is $current_branch"
  fi
}

if (( json == 0 )); then
  printf 'Running pmm doctor for %s\n' "$project_root"
fi

if [[ ! -f "$agents" ]]; then
  fail 'missing canonical entrypoint: AGENTS.md'
else
  info 'found AGENTS.md'
fi

core_files_present=0
for file in "$current_state" "$active_task" "$verifier_map" "$change_log"; do
  [[ ! -f "$file" ]] || core_files_present=$((core_files_present + 1))
done
shared_primary_id=''
shared_primary_status=0
if shared_primary_id="$(pmm_claim_primary_task "$project_root" 2>/dev/null)"; then
  :
else
  shared_primary_status=$?
  if (( shared_primary_status == 2 )); then
    fail 'multiple primary task claims exist in the Git common directory; repair claims before continuing'
  fi
fi
shared_primary_branch=''
[[ -z "$shared_primary_id" ]] || shared_primary_branch="$(pmm_claim_value "$project_root" "$shared_primary_id" branch 2>/dev/null || true)"
work_item_present=0
if [[ -d "$work_items_dir" ]]; then
  for file in "$work_items_dir"/*.md; do
    [[ -e "$file" ]] || continue
    work_item_present=1
    break
  done
fi

if (( core_files_present == 0 )); then
  warn 'Core Pack files are absent; this is acceptable only for No PMM or very small Pulse work'
elif (( core_files_present < 4 )); then
  require_file "$current_state" 'current state'
  if [[ -f "$active_task" ]]; then
    info 'found active task'
  elif (( work_item_present == 1 )) && [[ -n "$shared_primary_id" ]]; then
    info "active primary task is represented by shared local claim: $shared_primary_id"
  else
    require_file "$active_task" 'active task'
  fi
  require_file "$verifier_map" 'verifier map'
  require_file "$change_log" 'change log'
else
  info 'Core Pack hot-path files are present'
fi

if pmm_mutation_lock_is_orphan "$project_root"; then
  warn 'orphan mutation lock detected; the next lifecycle mutation will recover it after confirming the recorded local process is dead'
fi

if [[ -f "$active_task" ]]; then
  if pmm_has_schema "$active_task"; then
    check_structured_task "$active_task" primary
    local_primary_id="$(pmm_frontmatter_value "$active_task" task_id 2>/dev/null || true)"
    local_primary_execution="$(pmm_frontmatter_value "$active_task" execution_status 2>/dev/null || true)"
    if [[ "$local_primary_execution" != 'idle' ]]; then
      if [[ -n "$shared_primary_id" && "$shared_primary_id" != "$local_primary_id" ]]; then
        fail "active-task.md task_id $local_primary_id conflicts with shared primary claim $shared_primary_id"
      elif (( shared_primary_status != 2 )) && ! pmm_claim_matches "$project_root" "$local_primary_id" \
        "$(pmm_frontmatter_value "$active_task" owner 2>/dev/null || true)" \
        "$(pmm_frontmatter_value "$active_task" branch 2>/dev/null || true)" none primary; then
        fail "active-task.md primary claim is missing or mismatched for task $local_primary_id"
      fi
    fi
  else
    legacy_contracts="$(pmm_legacy_contract_count "$active_task")"
    if (( legacy_contracts > 1 )); then
      fail "active-task.md contains multiple task contracts ($legacy_contracts); keep one current task and migrate or archive the rest"
    fi
    if ! rg -q --pcre2 '(?i)(^## Verifier$|^- Verifier:|^- Required Checks:|Manual Acceptance|Evidence Needed)' "$active_task"; then
      fail 'active-task.md does not define verifier evidence'
    fi
    legacy_status_raw="$(awk -F ': ' '/^- Status:/{print $2; exit}' "$active_task")"
    if [[ -n "$legacy_status_raw" ]]; then
      legacy_status="$(pmm_normalize_legacy_status "$legacy_status_raw")"
      [[ "$legacy_status" != 'unknown' ]] || warn "active-task.md uses an unknown legacy status: $legacy_status_raw"
      [[ "$legacy_status_raw" == "$legacy_status" ]] || warn "active-task.md uses legacy status '$legacy_status_raw'; migrate to execution_status: $legacy_status"
      if [[ "$legacy_status" == 'done' ]]; then
        legacy_evidence="$(awk '/^- Verification Evidence:/{sub(/^- Verification Evidence:[[:space:]]*/, ""); print; exit}' "$active_task")"
        legacy_evidence="${legacy_evidence%.}"
        case "$(printf '%s' "$legacy_evidence" | tr '[:upper:]' '[:lower:]')" in
          '' | pending | none | n/a) fail 'active-task.md is done without verification evidence' ;;
        esac
      fi
    fi
  fi
fi

if [[ -d "$work_items_dir" ]]; then
  primary_branch="$(pmm_frontmatter_value "$active_task" branch 2>/dev/null || true)"
  primary_task_id="$(pmm_frontmatter_value "$active_task" task_id 2>/dev/null || true)"
  if [[ -z "$primary_task_id" || "$primary_task_id" == 'none' ]]; then
    primary_task_id="$shared_primary_id"
    primary_branch="$shared_primary_branch"
  fi
  seen_ids='|'
  [[ -z "$primary_task_id" || "$primary_task_id" == 'none' ]] || seen_ids="|$primary_task_id|"
  seen_branches='|'
  for file in "$work_items_dir"/*.md; do
    [[ -e "$file" ]] || continue
    if ! pmm_has_schema "$file"; then
      fail "${file#$project_root/} is not a structured pmm.task/v1 work item"
      continue
    fi
    check_structured_task "$file" work-item
    work_id="$(pmm_frontmatter_value "$file" task_id 2>/dev/null || true)"
    expected_id="$(basename "$file" .md)"
    [[ "$work_id" == "$expected_id" ]] || fail "${file#$project_root/} task_id must match its filename: $expected_id"
    if [[ "$seen_ids" == *"|$work_id|"* ]]; then
      fail "duplicate work-item task_id: $work_id"
    fi
    seen_ids="${seen_ids}${work_id}|"
    work_branch="$(pmm_frontmatter_value "$file" branch 2>/dev/null || true)"
    work_execution="$(pmm_frontmatter_value "$file" execution_status 2>/dev/null || true)"
    work_parent="$(pmm_frontmatter_value "$file" parent_task_id 2>/dev/null || true)"
    work_owner="$(pmm_frontmatter_value "$file" owner 2>/dev/null || true)"
    if [[ -z "$primary_task_id" || "$primary_task_id" == 'none' || "$work_parent" != "$primary_task_id" ]]; then
      fail "${file#$project_root/} parent_task_id must match the primary task: $primary_task_id"
    fi
    if [[ -n "$primary_branch" && "$work_branch" == "$primary_branch" ]]; then
      fail "${file#$project_root/} shares the primary task branch; concurrent writers require branch/worktree isolation"
    fi
    if [[ "$work_execution" != 'idle' && "$work_execution" != 'done' && "$work_branch" != 'none' ]]; then
      pmm_claim_matches "$project_root" "$work_id" "$work_owner" "$work_branch" "$work_parent" work-item || \
        fail "${file#$project_root/} claim is missing or mismatched in the Git common directory"
      if [[ "$seen_branches" == *"|$work_branch|"* ]]; then
        fail "duplicate active work-item branch: $work_branch"
      fi
      seen_branches="${seen_branches}${work_branch}|"
    fi
  done
fi

if [[ -f "$verifier_map" ]] && ! rg -q --pcre2 '(?i)(False-Pass|false pass|skipped checks|mock)' "$verifier_map"; then
  warn 'verifier-map.md has no visible false-pass guard'
fi

warn_if_over_lines "$agents" 220 'AGENTS.md'
warn_if_over_lines "$current_state" 180 'current-state.md'
warn_if_over_lines "$active_task" 120 'active-task.md'
warn_if_over_lines "$verifier_map" 120 'verifier-map.md'

check_adapter "$project_root/CLAUDE.md"
check_adapter "$project_root/HERMES.md"
check_adapter "$project_root/.hermes.md"
check_adapter "$project_root/openclaw-project-card.md"

if (( json == 1 )); then
  result='pass'
  (( failures == 0 )) || result='fail'
  printf '{"result":"%s","failures":%s,"warnings":%s,"messages":[' "$result" "$failures" "$warnings"
  first=1
  for entry in "${messages[@]}"; do
    level="${entry%%|*}"
    message="${entry#*|}"
    (( first == 1 )) || printf ','
    first=0
    printf '{"level":"%s","message":"%s"}' "$(pmm_json_escape "$level")" "$(pmm_json_escape "$message")"
  done
  printf ']}\n'
else
  if (( failures > 0 )); then
    printf 'PMM_DOCTOR_FAIL failures=%s warnings=%s\n' "$failures" "$warnings"
  else
    printf 'PMM_DOCTOR_PASS failures=0 warnings=%s\n' "$warnings"
  fi
fi

(( failures == 0 ))
