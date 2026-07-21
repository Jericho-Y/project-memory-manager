# Project Instructions

Purpose: Canonical project entrypoint and hot-path instructions for future agents.
Read when: Entering the project, starting a task, resuming work, or checking safety boundaries.
Skip when: Never skip during project work.

<!-- pmm-runtime:start -->
## PMM Runtime

- Managed runtime version: `0.5.1`.
- Before non-trivial task writes, run the installed `pmm-task.sh upgrade --project . --auto --owner <agent-id>` Upgrade Gate.
- Treat `docs/00-project-memory/runtime-state.md` as project runtime state; compatibility readers are for migration, recovery, rollback, and ambiguity review only.
- Keep exactly one primary task in `active-task.md`; concurrent writers use isolated branches/worktrees and work-item files.
<!-- pmm-runtime:end -->

## Project Identity

- Name:
- One-sentence positioning:
- Project type:
- Current phase:
- Current top objective:

## Runtime Profile

Default profile: Sprint

Use:
- Pulse for tiny edits or known-file lookups
- Sprint for normal implementation
- Project for new project or major requirements work
- Recovery for interrupted or failed-retryable work
- Audit for release, security, production, auth, payment, or compatibility risk

## Mandatory Reading Order

1. `AGENTS.md`
2. `docs/00-project-memory/current-state.md`
3. `docs/00-project-memory/active-task.md`
4. `docs/00-project-memory/verifier-map.md`
5. Task-specific source docs only when needed

## Task Reading Map

- Product/features: `PRD.md` by default; split product docs only when needed
- UI/design:
- Frontend:
- Backend/API/database:
- Auth/payment/permissions:
- PRD/requirements/source review: `PRD.md` plus concrete source artifacts
- Deployment/operations:
- Testing/bug fixing:
- Recovery:
- Audit/release:

## Execution Rules

- Keep project state in project docs, not in agent-global memory.
- Run the Workspace Gate before the Subagent Gate: inspect the primary task, branch/worktree, owner, allowed scope, and existing work items.
- Keep exactly one primary task in `active-task.md`; never append a second task contract.
- Use `docs/00-project-memory/work-items/<task-id>.md` only for branch/worktree-isolated child work.
- Put queued, paused, confirmation-gated, deployment, and release work in an optional task queue instead of the active hot path.
- Update the owned task file before broad, risky, or long-running work.
- Define Task, Harness, Verifier, Critic, Repair, and Stop Condition for substantial tasks.
- Choose Agent Mode before broad work: `solo`, `assisted`, `parallel`, or `review-only`.
- Use specialized skills or subagents only when they add value, ownership is clear, and the parent agent keeps final verification.
- Never allow two active writers to share one branch/worktree; overlapping scopes execute sequentially.
- Keep one non-idle primary claim across local worktrees, including paused/blocked tasks; require each non-idle task file to match its complete owner/branch/parent/kind claim, and never reuse an archived task ID.
- Use the lifecycle CLI for whole-file task transactions; interrupted writes must leave neither partial task state nor orphan temporary files/claims, and an interrupted takeover must restore the owner matching the durable task file.
- Treat any source-touching commit after verification as stale evidence even when a later commit reverts it.
- Keep a verified child claim at `ready-to-integrate` until its commit is merged and the primary owner runs `pmm-task.sh integrate`; then reverify the primary task.
- Do not copy full project rules into agent-specific adapters.

## Safety Boundaries

- Do not store secrets in files, docs, logs, or chat.
- Do not delete, migrate, overwrite, publish, charge, message, or change production data without confirmation.
- Do not modify payment, user, order, permission, billing, credential, or external publication behavior without confirmation.
- Do not use mock data as proof of real integration.

## Definition Of Done

- Requested behavior implemented or blocker recorded.
- Verifier run after the final change and evidence still matches the current HEAD/source hash, or limitation recorded.
- Critic checked false-pass risk.
- `active-task.md`, `current-state.md`, `change-log.md`, and source docs updated only when durable state changed.
- Remaining risk is explicit.
- Every child work item is merged, explicitly integrated, and followed by fresh primary-task verification.
