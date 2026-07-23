#!/usr/bin/env bash
# Purpose: Manage pmm structured task lifecycle, project upgrades, local claims, verification evidence, delivery, and migration.
# Read when: Upgrading, starting, checkpointing, verifying, resuming, closing, or migrating project tasks.
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
  pmm-task.sh upgrade --project PATH --auto --owner OWNER [--id ID]
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
auto=0
delivery_status=""
auto_routed=0

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
    --auto) auto=1; shift ;;
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
runtime_state="$memory_dir/runtime-state.md"
agents_file="$project/AGENTS.md"
current_state="$memory_dir/current-state.md"
verifier_map="$memory_dir/verifier-map.md"
change_log="$project/docs/07-decisions/change-log.md"
current_runtime_version="$(tr -d '[:space:]' <"$script_dir/../VERSION")"
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
upgrade_stage_dir=""
upgrade_backup_dir=""
upgrade_manifest=""
upgrade_rollback_active=0

release_state_lock() {
  if (( upgrade_rollback_active == 1 )) && [[ -f "$upgrade_manifest" ]]; then
    while IFS='|' read -r upgrade_rel upgrade_existed; do
      [[ -n "$upgrade_rel" ]] || continue
      upgrade_target="$project/$upgrade_rel"
      if [[ "$upgrade_existed" == '1' ]]; then
        mkdir -p "$(dirname "$upgrade_target")" || true
        cp "$upgrade_backup_dir/$upgrade_rel" "$upgrade_target" || true
      else
        rm -f "$upgrade_target" || true
      fi
    done <"$upgrade_manifest"
    upgrade_rollback_active=0
  fi
  if [[ -n "$upgrade_stage_dir" ]]; then
    rm -rf "$upgrade_stage_dir" || true
    upgrade_stage_dir=""
  fi
  if (( upgrade_rollback_active == 0 )) && [[ -n "$upgrade_backup_dir" && ! -f "$runtime_state" ]]; then
    rm -rf "$upgrade_backup_dir" || true
  fi
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
  local attempt=1
  local max_attempts=1
  [[ "$command" != 'start' ]] || max_attempts=100
  while (( attempt <= max_attempts )); do
    if pmm_mutation_lock_acquire "$project" "$lock_id"; then
      lock_held=1
      return 0
    fi
    (( attempt == max_attempts )) && break
    sleep 0.05
    attempt=$((attempt + 1))
  done
  die 'PMM_STATE_BUSY: another pmm lifecycle mutation is in progress'
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

auto_route_isolated_start() {
  local claimed_primary claim_status current_branch branch_owner primary_branch primary_owner
  local primary_worktree primary_task primary_status
  (( work_item == 0 )) || return 0

  current_branch="$(pmm_git_branch "$project")"
  branch_owner="$(pmm_claim_task_for_branch "$project" "$current_branch" 2>/dev/null || true)"
  [[ -z "$branch_owner" ]] || return 0

  if claimed_primary="$(pmm_claim_primary_task "$project" 2>/dev/null)"; then
    :
  else
    claim_status=$?
    case "$claim_status" in
      1) return 0 ;;
      2) die 'MULTIPLE_PRIMARY_TASK_CLAIMS: repair the Git common-directory claims before continuing' ;;
      *) die 'PRIMARY_TASK_CLAIM_CHECK_FAILED' ;;
    esac
  fi

  primary_branch="$(pmm_claim_value "$project" "$claimed_primary" branch 2>/dev/null || true)"
  primary_owner="$(pmm_claim_value "$project" "$claimed_primary" owner 2>/dev/null || true)"
  [[ -n "$primary_branch" && "$current_branch" != "$primary_branch" ]] || return 0
  pmm_claim_matches "$project" "$claimed_primary" "$primary_owner" "$primary_branch" none primary || \
    die "PARENT_CLAIM_MISSING_OR_MISMATCH: $claimed_primary"

  primary_worktree="$(pmm_git_worktree_for_branch "$project" "$primary_branch" 2>/dev/null || true)"
  [[ -n "$primary_worktree" && -d "$primary_worktree" ]] || return 0
  primary_task="$primary_worktree/docs/00-project-memory/active-task.md"
  [[ -f "$primary_task" ]] || return 0
  pmm_has_schema "$primary_task" || return 0
  [[ "$(pmm_frontmatter_value "$primary_task" task_id 2>/dev/null || true)" == "$claimed_primary" ]] || return 0
  [[ "$(pmm_frontmatter_value "$primary_task" branch 2>/dev/null || true)" == "$primary_branch" ]] || return 0
  primary_status="$(pmm_frontmatter_value "$primary_task" execution_status 2>/dev/null || true)"
  [[ "$primary_status" == 'active' ]] || return 0

  work_item=1
  parent="$claimed_primary"
  auto_routed=1
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
  local target="${1:-$active_task}"
  local branch base now tmp
  [[ ! -d "$target" ]] || return 1
  branch="$(pmm_git_branch "$project")"
  base="$(pmm_git_head "$project")"
  now="$(pmm_now)"
  mkdir -p "$(dirname "$target")"
  tmp="${target}.tmp.$$"
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
  mv "$tmp" "$target" || return 1
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
  local target="${5:-$active_task}"
  local title_value objective_value verifier_value next_value branch base now tmp
  [[ ! -d "$target" ]] || return 1
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
  mkdir -p "$(dirname "$target")"
  tmp="${target}.tmp.$$"
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
  mv "$tmp" "$target" || return 1
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

write_managed_runtime_block() {
  local target="$1"
  {
    printf '%s\n' '<!-- pmm-runtime:start -->'
    printf '## PMM Runtime\n\n'
    printf -- '- Managed runtime version: `%s`.\n' "$current_runtime_version"
    printf -- '- Before non-trivial task writes, run the installed `pmm-task.sh upgrade --project . --auto --owner <agent-id>` Upgrade Gate.\n'
    printf -- '- Treat `docs/00-project-memory/runtime-state.md` as project runtime state; compatibility readers are for migration, recovery, rollback, and ambiguity review only.\n'
    printf -- '- Keep exactly one primary task in `active-task.md`; concurrent writers use isolated branches/worktrees and work-item files.\n'
    printf '%s\n' '<!-- pmm-runtime:end -->'
  } >"$target"
}

render_upgraded_agents() {
  local target="$1"
  local base="$2"
  local block="$3"
  local start_count end_count
  start_count="$(awk '$0 == "<!-- pmm-runtime:start -->" { count++ } END { print count + 0 }' "$base")"
  end_count="$(awk '$0 == "<!-- pmm-runtime:end -->" { count++ } END { print count + 0 }' "$base")"
  if [[ "$start_count" != "$end_count" || "$start_count" -gt 1 ]]; then
    die 'PROJECT_UPGRADE_INVALID_MANAGED_BLOCK: AGENTS.md has unmatched or duplicate pmm runtime markers'
  fi
  if [[ "$start_count" == '1' ]]; then
    awk -v block="$block" '
      $0 == "<!-- pmm-runtime:start -->" {
        while ((getline line < block) > 0) print line
        close(block)
        skipping=1
        next
      }
      skipping && $0 == "<!-- pmm-runtime:end -->" { skipping=0; next }
      !skipping { print }
    ' "$base" >"$target"
  else
    {
      sed -n '1,$p' "$base"
      printf '\n'
      sed -n '1,$p' "$block"
    } >"$target"
  fi
}

upgrade_source_hash() {
  local rel file
  {
    for rel in AGENTS.md docs/00-project-memory/runtime-state.md \
      docs/00-project-memory/active-task.md docs/00-project-memory/task-ledger.md; do
      file="$project/$rel"
      [[ -f "$file" ]] || continue
      printf '%s:' "$rel"
      pmm_file_hash "$file" || return 1
    done
  } | pmm_hash_stream
}

derive_upgrade_task_id() {
  local source_file="$1"
  local selection_mode="$2"
  local requested_id="$3"
  local candidate source_digest
  if [[ -n "$requested_id" ]]; then
    pmm_validate_id "$requested_id" || die 'ERROR: --id must use 2-80 letters, digits, dots, underscores, or hyphens'
    printf '%s\n' "$requested_id"
    return
  fi
  candidate="$(pmm_legacy_title "$source_file" "$selection_mode" 2>/dev/null || true)"
  if pmm_validate_id "$candidate"; then
    printf '%s\n' "$candidate"
    return
  fi
  source_digest="$(pmm_file_hash "$source_file")" || die 'PROJECT_UPGRADE_SOURCE_HASH_FAILED'
  printf 'legacy-%s\n' "${source_digest:0:16}"
}

require_upgrade_task_id_available() {
  local candidate="$1"
  local archive_status
  if pmm_task_id_is_archived "$project" "$candidate"; then
    die "TASK_ID_ALREADY_ARCHIVED: $candidate"
  else
    archive_status=$?
  fi
  case "$archive_status" in
    1) return 0 ;;
    *) die "TASK_ID_ARCHIVE_CHECK_FAILED: $candidate" ;;
  esac
}

upgrade_register_target() {
  local rel="$1"
  local targets="$upgrade_stage_dir/targets"
  if [[ ! -f "$targets" ]] || ! rg -q --fixed-strings -x -- "$rel" "$targets"; then
    printf '%s\n' "$rel" >>"$targets"
  fi
}

upgrade_backup_file() {
  local rel="$1"
  local source="$project/$rel"
  local destination="$upgrade_backup_dir/$rel"
  [[ -f "$source" ]] || return 0
  [[ ! -e "$destination" ]] || return 0
  mkdir -p "$(dirname "$destination")"
  cp "$source" "$destination" || die "PROJECT_UPGRADE_BACKUP_FAILED: $rel"
}

write_runtime_state() {
  local target="$1"
  local migrated_from="$2"
  local source_hash="$3"
  local backup_path="$4"
  local now="$5"
  mkdir -p "$(dirname "$target")"
  {
    printf '%s\n' '---'
    printf 'pmm_schema: pmm.runtime/v1\n'
    printf 'runtime_version: %s\n' "$current_runtime_version"
    printf 'migration_status: complete\n'
    printf 'migrated_from: %s\n' "$migrated_from"
    printf 'source_hash: %s\n' "$source_hash"
    printf 'backup_path: %s\n' "$backup_path"
    printf 'upgraded_at: %s\n' "$now"
    printf '%s\n\n' '---'
    printf '# PMM Runtime State\n\n'
    printf 'Purpose: Project-level runtime version and completed migration evidence.\n'
    printf 'Read when: Upgrading, auditing, or recovering the PMM project runtime.\n'
    printf 'Skip when: Executing a current task after the Upgrade Gate passes.\n'
  } >"$target"
}

prepare_upgrade_claim() {
  local task_file="$1"
  local execution_value task_id_value owner_value branch_value claimed_primary claim_status
  execution_value="$(pmm_frontmatter_value "$task_file" execution_status 2>/dev/null || true)"
  if [[ "$execution_value" == 'idle' ]]; then
    if claimed_primary="$(pmm_claim_primary_task "$project" 2>/dev/null)"; then
      die "PRIMARY_TASK_ALREADY_CLAIMED: $claimed_primary"
    else
      claim_status=$?
      [[ "$claim_status" == '1' ]] || die 'MULTIPLE_PRIMARY_TASK_CLAIMS: repair claims before upgrading'
    fi
    return
  fi
  task_id_value="$(pmm_frontmatter_value "$task_file" task_id 2>/dev/null || true)"
  owner_value="$(pmm_frontmatter_value "$task_file" owner 2>/dev/null || true)"
  branch_value="$(pmm_frontmatter_value "$task_file" branch 2>/dev/null || true)"
  pmm_validate_id "$task_id_value" || die "PROJECT_UPGRADE_INVALID_TASK_ID: $task_id_value"
  pmm_validate_id "$owner_value" || die "PROJECT_UPGRADE_INVALID_OWNER: $owner_value"
  [[ "$branch_value" == "$(pmm_git_branch "$project")" ]] || \
    die "PROJECT_UPGRADE_BRANCH_MISMATCH: task $task_id_value belongs to $branch_value"
  if claimed_primary="$(pmm_claim_primary_task "$project" 2>/dev/null)"; then
    [[ "$claimed_primary" == "$task_id_value" ]] || die "PRIMARY_TASK_ALREADY_CLAIMED: $claimed_primary"
    pmm_claim_matches "$project" "$task_id_value" "$owner_value" "$branch_value" none primary || \
      die "PROJECT_UPGRADE_PRIMARY_CLAIM_MISMATCH: $task_id_value"
  else
    claim_status=$?
    [[ "$claim_status" == '1' ]] || die 'MULTIPLE_PRIMARY_TASK_CLAIMS: repair claims before upgrading'
    pmm_claim_acquire "$project" "$task_id_value" "$owner_value" "$branch_value" none primary || \
      die "TASK_OWNED_BY_OTHER: $task_id_value"
    pending_claim_id="$task_id_value"
  fi
}

perform_project_upgrade() {
  local requested_id="${1:-}"
  local allow_shared_primary="${2:-0}"
  local existing_runtime_version='' runtime_compare='' migrated_from='unversioned-project'
  local active_legacy_count=0 ledger_legacy_count=0 legacy_source='' legacy_label='' legacy_mode='all'
  local legacy_status_raw='' legacy_status='' migration_execution='' migrated_task_id=''
  local base_agents managed_block agents_candidate active_candidate result_task_file
  local needs_upgrade=0 rel source_hash backup_rel now target existed
  local saved_id="$id"
  local saved_owner="$owner"
  local shared_primary_id='' shared_primary_status=0

  require_owner
  require_git_context
  [[ "$current_runtime_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die 'PROJECT_RUNTIME_VERSION_INVALID: installed VERSION must be semantic x.y.z'

  if [[ -f "$runtime_state" ]]; then
    pmm_has_runtime_schema "$runtime_state" || die 'PROJECT_RUNTIME_STATE_INVALID: runtime-state.md must use pmm.runtime/v1'
    existing_runtime_version="$(pmm_frontmatter_value "$runtime_state" runtime_version 2>/dev/null || true)"
    runtime_compare="$(pmm_version_compare "$existing_runtime_version" "$current_runtime_version" 2>/dev/null || true)"
    [[ -n "$runtime_compare" ]] || die "PROJECT_RUNTIME_VERSION_INVALID: $existing_runtime_version"
    [[ "$runtime_compare" != '1' ]] || die "PROJECT_RUNTIME_NEWER_THAN_INSTALLED: project=$existing_runtime_version installed=$current_runtime_version"
    migrated_from="runtime-$existing_runtime_version"
    if [[ "$runtime_compare" != '0' || "$(pmm_frontmatter_value "$runtime_state" migration_status 2>/dev/null || true)" != 'complete' ]]; then
      needs_upgrade=1
    fi
  else
    needs_upgrade=1
  fi

  if shared_primary_id="$(pmm_claim_primary_task "$project" 2>/dev/null)"; then
    :
  else
    shared_primary_status=$?
    [[ "$shared_primary_status" == '1' ]] || die 'MULTIPLE_PRIMARY_TASK_CLAIMS: repair claims before upgrading'
  fi

  if [[ -f "$active_task" ]] && pmm_has_schema "$active_task"; then
    migrated_from="${migrated_from:-unversioned-structured}"
    [[ -n "$existing_runtime_version" ]] || migrated_from='unversioned-structured'
    if (( allow_shared_primary == 1 )) && [[ -n "$shared_primary_id" ]] && \
      { [[ "$(pmm_frontmatter_value "$active_task" execution_status 2>/dev/null || true)" == 'idle' ]] || \
        [[ "$(pmm_frontmatter_value "$active_task" task_id 2>/dev/null || true)" == "$shared_primary_id" ]]; }; then
      result_task_file=''
    else
      result_task_file="$active_task"
    fi
  else
    if [[ -f "$active_task" ]]; then
      active_legacy_count="$(pmm_legacy_contract_count "$active_task" all 2>/dev/null || printf '0')"
    fi
    if [[ -f "$memory_dir/task-ledger.md" ]]; then
      ledger_legacy_count="$(pmm_legacy_contract_count "$memory_dir/task-ledger.md" current 2>/dev/null || printf '0')"
    fi
    if (( active_legacy_count > 0 && ledger_legacy_count > 0 )); then
      die 'PROJECT_UPGRADE_AMBIGUOUS_SOURCES: active-task.md and task-ledger.md both contain current contracts'
    elif (( active_legacy_count > 0 )); then
      legacy_source="$active_task"
      legacy_label='active-task.md'
      legacy_mode='all'
      migrated_from='legacy-active-task'
    elif (( ledger_legacy_count > 0 )); then
      legacy_source="$memory_dir/task-ledger.md"
      legacy_label='task-ledger.md'
      legacy_mode='current'
      migrated_from='legacy-task-ledger'
    elif [[ -f "$memory_dir/task-ledger.md" || -f "$active_task" ]]; then
      legacy_source="${legacy_source:-${memory_dir}/task-ledger.md}"
      [[ -f "$legacy_source" ]] || legacy_source="$active_task"
      legacy_label="$(basename "$legacy_source")"
      legacy_mode='current'
      migrated_from='legacy-history-only'
    fi
    if (( active_legacy_count > 1 || ledger_legacy_count > 1 )); then
      die "PROJECT_UPGRADE_AMBIGUOUS: task_contracts=$((active_legacy_count + ledger_legacy_count))"
    fi
    if [[ -n "$legacy_source" && $((active_legacy_count + ledger_legacy_count)) -eq 1 ]]; then
      legacy_status_raw="$(pmm_legacy_contract_field "$legacy_source" "$legacy_mode" status 2>/dev/null || true)"
      [[ "$legacy_status_raw" != 'ambiguous' ]] || die 'PROJECT_UPGRADE_AMBIGUOUS_STATUS: legacy contract contains conflicting Status fields'
      legacy_status="$(pmm_normalize_legacy_status "$legacy_status_raw")"
      [[ "$legacy_status" != 'unknown' ]] || legacy_status='paused'
      migration_execution="$legacy_status"
      [[ "$migration_execution" != 'done' ]] || migration_execution='paused'
      if [[ "$migration_execution" != 'idle' ]]; then
        migrated_task_id="$(derive_upgrade_task_id "$legacy_source" "$legacy_mode" "$requested_id")"
        require_upgrade_task_id_available "$migrated_task_id"
      fi
    elif (( allow_shared_primary == 1 )) && [[ -n "$shared_primary_id" ]]; then
      migration_execution='shared-primary'
      migrated_from='shared-primary-claim'
    else
      migration_execution='idle'
    fi
    needs_upgrade=1
  fi

  upgrade_stage_dir="$project/.project-runtime/pmm/transactions/upgrade-$(pmm_now | tr -d ':-')-$$"
  mkdir -p "$upgrade_stage_dir"
  upgrade_manifest="$upgrade_stage_dir/manifest"
  : >"$upgrade_manifest"
  : >"$upgrade_stage_dir/targets"

  managed_block="$upgrade_stage_dir/managed-block.md"
  write_managed_runtime_block "$managed_block"
  base_agents="$agents_file"
  if [[ ! -f "$base_agents" ]]; then
    base_agents="$script_dir/../templates/core/AGENTS.md"
    [[ -f "$base_agents" ]] || die 'PROJECT_UPGRADE_TEMPLATE_MISSING: templates/core/AGENTS.md'
  fi
  agents_candidate="$upgrade_stage_dir/AGENTS.md"
  render_upgraded_agents "$agents_candidate" "$base_agents" "$managed_block"
  if [[ ! -f "$agents_file" ]] || ! cmp -s "$agents_candidate" "$agents_file"; then
    upgrade_register_target 'AGENTS.md'
    needs_upgrade=1
  fi

  for rel in docs/00-project-memory/current-state.md docs/00-project-memory/verifier-map.md docs/07-decisions/change-log.md; do
    [[ -f "$project/$rel" ]] && continue
    case "$rel" in
      docs/00-project-memory/current-state.md) template="$script_dir/../templates/core/current-state.md" ;;
      docs/00-project-memory/verifier-map.md) template="$script_dir/../templates/core/verifier-map.md" ;;
      docs/07-decisions/change-log.md) template="$script_dir/../templates/core/change-log.md" ;;
    esac
    [[ -f "$template" ]] || die "PROJECT_UPGRADE_TEMPLATE_MISSING: ${template#$script_dir/../}"
    mkdir -p "$upgrade_stage_dir/$(dirname "$rel")"
    cp "$template" "$upgrade_stage_dir/$rel"
    upgrade_register_target "$rel"
    needs_upgrade=1
  done

  if [[ "$migration_execution" != 'shared-primary' ]] && \
    { [[ ! -f "$active_task" ]] || ! pmm_has_schema "$active_task"; }; then
    active_candidate="$upgrade_stage_dir/docs/00-project-memory/active-task.md"
    if [[ "$migration_execution" == 'idle' ]]; then
      write_idle_task "$active_candidate" || die 'PROJECT_UPGRADE_TASK_RENDER_FAILED'
    else
      id="$migrated_task_id"
      write_migrated_task "$legacy_source" "$legacy_label" "$migration_execution" "$legacy_mode" "$active_candidate" || \
        die 'PROJECT_UPGRADE_TASK_RENDER_FAILED'
      id="$saved_id"
    fi
    upgrade_register_target 'docs/00-project-memory/active-task.md'
    result_task_file="$active_candidate"
    needs_upgrade=1
  fi

  if (( needs_upgrade == 0 )); then
    [[ -z "$result_task_file" ]] || prepare_upgrade_claim "$result_task_file"
    pending_claim_id=""
    rm -rf "$upgrade_stage_dir"
    upgrade_stage_dir=""
    upgrade_manifest=""
    printf 'PROJECT_UP_TO_DATE runtime_version=%s\n' "$current_runtime_version"
    last_upgrade_task_id="$(pmm_frontmatter_value "$result_task_file" task_id 2>/dev/null || true)"
    id="$saved_id"
    owner="$saved_owner"
    return 0
  fi

  now="$(pmm_now)"
  backup_rel=".project-runtime/pmm/backups/upgrade-$(printf '%s' "$now" | tr -d ':-')-$$"
  upgrade_backup_dir="$project/$backup_rel"
  mkdir -p "$upgrade_backup_dir"
  source_hash="$(upgrade_source_hash)" || die 'PROJECT_UPGRADE_SOURCE_HASH_FAILED'
  write_runtime_state "$upgrade_stage_dir/docs/00-project-memory/runtime-state.md" \
    "$migrated_from" "$source_hash" "$backup_rel" "$now"
  upgrade_register_target 'docs/00-project-memory/runtime-state.md'

  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    target="$project/$rel"
    existed=0
    if [[ -f "$target" ]]; then
      existed=1
      upgrade_backup_file "$rel"
    fi
    printf '%s|%s\n' "$rel" "$existed" >>"$upgrade_manifest"
  done <"$upgrade_stage_dir/targets"
  if [[ -n "$legacy_source" && -f "$legacy_source" ]]; then
    upgrade_backup_file "${legacy_source#$project/}"
  fi

  [[ -z "$result_task_file" ]] || prepare_upgrade_claim "$result_task_file"
  upgrade_rollback_active=1
  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    target="$project/$rel"
    mkdir -p "$(dirname "$target")"
    mv "$upgrade_stage_dir/$rel" "$target" || die "PROJECT_UPGRADE_COMMIT_FAILED: $rel"
  done <"$upgrade_stage_dir/targets"
  upgrade_rollback_active=0
  pending_claim_id=""
  last_upgrade_task_id="$(pmm_frontmatter_value "$active_task" task_id 2>/dev/null || true)"
  rm -rf "$upgrade_stage_dir"
  upgrade_stage_dir=""
  upgrade_manifest=""
  id="$saved_id"
  owner="$saved_owner"
  printf 'PROJECT_UPGRADED runtime_version=%s migrated_from=%s backup=%s\n' \
    "$current_runtime_version" "$migrated_from" "$backup_rel"
}

ensure_project_runtime() {
  local requested_id="${1:-}"
  local allow_shared_primary="${2:-0}"
  perform_project_upgrade "$requested_id" "$allow_shared_primary" >/dev/null
}

case "$command" in
  upgrade)
    (( auto == 1 )) || die 'ERROR: upgrade requires --auto'
    acquire_state_lock
    perform_project_upgrade "$id"
    ;;

  start)
    require_id
    require_owner
    require_git_context
    pmm_validate_scalar title "$title" || exit 1
    pmm_validate_scalar scope "$scope" || exit 1
    pmm_validate_scalar verifier "$verifier" || exit 1
    acquire_state_lock
    auto_route_isolated_start
    ensure_project_runtime '' "$work_item"
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
    if (( auto_routed == 1 )); then
      printf 'TASK_AUTO_ROUTED id=%s parent=%s branch=%s\n' \
        "$id" "$parent" "$(pmm_git_branch "$project")"
    fi
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
    require_owner
    pmm_validate_scalar next_action "$next_action" || exit 1
    acquire_state_lock
    ensure_project_runtime "$id" 1
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
    require_owner
    pmm_validate_scalar evidence "$evidence" || exit 1
    acquire_state_lock
    ensure_project_runtime "$id" 1
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
    ensure_project_runtime "$id" 1
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
    require_owner
    acquire_state_lock
    ensure_project_runtime "$id" 1
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
    require_owner
    acquire_state_lock
    ensure_project_runtime "$id" 1
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
    ensure_project_runtime "$id" 1
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
      if (( apply == 1 )); then
        require_id
        require_owner
        require_git_context
        perform_project_upgrade "$id"
        printf 'MIGRATION_APPLIED source=active-task.md task_id=%s runtime_version=%s\n' "$id" "$current_runtime_version"
      else
        printf 'MIGRATION_NOT_NEEDED schema=pmm.task/v1\n'
      fi
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
    perform_project_upgrade "$id"
    printf 'MIGRATION_APPLIED source=%s task_id=%s runtime_version=%s\n' \
      "$migration_source_label" "$id" "$current_runtime_version"
    ;;

  *)
    usage
    die "ERROR: unknown command: $command"
    ;;
esac
