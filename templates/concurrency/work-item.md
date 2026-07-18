---
pmm_schema: pmm.task/v1
task_id: work-item-id
parent_task_id: parent-task-id
task_kind: work-item
execution_status: queued
verification_status: pending
delivery_status: not-requested
owner: owner-id
branch: feature-branch
base_sha: base-commit
revision: 1
verification_head: none
verification_source_hash: none
verified_at: none
updated_at: timestamp
---

# Work Item

Purpose: Branch-isolated child work item owned by one conversation or Agent context.
Read when: Executing, verifying, integrating, or recovering this work item.
Skip when: Working on a different task or integrating only the parent task.

## Status

- Title:
- Runtime Profile:
- Risk Level:
- Stop Condition:

## Task

- Objective:
- Scope:
- Allowed Files or Areas:
- Forbidden Actions:
- Source Artifacts:

## Harness

- Agent Mode:
- Owner:
- Branch:
- Parent Task:
- Integration Owner:
- Environment Notes: never share a branch/worktree with another active writer.

## Verifier

- Required Checks:
- Manual Acceptance:
- Evidence Needed: fresh evidence bound to this branch HEAD and source hash.

## Repair

- Last Failure:
- Next Concrete Action: commit source changes, verify on this branch, run work-item close to enter ready-to-integrate, commit that checkpoint, merge, then ask the primary owner to run integrate.

## Record

- Verification Evidence:
- Remaining Risk: the work item is not complete until its verified commit is merged and accepted by the primary owner.
- Last Updated:
