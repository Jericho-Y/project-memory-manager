#!/usr/bin/env bash
# Purpose: Verify pmm v0.4 task-state, recovery, migration, and evidence-freshness contracts.
# Read when: Changing task runtime scripts, active-task templates, or backward compatibility.
# Skip when: The task does not change pmm runtime behavior.
set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
doctor="$repo_root/scripts/pmm-doctor.sh"
recovery="$repo_root/scripts/recovery-status.sh"
task_cli="$repo_root/scripts/pmm-task.sh"
# shellcheck source=../scripts/lib/pmm-state.sh
source "$repo_root/scripts/lib/pmm-state.sh"
tmp_parent="$repo_root/tmp"
mkdir -p "$tmp_parent"
tmp_root="$(mktemp -d "$tmp_parent/pmm-runtime-contract.XXXXXX")"
trap 'rm -rf "${tmp_root:?}"' EXIT

tests=0
failures=0
command_output=""
command_status=0

pass() {
  tests=$((tests + 1))
  printf 'PASS: %s\n' "$1"
}

fail() {
  tests=$((tests + 1))
  failures=$((failures + 1))
  printf 'FAIL: %s\n' "$1" >&2
}

run_capture() {
  command_output="$("$@" 2>&1)"
  command_status=$?
}

assert_status() {
  local expected="$1"
  local label="$2"
  if [[ "$command_status" == "$expected" ]]; then
    pass "$label"
  else
    fail "$label (expected status $expected, got $command_status; output: $command_output)"
  fi
}

assert_nonzero() {
  local label="$1"
  if (( command_status != 0 )); then
    pass "$label"
  else
    fail "$label (expected non-zero status; output: $command_output)"
  fi
}

assert_contains() {
  local needle="$1"
  local label="$2"
  if [[ "$command_output" == *"$needle"* ]]; then
    pass "$label"
  else
    fail "$label (missing '$needle'; output: $command_output)"
  fi
}

assert_not_contains() {
  local needle="$1"
  local label="$2"
  if [[ "$command_output" != *"$needle"* ]]; then
    pass "$label"
  else
    fail "$label (unexpected '$needle'; output: $command_output)"
  fi
}

assert_file_contains() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if [[ -f "$file" ]] && rg -q --fixed-strings -- "$needle" "$file"; then
    pass "$label"
  else
    fail "$label (missing '$needle' in $file)"
  fi
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label"
  else
    fail "$label (expected '$expected', got '$actual')"
  fi
}

file_hash() {
  pmm_file_hash "$1"
}

make_project() {
  local root="$1"
  mkdir -p "$root/docs/00-project-memory" "$root/docs/07-decisions" "$root/src"
  printf '# Fixture Project\n' >"$root/AGENTS.md"
  printf '# Current State\n\nFixture.\n' >"$root/docs/00-project-memory/current-state.md"
  printf '# Verifier Map\n\n## False-Pass Guards\n\n- Do not skip checks.\n' >"$root/docs/00-project-memory/verifier-map.md"
  printf '# Change Log\n' >"$root/docs/07-decisions/change-log.md"
  printf 'initial\n' >"$root/src/app.txt"
  git -C "$root" init -q
  git -C "$root" config user.name 'pmm-test'
  git -C "$root" config user.email 'pmm-test@example.invalid'
  git -C "$root" add .
  git -C "$root" commit -qm 'fixture baseline'
}

legacy_root="$tmp_root/legacy-overloaded"
make_project "$legacy_root"
printf '%s\n' \
  '# Active Task' \
  '' \
  '## Feature A' \
  '' \
  '- Task: Resume login.' \
  '- Status: In progress.' \
  '- Verifier: focused tests.' \
  '- Next Concrete Action: Write RED tests.' \
  '' \
  '## Feature B' \
  '' \
  '- Task: Release search.' \
  '- Status: Code-complete locally.' \
  '- Verifier: deployment checks.' \
  '- Next Concrete Action: Wait for release.' \
  >"$legacy_root/docs/00-project-memory/active-task.md"

run_capture bash "$doctor" "$legacy_root"
assert_nonzero 'Doctor rejects an overloaded legacy active-task file'
assert_contains 'multiple task contracts' 'Doctor reports the semantic multiplicity failure'

run_capture bash "$recovery" "$legacy_root"
assert_status 0 'Recovery inspection remains a read-only successful command'
assert_contains 'RECOVERY_NEEDED' 'Recovery maps legacy In progress to a recoverable task'
assert_contains 'Feature A' 'Recovery identifies the recoverable legacy task'

legacy_upper_root="$tmp_root/legacy-upper-status"
make_project "$legacy_upper_root"
printf '%s\n' \
  '# Active Task' \
  '' \
  '## Upper Status Task' \
  '' \
  '- Task: Preserve normalized recovery state.' \
  '- Status: ACTIVE.' \
  '- Verifier: bash tests/legacy-upper.sh' \
  >"$legacy_upper_root/docs/00-project-memory/active-task.md"
run_capture bash "$recovery" "$legacy_upper_root"
assert_contains 'RECOVERY_NEEDED' 'Recovery emits the canonical action for uppercase legacy active status'
assert_contains 'Status: active' 'Recovery reports normalized legacy status instead of the raw alias'

ledger_root="$tmp_root/legacy-ledger"
make_project "$ledger_root"
printf '%s\n' \
  '# Task Ledger' \
  '' \
  '## Ledger Feature' \
  '' \
  '- Task ID: ledger-feature' \
  '- Status: In progress' \
  '- Verifier: bash tests/legacy-ledger.sh' \
  >"$ledger_root/docs/00-project-memory/task-ledger.md"

run_capture bash "$recovery" "$ledger_root"
assert_status 0 'Recovery falls back to task-ledger.md when active-task.md is absent'
assert_contains 'RECOVERY_NEEDED' 'Legacy task-ledger active work remains recoverable'
assert_contains 'ledger-feature' 'Recovery identifies the task-ledger task ID'

ledger_hash_before="$(file_hash "$ledger_root/docs/00-project-memory/task-ledger.md")"
run_capture bash "$task_cli" migrate --project "$ledger_root" --dry-run
assert_status 0 'Migration dry-run supports a single unambiguous task-ledger fallback'
assert_contains 'source=task-ledger.md' 'Ledger migration reports its compatibility source'
run_capture bash "$task_cli" migrate --project "$ledger_root" --apply --id ledger-feature --owner ledger-agent
assert_status 0 'Migration can create structured active-task.md from one legacy ledger task'
assert_file_contains "$ledger_root/docs/00-project-memory/active-task.md" 'pmm_schema: pmm.task/v1' 'Ledger migration creates the structured primary slot'
ledger_hash_after="$(file_hash "$ledger_root/docs/00-project-memory/task-ledger.md")"
assert_equals "$ledger_hash_before" "$ledger_hash_after" 'Ledger migration preserves the original task-ledger.md unchanged'
run_capture bash "$doctor" "$ledger_root"
assert_status 0 'Doctor accepts the structured result of ledger migration'

official_v1_root="$tmp_root/official-v1-ledger"
make_project "$official_v1_root"
printf '%s\n' \
  '# Task Ledger' \
  '' \
  'Purpose: Active task checkpoint, retry state, and recovery status.' \
  '' \
  '## Active Task' \
  '' \
  '- Task ID: official-v1-task' \
  '- Source Request: migrate the official v0.1 layout' \
  '- Status: In progress' \
  '- Next Concrete Action: continue migration' \
  '- Verification Status: pending' \
  '' \
  '## Completed Tasks' \
  '' \
  '## Blocked Tasks' \
  >"$official_v1_root/docs/00-project-memory/task-ledger.md"
run_capture bash "$task_cli" migrate --project "$official_v1_root" --dry-run
assert_status 0 'Migration accepts the official v0.1 ledger with one active task section'
assert_contains 'task_contracts=1' 'Official v0.1 ledger migration counts task entries instead of section headings'
run_capture bash "$task_cli" migrate --project "$official_v1_root" --apply \
  --id official-v1-task --owner official-v1-agent
assert_status 0 'Migration applies to the official v0.1 single-active-task ledger'

official_v1_done_root="$tmp_root/official-v1-done-ledger"
make_project "$official_v1_done_root"
printf '%s\n' \
  '# Task Ledger' \
  '' \
  '## Active Task' \
  '' \
  '- Task ID: official-v1-done-task' \
  '- Status: Code-complete locally.' \
  '- Objective: revalidate before closing the current legacy task' \
  >"$official_v1_done_root/docs/00-project-memory/task-ledger.md"
run_capture bash "$task_cli" migrate --project "$official_v1_done_root" --dry-run
assert_status 0 'Migration keeps a code-complete entry in the official Active Task section current'
assert_contains 'target_execution=paused' 'Code-complete official Active Task migration fails closed to paused'

multi_entry_ledger_root="$tmp_root/multi-entry-v1-ledger"
make_project "$multi_entry_ledger_root"
printf '%s\n' \
  '# Task Ledger' \
  '' \
  '## Active Task' \
  '' \
  '- Task ID: ledger-active-a' \
  '- Status: In progress' \
  '- Objective: first active task' \
  '- Task ID: ledger-active-b' \
  '- Status: blocked' \
  '- Objective: second active task' \
  >"$multi_entry_ledger_root/docs/00-project-memory/task-ledger.md"
run_capture bash "$task_cli" migrate --project "$multi_entry_ledger_root" --dry-run
assert_nonzero 'Migration refuses multiple task entries inside one legacy ledger section'
assert_contains 'task_contracts=2' 'Legacy ledger counting treats each task field as a separate contract'

history_only_ledger_root="$tmp_root/history-only-v1-ledger"
make_project "$history_only_ledger_root"
printf '%s\n' \
  '# Task Ledger' \
  '' \
  '## Completed Tasks' \
  '' \
  '- Task ID: completed-ledger-task' \
  '- Status: completed' \
  '- Objective: already archived history' \
  >"$history_only_ledger_root/docs/00-project-memory/task-ledger.md"
run_capture bash "$task_cli" migrate --project "$history_only_ledger_root" --dry-run
assert_nonzero 'Migration refuses a legacy ledger with no current task'
assert_contains 'MIGRATION_NO_CURRENT_TASK' 'History-only ledger migration reports the missing current contract'

mixed_ledger_root="$tmp_root/mixed-v1-ledger"
make_project "$mixed_ledger_root"
printf '%s\n' \
  '# Task Ledger' \
  '' \
  '## Completed Tasks' \
  '' \
  '- Task ID: old-ledger-task' \
  '- Status: completed' \
  '- Objective: old history must remain cold' \
  '' \
  '## Active Task' \
  '' \
  '- Task ID: live-ledger-task' \
  '- Status: In progress' \
  '- Objective: migrate the live task only' \
  '- Verifier: bash tests/live-ledger.sh' \
  >"$mixed_ledger_root/docs/00-project-memory/task-ledger.md"
run_capture bash "$task_cli" migrate --project "$mixed_ledger_root" --dry-run
assert_status 0 'Migration ignores completed ledger history when one current task exists'
assert_contains 'task_contracts=1' 'Mixed ledger migration counts only the current contract'
run_capture bash "$task_cli" migrate --project "$mixed_ledger_root" --apply \
  --id live-ledger-task --owner live-ledger-agent
assert_status 0 'Migration selects the current task after completed ledger history'
assert_file_contains "$mixed_ledger_root/docs/00-project-memory/active-task.md" '- Title: live-ledger-task' 'Migration preserves the selected live ledger identity'
assert_file_contains "$mixed_ledger_root/docs/00-project-memory/active-task.md" '- Objective: migrate the live task only' 'Migration preserves the selected live ledger objective'

sectioned_legacy_root="$tmp_root/sectioned-v03-active-task"
make_project "$sectioned_legacy_root"
printf '%s\n' \
  '# Active Task' \
  '' \
  '## Status' \
  '' \
  '- Task ID: sectioned-v03-task' \
  '- Status: active' \
  '- Runtime Profile: Sprint' \
  '' \
  '## Task' \
  '' \
  '- Objective: preserve the sectioned legacy objective' \
  '- Scope: scripts and tests' \
  '' \
  '## Verifier' \
  '' \
  '- Required Checks: bash tests/sectioned-v03.sh' \
  '' \
  '## Repair' \
  '' \
  '- Next Concrete Action: resume the exact sectioned checkpoint' \
  >"$sectioned_legacy_root/docs/00-project-memory/active-task.md"
run_capture bash "$task_cli" migrate --project "$sectioned_legacy_root" --dry-run
assert_status 0 'Migration accepts one formal v0.2/v0.3 sectioned active-task contract'
assert_contains 'task_contracts=1' 'Section headings do not split one formal legacy task contract'
run_capture bash "$task_cli" migrate --project "$sectioned_legacy_root" --apply \
  --id sectioned-v03-task --owner sectioned-v03-agent
assert_status 0 'Migration applies one formal v0.2/v0.3 sectioned active task'
sectioned_hot_path="$(awk '/^## Legacy Source$/ { exit } { print }' \
  "$sectioned_legacy_root/docs/00-project-memory/active-task.md")"
if [[ "$sectioned_hot_path" == *'- Objective: preserve the sectioned legacy objective'* ]]; then
  pass 'Sectioned migration preserves the real objective in the structured hot path'
else
  fail 'Sectioned migration lost the real objective before the preserved Legacy Source'
fi
if [[ "$sectioned_hot_path" == *'- Required Checks: bash tests/sectioned-v03.sh'* ]]; then
  pass 'Sectioned migration preserves the real verifier in the structured hot path'
else
  fail 'Sectioned migration lost the real verifier before the preserved Legacy Source'
fi
if [[ "$sectioned_hot_path" == *'- Next Concrete Action: resume the exact sectioned checkpoint'* ]]; then
  pass 'Sectioned migration preserves the real recovery action in the structured hot path'
else
  fail 'Sectioned migration lost the real recovery action before the preserved Legacy Source'
fi

legacy_done_root="$tmp_root/legacy-done"
make_project "$legacy_done_root"
printf '%s\n' \
  '# Active Task' \
  '' \
  '## Completed Without Evidence' \
  '' \
  '- Task: Legacy completion.' \
  '- Status: done' \
  '- Verifier: bash tests/legacy.sh' \
  '- Verification Evidence: pending' \
  >"$legacy_done_root/docs/00-project-memory/active-task.md"
run_capture bash "$doctor" "$legacy_done_root"
assert_nonzero 'Doctor rejects legacy done state without verification evidence'
assert_contains 'done without verification evidence' 'Doctor explains the legacy false-completion failure'
run_capture bash "$task_cli" migrate --project "$legacy_done_root" --apply --id legacy-completed --owner legacy-agent
assert_status 0 'Migration converts an unverified legacy done task into a revalidation state'
assert_file_contains "$legacy_done_root/docs/00-project-memory/active-task.md" 'execution_status: paused' 'Legacy done migration pauses instead of recording a false structured completion'
run_capture bash "$doctor" "$legacy_done_root"
assert_status 0 'Doctor accepts the fail-closed migrated legacy completion'
run_capture bash "$recovery" "$legacy_done_root" --task-id legacy-completed
assert_contains 'RECOVERY_PAUSED' 'Recovery reports the migrated legacy completion as paused for revalidation'
legacy_paused_claim="$(pmm_claim_primary_task "$legacy_done_root" 2>/dev/null || true)"
assert_equals 'legacy-completed' "$legacy_paused_claim" 'A migrated paused task keeps the project primary slot reserved'
legacy_paused_worktree="$tmp_root/legacy-paused-sibling"
git -C "$legacy_done_root" worktree add -q -b feature/legacy-paused-sibling "$legacy_paused_worktree"
run_capture bash "$task_cli" start --project "$legacy_paused_worktree" --id paused-sibling-primary \
  --title 'Paused Sibling Primary' --owner sibling-agent --scope 'src/app.txt' --verifier 'bash tests/sibling.sh'
assert_nonzero 'Lifecycle rejects a new primary while another worktree has a paused primary task'
assert_contains 'PRIMARY_TASK_ALREADY_CLAIMED' 'Paused primary collision identifies the reserved project slot'
pmm_claim_release "$legacy_paused_worktree" paused-sibling-primary || true
git -C "$legacy_done_root" worktree remove --force "$legacy_paused_worktree"

legacy_idle_root="$tmp_root/legacy-idle"
make_project "$legacy_idle_root"
printf '%s\n' \
  '# Active Task' \
  '' \
  '- Task ID: old-idle-task' \
  '- Status: idle' \
  '- Verifier: none' \
  >"$legacy_idle_root/docs/00-project-memory/active-task.md"
run_capture bash "$task_cli" migrate --project "$legacy_idle_root" --apply --id old-idle-task --owner legacy-agent
assert_status 0 'Migration converts a legacy idle file into the canonical empty primary slot'
assert_file_contains "$legacy_idle_root/docs/00-project-memory/active-task.md" 'task_id: none' 'Legacy idle migration clears the old task identity'
assert_file_contains "$legacy_idle_root/docs/00-project-memory/active-task.md" 'verification_status: not-required' 'Legacy idle migration uses canonical idle verification state'
run_capture bash "$doctor" "$legacy_idle_root"
assert_status 0 'Doctor accepts the migrated legacy idle slot'

for legacy_state in paused blocked; do
  legacy_state_root="$tmp_root/legacy-$legacy_state"
  make_project "$legacy_state_root"
  printf '%s\n' \
    '# Active Task' \
    '' \
    "- Task ID: legacy-$legacy_state-task" \
    "- Status: $legacy_state" \
    '- Verifier: bash tests/legacy-state.sh' \
    >"$legacy_state_root/docs/00-project-memory/active-task.md"
  run_capture bash "$task_cli" migrate --project "$legacy_state_root" --apply \
    --id "legacy-$legacy_state-task" --owner legacy-agent
  assert_status 0 "Migration preserves a legacy $legacy_state execution state"
  assert_file_contains "$legacy_state_root/docs/00-project-memory/active-task.md" \
    "execution_status: $legacy_state" "Legacy $legacy_state migration creates a valid structured state"
  run_capture bash "$doctor" "$legacy_state_root"
  assert_status 0 "Doctor accepts the migrated legacy $legacy_state task"
  run_capture bash "$recovery" "$legacy_state_root" --task-id "legacy-$legacy_state-task"
  if [[ "$legacy_state" == 'paused' ]]; then
    assert_contains 'RECOVERY_PAUSED' 'Recovery reports a structured paused task'
  else
    assert_contains 'RECOVERY_BLOCKED' 'Recovery reports a structured blocked task'
  fi
done

legacy_hash_before="$(file_hash "$legacy_root/docs/00-project-memory/active-task.md")"
run_capture bash "$task_cli" migrate --project "$legacy_root" --dry-run
assert_nonzero 'Migration refuses to rewrite an ambiguous multi-task legacy file'
assert_contains 'MIGRATION_AMBIGUOUS' 'Migration explains why automatic conversion is unsafe'
legacy_hash_after="$(file_hash "$legacy_root/docs/00-project-memory/active-task.md")"
if [[ "$legacy_hash_before" == "$legacy_hash_after" ]]; then
  pass 'Ambiguous migration leaves the legacy file unchanged'
else
  fail 'Ambiguous migration changed the legacy file'
fi

single_root="$tmp_root/legacy-single"
make_project "$single_root"
printf '%s\n' \
  '# Active Task' \
  '' \
  '## Legacy Feature' \
  '' \
  '- Task: Preserve old projects.' \
  '- Status: active' \
  '- Verifier: bash tests/legacy.sh' \
  '- Next Concrete Action: Continue implementation.' \
  >"$single_root/docs/00-project-memory/active-task.md"

run_capture bash "$task_cli" migrate --project "$single_root" --apply --id legacy-feature --owner fixture-agent
assert_status 0 'One unambiguous legacy task can be migrated explicitly'
assert_contains 'MIGRATION_APPLIED' 'Migration reports the applied compatibility conversion'
assert_file_contains "$single_root/docs/00-project-memory/active-task.md" 'pmm_schema: pmm.task/v1' 'Migrated task has the v0.4 schema marker'
assert_file_contains "$single_root/docs/00-project-memory/active-task.md" '## Legacy Feature' 'Migration preserves the legacy human-readable body'
run_capture bash "$doctor" "$single_root"
assert_status 0 'Doctor accepts a migrated single-task active-task contract'

structured_root="$tmp_root/structured"
make_project "$structured_root"

run_capture bash "$task_cli" start \
  --project "$structured_root" \
  --id task-001 \
  --title 'Structured Runtime' \
  --owner fixture-agent \
  --scope 'src/app.txt' \
  --verifier 'bash tests/runtime.sh'
assert_status 0 'Lifecycle start creates a structured primary task'
assert_contains 'TASK_STARTED task-001' 'Lifecycle start reports the task identity'
assert_file_contains "$structured_root/docs/00-project-memory/active-task.md" 'execution_status: active' 'Structured task records canonical execution state'
assert_file_contains "$structured_root/docs/00-project-memory/active-task.md" 'verification_status: pending' 'Structured task begins with pending verification'
assert_file_contains "$structured_root/docs/00-project-memory/active-task.md" 'delivery_status: not-requested' 'Structured task separates delivery state'

run_capture bash "$task_cli" status --project "$structured_root" --id '../task-001'
assert_nonzero 'Lifecycle status rejects an invalid task ID before path lookup'
assert_contains 'ERROR: --id must use' 'Status reports the same stable task-ID validation as mutations'

run_capture bash "$task_cli" checkpoint \
  --project "$structured_root" \
  --id task-001 \
  --owner second-agent \
  --next 'Unauthorized checkpoint'
assert_nonzero 'Lifecycle refuses checkpoint from a non-owner'
assert_contains 'TASK_OWNERSHIP_MISMATCH' 'Lifecycle explains the ownership mismatch'

claim_root="$(pmm_claim_root "$structured_root")"
orphan_lock="$claim_root/.mutation-lock"
mkdir -p "$orphan_lock/stale-owner-token"
printf '%s\n' "$(uname -n)" >"$orphan_lock/stale-owner-token/host"
printf '%s\n' '2147483647' >"$orphan_lock/stale-owner-token/pid"
run_capture bash "$doctor" "$structured_root"
assert_status 0 'Doctor can inspect a project with an orphan lifecycle lock'
assert_contains 'orphan mutation lock' 'Doctor reports the orphan lifecycle lock'
run_capture bash "$task_cli" checkpoint \
  --project "$structured_root" \
  --id task-001 \
  --owner fixture-agent \
  --next 'Continue after orphan lock recovery'
assert_status 0 'Lifecycle automatically recovers a same-host lock owned by a dead process'
if [[ -d "$orphan_lock" ]]; then
  rm -rf "$orphan_lock"
fi
mkdir -p "$orphan_lock"
touch -t 200001010000 "$orphan_lock"
run_capture bash "$doctor" "$structured_root"
assert_contains 'orphan mutation lock' 'Doctor reports an old empty lock left before owner metadata was written'
run_capture bash "$task_cli" checkpoint \
  --project "$structured_root" \
  --id task-001 \
  --owner fixture-agent \
  --next 'Continue after empty lock recovery'
assert_status 0 'Lifecycle automatically recovers an old empty initialization lock'
if [[ -d "$orphan_lock" ]]; then
  rm -rf "$orphan_lock"
fi

run_capture bash "$task_cli" start \
  --project "$structured_root" \
  --id task-002 \
  --title 'Conflicting Task' \
  --owner second-agent \
  --scope 'src/other.txt' \
  --verifier 'bash tests/other.sh'
assert_nonzero 'Lifecycle refuses a second primary task in the same project state'
assert_contains 'ACTIVE_TASK_EXISTS' 'Lifecycle reports the existing primary-task collision'

run_capture bash "$task_cli" start \
  --project "$structured_root" \
  --id child-001 \
  --parent task-001 \
  --work-item \
  --title 'Same Branch Child' \
  --owner second-agent \
  --scope 'src/other.txt' \
  --verifier 'bash tests/other.sh'
assert_nonzero 'Lifecycle refuses a concurrent work item on the parent branch'
assert_contains 'SEPARATE_BRANCH_REQUIRED' 'Lifecycle explains the branch isolation requirement'

real_git="$(command -v git)"
fake_bin="$tmp_root/fake-bin"
mkdir -p "$fake_bin"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'if [[ "${1:-}" == "diff" ]]; then' \
  '  exit 42' \
  'fi' \
  "exec \"$real_git\" \"\$@\"" \
  >"$fake_bin/git"
chmod +x "$fake_bin/git"

run_capture env PATH="$fake_bin:$PATH" bash "$task_cli" verify \
  --project "$structured_root" \
  --id task-001 \
  --owner fixture-agent \
  --evidence 'must not be recorded'
assert_nonzero 'Verification fails closed when Git source diff cannot be read'
assert_contains 'SOURCE_HASH_FAILED' 'Verification reports the source-hash failure'
assert_file_contains "$structured_root/docs/00-project-memory/active-task.md" 'verification_status: pending' 'Failed source hashing does not record a false verification pass'

printf 'untracked hash input\n' >"$structured_root/src/untracked.txt"
run_capture bash -c '
  source "$1"
  pmm_file_hash() { return 1; }
  pmm_source_hash "$2"
' _ "$repo_root/scripts/lib/pmm-state.sh" "$structured_root"
assert_nonzero 'Source hashing fails closed when an untracked file cannot be hashed'
rm -f "$structured_root/src/untracked.txt"

run_capture bash "$task_cli" verify --project "$structured_root" --id task-001 --owner fixture-agent --evidence 'fixture verification'
assert_status 0 'Lifecycle records verification evidence against the current source state'
assert_contains 'TASK_VERIFIED task-001' 'Verification reports the task identity'

run_capture bash "$doctor" "$structured_root"
assert_status 0 'Doctor accepts a fresh structured task contract'
assert_contains 'PMM_DOCTOR_PASS' 'Doctor reports a clean structured runtime'

printf 'changed after verification\n' >>"$structured_root/src/app.txt"
run_capture bash "$doctor" "$structured_root"
assert_nonzero 'Doctor rejects stale verification after source changes'
assert_contains 'verification evidence is stale' 'Doctor explains the stale-evidence failure'

run_capture bash "$task_cli" checkpoint \
  --project "$structured_root" \
  --id task-001 \
  --owner fixture-agent \
  --next 'Reverify after source change'
assert_status 0 'Checkpoint updates the next action and invalidates old verification'
assert_file_contains "$structured_root/docs/00-project-memory/active-task.md" 'verification_status: pending' 'Checkpoint resets verification state to pending'

run_capture bash "$task_cli" verify --project "$structured_root" --id task-001 --owner fixture-agent --evidence 'fixture re-verification'
assert_status 0 'Task can be reverified after source changes'
git -C "$structured_root" add docs/00-project-memory/active-task.md
git -C "$structured_root" commit -qm 'record primary verification checkpoint'
run_capture bash "$doctor" "$structured_root"
assert_status 0 'Primary verification stays fresh after an operational-only checkpoint commit'

pmm_set_frontmatter "$structured_root/docs/00-project-memory/active-task.md" delivery_status ready
run_capture bash "$task_cli" close --project "$structured_root" --id task-001 --owner fixture-agent
assert_status 0 'Verified task closes and archives explicitly'
assert_contains 'TASK_CLOSED task-001' 'Close reports the archived task identity'
assert_file_contains "$structured_root/docs/00-project-memory/active-task.md" 'execution_status: idle' 'Close restores the singleton active-task slot to idle'
assert_file_contains "$structured_root/docs/00-project-memory/task-history.md" 'task-001' 'Close appends a compact task-history record'
assert_file_contains "$structured_root/docs/00-project-memory/task-history.md" 'Delivery State: ready' 'Close preserves delivery state in durable history'
assert_file_contains "$structured_root/docs/00-project-memory/task-queue.md" 'task-001' 'Close routes unfinished delivery into the task queue'

run_capture bash "$doctor" --json "$structured_root"
assert_status 0 'Doctor JSON mode succeeds for an idle structured project'
assert_contains '"result":"pass"' 'Doctor JSON mode returns a machine-readable pass result'

atomic_verify_root="$tmp_root/atomic-verify"
make_project "$atomic_verify_root"
run_capture bash "$task_cli" start --project "$atomic_verify_root" --id atomic-verify-task \
  --title 'Atomic Verify' --owner atomic-agent --scope 'src/app.txt' --verifier 'bash tests/atomic.sh'
assert_status 0 'Atomic verification fixture starts a primary task'
atomic_real_awk="$(command -v awk)"
atomic_fake_bin="$tmp_root/atomic-fake-bin"
mkdir -p "$atomic_fake_bin"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'for arg in "$@"; do' \
  '  if [[ "$arg" == "prefix=- Verification Evidence:" ]]; then' \
  '    exit 42' \
  '  fi' \
  'done' \
  "exec \"$atomic_real_awk\" \"\$@\"" \
  >"$atomic_fake_bin/awk"
chmod +x "$atomic_fake_bin/awk"
run_capture env PATH="$atomic_fake_bin:$PATH" bash "$task_cli" verify \
  --project "$atomic_verify_root" --id atomic-verify-task --owner atomic-agent \
  --evidence 'must remain uncommitted'
assert_nonzero 'Verification reports a late task-body write failure'
assert_file_contains "$atomic_verify_root/docs/00-project-memory/active-task.md" \
  'verification_status: pending' 'Failed verification update leaves the original pending state intact'
assert_file_contains "$atomic_verify_root/docs/00-project-memory/active-task.md" \
  'verification_head: none' 'Failed verification update does not expose partially committed evidence metadata'
atomic_leftover="$(find "$atomic_verify_root/docs/00-project-memory" -maxdepth 1 -name '*.pmm-txn.*' -print -quit)"
assert_equals '' "$atomic_leftover" 'Failed verification update removes staged transaction files'

archived_id_root="$tmp_root/archived-task-id"
make_project "$archived_id_root"
run_capture bash "$task_cli" start --project "$archived_id_root" --id archived-primary \
  --title 'Archived Primary' --owner archive-agent --scope 'src/app.txt' --verifier 'bash tests/archive.sh'
assert_status 0 'Archived-ID fixture starts a primary task'
run_capture bash "$task_cli" verify --project "$archived_id_root" --id archived-primary \
  --owner archive-agent --evidence 'archive fixture verification'
assert_status 0 'Archived-ID fixture records fresh evidence'
run_capture bash "$task_cli" close --project "$archived_id_root" --id archived-primary --owner archive-agent
assert_status 0 'Archived-ID fixture closes the primary task'
archived_id_worktree="$tmp_root/archived-task-id-worktree"
git -C "$archived_id_root" worktree add -q -b feature/archived-id-reuse "$archived_id_worktree"
run_capture bash "$task_cli" start --project "$archived_id_worktree" --id archived-primary \
  --title 'Reused Primary' --owner reuse-agent --scope 'src/app.txt' --verifier 'bash tests/reuse.sh'
assert_nonzero 'Lifecycle rejects a primary task ID already archived in another worktree'
assert_contains 'TASK_ID_ALREADY_ARCHIVED' 'Primary ID reuse reports the durable archive collision'
pmm_claim_release "$archived_id_worktree" archived-primary || true
rm -f "$archived_id_worktree/docs/00-project-memory/active-task.md"
printf '%s\n' \
  '# Active Task' \
  '' \
  '## Archived Legacy Retry' \
  '' \
  '- Task: Reuse a closed task ID through migration.' \
  '- Status: active' \
  '- Verifier: bash tests/reuse.sh' \
  >"$archived_id_worktree/docs/00-project-memory/active-task.md"
run_capture bash "$task_cli" migrate --project "$archived_id_worktree" --apply \
  --id archived-primary --owner reuse-agent
assert_nonzero 'Migration rejects a task ID already archived in another worktree'
assert_contains 'TASK_ID_ALREADY_ARCHIVED' 'Migration ID reuse reports the durable archive collision'
pmm_claim_release "$archived_id_worktree" archived-primary || true
git -C "$archived_id_root" worktree remove --force "$archived_id_worktree"

legacy_archive_ref_root="$tmp_root/legacy-archive-ref"
make_project "$legacy_archive_ref_root"
legacy_archive_base="$(git -C "$legacy_archive_ref_root" rev-parse HEAD)"
printf '%s\n' \
  '# Task History' \
  '' \
  '### 2026-01-01 history-only-task' \
  '' \
  '- Status: done' \
  >"$legacy_archive_ref_root/docs/00-project-memory/task-history.md"
git -C "$legacy_archive_ref_root" add docs/00-project-memory/task-history.md
git -C "$legacy_archive_ref_root" commit -qm 'record legacy archived task'
legacy_archive_ref_worktree="$tmp_root/legacy-archive-ref-worktree"
git -C "$legacy_archive_ref_root" worktree add -q -b feature/stale-legacy-history \
  "$legacy_archive_ref_worktree" "$legacy_archive_base"
run_capture bash "$task_cli" start --project "$legacy_archive_ref_worktree" --id history-only-task \
  --title 'History Only Reuse' --owner history-agent --scope 'src/app.txt' --verifier 'bash tests/history.sh'
assert_nonzero 'Lifecycle rejects an archived legacy task ID visible only in another local Git ref'
assert_contains 'TASK_ID_ALREADY_ARCHIVED' 'Cross-ref legacy history protects task ID uniqueness after upgrade'
pmm_claim_release "$legacy_archive_ref_worktree" history-only-task || true
git -C "$legacy_archive_ref_root" worktree remove --force "$legacy_archive_ref_worktree"

history_parser_root="$tmp_root/history-parser-failure"
make_project "$history_parser_root"
printf '%s\n' \
  '# Task History' \
  '' \
  '## 2026-01-01 parser-archived-task' \
  '' \
  '<!-- pmm-task-id: parser-archived-task -->' \
  >"$history_parser_root/docs/00-project-memory/task-history.md"
history_parser_fake_bin="$tmp_root/history-parser-fake-bin"
mkdir -p "$history_parser_fake_bin"
printf '%s\n' '#!/usr/bin/env bash' 'exit 2' >"$history_parser_fake_bin/rg"
chmod +x "$history_parser_fake_bin/rg"
run_capture env PATH="$history_parser_fake_bin:$PATH" bash "$task_cli" start \
  --project "$history_parser_root" --id parser-archived-task --title 'Parser Archived Reuse' \
  --owner parser-agent --scope 'src/app.txt' --verifier 'bash tests/parser.sh'
assert_nonzero 'Archived-ID detection does not treat a failed text search as no match'
assert_contains 'TASK_ID_ALREADY_ARCHIVED' 'Structured history parsing protects an archived ID when rg is unavailable or fails'
pmm_claim_release "$history_parser_root" parser-archived-task || true

archive_scan_root="$tmp_root/archive-scan-failure"
make_project "$archive_scan_root"
archive_scan_real_git="$(command -v git)"
archive_scan_fake_bin="$tmp_root/archive-scan-fake-bin"
mkdir -p "$archive_scan_fake_bin"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'for arg in "$@"; do' \
  '  if [[ "$arg" == "for-each-ref" ]]; then' \
  '    exit 42' \
  '  fi' \
  'done' \
  "exec \"$archive_scan_real_git\" \"\$@\"" \
  >"$archive_scan_fake_bin/git"
chmod +x "$archive_scan_fake_bin/git"
run_capture env PATH="$archive_scan_fake_bin:$PATH" bash "$task_cli" start \
  --project "$archive_scan_root" --id archive-scan-task --title 'Archive Scan Failure' \
  --owner archive-scan-agent --scope 'src/app.txt' --verifier 'bash tests/archive-scan.sh'
assert_nonzero 'Lifecycle fails closed when archived-ID Git ref inspection fails'
assert_contains 'TASK_ID_ARCHIVE_CHECK_FAILED' 'Archived-ID inspection failure has a stable diagnostic'
pmm_claim_release "$archive_scan_root" archive-scan-task || true

write_failure_root="$tmp_root/write-failure"
make_project "$write_failure_root"
mkdir "$write_failure_root/docs/00-project-memory/active-task.md"
run_capture bash "$task_cli" start \
  --project "$write_failure_root" \
  --id write-failure \
  --title 'Write Failure' \
  --owner write-agent \
  --scope 'src/app.txt' \
  --verifier 'bash tests/write.sh'
assert_nonzero 'Lifecycle reports an atomic task-file write failure'
assert_contains 'TASK_WRITE_FAILED' 'Lifecycle gives a stable write-failure diagnostic'
branch_claim="$(pmm_claim_task_for_branch "$write_failure_root" "$(pmm_git_branch "$write_failure_root")" 2>/dev/null || true)"
assert_equals '' "$branch_claim" 'Failed start rolls back its branch/task claim'

signal_start_root="$tmp_root/signal-start"
make_project "$signal_start_root"
signal_real_mv="$(command -v mv)"
signal_fake_bin="$tmp_root/signal-fake-bin"
mkdir -p "$signal_fake_bin"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'for arg in "$@"; do' \
  '  if [[ "$arg" == */docs/00-project-memory/active-task.md ]]; then' \
  '    kill -TERM "$PPID"' \
  '    exit 143' \
  '  fi' \
  'done' \
  "exec \"$signal_real_mv\" \"\$@\"" \
  >"$signal_fake_bin/mv"
chmod +x "$signal_fake_bin/mv"
run_capture env PATH="$signal_fake_bin:$PATH" bash "$task_cli" start \
  --project "$signal_start_root" --id signal-start-task --title 'Signal Start' \
  --owner signal-agent --scope 'src/app.txt' --verifier 'bash tests/signal.sh'
assert_nonzero 'Interrupted start exits without reporting success'
signal_claim="$(pmm_claim_task_for_branch "$signal_start_root" "$(pmm_git_branch "$signal_start_root")" 2>/dev/null || true)"
assert_equals '' "$signal_claim" 'Interrupted start rolls back the newly acquired task claim'
signal_leftover="$(find "$signal_start_root/docs/00-project-memory" -maxdepth 1 -name 'active-task.md.tmp.*' -print -quit)"
assert_equals '' "$signal_leftover" 'Interrupted start removes the uncommitted task temp file'

takeover_signal_root="$tmp_root/takeover-signal"
make_project "$takeover_signal_root"
run_capture bash "$task_cli" start --project "$takeover_signal_root" --id takeover-task \
  --title 'Takeover Signal' --owner original-agent --scope 'src/app.txt' --verifier 'bash tests/takeover.sh'
assert_status 0 'Takeover signal fixture starts with the original owner'
run_capture env PATH="$signal_fake_bin:$PATH" bash "$task_cli" resume \
  --project "$takeover_signal_root" --id takeover-task --owner replacement-agent --takeover
assert_nonzero 'Interrupted takeover exits without reporting success'
assert_file_contains "$takeover_signal_root/docs/00-project-memory/active-task.md" 'owner: original-agent' 'Interrupted takeover preserves the original task-file owner'
if pmm_claim_matches "$takeover_signal_root" takeover-task original-agent \
  "$(pmm_git_branch "$takeover_signal_root")" none primary; then
  pass 'Interrupted takeover restores the original complete claim'
else
  fail 'Interrupted takeover left the original claim missing or mismatched'
fi
takeover_leftover="$(find "$takeover_signal_root/docs/00-project-memory" -maxdepth 1 -name 'active-task.md.pmm-txn.*' -print -quit)"
assert_equals '' "$takeover_leftover" 'Interrupted takeover removes its staged task transaction'
run_capture bash "$task_cli" resume --project "$takeover_signal_root" --id takeover-task \
  --owner replacement-agent --takeover
assert_status 0 'Takeover succeeds after the interrupted attempt is rolled back'
assert_file_contains "$takeover_signal_root/docs/00-project-memory/active-task.md" 'owner: replacement-agent' 'Successful takeover commits the replacement owner'

primary_claim_doctor_root="$tmp_root/primary-claim-doctor"
make_project "$primary_claim_doctor_root"
run_capture bash "$task_cli" start --project "$primary_claim_doctor_root" --id doctor-primary \
  --title 'Doctor Primary Claim' --owner doctor-owner --scope 'src/app.txt' --verifier 'bash tests/doctor-primary.sh'
assert_status 0 'Primary-claim Doctor fixture starts a structured task'
pmm_claim_release "$primary_claim_doctor_root" doctor-primary
run_capture bash "$doctor" "$primary_claim_doctor_root"
assert_nonzero 'Doctor rejects a non-idle primary whose shared claim is missing'
assert_contains 'primary claim is missing or mismatched' 'Doctor explains the missing primary claim integrity failure'
pmm_claim_acquire "$primary_claim_doctor_root" doctor-primary wrong-owner \
  "$(pmm_git_branch "$primary_claim_doctor_root")" none primary
run_capture bash "$doctor" "$primary_claim_doctor_root"
assert_nonzero 'Doctor rejects a primary claim whose owner mismatches the task file'
assert_contains 'primary claim is missing or mismatched' 'Doctor explains the mismatched primary claim metadata'
pmm_claim_release "$primary_claim_doctor_root" doctor-primary
pmm_claim_acquire "$primary_claim_doctor_root" doctor-primary doctor-owner \
  "$(pmm_git_branch "$primary_claim_doctor_root")" none primary
run_capture bash "$doctor" "$primary_claim_doctor_root"
assert_status 0 'Doctor accepts a non-idle primary only with a complete matching claim'

race_root="$tmp_root/simultaneous-start"
make_project "$race_root"
race_results="$tmp_root/simultaneous-results"
mkdir -p "$race_results"
(
  bash "$task_cli" start --project "$race_root" --id race-a --title 'Race A' --owner race-agent-a \
    --scope 'src/a.txt' --verifier 'bash tests/a.sh' >"$race_results/a.out" 2>&1
  printf '%s\n' "$?" >"$race_results/a.status"
) &
race_pid_a=$!
(
  bash "$task_cli" start --project "$race_root" --id race-b --title 'Race B' --owner race-agent-b \
    --scope 'src/b.txt' --verifier 'bash tests/b.sh' >"$race_results/b.out" 2>&1
  printf '%s\n' "$?" >"$race_results/b.status"
) &
race_pid_b=$!
wait "$race_pid_a" || true
wait "$race_pid_b" || true
race_successes=0
[[ "$(sed -n '1p' "$race_results/a.status")" == '0' ]] && race_successes=$((race_successes + 1))
[[ "$(sed -n '1p' "$race_results/b.status")" == '0' ]] && race_successes=$((race_successes + 1))
assert_equals '1' "$race_successes" 'Exactly one simultaneous primary start acquires the singleton slot'
run_capture bash "$doctor" "$race_root"
assert_status 0 'Doctor accepts the winner after simultaneous primary starts'
race_branch="$(pmm_git_branch "$race_root")"
race_owner_id="$(pmm_claim_task_for_branch "$race_root" "$race_branch" 2>/dev/null || true)"
assert_file_contains "$race_root/docs/00-project-memory/active-task.md" "task_id: $race_owner_id" 'The singleton task file matches the atomic branch claim winner'

cross_root="$tmp_root/cross-worktree-primary"
make_project "$cross_root"
cross_worktree="$tmp_root/cross-worktree-primary-sibling"
git -C "$cross_root" worktree add -q -b feature/cross-primary "$cross_worktree"
run_capture bash "$task_cli" start --project "$cross_root" --id cross-primary \
  --title 'Cross Primary' --owner cross-agent --scope 'src/app.txt' --verifier 'bash tests/cross.sh'
assert_status 0 'Cross-worktree fixture starts the first primary task'
run_capture bash "$task_cli" start --project "$cross_worktree" --id cross-secondary \
  --title 'Cross Secondary' --owner cross-agent-two --scope 'src/app.txt' --verifier 'bash tests/cross-two.sh'
assert_nonzero 'Lifecycle rejects a second primary task from a sibling worktree'
assert_contains 'PRIMARY_TASK_ALREADY_CLAIMED' 'Cross-worktree primary collision identifies the shared claim'
pmm_claim_release "$cross_worktree" cross-secondary || true
rm -f "$cross_worktree/docs/00-project-memory/active-task.md"
printf '%s\n' \
  '# Active Task' \
  '' \
  '## Cross Legacy Task' \
  '' \
  '- Task: Migrate while another worktree owns the primary slot.' \
  '- Status: active' \
  '- Verifier: bash tests/cross-migrate.sh' \
  >"$cross_worktree/docs/00-project-memory/active-task.md"
run_capture bash "$task_cli" migrate --project "$cross_worktree" --apply \
  --id cross-migrated --owner cross-migrate-agent
assert_nonzero 'Migration rejects a second primary claim from a sibling worktree'
assert_contains 'PRIMARY_TASK_ALREADY_CLAIMED' 'Cross-worktree migration collision identifies the shared claim'
pmm_claim_release "$cross_worktree" cross-migrated || true
pmm_claim_acquire "$cross_root" cross-corrupt corrupt-agent feature/corrupt none primary
run_capture bash "$doctor" "$cross_root"
assert_nonzero 'Doctor rejects multiple primary claims in the Git common directory'
assert_contains 'multiple primary task claims' 'Doctor reports common-directory primary-claim corruption'
pmm_claim_release "$cross_root" cross-corrupt || true
git -C "$cross_root" worktree remove --force "$cross_worktree"

primary_claim_recovery_root="$tmp_root/primary-claim-recovery"
make_project "$primary_claim_recovery_root"
primary_claim_recovery_worktree="$tmp_root/primary-claim-recovery-sibling"
git -C "$primary_claim_recovery_root" worktree add -q -b feature/primary-claim-recovery "$primary_claim_recovery_worktree"
run_capture bash "$task_cli" start --project "$primary_claim_recovery_worktree" --id sibling-primary \
  --title 'Sibling Primary' --owner sibling-primary-agent --scope 'src/app.txt' --verifier 'bash tests/sibling-primary.sh'
assert_status 0 'Sibling-primary Recovery fixture starts an uncommitted primary task'
run_capture bash "$recovery" "$primary_claim_recovery_root" --task-id sibling-primary
assert_status 0 'Recovery discovers a primary task that exists only in a sibling-worktree claim'
assert_contains 'RECOVERY_CLAIM_ONLY' 'Claim-only Recovery reports the uncommitted sibling primary'
assert_contains 'Task: sibling-primary' 'Claim-only Recovery preserves the sibling primary identity'
assert_contains 'Branch: feature/primary-claim-recovery' 'Claim-only Recovery reports the sibling primary branch'
pmm_claim_release "$primary_claim_recovery_root" sibling-primary
git -C "$primary_claim_recovery_root" worktree remove --force "$primary_claim_recovery_worktree"

parallel_root="$tmp_root/parallel-cross-worktree-primary"
make_project "$parallel_root"
parallel_worktree_a="$tmp_root/parallel-primary-a"
parallel_worktree_b="$tmp_root/parallel-primary-b"
git -C "$parallel_root" worktree add -q -b feature/parallel-primary-a "$parallel_worktree_a"
git -C "$parallel_root" worktree add -q -b feature/parallel-primary-b "$parallel_worktree_b"
parallel_results="$tmp_root/parallel-primary-results"
mkdir -p "$parallel_results"
(
  bash "$task_cli" start --project "$parallel_worktree_a" --id parallel-primary-a \
    --title 'Parallel Primary A' --owner parallel-agent-a --scope 'src/a.txt' --verifier 'bash tests/a.sh' \
    >"$parallel_results/a.out" 2>&1
  printf '%s\n' "$?" >"$parallel_results/a.status"
) &
parallel_pid_a=$!
(
  bash "$task_cli" start --project "$parallel_worktree_b" --id parallel-primary-b \
    --title 'Parallel Primary B' --owner parallel-agent-b --scope 'src/b.txt' --verifier 'bash tests/b.sh' \
    >"$parallel_results/b.out" 2>&1
  printf '%s\n' "$?" >"$parallel_results/b.status"
) &
parallel_pid_b=$!
wait "$parallel_pid_a" || true
wait "$parallel_pid_b" || true
parallel_successes=0
[[ "$(sed -n '1p' "$parallel_results/a.status")" == '0' ]] && parallel_successes=$((parallel_successes + 1))
[[ "$(sed -n '1p' "$parallel_results/b.status")" == '0' ]] && parallel_successes=$((parallel_successes + 1))
assert_equals '1' "$parallel_successes" 'Exactly one simultaneous cross-worktree primary start acquires the project slot'
pmm_claim_release "$parallel_root" parallel-primary-a || true
pmm_claim_release "$parallel_root" parallel-primary-b || true
git -C "$parallel_root" worktree remove --force "$parallel_worktree_a"
git -C "$parallel_root" worktree remove --force "$parallel_worktree_b"

concurrency_root="$tmp_root/concurrency"
make_project "$concurrency_root"
run_capture bash "$task_cli" start \
  --project "$concurrency_root" \
  --id parent-001 \
  --title 'Parent Runtime' \
  --owner parent-agent \
  --scope 'src/app.txt' \
  --verifier 'bash tests/parent.sh'
assert_status 0 'Concurrency fixture starts a primary task'
concurrency_worktree="$tmp_root/concurrency-child"
git -C "$concurrency_root" worktree add -q -b feature/child "$concurrency_worktree"

run_capture bash "$task_cli" start \
  --project "$concurrency_worktree" \
  --id invalid-parent-child \
  --parent 'parent-001/../parent-001' \
  --work-item \
  --title 'Invalid Parent Path' \
  --owner invalid-parent-agent \
  --scope 'src/app.txt' \
  --verifier 'bash tests/invalid-parent.sh'
assert_nonzero 'Lifecycle rejects a non-canonical parent ID before claim path lookup'
assert_contains 'INVALID_PARENT_TASK_ID' 'Invalid work-item parent has a stable diagnostic'
pmm_claim_release "$concurrency_worktree" invalid-parent-child || true
rm -f "$concurrency_worktree/docs/00-project-memory/work-items/invalid-parent-child.md"

run_capture bash "$task_cli" start \
  --project "$concurrency_worktree" \
  --id child-002 \
  --parent parent-001 \
  --work-item \
  --title 'Branch-Isolated Child' \
  --owner child-agent \
  --scope 'src/app.txt' \
  --verifier 'bash tests/child.sh'
assert_status 0 'Lifecycle allows a work item when the uncommitted parent task exists only in another worktree'
assert_contains 'TASK_STARTED child-002' 'Work-item start reports its task identity'
assert_file_contains "$concurrency_worktree/docs/00-project-memory/work-items/child-002.md" 'task_kind: work-item' 'Branch-isolated task uses a work-item file'
assert_file_contains "$concurrency_worktree/docs/00-project-memory/work-items/child-002.md" 'branch: feature/child' 'Work item records its isolated branch'
run_capture bash "$recovery" "$concurrency_root" --task-id child-002
assert_contains 'RECOVERY_CLAIM_ONLY' 'Recovery discovers an uncommitted child from its sibling-worktree claim'
assert_contains 'Branch: feature/child' 'Claim-only Recovery reports the child worktree branch'

run_capture bash "$task_cli" verify \
  --project "$concurrency_worktree" \
  --id parent-001 \
  --owner parent-agent \
  --evidence 'wrong branch evidence'
assert_nonzero 'Lifecycle refuses to verify the parent task from a child branch'
assert_contains 'TASK_BRANCH_MISMATCH' 'Lifecycle explains the mutating branch mismatch'

run_capture bash "$task_cli" start \
  --project "$concurrency_worktree" \
  --id child-003 \
  --parent parent-001 \
  --work-item \
  --title 'Second Child On Same Branch' \
  --owner second-child-agent \
  --scope 'src/other.txt' \
  --verifier 'bash tests/second-child.sh'
assert_nonzero 'Lifecycle refuses a second work item in the same isolated branch/worktree'
assert_contains 'BRANCH_ALREADY_OWNED' 'Lifecycle reports which task already owns the child branch'

run_capture bash "$task_cli" start \
  --project "$concurrency_worktree" \
  --id parent-001 \
  --parent parent-001 \
  --work-item \
  --title 'Duplicate Parent Identity' \
  --owner child-agent \
  --scope 'src/app.txt' \
  --verifier 'bash tests/duplicate.sh'
assert_nonzero 'Lifecycle refuses a work item that reuses its parent task ID'
assert_contains 'WORK_ITEM_ID_MUST_DIFFER' 'Lifecycle explains the duplicate parent/work-item identity'

run_capture bash "$doctor" "$concurrency_worktree"
assert_status 0 'Doctor accepts parent and child tasks on distinct branches'
pmm_claim_release "$concurrency_worktree" child-002
run_capture bash "$doctor" "$concurrency_worktree"
assert_nonzero 'Doctor rejects a non-idle work item whose common-directory claim is missing'
assert_contains 'claim is missing or mismatched' 'Doctor explains the work-item claim integrity failure'
pmm_claim_acquire "$concurrency_worktree" child-002 child-agent feature/child parent-001 work-item
pmm_set_frontmatter "$concurrency_worktree/docs/00-project-memory/work-items/child-002.md" parent_task_id wrong-parent
run_capture bash "$doctor" "$concurrency_worktree"
assert_nonzero 'Doctor rejects a work item whose parent does not match the primary task'
assert_contains 'parent_task_id must match the primary task' 'Doctor explains the work-item parent mismatch'
pmm_set_frontmatter "$concurrency_worktree/docs/00-project-memory/work-items/child-002.md" parent_task_id parent-001
sed 's/task_id: child-002/task_id: child-003/' \
  "$concurrency_worktree/docs/00-project-memory/work-items/child-002.md" \
  >"$concurrency_worktree/docs/00-project-memory/work-items/child-003.md"
run_capture bash "$doctor" "$concurrency_worktree"
assert_nonzero 'Doctor rejects two active work items that claim one branch'
assert_contains 'duplicate active work-item branch' 'Doctor reports duplicate work-item branch ownership'
rm -f "$concurrency_worktree/docs/00-project-memory/work-items/child-003.md"

printf 'child implementation\n' >>"$concurrency_worktree/src/app.txt"
git -C "$concurrency_worktree" add src/app.txt docs/00-project-memory/work-items/child-002.md
git -C "$concurrency_worktree" commit -qm 'implement child work item'
printf 'parent implementation\n' >"$concurrency_root/src/parent.txt"
git -C "$concurrency_root" add src/parent.txt
git -C "$concurrency_root" commit -qm 'implement independent parent work'
run_capture bash "$task_cli" verify --project "$concurrency_root" --id parent-001 --owner parent-agent --evidence 'parent fixture verification'
assert_status 0 'Primary task can record evidence while a child work item is active'
run_capture bash "$task_cli" close --project "$concurrency_root" --id parent-001 --owner parent-agent
assert_nonzero 'Lifecycle refuses to close a primary task with an active child claim'
assert_contains 'ACTIVE_WORK_ITEMS_EXIST' 'Primary close reports the active child work item'
run_capture bash "$task_cli" verify --project "$concurrency_worktree" --id child-002 --owner child-agent --evidence 'child fixture verification'
assert_status 0 'Branch-isolated work item can record fresh verification'
run_capture bash "$task_cli" close --project "$concurrency_worktree" --id child-002 --owner child-agent
assert_status 0 'Verified work item transitions to ready-to-integrate without releasing ownership'
assert_contains 'TASK_READY_TO_INTEGRATE' 'Work-item close reports the integration gate'
assert_file_contains "$concurrency_worktree/docs/00-project-memory/work-items/child-002.md" 'execution_status: ready-to-integrate' 'Work-item close preserves an explicit pending-integration state'
run_capture bash "$recovery" "$concurrency_worktree" --task-id child-002
assert_contains 'PENDING_INTEGRATION' 'Recovery reports a ready work item as pending integration'
run_capture bash "$task_cli" close --project "$concurrency_root" --id parent-001 --owner parent-agent
assert_nonzero 'Primary remains blocked after child verification until integration is accepted'
assert_contains 'ACTIVE_WORK_ITEMS_EXIST' 'Primary close sees the ready-to-integrate child claim'
run_capture bash "$task_cli" integrate --project "$concurrency_root" --id child-002 --owner parent-agent
assert_nonzero 'Integration refuses a child whose verified commit is not in the parent branch'
git -C "$concurrency_worktree" add docs/00-project-memory/work-items/child-002.md
git -C "$concurrency_worktree" commit -qm 'mark child ready to integrate'
run_capture bash "$doctor" "$concurrency_worktree"
assert_status 0 'Operational ready-to-integrate commit preserves fresh child verification'
run_capture bash "$task_cli" close --project "$concurrency_worktree" --id child-002 --owner child-agent
assert_status 0 'Repeating work-item close is idempotent while integration remains pending'
printf 'unverified post-ready change\n' >>"$concurrency_worktree/src/app.txt"
git -C "$concurrency_worktree" add src/app.txt
git -C "$concurrency_worktree" commit -qm 'change child source after verification'
git -C "$concurrency_root" merge -q --no-ff --no-edit feature/child
run_capture bash "$task_cli" integrate --project "$concurrency_root" --id child-002 --owner parent-agent
assert_nonzero 'Integration rejects source commits added after the child verifier passed'
assert_contains 'WORK_ITEM_VERIFICATION_STALE' 'Integration explains that post-verification child source changed'
run_capture bash "$task_cli" verify --project "$concurrency_worktree" --id child-002 --owner child-agent --evidence 'child post-change verification'
assert_status 0 'Ready work item can refresh evidence after a later source commit'
run_capture bash "$task_cli" close --project "$concurrency_worktree" --id child-002 --owner child-agent
assert_status 0 'Reverified work item remains ready to integrate'
git -C "$concurrency_worktree" add docs/00-project-memory/work-items/child-002.md
git -C "$concurrency_worktree" commit -qm 'refresh child integration evidence'
printf 'transient post-verification change\n' >>"$concurrency_worktree/src/app.txt"
git -C "$concurrency_worktree" add src/app.txt
git -C "$concurrency_worktree" commit -qm 'add transient source after verification'
transient_source_commit="$(git -C "$concurrency_worktree" rev-parse HEAD)"
git -C "$concurrency_worktree" revert --no-edit "$transient_source_commit" >/dev/null
run_capture bash "$doctor" "$concurrency_worktree"
assert_nonzero 'Doctor rejects a post-verification source commit even when a later commit reverts it'
assert_contains 'verification evidence is stale' 'Doctor reports the reverted post-verification source history'
run_capture bash "$task_cli" verify --project "$concurrency_worktree" --id child-002 \
  --owner child-agent --evidence 'child source-revert verification'
assert_status 0 'Work item can refresh evidence after the source-revert sequence'
run_capture bash "$task_cli" close --project "$concurrency_worktree" --id child-002 --owner child-agent
assert_status 0 'Reverified source-revert work item remains ready to integrate'
git -C "$concurrency_worktree" add docs/00-project-memory/work-items/child-002.md
git -C "$concurrency_worktree" commit -qm 'refresh evidence after source revert'
git -C "$concurrency_root" merge -q --no-ff --no-edit feature/child
run_capture bash "$doctor" "$concurrency_root"
assert_nonzero 'Doctor invalidates primary evidence after the child merge changes main HEAD'
assert_contains 'active-task.md verification evidence is stale' 'Doctor reports the primary evidence that needs post-integration refresh'
assert_not_contains 'child-002.md ready-to-integrate evidence is stale' 'Doctor keeps merged child evidence valid against its recorded branch'
run_capture bash "$task_cli" integrate --project "$concurrency_root" --id child-002 --owner parent-agent
assert_status 0 'Primary owner accepts a work item only after its verified commit is merged'
assert_contains 'TASK_INTEGRATED child-002' 'Integration reports the accepted child identity'
if [[ ! -e "$concurrency_root/docs/00-project-memory/work-items/child-002.md" ]]; then
  pass 'Integration archives the child work-item file from the primary branch'
else
  fail 'Integration left the child work-item file active in the primary branch'
fi
assert_file_contains "$concurrency_root/docs/00-project-memory/active-task.md" 'verification_status: pending' 'Integrating a child invalidates earlier primary verification'
git -C "$concurrency_root" add \
  docs/00-project-memory/active-task.md \
  docs/00-project-memory/task-history.md \
  docs/00-project-memory/work-items/child-002.md
git -C "$concurrency_root" commit -qm 'record child integration'
reuse_child_worktree="$tmp_root/reuse-child-worktree"
git -C "$concurrency_root" worktree add -q -b feature/reuse-child "$reuse_child_worktree"
run_capture bash "$task_cli" start --project "$reuse_child_worktree" --id child-002 \
  --parent parent-001 --work-item --title 'Reused Child ID' --owner reuse-child-agent \
  --scope 'src/app.txt' --verifier 'bash tests/reuse-child.sh'
assert_nonzero 'Lifecycle rejects a work-item ID already archived by integration'
assert_contains 'TASK_ID_ALREADY_ARCHIVED' 'Work-item ID reuse reports the durable archive collision'
pmm_claim_release "$reuse_child_worktree" child-002 || true
git -C "$concurrency_root" worktree remove --force "$reuse_child_worktree"
git -C "$concurrency_root" worktree remove --force "$concurrency_worktree"
run_capture bash "$task_cli" verify --project "$concurrency_root" --id parent-001 --owner parent-agent --evidence 'parent post-integration verification'
assert_status 0 'Primary task is reverified after child integration changes its HEAD'
run_capture bash "$task_cli" close --project "$concurrency_root" --id parent-001 --owner parent-agent
assert_status 0 'Primary task closes after every child claim is released'

rename_root="$tmp_root/post-verify-source-rename"
make_project "$rename_root"
run_capture bash "$task_cli" start --project "$rename_root" --id rename-parent \
  --title 'Rename Parent' --owner rename-parent-agent --scope 'src/app.txt' --verifier 'bash tests/rename-parent.sh'
assert_status 0 'Rename fixture starts a primary task'
rename_worktree="$tmp_root/post-verify-source-rename-child"
git -C "$rename_root" worktree add -q -b feature/rename-child "$rename_worktree"
run_capture bash "$task_cli" start --project "$rename_worktree" --id rename-child \
  --parent rename-parent --work-item --title 'Rename Child' --owner rename-child-agent \
  --scope 'src/app.txt' --verifier 'bash tests/rename-child.sh'
assert_status 0 'Rename fixture starts an isolated child work item'
run_capture bash "$task_cli" verify --project "$rename_worktree" --id rename-child \
  --owner rename-child-agent --evidence 'rename child baseline verification'
assert_status 0 'Rename fixture records child evidence before the source move'
run_capture bash "$task_cli" close --project "$rename_worktree" --id rename-child --owner rename-child-agent
assert_status 0 'Rename fixture moves the verified child to ready-to-integrate'
git -C "$rename_worktree" add docs/00-project-memory/work-items/rename-child.md
git -C "$rename_worktree" commit -qm 'record rename child readiness'
git -C "$rename_worktree" mv src/app.txt docs/00-project-memory/task-history.md
git -C "$rename_worktree" commit -qm 'move verified source into an operational path'
run_capture bash "$doctor" "$rename_worktree"
assert_nonzero 'Doctor rejects source renamed into an operational path after verification'
assert_contains 'verification evidence is stale' 'Doctor reports the post-verification source rename'
git -C "$rename_root" merge -q --no-ff --no-edit feature/rename-child
run_capture bash "$task_cli" integrate --project "$rename_root" --id rename-child --owner rename-parent-agent
assert_nonzero 'Integration rejects source renamed into an operational path after verification'
assert_contains 'WORK_ITEM_VERIFICATION_STALE' 'Integration reports the renamed-source false-pass attempt'
git -C "$rename_root" worktree remove --force "$rename_worktree"

interleave_root="$tmp_root/parent-child-interleave"
make_project "$interleave_root"
run_capture bash "$task_cli" start \
  --project "$interleave_root" \
  --id interleave-parent \
  --title 'Interleave Parent' \
  --owner interleave-parent-agent \
  --scope 'src/app.txt' \
  --verifier 'bash tests/interleave-parent.sh'
assert_status 0 'Interleave fixture starts a primary task'
git -C "$interleave_root" add docs/00-project-memory/active-task.md
git -C "$interleave_root" commit -qm 'record interleave parent'
run_capture bash "$task_cli" verify --project "$interleave_root" --id interleave-parent \
  --owner interleave-parent-agent --evidence 'interleave parent verified'
assert_status 0 'Interleave parent records fresh evidence'
interleave_worktree="$tmp_root/parent-child-interleave-worktree"
git -C "$interleave_root" worktree add -q -b feature/interleave-child "$interleave_worktree"
interleave_results="$tmp_root/interleave-results"
mkdir -p "$interleave_results"
(
  bash "$task_cli" close --project "$interleave_root" --id interleave-parent --owner interleave-parent-agent \
    >"$interleave_results/close.out" 2>&1
  printf '%s\n' "$?" >"$interleave_results/close.status"
) &
interleave_close_pid=$!
(
  bash "$task_cli" start --project "$interleave_worktree" --id interleave-child \
    --parent interleave-parent --work-item --title 'Interleave Child' --owner interleave-child-agent \
    --scope 'src/app.txt' --verifier 'bash tests/interleave-child.sh' \
    >"$interleave_results/child.out" 2>&1
  printf '%s\n' "$?" >"$interleave_results/child.status"
) &
interleave_child_pid=$!
wait "$interleave_close_pid" || true
wait "$interleave_child_pid" || true
interleave_close_status="$(sed -n '1p' "$interleave_results/close.status")"
interleave_child_status="$(sed -n '1p' "$interleave_results/child.status")"
interleave_successes=0
[[ "$interleave_close_status" == '0' ]] && interleave_successes=$((interleave_successes + 1))
[[ "$interleave_child_status" == '0' ]] && interleave_successes=$((interleave_successes + 1))
assert_equals '1' "$interleave_successes" 'Parent close and child start serialize without creating an orphan'
interleave_cleanup_ok=1
if [[ "$interleave_child_status" == '0' ]]; then
  run_capture bash "$task_cli" verify --project "$interleave_worktree" --id interleave-child \
    --owner interleave-child-agent --evidence 'interleave child verified'
  [[ "$command_status" == '0' ]] || interleave_cleanup_ok=0
  run_capture bash "$task_cli" close --project "$interleave_worktree" --id interleave-child --owner interleave-child-agent
  [[ "$command_status" == '0' ]] || interleave_cleanup_ok=0
  run_capture bash "$task_cli" close --project "$interleave_root" --id interleave-parent --owner interleave-parent-agent
  [[ "$command_status" == '0' ]] || interleave_cleanup_ok=0
else
  interleave_child_claim="$(pmm_claim_task_for_branch "$interleave_worktree" feature/interleave-child 2>/dev/null || true)"
  [[ -z "$interleave_child_claim" ]] || interleave_cleanup_ok=0
fi
assert_equals '1' "$interleave_cleanup_ok" 'Serialized winner cleanup leaves no orphan task or claim'
assert_file_contains "$interleave_root/docs/00-project-memory/active-task.md" 'execution_status: idle' 'Interleave fixture converges to an idle primary slot'
git -C "$interleave_root" worktree remove --force "$interleave_worktree"

assert_file_contains "$repo_root/scripts/sync-local-skill.sh" 'scripts/pmm-task.sh' 'Maintainer sync includes the v0.4 lifecycle CLI'
assert_file_contains "$repo_root/scripts/sync-local-skill.sh" 'scripts/lib/pmm-state.sh' 'Maintainer sync includes the shared state library'
assert_file_contains "$repo_root/scripts/sync-local-skill.sh" 'tests/pmm-runtime-contract.sh' 'Maintainer sync includes the runtime contract test'
assert_file_contains "$repo_root/scripts/install-local-skill.ps1" 'pmm-task.sh' 'PowerShell install includes the v0.4 lifecycle CLI'
assert_file_contains "$repo_root/scripts/install-local-skill.ps1" 'pmm-state.sh' 'PowerShell install includes the shared state library'
assert_file_contains "$repo_root/scripts/install-local-skill.ps1" 'pmm-runtime-contract.sh' 'PowerShell install includes the runtime contract test'
assert_file_contains "$repo_root/scripts/public-safety-rules.conf" 'templates/concurrency/work-item.md' 'Public safety requires the work-item template'
assert_file_contains "$repo_root/scripts/public-safety-rules.conf" 'tests/pmm-runtime-contract.sh' 'Public safety reviews the runtime contract test'

printf 'PMM_RUNTIME_TESTS tests=%s failures=%s\n' "$tests" "$failures"
if (( failures > 0 )); then
  exit 1
fi
