---
pmm_schema: pmm.task/v1
task_id: none
parent_task_id: none
task_kind: primary
execution_status: idle
verification_status: not-required
delivery_status: not-requested
owner: none
branch: none
base_sha: none
revision: 0
verification_head: none
verification_source_hash: none
verified_at: none
updated_at: none
---

# Active Task

Purpose: Single primary task contract, verifier, retry state, and integration checkpoint.
Read when: Starting, executing, verifying, integrating, or recovering the primary task.
Skip when: The action is a tiny read-only lookup with no durable state.

## Status

- Title:
- Runtime Profile:
- Risk Level:
- Loop Budget:
- Current Attempt:
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
- Parent Task: none
- Delegated Scopes:
- Tools:
- Skills:
- Commands:
- Environment Notes: one writer owns this task file and branch.

## Verifier

- Required Checks:
- Manual Acceptance:
- Evidence Needed: fresh evidence bound to the current HEAD and source hash.

## Critic

- Pass/Fail:
- Missing Evidence:
- False-Pass Risk:
- Next Action:

## Repair

- Last Failure:
- Failure Class:
- Attempted Fix:
- Next Concrete Action:

## Record

- Verification Evidence:
- Docs Updated:
- Remaining Risk:
- Memory Promotion Decision:
- Last Updated:
