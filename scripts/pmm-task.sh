#!/usr/bin/env bash
# Purpose: Manage pmm v0.5 structured task lifecycle, local claims, verification evidence, delivery, and migration.
# Read when: Starting, checkpointing, verifying, resuming, closing, or migrating project tasks.
# Skip when: Performing a read-only lookup with no durable task state.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/pmm-state.sh
source "$script_dir/lib/pmm-state.sh"

usage() {
  cat <<'EOF'
Usage:
  pmm-task.sh --help | --version
  pmm-task.sh start --project PATH --id ID --title TEXT --owner ID --scope TEXT --verifier TEXT
                    [--parent ID --work-item]
  pmm-task.sh status --project PATH [--id ID]
  pmm-task.sh checkpoint --project PATH --id ID --owner ID --next TEXT
  pmm-task.sh verify --project PATH --id ID --owner ID --evidence TEXT
  pmm-task.sh resume --project PATH --id ID --owner ID [--takeover]
  pmm-task.sh close --project PATH --id ID --owner ID
  pmm-task.sh integrate --project PATH --id WORK_ITEM_ID --owner PRIMARY_OWNER
  pmm-task.sh delivery --project PATH --id ID --owner ID --status STATUS --evidence TEXT
  pmm-task.sh delivery --project PATH --id ID
  pmm-task.sh migrate --project PATH --plan
  pmm-task.sh migrate --project PATH --dry-run
  pmm-task.sh migrate --project PATH --apply --id ID --owner ID
EOF
}

die() {
  printf '%s\n' "$1" >&2
  exit "${2:-1}"
}

command="${1:-help}"
if [[ "$command" == '--help' || "$command" == '-h' ]]; then
  usage
  exit 0
fi
if [[ "$command" == '--version' || "$command" == '-V' ]]; then
  printf 'pmm %s\n' "$(tr -d '[:space:]' <"$script_dir/../VERSION")"
  exit 0
fi
[[ $# -gt 0 ]] && shift

project=""
id=""
title=""
owner="${PMM_OWNER:-}"
scope=""
verifier=""
parent="none"
next_action=""
evidence=""
work_item=0
dry_run=0
apply=0
plan=0
takeover=0
delivery_status=""

while (( $# > 0 )); do
  case "$1" in
    --project) project="${2:-}"; shift 2 ;;
    --id) id="${2:-}"; shift 2 ;;
    --title) title="${2:-}"; shift 2 ;;
    --owner) owner="${2:-}"; shift 2 ;;
    --scope) scope="${2:-}"; shift 2 ;;
    --verifier) verifier="${2:-}"; shift 2 ;;
    --parent) parent="${2:-}"; shift 2 ;;
    --next) next_action="${2:-}"; shift 2 ;;
    --evidence) evidence="${2:-}"; shift 2 ;;
    --status) delivery_status="${2:-}"; shift 2 ;;
    --work-item) work_item=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    --plan) plan=1; shift ;;
    --apply) apply=1; shift ;;
    --takeover) takeover=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) die "ERROR: unknown option: $1" ;;
  esac
done

if [[ "$command" == 'help' ]]; then
  usage
  exit 0
fi

if [[ -z "$project" ]]; then
  project="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
[[ -d "$project" ]] || die "ERROR: project does not exist: $project"
project="$(cd "$project" && pwd)"
memory_dir="$project/docs/00-project-memory"
active_task="$memory_dir/active-task.md"
work_items_dir="$memory_dir/work-items"
history="$memory_dir/task-history.md"
task_queue="$memory_dir/task-queue.md"
lock_id="pmm-task-$$-$(pmm_now)"
lock_held=0
pending_claim_id=""
staged_task_file=""
pending_temp_file=""
rollback_claim_id=""
rollback_claim_owner=""
rollback_claim_new_owner=""
rollback_claim_branch=""
rollback_claim_parent=""
rollback_claim_kind=""

release_state_lock() {
  if [[ -n "$staged_task_file" ]]; then
    rm -f "$staged_task_file" "${staged_task_file}.tmp.$$" || true
    staged_task_file=""
  fi
  if [[ -n "$pending_temp_file" ]]; then
    rm -f "$pending_temp_file" || true
    pending_temp_file=""
  fi
  if [[ -n "$rollback_claim_id" ]]; then
    rollback_file="$(pmm_task_file "$project" "$rollback_claim_id" 2>/dev/null || true)"
    rollback_file_owner=""
    [[ -z "$rollback_file" ]] || rollback_file_owner="$(pmm_frontmatter_value "$rollback_file" owner 2>/dev/null || true)"
    pmm_claim_release "$project" "$rollback_claim_id" || true
    if [[ "$rollback_file_owner" == "$rollback_claim_new_owner" ]]; then
      pmm_claim_acquire "$project" "$rollback_claim_id" "$rollback_claim_new_owner" \
        "$rollback_claim_branch" "$rollback_claim_parent" "$rollback_claim_kind" || true
    else
      pmm_claim_acquire "$project" "$rollback_claim_id" "$rollback_claim_owner" \
        "$rollback_claim_branch" "$rollback_claim_parent" "$rollback_claim_kind" || true
    fi
    rollback_claim_id=""
  fi
  if [[ -n "$pending_claim_id" ]]; then
    pmm_claim_release "$project" "$pending_claim_id" || true
    pending_claim_id=""
  fi
  if (( lock_held == 1 )); then
    pmm_mutation_lock_release "$project" "$lock_id" || true
    lock_held=0
  fi
}

trap release_state_lock EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

acquire_state_lock() {
  pmm_mutation_lock_acquire "$project" "$lock_id" || die 'PMM_STATE_BUSY: another pmm lifecycle mutation is in progress'
  lock_held=1
}

begin_task_update() {
  local file="$1"
  [[ -z "$staged_task_file" ]] || die 'TASK_UPDATE_ALREADY_STAGED'
  staged_task_file="${file}.pmm-txn.$$"
  cp "$file" "$staged_task_file" || die "TASK_UPDATE_STAGE_FAILED: ${file#$project/}"
}

commit_task_update() {
  local file="$1"
  [[ -n "$staged_task_file" ]] || die 'TASK_UPDATE_NOT_STAGED'
  mv "$staged_task_file" "$file" || die "TASK_UPDATE_COMMIT_FAILED: ${file#$project/}"
  staged_task_file=""
}

require_unarchived_task_id() {
  local archive_status
  if pmm_task_id_is_archived "$project" "$id"; then
    die "TASK_ID_ALREADY_ARCHIVED: $id"
  else
    archive_status=$?
  fi
  case "$archive_status" in
    1) return 0 ;;
    *) die "TASK_ID_ARCHIVE_CHECK_FAILED: $id" ;;
  esac
}

require_primary_claim_available() {
  local claimed_primary claim_status
  if claimed_primary="$(pmm_claim_primary_task "$project" 2>/dev/null)"; then
    die "PRIMARY_TASK_ALREADY_CLAIMED: $claimed_primary"
  else
    claim_status=$?
  fi
  case "$claim_status" in
    1) return 0 ;;
    2) die 'MULTIPLE_PRIMARY_TASK_CLAIMS: repair the Git common-directory claims before continuing' ;;
    *) die 'PRIMARY_TASK_CLAIM_CHECK_FAILED' ;;
  esac
}

require_id() {
  [[ -n "$id" ]] || die 'ERROR: --id is required'
  pmm_validate_id "$id" || die 'ERROR: --id must use 2-80 letters, digits, dots, underscores, or hyphens'
}

require_owner() {
  [[ -n "$owner" ]] || die 'ERROR: --owner or PMM_OWNER is required for lifecycle mutations'
  pmm_validate_id "$owner" || die 'ERROR: --owner must use 2-80 letters, digits, dots, underscores, or hyphens'
}

require_git_context() {
  local branch_value head_value
  branch_value="$(pmm_git_branch "$project")"
  head_value="$(pmm_git_head "$project")"
  [[ "$branch_value" != 'detached' && "$head_value" != 'none' ]] || die 'GIT_CONTEXT_REQUIRED: structured task lifecycle requires a Git branch with at least one commit'
}

require_task_control() {
  local file="$1"
  local task_id recorded_owner recorded_branch current_branch parent_id kind
  require_owner
  task_id="$(pmm_frontmatter_value "$file" task_id)"
  recorded_owner="$(pmm_frontmatter_value "$file" owner)"
  recorded_branch="$(pmm_frontmatter_value "$file" branch)"
  current_branch="$(pmm_git_branch "$project")"
  parent_id="$(pmm_frontmatter_value "$file" parent_task_id)"
  kind="$(pmm_frontmatter_value "$file" task_kind)"
  [[ "$recorded_branch" == "$current_branch" ]] || die "TASK_BRANCH_MISMATCH: $task_id belongs to $recorded_branch, current branch is $current_branch"
  [[ "$recorded_owner" == "$owner" ]] || die "TASK_OWNERSHIP_MISMATCH: $task_id is owned by $recorded_owner"
  pmm_claim_matches "$project" "$task_id" "$owner" "$recorded_branch" "$parent_id" "$kind" || \
    die "TASK_CLAIM_MISSING_OR_MISMATCH: run resume for $task_id before mutating it"
}

resolve_task_file() {
  local claimed_branch current_branch
  file="$(pmm_task_file "$project" "$id" 2>/dev/null || true)"
  if [[ -z "$file" ]]; then
    claimed_branch="$(pmm_claim_value "$project" "$id" branch 2>/dev/null || true)"
    current_branch="$(pmm_git_branch "$project")"
    if [[ -n "$claimed_branch" && "$claimed_branch" != "$current_branch" ]]; then
      die "TASK_BRANCH_MISMATCH: $id belongs to $claimed_branch, current branch is $current_branch"
    fi
    die "TASK_NOT_FOUND: $id"
  fi
}

task_revision() {
  local file="$1"
  local value
  value="$(pmm_frontmatter_value "$file" revision 2>/dev/null || printf '0')"
  [[ "$value" =~ ^[0-9]+$ ]] || value=0
  printf '%s\n' "$value"
}

task_owns_branch() {
  local file branch_value execution_value
  branch_value="$1"
  [[ -d "$work_items_dir" ]] || return 1
  for file in "$work_items_dir"/*.md; do
    [[ -e "$file" ]] || continue
    pmm_has_schema "$file" || continue
    execution_value="$(pmm_frontmatter_value "$file" execution_status 2>/dev/null || true)"
    [[ "$execution_value" != 'idle' && "$execution_value" != 'done' ]] || continue
    if [[ "$(pmm_frontmatter_value "$file" branch 2>/dev/null || true)" == "$branch_value" ]]; then
      pmm_frontmatter_value "$file" task_id
      return 0
    fi
  done
  return 1
}

active_child_ids() {
  local parent_id="$1"
  local file execution_value
  {
    pmm_claim_children "$project" "$parent_id"
    if [[ -d "$work_items_dir" ]]; then
      for file in "$work_items_dir"/*.md; do
        [[ -e "$file" ]] || continue
        pmm_has_schema "$file" || continue
        [[ "$(pmm_frontmatter_value "$file" parent_task_id 2>/dev/null || true)" == "$parent_id" ]] || continue
        execution_value="$(pmm_frontmatter_value "$file" execution_status 2>/dev/null || true)"
        [[ "$execution_value" != 'idle' && "$execution_value" != 'done' ]] || continue
        pmm_frontmatter_value "$file" task_id
      done
    fi
  } | awk 'NF && !seen[$0]++'
}

write_task_file() {
  local file="$1"
  local kind="$2"
  local heading purpose branch base now tmp
  [[ ! -d "$file" ]] || return 1
  branch="$(pmm_git_branch "$project")"
  base="$(pmm_git_head "$project")"
  now="$(pmm_now)"
  if [[ "$kind" == 'primary' ]]; then
    heading='Active Task'
    purpose='Single primary task contract, verifier, retry state, and integration checkpoint.'
  else
    heading='Work Item'
    purpose='Branch-isolated child work item owned by one execution context.'
  fi
  mkdir -p "$(dirname "$file")"
  tmp="${file}.tmp.$$"
  pending_temp_file="$tmp"
  {
    printf '%s\n' '---'
    printf 'pmm_schema: pmm.task/v1\n'
    printf 'task_id: %s\n' "$id"
    printf 'parent_task_id: %s\n' "$parent"
    printf 'task_kind: %s\n' "$kind"
    printf 'execution_status: active\n'
    printf 'verification_status: pending\n'
    printf 'delivery_status: not-requested\n'
    printf 'owner: %s\n' "$owner"
    printf 'branch: %s\n' "$branch"
    printf 'base_sha: %s\n' "$base"
    printf 'revision: 1\n'
    printf 'verification_head: none\n'
    printf 'verification_source_hash: none\n'
    printf 'verified_at: none\n'
    printf 'updated_at: %s\n' "$now"
    printf '%s\n' '---' '' "# $heading" ''
    printf 'Purpose: %s\n' "$purpose"
    printf 'Read when: Starting, executing, verifying, integrating, or recovering this task.\n'
    printf 'Skip when: The task is unrelated to the current execution context.\n\n'
    printf '## Status\n\n'
    printf -- '- Title: %s\n' "$title"
    printf -- '- Runtime Profile: Sprint\n'
    printf -- '- Risk Level: normal\n'
    printf -- '- Loop Budget: 3\n'
    printf -- '- Current Attempt: 1\n'
    printf -- '- Stop Condition: required behavior is verified or a concrete blocker is recorded.\n\n'
    printf '## Task\n\n'
    printf -- '- Objective: %s\n' "$title"
    printf -- '- Scope: %s\n' "$scope"
    printf -- '- Allowed Files or Areas: %s\n' "$scope"
    printf -- '- Forbidden Actions: unrelated edits, destructive operations, publication, and production writes without explicit authorization.\n'
    printf -- '- Source Artifacts: project instructions, current source, and task request.\n\n'
    printf '## Harness\n\n'
    printf -- '- Agent Mode: solo\n'
    printf -- '- Owner: %s\n' "$owner"
    printf -- '- Branch: %s\n' "$branch"
    printf -- '- Parent Task: %s\n' "$parent"
    printf -- '- Tools: project-local tools and pmm lifecycle helpers.\n'
    printf -- '- Environment Notes: one writer owns this task file and branch.\n\n'
    printf '## Verifier\n\n'
    printf -- '- Required Checks: %s\n' "$verifier"
    printf -- '- Manual Acceptance: task-specific acceptance remains explicit.\n'
    printf -- '- Evidence Needed: fresh command output bound to the current HEAD and source hash.\n\n'
    printf '## Critic\n\n'
    printf -- '- Pass/Fail: pending\n'
    printf -- '- Missing Evidence: required checks have not completed.\n'
    printf -- '- False-Pass Risk: stale or unrelated evidence must not count.\n'
    printf -- '- Next Action: execute the first unverified acceptance step.\n\n'
    printf '## Repair\n\n'
    printf -- '- Last Failure: none\n'
    printf -- '- Failure Class: none\n'
    printf -- '- Attempted Fix: none\n'
    printf -- '- Next Concrete Action: execute the first unverified acceptance step.\n\n'
    printf '## Record\n\n'
    printf -- '- Verification Evidence: pending\n'
    printf -- '- Delivery Status: not-requested\n'
    printf -- '- Delivery Evidence: pending\n'
    printf -- '- Docs Updated: pending\n'
    printf -- '- Remaining Risk: pending verification.\n'
    printf -- '- Memory Promotion Decision: pending\n'
    printf -- '- Last Updated: %s\n' "$now"
  } >"$tmp" || return 1
  mv "$tmp" "$file" || return 1
  pending_temp_file=""
}

write_idle_task() {
  local branch base now tmp
  [[ ! -d "$active_task" ]] || return 1
  branch="$(pmm_git_branch "$project")"
  base="$(pmm_git_head "$project")"
  now="$(pmm_now)"
  mkdir -p "$memory_dir"
  tmp="${active_task}.tmp.$$"
  pending_temp_file="$tmp"
  {
    printf '%s\n' '---'
    printf 'pmm_schema: pmm.task/v1\n'
    printf 'task_id: none\n'
    printf 'parent_task_id: none\n'
    printf 'task_kind: primary\n'
    printf 'execution_status: idle\n'
    printf 'verification_status: not-required\n'
    printf 'delivery_status: not-requested\n'
    printf 'owner: none\n'
    printf 'branch: %s\n' "$branch"
    printf 'base_sha: %s\n' "$base"
    printf 'revision: 0\n'
    printf 'verification_head: none\n'
    printf 'verification_source_hash: none\n'
    printf 'verified_at: none\n'
    printf 'updated_at: %s\n' "$now"
    printf '%s\n' '---' '' '# Active Task' ''
    printf 'Purpose: Preserve one explicit primary-task slot for the project.\n'
    printf 'Read when: Starting or recovering substantial work.\n'
    printf 'Skip when: Performing a tiny read-only lookup.\n\n'
    printf '## Status\n\n- No active primary task.\n'
  } >"$tmp" || return 1
  mv "$tmp" "$active_task" || return 1
  pending_temp_file=""
}

write_history_entry() {
  local task_id="$1"
  local parent_id="$2"
  local title_value="$3"
  local execution_value="$4"
  local verification_value="$5"
  local delivery_value="$6"
  local evidence_value="$7"
  local tmp="${history}.tmp.$$"
  mkdir -p "$memory_dir"
  pending_temp_file="$tmp"
  if [[ -f "$history" ]]; then
    cp "$history" "$tmp"
  else
    printf '# Task History\n\nPurpose: Append-only compact summaries of closed tasks.\n' >"$tmp"
  fi
  if ! rg -q --fixed-strings "<!-- pmm-task-id: ${task_id} -->" "$tmp"; then
    {
      printf '\n## %s %s\n\n' "$(date -u '+%Y-%m-%d')" "$task_id"
      printf '<!-- pmm-task-id: %s -->\n\n' "$task_id"
      printf -- '- Status: done\n'
      printf -- '- Parent Task: %s\n' "$parent_id"
      printf -- '- Title: %s\n' "${title_value:-$task_id}"
      printf -- '- Execution State: %s\n' "$execution_value"
      printf -- '- Verification State: %s\n' "$verification_value"
      printf -- '- Delivery State: %s\n' "$delivery_value"
      printf -- '- Verification Evidence: %s\n' "${evidence_value:-recorded in task file}"
      printf -- '- Closed At: %s\n' "$(pmm_now)"
    } >>"$tmp"
  fi
  mv "$tmp" "$history" || return 1
  pending_temp_file=""
}

write_pending_delivery() {
  local task_id="$1"
  local owner_value="$2"
  local delivery_value="$3"
  local tmp="${task_queue}.tmp.$$"
  case "$delivery_value" in
    waiting-confirmation | ready) ;;
    *) return 0 ;;
  esac
  pending_temp_file="$tmp"
  if [[ -f "$task_queue" ]]; then
    cp "$task_queue" "$tmp"
  else
    {
      printf '# Task Queue\n\n'
      printf 'Purpose: Optional queue for work outside the single primary task slot.\n\n'
      printf '## Runtime Pending Delivery\n\n'
      printf '| Task ID | Reason | Owner | Resume Condition | Delivery State |\n'
      printf '| --- | --- | --- | --- | --- |\n'
    } >"$tmp"
  fi
  if ! rg -q --fixed-strings '## Runtime Pending Delivery' "$tmp"; then
    {
      printf '\n## Runtime Pending Delivery\n\n'
      printf '| Task ID | Reason | Owner | Resume Condition | Delivery State |\n'
      printf '| --- | --- | --- | --- | --- |\n'
    } >>"$tmp"
  fi
  if ! rg -q --fixed-strings "| ${task_id} |" "$tmp"; then
    printf '| %s | delivery follow-up | %s | explicit delivery action or confirmation | %s |\n' \
      "$task_id" "$owner_value" "$delivery_value" >>"$tmp"
  fi
  mv "$tmp" "$task_queue" || return 1
  pending_temp_file=""
}

write_migrated_task() {
  local source_file="$1"
  local source_label="$2"
  local legacy_status="$3"
  local selection_mode="${4:-all}"
  local title_value objective_value verifier_value next_value branch base now tmp
  [[ ! -d "$active_task" ]] || return 1
  title_value="$(pmm_legacy_title "$source_file" "$selection_mode")"
  objective_value="$(pmm_legacy_contract_field "$source_file" "$selection_mode" objective)"
  verifier_value="$(pmm_legacy_contract_field "$source_file" "$selection_mode" verifier)"
  next_value="$(pmm_legacy_contract_field "$source_file" "$selection_mode" next)"
  [[ -n "$title_value" ]] || title_value="$id"
  [[ -n "$objective_value" ]] || objective_value="Continue migrated legacy task: $title_value"
  [[ -n "$verifier_value" ]] || verifier_value='define and run the legacy task verifier before close'
  [[ -n "$next_value" ]] || next_value='inspect the preserved legacy source and define the next verified action'
  branch="$(pmm_git_branch "$project")"
  base="$(pmm_git_head "$project")"
  now="$(pmm_now)"
  tmp="${active_task}.tmp.$$"
  pending_temp_file="$tmp"
  {
    printf '%s\n' '---'
    printf 'pmm_schema: pmm.task/v1\n'
    printf 'task_id: %s\n' "$id"
    printf 'parent_task_id: none\n'
    printf 'task_kind: primary\n'
    printf 'execution_status: %s\n' "$legacy_status"
    printf 'verification_status: pending\n'
    printf 'delivery_status: not-requested\n'
    printf 'owner: %s\n' "$owner"
    printf 'branch: %s\n' "$branch"
    printf 'base_sha: %s\n' "$base"
    printf 'revision: 1\n'
    printf 'verification_head: none\n'
    printf 'verification_source_hash: none\n'
    printf 'verified_at: none\n'
    printf 'updated_at: %s\n' "$now"
    printf '%s\n\n' '---'
    printf '# Active Task\n\n'
    printf 'Purpose: Structured primary task migrated from %s.\n\n' "$source_label"
    printf '## Status\n\n- Title: %s\n\n' "$title_value"
    printf '## Task\n\n- Objective: %s\n- Scope: preserved legacy scope; refine before implementation.\n\n' "$objective_value"
    printf '## Harness\n\n- Agent Mode: solo\n- Owner: %s\n- Branch: %s\n\n' "$owner" "$branch"
    printf '## Verifier\n\n- Required Checks: %s\n- Evidence Needed: fresh evidence bound to HEAD and source hash.\n\n' "$verifier_value"
    printf '## Critic\n\n- Pass/Fail: pending\n- Missing Evidence: migrated legacy evidence must be revalidated.\n\n'
    printf '## Repair\n\n- Last Failure: none recorded during migration.\n- Next Concrete Action: %s\n\n' "$next_value"
    printf '## Record\n\n- Verification Evidence: pending after migration.\n- Delivery Status: not-requested\n- Delivery Evidence: pending\n- Remaining Risk: legacy fields require owner review.\n\n'
    printf '## Legacy Source\n\n'
    sed -n '1,$p' "$source_file"
  } >"$tmp" || return 1
  mv "$tmp" "$active_task" || return 1
  pending_temp_file=""
}

require_delivery_update() {
  pmm_validate_scalar delivery_status "$delivery_status" || exit 1
  case "$delivery_status" in
    waiting-confirmation | ready | deployed | released) ;;
    not-requested) die 'DELIVERY_STATUS_NOT_ACTIONABLE: use waiting-confirmation, ready, deployed, or released' ;;
    *) die "INVALID_DELIVERY_STATUS: $delivery_status" ;;
  esac
  pmm_validate_scalar evidence "$evidence" || exit 1
}

print_migration_plan() {
  local source_file="$1"
  local source_label="$2"
  local mode="$3"
  local index=0 id heading raw normalized section line target
  printf 'MIGRATION_PLAN source=%s mode=%s\n' "$source_label" "$mode"
  while IFS=$'\t' read -r id heading raw normalized section line; do
    [[ -n "$id" ]] || continue
    [[ "$section" != 'history' ]] || continue
    if [[ "$mode" == 'current' ]]; then
      case "$section" in
        ledger-task) [[ "$normalized" != 'done' && "$raw" != '-' ]] || continue ;;
        pending) [[ "$normalized" != 'done' ]] || continue ;;
        current) [[ "$normalized" != 'done' ]] || continue ;;
      esac
    fi
    index=$((index + 1))
    target="$normalized"
    [[ "$target" != 'done' ]] || target='paused'
    [[ "$target" != 'unknown' && "$target" != 'ambiguous' ]] || target='paused'
    printf 'MIGRATION_CANDIDATE index=%s label=%s section=%s status=%s target_execution=%s line=%s\n' \
      "$index" "$id" "$section" "$normalized" "$target" "$line"
  done < <(pmm_legacy_contract_records "$source_file")
  printf 'MIGRATION_PLAN_RESULT candidates=%s\n' "$index"
}

case "$command" in
  start)
    require_id
    require_owner
    require_git_context
    pmm_validate_scalar title "$title" || exit 1
    pmm_validate_scalar scope "$scope" || exit 1
    pmm_validate_scalar verifier "$verifier" || exit 1
    acquire_state_lock
    require_unarchived_task_id

    if (( work_item == 1 )); then
      [[ "$parent" != 'none' ]] || die 'ERROR: --parent is required with --work-item'
      pmm_validate_id "$parent" || die 'INVALID_PARENT_TASK_ID: --parent must use 2-80 letters, digits, dots, underscores, or hyphens'
      [[ "$id" != "$parent" ]] || die 'WORK_ITEM_ID_MUST_DIFFER: a work item cannot reuse its parent task ID'
      parent_branch="$(pmm_claim_value "$project" "$parent" branch 2>/dev/null || true)"
      parent_owner="$(pmm_claim_value "$project" "$parent" owner 2>/dev/null || true)"
      parent_claim_parent="$(pmm_claim_value "$project" "$parent" parent 2>/dev/null || true)"
      parent_kind="$(pmm_claim_value "$project" "$parent" kind 2>/dev/null || true)"
      [[ -n "$parent_branch" && "$parent_claim_parent" == 'none' && "$parent_kind" == 'primary' ]] || die 'PARENT_TASK_NOT_FOUND'
      pmm_claim_matches "$project" "$parent" "$parent_owner" "$parent_branch" none primary || \
        die 'PARENT_CLAIM_MISSING_OR_MISMATCH: the integration task must still own its branch'
      current_branch="$(pmm_git_branch "$project")"
      [[ "$current_branch" != 'detached' && "$current_branch" != "$parent_branch" ]] || die 'SEPARATE_BRANCH_REQUIRED: concurrent work items must use a different branch/worktree from the parent'
      branch_owner="$(pmm_claim_task_for_branch "$project" "$current_branch" 2>/dev/null || true)"
      [[ -z "$branch_owner" || "$branch_owner" == "$id" ]] || die "BRANCH_ALREADY_OWNED: $current_branch is owned by $branch_owner"
      branch_owner="$(task_owns_branch "$current_branch" 2>/dev/null || true)"
      [[ -z "$branch_owner" || "$branch_owner" == "$id" ]] || die "BRANCH_ALREADY_OWNED: $current_branch is owned by $branch_owner"
      target="$work_items_dir/$id.md"
      [[ ! -e "$target" ]] || die "TASK_ALREADY_EXISTS: $id"
      kind='work-item'
    else
      parent='none'
      target="$active_task"
      kind='primary'
      if [[ -f "$target" ]]; then
        if pmm_has_schema "$target"; then
          current_status="$(pmm_frontmatter_value "$target" execution_status)"
          [[ "$current_status" == 'idle' ]] || die "ACTIVE_TASK_EXISTS: $(pmm_frontmatter_value "$target" task_id)"
        else
          die 'LEGACY_TASK_REQUIRES_MIGRATION: run migrate --dry-run before starting another primary task'
        fi
      fi
      require_primary_claim_available
      current_branch="$(pmm_git_branch "$project")"
      branch_owner="$(pmm_claim_task_for_branch "$project" "$current_branch" 2>/dev/null || true)"
      [[ -z "$branch_owner" || "$branch_owner" == "$id" ]] || die "BRANCH_ALREADY_OWNED: $current_branch is owned by $branch_owner"
    fi

    pmm_claim_acquire "$project" "$id" "$owner" "$(pmm_git_branch "$project")" "$parent" "$kind" || die "TASK_OWNED_BY_OTHER: $id"
    pending_claim_id="$id"
    if ! write_task_file "$target" "$kind"; then
      pmm_claim_release "$project" "$id" || true
      pending_claim_id=""
      die "TASK_WRITE_FAILED: $id"
    fi
    pending_claim_id=""
    printf 'TASK_STARTED %s file=%s\n' "$id" "${target#$project/}"
    ;;

  status)
    if [[ -n "$id" ]]; then
      require_id
      file="$(pmm_task_file "$project" "$id" 2>/dev/null || true)"
      [[ -n "$file" ]] || die "TASK_NOT_FOUND: $id"
      printf 'TASK_STATUS id=%s execution=%s verification=%s delivery=%s owner=%s branch=%s\n' \
        "$id" \
        "$(pmm_frontmatter_value "$file" execution_status)" \
        "$(pmm_frontmatter_value "$file" verification_status)" \
        "$(pmm_frontmatter_value "$file" delivery_status)" \
        "$(pmm_frontmatter_value "$file" owner)" \
        "$(pmm_frontmatter_value "$file" branch)"
    elif [[ -f "$active_task" ]] && pmm_has_schema "$active_task"; then
      printf 'PRIMARY_TASK id=%s execution=%s verification=%s delivery=%s\n' \
        "$(pmm_frontmatter_value "$active_task" task_id)" \
        "$(pmm_frontmatter_value "$active_task" execution_status)" \
        "$(pmm_frontmatter_value "$active_task" verification_status)" \
        "$(pmm_frontmatter_value "$active_task" delivery_status)"
      if [[ -d "$work_items_dir" ]]; then
        for file in "$work_items_dir"/*.md; do
          [[ -e "$file" ]] || continue
          printf 'WORK_ITEM id=%s execution=%s verification=%s branch=%s\n' \
            "$(pmm_frontmatter_value "$file" task_id)" \
            "$(pmm_frontmatter_value "$file" execution_status)" \
            "$(pmm_frontmatter_value "$file" verification_status)" \
            "$(pmm_frontmatter_value "$file" branch)"
        done
      fi
    else
      printf 'LEGACY_OR_MISSING_TASK_STATE\n'
    fi
    ;;

  checkpoint)
    require_id
    pmm_validate_scalar next_action "$next_action" || exit 1
    acquire_state_lock
    resolve_task_file
    require_task_control "$file"
    begin_task_update "$file"
    revision="$(task_revision "$staged_task_file")"
    pmm_set_frontmatter "$staged_task_file" revision "$((revision + 1))"
    pmm_set_frontmatter "$staged_task_file" verification_status pending
    pmm_set_frontmatter "$staged_task_file" verification_head none
    pmm_set_frontmatter "$staged_task_file" verification_source_hash none
    pmm_set_frontmatter "$staged_task_file" verified_at none
    pmm_set_frontmatter "$staged_task_file" updated_at "$(pmm_now)"
    pmm_replace_bullet "$staged_task_file" 'Next Concrete Action' "$next_action"
    pmm_replace_bullet "$staged_task_file" 'Verification Evidence' 'pending after checkpoint'
    commit_task_update "$file"
    printf 'TASK_CHECKPOINTED %s\n' "$id"
    ;;

  verify)
    require_id
    pmm_validate_scalar evidence "$evidence" || exit 1
    acquire_state_lock
    resolve_task_file
    require_task_control "$file"
    verification_head_value="$(pmm_git_head "$project")"
    [[ "$verification_head_value" != 'none' ]] || die "SOURCE_HASH_FAILED: $id has no Git HEAD"
    verification_hash_value="$(pmm_source_hash "$project")" || die "SOURCE_HASH_FAILED: $id"
    [[ "$verification_hash_value" != 'none' ]] || die "SOURCE_HASH_FAILED: $id"
    begin_task_update "$file"
    revision="$(task_revision "$staged_task_file")"
    pmm_set_frontmatter "$staged_task_file" verification_head "$verification_head_value"
    pmm_set_frontmatter "$staged_task_file" verification_source_hash "$verification_hash_value"
    pmm_set_frontmatter "$staged_task_file" verified_at "$(pmm_now)"
    pmm_set_frontmatter "$staged_task_file" updated_at "$(pmm_now)"
    pmm_set_frontmatter "$staged_task_file" revision "$((revision + 1))"
    pmm_replace_bullet "$staged_task_file" 'Verification Evidence' "$evidence"
    pmm_replace_bullet "$staged_task_file" 'Pass/Fail' 'pass'
    pmm_set_frontmatter "$staged_task_file" verification_status passed
    commit_task_update "$file"
    printf 'TASK_VERIFIED %s\n' "$id"
    ;;

  resume)
    require_id
    require_owner
    require_git_context
    acquire_state_lock
    resolve_task_file
    recorded_branch="$(pmm_frontmatter_value "$file" branch)"
    recorded_owner="$(pmm_frontmatter_value "$file" owner)"
    current_branch="$(pmm_git_branch "$project")"
    [[ "$recorded_branch" == "$current_branch" ]] || die "TASK_BRANCH_MISMATCH: $id belongs to $recorded_branch, current branch is $current_branch"
    if (( takeover == 0 )); then
      [[ "$recorded_owner" == "$owner" ]] || die "TASK_OWNERSHIP_MISMATCH: $id is owned by $recorded_owner; use --takeover only after confirming it stopped"
    fi
    if (( takeover == 1 )); then
      rollback_claim_id="$id"
      rollback_claim_owner="$recorded_owner"
      rollback_claim_new_owner="$owner"
      rollback_claim_branch="$recorded_branch"
      rollback_claim_parent="$(pmm_frontmatter_value "$file" parent_task_id)"
      rollback_claim_kind="$(pmm_frontmatter_value "$file" task_kind)"
      pmm_claim_release "$project" "$id" || die "TASK_CLAIM_RELEASE_FAILED: $id"
    fi
    pmm_claim_acquire "$project" "$id" "$owner" "$recorded_branch" \
      "$(pmm_frontmatter_value "$file" parent_task_id)" \
      "$(pmm_frontmatter_value "$file" task_kind)" || die "TASK_OWNED_BY_OTHER: $id"
    begin_task_update "$file"
    pmm_set_frontmatter "$staged_task_file" owner "$owner"
    pmm_set_frontmatter "$staged_task_file" execution_status active
    pmm_set_frontmatter "$staged_task_file" updated_at "$(pmm_now)"
    commit_task_update "$file"
    rollback_claim_id=""
    printf 'TASK_RESUMED %s owner=%s\n' "$id" "$owner"
    ;;

  close)
    require_id
    acquire_state_lock
    resolve_task_file
    require_task_control "$file"
    kind="$(pmm_frontmatter_value "$file" task_kind)"
    if [[ "$kind" == 'primary' ]]; then
      child_ids="$(active_child_ids "$id")"
      [[ -z "$child_ids" ]] || die "ACTIVE_WORK_ITEMS_EXIST: $(printf '%s' "$child_ids" | paste -sd, -)"
    fi
    if [[ "$kind" == 'work-item' && "$(pmm_frontmatter_value "$file" execution_status)" == 'ready-to-integrate' ]]; then
      pmm_evidence_is_fresh "$project" "$file" || die "STALE_VERIFICATION: $id"
      printf 'TASK_READY_TO_INTEGRATE %s\n' "$id"
      exit 0
    fi
    [[ "$(pmm_frontmatter_value "$file" verification_status)" == 'passed' ]] || die "TASK_NOT_VERIFIED: $id"
    if ! pmm_evidence_is_fresh "$project" "$file"; then
      pmm_set_frontmatter "$file" verification_status stale
      die "STALE_VERIFICATION: $id"
    fi
    if [[ "$kind" == 'work-item' ]]; then
      pmm_source_is_clean "$project" || die "WORK_ITEM_SOURCE_NOT_COMMITTED: commit source changes before final work-item verification"
      begin_task_update "$file"
      revision="$(task_revision "$staged_task_file")"
      pmm_set_frontmatter "$staged_task_file" execution_status ready-to-integrate
      pmm_set_frontmatter "$staged_task_file" updated_at "$(pmm_now)"
      pmm_set_frontmatter "$staged_task_file" revision "$((revision + 1))"
      pmm_replace_bullet "$staged_task_file" 'Next Concrete Action' 'commit this operational checkpoint, merge the branch, then run pmm-task.sh integrate from the primary branch'
      commit_task_update "$file"
      printf 'TASK_READY_TO_INTEGRATE %s\n' "$id"
      exit 0
    fi
    title_value="$(awk -F ': ' '/^- Title:/{print $2; exit}' "$file")"
    evidence_value="$(awk -F ': ' '/^- Verification Evidence:/{sub(/^- Verification Evidence:[[:space:]]*/, ""); print; exit}' "$file")"
    parent_value="$(pmm_frontmatter_value "$file" parent_task_id)"
    execution_value='done'
    verification_value="$(pmm_frontmatter_value "$file" verification_status)"
    delivery_value="$(pmm_frontmatter_value "$file" delivery_status)"
    write_history_entry "$id" "$parent_value" "$title_value" "$execution_value" "$verification_value" "$delivery_value" "$evidence_value" || \
      die "TASK_HISTORY_WRITE_FAILED: $id"
    pmm_task_id_archive "$project" "$id" || die "TASK_ID_ARCHIVE_FAILED: $id"
    write_pending_delivery "$id" "$owner" "$delivery_value" || die "TASK_QUEUE_WRITE_FAILED: $id"
    write_idle_task || die "TASK_IDLE_WRITE_FAILED: $id"
    pmm_claim_release "$project" "$id" || die "TASK_CLAIM_RELEASE_FAILED: $id"
    printf 'TASK_CLOSED %s\n' "$id"
    ;;

  integrate)
    require_id
    acquire_state_lock
    pmm_has_schema "$active_task" || die 'PRIMARY_TASK_NOT_STRUCTURED'
    [[ "$(pmm_frontmatter_value "$active_task" execution_status)" != 'idle' ]] || die 'PRIMARY_TASK_NOT_ACTIVE'
    require_task_control "$active_task"
    primary_id="$(pmm_frontmatter_value "$active_task" task_id)"
    resolve_task_file
    [[ "$file" != "$active_task" ]] || die 'WORK_ITEM_REQUIRED: integrate accepts only child work items'
    [[ "$(pmm_frontmatter_value "$file" task_kind)" == 'work-item' ]] || die 'WORK_ITEM_REQUIRED: integrate accepts only child work items'
    [[ "$(pmm_frontmatter_value "$file" parent_task_id)" == "$primary_id" ]] || die "WORK_ITEM_PARENT_MISMATCH: $id does not belong to $primary_id"
    [[ "$(pmm_frontmatter_value "$file" execution_status)" == 'ready-to-integrate' ]] || die "WORK_ITEM_NOT_READY: $id"
    [[ "$(pmm_frontmatter_value "$file" verification_status)" == 'passed' ]] || die "TASK_NOT_VERIFIED: $id"
    child_owner="$(pmm_frontmatter_value "$file" owner)"
    child_branch="$(pmm_frontmatter_value "$file" branch)"
    pmm_claim_matches "$project" "$id" "$child_owner" "$child_branch" "$primary_id" work-item || \
      die "TASK_CLAIM_MISSING_OR_MISMATCH: $id"
    pmm_ready_evidence_is_fresh_on_branch "$project" "$file" || die "WORK_ITEM_VERIFICATION_STALE: $id has unverified source commits after its recorded verifier"
    child_head="$(pmm_frontmatter_value "$file" verification_head)"
    [[ "$child_head" != 'none' ]] || die "TASK_NOT_VERIFIED: $id"
    git -C "$project" merge-base --is-ancestor "$child_head" HEAD 2>/dev/null || die "WORK_ITEM_NOT_MERGED: $id verified commit $child_head is not in $(pmm_git_branch "$project")"
    child_tip="$(git -C "$project" rev-parse "refs/heads/$child_branch" 2>/dev/null || true)"
    [[ -n "$child_tip" ]] || die "WORK_ITEM_BRANCH_NOT_FOUND: $child_branch"
    git -C "$project" merge-base --is-ancestor "$child_tip" HEAD 2>/dev/null || die "WORK_ITEM_NOT_MERGED: $id branch tip $child_tip is not in $(pmm_git_branch "$project")"
    title_value="$(awk -F ': ' '/^- Title:/{print $2; exit}' "$file")"
    evidence_value="$(awk -F ': ' '/^- Verification Evidence:/{sub(/^- Verification Evidence:[[:space:]]*/, ""); print; exit}' "$file")"
    delivery_value="$(pmm_frontmatter_value "$file" delivery_status)"
    write_history_entry "$id" "$primary_id" "$title_value" done passed "$delivery_value" "$evidence_value" || \
      die "TASK_HISTORY_WRITE_FAILED: $id"
    pmm_task_id_archive "$project" "$id" || die "TASK_ID_ARCHIVE_FAILED: $id"
    write_pending_delivery "$id" "$child_owner" "$delivery_value" || die "TASK_QUEUE_WRITE_FAILED: $id"
    begin_task_update "$active_task"
    primary_revision="$(task_revision "$staged_task_file")"
    pmm_set_frontmatter "$staged_task_file" verification_status pending
    pmm_set_frontmatter "$staged_task_file" verification_head none
    pmm_set_frontmatter "$staged_task_file" verification_source_hash none
    pmm_set_frontmatter "$staged_task_file" verified_at none
    pmm_set_frontmatter "$staged_task_file" updated_at "$(pmm_now)"
    pmm_set_frontmatter "$staged_task_file" revision "$((primary_revision + 1))"
    pmm_replace_bullet "$staged_task_file" 'Verification Evidence' 'pending after child integration'
    pmm_replace_bullet "$staged_task_file" 'Pass/Fail' 'pending'
    commit_task_update "$active_task"
    rm -f "$file" || die "TASK_ARCHIVE_REMOVE_FAILED: $id"
    pmm_claim_release "$project" "$id" || die "TASK_CLAIM_RELEASE_FAILED: $id"
    printf 'TASK_INTEGRATED %s parent=%s\n' "$id" "$primary_id"
    ;;

  delivery)
    require_id
    if [[ -z "$delivery_status" && -z "$evidence" ]]; then
      file="$(pmm_task_file "$project" "$id" 2>/dev/null || true)"
      [[ -n "$file" ]] || die "TASK_NOT_FOUND: $id"
      printf 'DELIVERY_STATUS id=%s status=%s execution=%s verification=%s\n' \
        "$id" \
        "$(pmm_frontmatter_value "$file" delivery_status)" \
        "$(pmm_frontmatter_value "$file" execution_status)" \
        "$(pmm_frontmatter_value "$file" verification_status)"
      exit 0
    fi
    require_owner
    require_delivery_update
    acquire_state_lock
    resolve_task_file
    require_task_control "$file"
    begin_task_update "$file"
    revision="$(task_revision "$staged_task_file")"
    pmm_set_frontmatter "$staged_task_file" delivery_status "$delivery_status"
    pmm_set_frontmatter "$staged_task_file" updated_at "$(pmm_now)"
    pmm_set_frontmatter "$staged_task_file" revision "$((revision + 1))"
    pmm_replace_bullet "$staged_task_file" 'Delivery Status' "$delivery_status"
    pmm_replace_bullet "$staged_task_file" 'Delivery Evidence' "$evidence"
    commit_task_update "$file"
    printf 'DELIVERY_UPDATED %s status=%s\n' "$id" "$delivery_status"
    ;;

  migrate)
    acquire_state_lock
    (( apply == 0 )) || (( plan == 0 )) || die 'ERROR: migrate --plan cannot be combined with --apply'
    legacy_ledger="$memory_dir/task-ledger.md"
    if [[ -f "$active_task" ]] && pmm_has_schema "$active_task"; then
      migration_source="$active_task"
      migration_source_label='active-task.md'
    elif [[ -f "$active_task" ]]; then
      active_legacy_count="$(pmm_legacy_contract_count "$active_task" all 2>/dev/null || printf '0')"
      ledger_legacy_count=0
      [[ ! -f "$legacy_ledger" ]] || ledger_legacy_count="$(pmm_legacy_contract_count "$legacy_ledger" current 2>/dev/null || printf '0')"
      if (( active_legacy_count > 0 && ledger_legacy_count > 0 )); then
        die 'MIGRATION_AMBIGUOUS_SOURCES: both active-task.md and task-ledger.md contain current legacy contracts'
      elif (( active_legacy_count > 0 )); then
        migration_source="$active_task"
        migration_source_label='active-task.md'
      elif (( ledger_legacy_count > 0 )); then
        migration_source="$legacy_ledger"
        migration_source_label='task-ledger.md'
      else
        migration_source="$active_task"
        migration_source_label='active-task.md'
      fi
    elif [[ -f "$legacy_ledger" ]]; then
      migration_source="$legacy_ledger"
      migration_source_label='task-ledger.md'
    else
      die 'MIGRATION_NOT_NEEDED: active-task.md and task-ledger.md are missing'
    fi
    if [[ "$migration_source" == "$active_task" ]] && pmm_has_schema "$active_task"; then
      printf 'MIGRATION_NOT_NEEDED schema=pmm.task/v1\n'
      exit 0
    fi
    migration_mode='all'
    [[ "$migration_source" != "$legacy_ledger" ]] || migration_mode='current'
    count="$(pmm_legacy_contract_count "$migration_source" "$migration_mode")"
    if (( plan == 1 )); then
      print_migration_plan "$migration_source" "$migration_source_label" "$migration_mode"
      exit 0
    fi
    if (( count == 0 )); then
      printf 'MIGRATION_NO_CURRENT_TASK source=%s task_contracts=0 action=leave-legacy-history\n' "$migration_source_label" >&2
      exit 2
    fi
    if (( count > 1 )); then
      printf 'MIGRATION_AMBIGUOUS source=%s task_contracts=%s action=split-manually\n' "$migration_source_label" "$count" >&2
      exit 2
    fi
    legacy_status_raw="$(pmm_legacy_contract_field "$migration_source" "$migration_mode" status)"
    [[ "$legacy_status_raw" != 'ambiguous' ]] || die 'MIGRATION_AMBIGUOUS_STATUS: legacy contract contains conflicting Status fields; review it manually before apply'
    legacy_status="$(pmm_normalize_legacy_status "$legacy_status_raw")"
    [[ "$legacy_status" != 'unknown' ]] || legacy_status='paused'
    migration_execution="$legacy_status"
    [[ "$migration_execution" != 'done' ]] || migration_execution='paused'
    if (( dry_run == 1 )); then
      print_migration_plan "$migration_source" "$migration_source_label" "$migration_mode"
      printf 'MIGRATION_READY source=%s task_contracts=%s legacy_status=%s target_execution=%s\n' \
        "$migration_source_label" "$count" "$legacy_status" "$migration_execution"
      exit 0
    fi
    (( apply == 1 )) || die 'ERROR: migrate requires --dry-run or --apply'
    require_id
    require_owner
    require_git_context
    require_unarchived_task_id
    if [[ "$migration_execution" != 'idle' ]]; then
      require_primary_claim_available
    fi
    backup_dir="$project/.project-runtime/pmm/backups"
    mkdir -p "$backup_dir"
    backup="$backup_dir/${migration_source_label%.md}.$(date -u '+%Y%m%dT%H%M%SZ').$$.md"
    cp "$migration_source" "$backup" || die 'MIGRATION_BACKUP_FAILED'
    if [[ "$migration_execution" == 'idle' ]]; then
      write_idle_task || die 'MIGRATION_WRITE_FAILED'
    else
      pmm_claim_acquire "$project" "$id" "$owner" "$(pmm_git_branch "$project")" none primary || \
        die "TASK_OWNED_BY_OTHER: $id"
      pending_claim_id="$id"
      if ! write_migrated_task "$migration_source" "$migration_source_label" "$migration_execution" "$migration_mode"; then
        pmm_claim_release "$project" "$id" || true
        pending_claim_id=""
        die 'MIGRATION_WRITE_FAILED'
      fi
      pending_claim_id=""
    fi
    printf 'MIGRATION_APPLIED source=%s task_id=%s backup=%s\n' "$migration_source_label" "$id" "${backup#$project/}"
    ;;

  *)
    usage
    die "ERROR: unknown command: $command"
    ;;
esac
