#!/usr/bin/env bash
# Purpose: Resolve structured and legacy recoverable pmm tasks without guessing across ambiguous candidates.
# Read when: Recovering interrupted work, compact failure, tool interruption, or scheduled continuation.
# Skip when: No interrupted task recovery is involved.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/pmm-state.sh
source "$script_dir/lib/pmm-state.sh"

repo_root=""
requested_id=""

while (( $# > 0 )); do
  case "$1" in
    --task-id) requested_id="${2:-}"; shift 2 ;;
    -h | --help)
      printf 'Usage: recovery-status.sh [PROJECT_ROOT] [--task-id ID]\n'
      exit 0
      ;;
    *)
      [[ -z "$repo_root" ]] || {
        printf 'ERROR: only one PROJECT_ROOT is allowed\n' >&2
        exit 2
      }
      repo_root="$1"
      shift
      ;;
  esac
done

if [[ -z "$repo_root" ]]; then
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
repo_root="$(cd "$repo_root" && pwd)"

agents="$repo_root/AGENTS.md"
current_state="$repo_root/docs/00-project-memory/current-state.md"
active_task="$repo_root/docs/00-project-memory/active-task.md"
work_items_dir="$repo_root/docs/00-project-memory/work-items"
legacy_ledger="$repo_root/docs/00-project-memory/task-ledger.md"
recovery_rules="$repo_root/docs/00-project-memory/recovery-rules.md"
change_log="$repo_root/docs/07-decisions/change-log.md"

[[ -f "$agents" ]] || {
  printf 'ERROR: missing AGENTS.md\n' >&2
  exit 1
}

candidate_ids=()
candidate_files=()
candidate_statuses=()
candidate_owners=()
candidate_branches=()
runtime_state_present=0
shared_claim_present=0

add_candidate() {
  local id="$1"
  local file="$2"
  local status="$3"
  local owner="$4"
  local branch="$5"
  if [[ -n "$requested_id" && "$requested_id" != "$id" ]]; then
    return 0
  fi
  candidate_ids+=("$id")
  candidate_files+=("$file")
  candidate_statuses+=("$status")
  candidate_owners+=("$owner")
  candidate_branches+=("$branch")
}

candidate_exists() {
  local expected_id="$1"
  local index
  for ((index = 0; index < ${#candidate_ids[@]}; index++)); do
    [[ "${candidate_ids[$index]}" != "$expected_id" ]] || return 0
  done
  return 1
}

inspect_structured() {
  local file="$1"
  local id execution owner branch
  id="$(pmm_frontmatter_value "$file" task_id 2>/dev/null || true)"
  execution="$(pmm_frontmatter_value "$file" execution_status 2>/dev/null || true)"
  owner="$(pmm_frontmatter_value "$file" owner 2>/dev/null || printf 'unknown')"
  branch="$(pmm_frontmatter_value "$file" branch 2>/dev/null || printf 'unknown')"
  case "$execution" in
    queued | active | paused | blocked | ready-to-integrate)
      add_candidate "$id" "$file" "$execution" "$owner" "$branch"
      ;;
  esac
}

inspect_legacy() {
  local file="$1"
  local label heading raw normalized section line candidate_status
  while IFS=$'\t' read -r label heading raw normalized section line; do
    [[ -n "$label" ]] || label="legacy-line-$line"
    [[ "$section" != 'history' ]] || continue
    case "$normalized" in
      active | paused | blocked)
        candidate_status="$normalized"
        ;;
      done)
        # A deferred item that is already done is historical for recovery;
        # only an active/current done contract needs revalidation.
        [[ "$section" == 'pending' || "$section" == 'ledger-task' ]] && continue
        candidate_status='paused'
        ;;
      ambiguous | unknown)
        # A non-history legacy contract with prose status still needs review;
        # never discard it as if no task existed.
        candidate_status='paused'
        ;;
      *)
        continue
        ;;
    esac
    add_candidate "$label" "$file" "$candidate_status" legacy unknown
  done < <(pmm_legacy_contract_records "$file")
}

if [[ -f "$active_task" ]]; then
  runtime_state_present=1
  if pmm_has_schema "$active_task"; then
    inspect_structured "$active_task"
  else
    active_legacy_count="$(pmm_legacy_contract_count "$active_task" all 2>/dev/null || printf '0')"
    ledger_legacy_count=0
    [[ ! -f "$legacy_ledger" ]] || ledger_legacy_count="$(pmm_legacy_contract_count "$legacy_ledger" current 2>/dev/null || printf '0')"
    if (( active_legacy_count > 0 && ledger_legacy_count > 0 )); then
      printf 'AMBIGUOUS_LEGACY_SOURCES sources=active-task.md,task-ledger.md action=choose-one-source\n' >&2
      exit 2
    elif (( active_legacy_count > 0 )); then
      inspect_legacy "$active_task"
    elif (( ledger_legacy_count > 0 )); then
      inspect_legacy "$legacy_ledger"
    fi
  fi
elif [[ -f "$legacy_ledger" ]]; then
  runtime_state_present=1
  inspect_legacy "$legacy_ledger"
fi

if [[ -d "$work_items_dir" ]]; then
  for file in "$work_items_dir"/*.md; do
    [[ -e "$file" ]] || continue
    runtime_state_present=1
    if pmm_has_schema "$file"; then
      inspect_structured "$file"
    else
      inspect_legacy "$file"
    fi
  done
fi

shared_primary_id=''
if shared_primary_id="$(pmm_claim_primary_task "$repo_root" 2>/dev/null)"; then
  shared_claim_present=1
  if ! candidate_exists "$shared_primary_id"; then
    claim_owner="$(pmm_claim_value "$repo_root" "$shared_primary_id" owner 2>/dev/null || printf 'unknown')"
    claim_branch="$(pmm_claim_value "$repo_root" "$shared_primary_id" branch 2>/dev/null || printf 'unknown')"
    add_candidate "$shared_primary_id" "shared-claim:$claim_branch" claim-only "$claim_owner" "$claim_branch"
  fi
else
  shared_primary_status=$?
  if (( shared_primary_status == 2 )); then
    printf 'AMBIGUOUS_PRIMARY_CLAIMS action=repair-shared-claims\n' >&2
    exit 2
  fi
fi

while IFS= read -r claim_id; do
  [[ -n "$claim_id" ]] || continue
  shared_claim_present=1
  candidate_exists "$claim_id" && continue
  claim_owner="$(pmm_claim_value "$repo_root" "$claim_id" owner 2>/dev/null || printf 'unknown')"
  claim_branch="$(pmm_claim_value "$repo_root" "$claim_id" branch 2>/dev/null || printf 'unknown')"
  add_candidate "$claim_id" "shared-claim:$claim_branch" claim-only "$claim_owner" "$claim_branch"
done < <(pmm_claim_work_items "$repo_root")

candidate_count="${#candidate_ids[@]}"
if (( candidate_count == 0 )); then
  if [[ -n "$requested_id" ]]; then
    printf 'TASK_ID_NOT_FOUND task_id=%s\n' "$requested_id" >&2
    exit 2
  fi
  if (( runtime_state_present == 0 && shared_claim_present == 0 )); then
    printf 'ERROR: missing docs/00-project-memory/active-task.md, legacy task-ledger.md, work-item state, or shared claims\n' >&2
    exit 1
  fi
  printf 'NO_ACTIVE_RECOVERABLE_TASK\n'
  exit 0
fi

if (( candidate_count > 1 )); then
  printf 'AMBIGUOUS_ACTIVE_TASKS count=%s\n' "$candidate_count" >&2
  for ((index = 0; index < candidate_count; index++)); do
    printf -- '- id=%s status=%s file=%s owner=%s branch=%s\n' \
      "${candidate_ids[$index]}" \
      "${candidate_statuses[$index]}" \
      "${candidate_files[$index]#$repo_root/}" \
      "${candidate_owners[$index]}" \
      "${candidate_branches[$index]}" >&2
  done
  printf 'Re-run with --task-id ID. Recovery will not guess.\n' >&2
  exit 2
fi

case "${candidate_statuses[0]}" in
  active | 'In progress' | 'In progress.' | in-progress | working | failed-retryable)
    printf 'RECOVERY_NEEDED\n'
    ;;
  paused | on-hold | 'on hold')
    printf 'RECOVERY_PAUSED\n'
    ;;
  blocked | failed-blocked)
    printf 'RECOVERY_BLOCKED\n'
    ;;
  ready-to-integrate)
    printf 'PENDING_INTEGRATION\n'
    ;;
  queued)
    printf 'RECOVERY_QUEUED\n'
    ;;
  claim-only)
    printf 'RECOVERY_CLAIM_ONLY\n'
    ;;
  *)
    printf 'RECOVERY_STATE_REVIEW_REQUIRED\n'
    ;;
esac
printf 'Task: %s\n' "${candidate_ids[0]}"
printf 'Status: %s\n' "${candidate_statuses[0]}"
printf 'Owner: %s\n' "${candidate_owners[0]}"
printf 'Branch: %s\n' "${candidate_branches[0]}"
printf 'Task file: %s\n' "${candidate_files[0]}"
printf 'Read these files before resuming:\n'
printf -- '- %s\n' "$agents"
[[ -f "$current_state" ]] && printf -- '- %s\n' "$current_state"
printf -- '- %s\n' "${candidate_files[0]}"
[[ -f "$recovery_rules" ]] && printf -- '- %s\n' "$recovery_rules"
[[ -f "$change_log" ]] && printf -- '- %s\n' "$change_log"
printf 'Resume only after checking workspace state, ownership, partial side effects, and verification freshness.\n'
