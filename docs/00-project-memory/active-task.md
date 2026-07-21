---
pmm_schema: pmm.task/v1
task_id: 2026-07-21-pmm-v0.5-compat-runtime
parent_task_id: none
task_kind: primary
execution_status: active
verification_status: passed
delivery_status: ready
owner: codex-root
branch: main
base_sha: f634672c00410e95a719e83bfa5debec9c4917a7
revision: 4
verification_head: 28f16dccaf0d8f34f95d961e2b019bd9aa170fd5
verification_source_hash: 82a1ec2b5af3414bdaa20babe8237153af62ff3273f9a795210d02c948eafc5c
verified_at: 2026-07-21T07:12:10Z
updated_at: 2026-07-21T07:12:53Z
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

- Pass/Fail: pass
- Missing Evidence: none for the source and isolated installed-package release gate.
- False-Pass Risk: stale or unrelated evidence must not count.
- Next Action: publish v0.5.0, sync from public main, verify the real local install, and close the task.

## Repair

- Last Failure: none
- Failure Class: none
- Attempted Fix: none
- Next Concrete Action: publish v0.5.0, sync from public main, verify the real local install, and close the task.

## Record

- Verification Evidence: source preflight 289/289; isolated installed-package preflight 288/288; public safety passed; Doctor failures=0 warnings=0; shell syntax and diff checks passed
- Docs Updated: version metadata, bilingual release docs, runtime and compatibility guides, install and maintenance docs, current state, task template, and change log.
- Remaining Risk: public release and real local installation still require post-publication verification.
- Memory Promotion Decision: no global promotion; durable compatibility behavior is recorded in project-local source and change history.
- Last Updated: 2026-07-21T07:12:53Z
- Delivery Status: ready
- Delivery Evidence: v0.5.0 commit 28f16dc passed source and isolated installed-package preflight
