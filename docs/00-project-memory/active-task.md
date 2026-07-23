---
pmm_schema: pmm.task/v1
task_id: pmm-low-io-budget
parent_task_id: none
task_kind: primary
execution_status: active
verification_status: pending
delivery_status: not-requested
owner: codex-root
branch: main
base_sha: 283efd2ca827a6162b2a72880a2fcf9adf9dffb2
revision: 1
verification_head: none
verification_source_hash: none
verified_at: none
updated_at: 2026-07-23T15:12:48Z
---

# Active Task

Purpose: Single primary task contract, verifier, retry state, and integration checkpoint.
Read when: Starting, executing, verifying, integrating, or recovering this task.
Skip when: The task is unrelated to the current execution context.

## Status

- Title: 降低 PMM 文件读写与上下文额度成本
- Runtime Profile: Sprint
- Risk Level: normal
- Loop Budget: 3
- Current Attempt: 1
- Stop Condition: required behavior is verified or a concrete blocker is recorded.

## Task

- Objective: 降低 PMM 文件读写与上下文额度成本
- Scope: SKILL.md, docs/runtime.md, README mirrors, templates/core, runtime contract tests, public docs and changelog only; preserve all existing untracked files
- Allowed Files or Areas: SKILL.md, docs/runtime.md, README mirrors, templates/core, runtime contract tests, public docs and changelog only; preserve all existing untracked files
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

- Required Checks: targeted RED/GREEN contract assertions; bash tests/pmm-runtime-contract.sh; bash scripts/check-public-safety.sh; bash scripts/pmm-doctor.sh .; git diff --check; size and line-budget audit
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
- Last Updated: 2026-07-23T15:12:48Z
