---
pmm_schema: pmm.task/v1
task_id: 2026-07-18-pmm-v0.4.1-installed-contract
parent_task_id: none
task_kind: primary
execution_status: active
verification_status: passed
delivery_status: ready
owner: codex-root
branch: main
base_sha: 73ffbcf22092c336913341ca30898c0e473c58af
revision: 3
verification_head: 073ce13cbcb075480ca61dc4845db208ef800554
verification_source_hash: 82a1ec2b5af3414bdaa20babe8237153af62ff3273f9a795210d02c948eafc5c
verified_at: 2026-07-18T15:30:34Z
updated_at: 2026-07-18T15:30:43Z
---

# Active Task

Purpose: Single primary task contract, verifier, retry state, and integration checkpoint.
Read when: Starting, executing, verifying, integrating, or recovering this task.
Skip when: The task is unrelated to the current execution context.

## Status

- Title: pmm v0.4.1 installed contract hotfix
- Runtime Profile: Sprint
- Risk Level: normal
- Loop Budget: 3
- Current Attempt: 1
- Stop Condition: required behavior is verified or a concrete blocker is recorded.

## Task

- Objective: pmm v0.4.1 installed contract hotfix
- Scope: tests/pmm-runtime-contract.sh, release metadata, changelog, project memory
- Allowed Files or Areas: tests/pmm-runtime-contract.sh, release metadata, changelog, project memory
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

- Required Checks: source and installed runtime contract 233/233; public safety; Doctor; sync smoke
- Manual Acceptance: task-specific acceptance remains explicit.
- Evidence Needed: fresh command output bound to the current HEAD and source hash.

## Critic

- Pass/Fail: pass
- Missing Evidence: remote push, tag, GitHub Release, and final local installed-skill verification remain.
- False-Pass Risk: stale or unrelated evidence must not count.
- Next Action: push the verified commits, publish v0.4.1, sync from public main, and rerun the installed contract.

## Repair

- Last Failure: none
- Failure Class: none
- Attempted Fix: none
- Next Concrete Action: execute the first unverified acceptance step.

## Record

- Verification Evidence: committed source contract 233/233; simulated installed contract 233/233; isolated sync installed contract 233/233; public safety, Doctor text/JSON, shell syntax, version and diff checks passed
- Docs Updated: version metadata, bilingual changelogs, current state, and change log.
- Remaining Risk: public release and final local installed-skill verification remain.
- Memory Promotion Decision: keep the source/install layout distinction in the public contract test and changelog.
- Last Updated: 2026-07-18T15:19:09Z
