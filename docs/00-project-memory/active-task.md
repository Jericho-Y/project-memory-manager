---
pmm_schema: pmm.task/v1
task_id: pmm-worktree-auto-route
parent_task_id: none
task_kind: primary
execution_status: active
verification_status: pending
delivery_status: not-requested
owner: codex-root
branch: main
base_sha: aa78bed71caedbcec2bb4e513723d3beb9d4d7ce
revision: 2
verification_head: none
verification_source_hash: none
verified_at: none
updated_at: 2026-07-23T15:51:55Z
---

# Active Task

Purpose: Single primary task contract, verifier, retry state, and integration checkpoint.
Read when: Starting, executing, verifying, integrating, or recovering this task.
Skip when: The task is unrelated to the current execution context.

## Status

- Title: 修复多任务对话同时使用 PMM 的阻塞
- Runtime Profile: Sprint
- Risk Level: normal
- Loop Budget: 3
- Current Attempt: 1
- Stop Condition: required behavior is verified or a concrete blocker is recorded.

## Task

- Objective: 修复多任务对话同时使用 PMM 的阻塞
- Scope: scripts/pmm-task.sh, scripts/lib/pmm-state.sh, tests/pmm-runtime-contract.sh, SKILL.md, runtime and compatibility docs, templates, README mirrors, changelogs and project memory; preserve existing untracked files
- Allowed Files or Areas: scripts/pmm-task.sh, scripts/lib/pmm-state.sh, tests/pmm-runtime-contract.sh, SKILL.md, runtime and compatibility docs, templates, README mirrors, changelogs and project memory; preserve existing untracked files
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

- Required Checks: targeted RED/GREEN concurrency contract; full source and installed runtime contracts; public safety; Doctor; shell syntax; git diff check
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
- Next Concrete Action: Commit verified source changes, push main, sync the installed skill, and run installed-package preflight.

## Record

- Verification Evidence: pending after checkpoint
- Delivery Status: not-requested
- Delivery Evidence: pending
- Docs Updated: pending
- Remaining Risk: pending verification.
- Memory Promotion Decision: pending
- Last Updated: 2026-07-23T15:38:47Z
