---
pmm_schema: pmm.task/v1
task_id: 2026-07-18-pmm-v0.4-task-runtime
parent_task_id: none
task_kind: primary
execution_status: active
verification_status: pending
delivery_status: ready
owner: codex-root
branch: main
base_sha: 466276e4f8dcfbeb17986674ef19c720e8d77c4e
revision: 6
verification_head: none
verification_source_hash: none
verified_at: none
updated_at: 2026-07-18T11:27:07Z
---

# Active Task

Purpose: Single repository task for the backward-compatible `pmm` v0.4.0 task runtime upgrade.
Read when: Implementing, verifying, publishing, or recovering this upgrade.
Skip when: Looking up unrelated static repository history.

## Status

- Title: pmm v0.4.0 structured task runtime
- Runtime Profile: Audit
- Risk Level: high
- Loop Budget: 3 repair rounds per failed acceptance point
- Current Attempt: 6
- Stop Condition: backward-compatible runtime, tests, public release, and installed local sync are all freshly verified.

## Task

- Objective: prevent multi-conversation task-state corruption while preserving legacy project execution and recovery.
- Scope: structured task state, lifecycle CLI, workspace/concurrency gate, Doctor v2, Recovery v2, evidence freshness, safe migration, templates, public docs, versioning, release, and local sync.
- Allowed Files or Areas: public skill repository files and the dedicated installed `pmm` skill directory during authorized sync.
- Forbidden Actions: secrets, private paths, destructive legacy migration, unrelated file cleanup, workflow activation, repository visibility changes, or production-system operations.
- Source Artifacts: user request, current repository behavior, backward-compatibility fixtures, and recent real-project failure evidence.

## Harness

- Agent Mode: solo implementation with independent read-only review and forward-test evidence.
- Owner: codex-root
- Branch: main
- Parent Task: none
- Delegated Scopes: independent old-skill baseline, revised-skill forward test, and final release review only.
- Tools: shell, apply_patch, Git, GitHub CLI, public safety and sync helpers.
- Skills: `pmm`, `skill-creator`, `superpowers:writing-skills`, `superpowers:test-driven-development`, `superpowers:verification-before-completion`.
- Commands: runtime contract tests, shell syntax, Doctor/Recovery fixtures, public safety, link/version checks, Git checks, local sync smoke, installed-skill checks, and GitHub release verification.
- Environment Notes: existing untracked retired docs/templates belong to the user and remain outside the release commit.

## Verifier

- Required Checks: `bash tests/pmm-runtime-contract.sh`; `bash -n scripts/*.sh scripts/lib/*.sh tests/*.sh`; `bash scripts/check-public-safety.sh`; `bash scripts/pmm-doctor.sh .`; `git diff --check`; release and installed-skill verification.
- Manual Acceptance: legacy single-task and task-ledger projects remain readable; ambiguous multi-task files are reported without rewrite; concurrent writers require isolated branches/worktrees.
- Evidence Needed: observed RED then GREEN, final command outputs, commit/tag/release identity, remote checks, and installed file/version checks.

## Critic

- Pass/Fail: implementation and independent review pass; release delivery remains pending.
- Missing Evidence: committed-package verification, push, tag, GitHub Release, and installed-skill verification remain.
- False-Pass Risk: tests could pass while the installed package omits new scripts/templates or legacy status handling regresses.
- Next Action: run the final working-tree gate, commit only intended v0.4 files, and reverify the committed package.

## Repair

- Last Failure: final independent review found interrupted takeover claim drift, legacy ledger zero/multi-current selection gaps, permissive primary claim diagnostics, and missing sibling-primary Recovery.
- Failure Class: ownership rollback, backward-compatible current-task selection, strict claim integrity, and shared-state recovery completeness.
- Attempted Fix: restored takeover claims from durable owner state, parsed legacy records per task field, made non-idle primary claim mismatch fatal, and merged primary/work-item sibling claims into Recovery.
- Next Concrete Action: commit the reviewed v0.4 source after the final working-tree gate.

## Record

- Verification Evidence: TDD RED reproduced every review blocker; the expanded runtime contract passes 233/233 in the working tree, including takeover rollback, legacy current/history and multi-section field preservation, strict primary claims, sibling-primary Recovery, and failure/signal transaction cleanup. Final release checks still remain.
- Docs Updated: implementation plan, runtime, templates, install/compatibility, README mirrors, changelogs, and project memory.
- Remaining Risk: committed-package verification, local install sync, and public release remain unverified.
- Memory Promotion Decision: keep behavior in the public skill and project memory; do not promote operational task state globally.
- Last Updated: 2026-07-18T12:20:57Z
