---
pmm_schema: pmm.task/v1
task_id: 2026-07-21-pmm-v0.5-compat-runtime
parent_task_id: none
task_kind: primary
execution_status: active
verification_status: pending
delivery_status: not-requested
owner: codex-root
branch: main
base_sha: f634672c00410e95a719e83bfa5debec9c4917a7
revision: 1
verification_head: none
verification_source_hash: none
verified_at: none
updated_at: 2026-07-21T05:36:19Z
---

# Active Task

Purpose: Single primary task contract, verifier, retry state, and integration checkpoint.
Read when: Starting, executing, verifying, integrating, or recovering this task.
Skip when: The task is unrelated to the current execution context.

## Status

- Title: pmm v0.5 compatibility-first runtime
- Runtime Profile: Sprint
- Risk Level: normal
- Loop Budget: 3
- Current Attempt: 1
- Stop Condition: required behavior is verified or a concrete blocker is recorded.

## Task

- Objective: pmm v0.5 compatibility-first runtime
- Scope: legacy parser, recovery, migration plan, Doctor compatibility diagnostics, delivery CLI, release preflight, docs, tests
- Allowed Files or Areas: legacy parser, recovery, migration plan, Doctor compatibility diagnostics, delivery CLI, release preflight, docs, tests
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

- Required Checks: runtime contract; legacy fixtures; Doctor auto/strict; migration plan; installed package; public safety; release preflight
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
- Docs Updated: pending
- Remaining Risk: pending verification.
- Memory Promotion Decision: pending
- Last Updated: 2026-07-21T05:36:19Z
