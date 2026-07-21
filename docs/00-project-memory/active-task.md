---
pmm_schema: pmm.task/v1
task_id: 2026-07-21-pmm-v0.5.1-project-upgrade
parent_task_id: none
task_kind: primary
execution_status: active
verification_status: pending
delivery_status: not-requested
owner: codex-root
branch: main
base_sha: 9ec806e7e0af2aafa0ed168072409ef8f5d8ea2d
revision: 1
verification_head: none
verification_source_hash: none
verified_at: none
updated_at: 2026-07-21T07:33:12Z
---

# Active Task

Purpose: Single primary task contract, verifier, retry state, and integration checkpoint.
Read when: Starting, executing, verifying, integrating, or recovering this task.
Skip when: The task is unrelated to the current execution context.

## Status

- Title: pmm v0.5.1 automatic project upgrade gate
- Runtime Profile: Sprint
- Risk Level: normal
- Loop Budget: 3
- Current Attempt: 1
- Stop Condition: required behavior is verified or a concrete blocker is recorded.

## Task

- Objective: pmm v0.5.1 automatic project upgrade gate
- Scope: project runtime version state, automatic upgrade gate, legacy-to-current convergence, Doctor/lifecycle enforcement, docs, tests, release and local install
- Allowed Files or Areas: project runtime version state, automatic upgrade gate, legacy-to-current convergence, Doctor/lifecycle enforcement, docs, tests, release and local install
- Forbidden Actions: unrelated edits, destructive operations, publication, and production writes without explicit authorization.
- Source Artifacts: project instructions, current source, and task request.

## Harness

- Agent Mode: solo
- Owner: codex-root
- Branch: main
- Parent Task: none
- Tools: project-local tools and pmm lifecycle helpers.
- Environment Notes: one writer owns this task file and branch.

## Verifier

- Required Checks: source and installed runtime contracts; v0.1-v0.5 upgrade matrix; ambiguity fail-closed; idempotency; backup and managed-block preservation; Doctor; public safety; release preflight
- Manual Acceptance: task-specific acceptance remains explicit.
- Evidence Needed: fresh command output bound to the current HEAD and source hash.

## Critic

- Pass/Fail: pending
- Missing Evidence: required checks have not completed.
- False-Pass Risk: stale or unrelated evidence must not count.
- Next Action: execute the first unverified acceptance step.

## Repair

- Last Failure: none
- Failure Class: none
- Attempted Fix: none
- Next Concrete Action: execute the first unverified acceptance step.

## Record

- Verification Evidence: pending
- Delivery Status: not-requested
- Delivery Evidence: pending
- Docs Updated: pending
- Remaining Risk: pending verification.
- Memory Promotion Decision: pending
- Last Updated: 2026-07-21T07:33:12Z
