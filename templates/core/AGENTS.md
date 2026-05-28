# Project Instructions

Purpose: Canonical project entrypoint and hot-path instructions for future agents.
Read when: Entering the project, starting a task, resuming work, or checking safety boundaries.
Skip when: Never skip during project work.

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

- Product/features:
- UI/design:
- Frontend:
- Backend/API/database:
- Auth/payment/permissions:
- PRD/requirements/source review:
- Deployment/operations:
- Testing/bug fixing:
- Recovery:
- Audit/release:

## Execution Rules

- Keep project state in project docs, not in agent-global memory.
- Update `active-task.md` before broad, risky, or long-running work.
- Define Task, Harness, Verifier, Critic, Repair, and Stop Condition for substantial tasks.
- Use specialized skills or subagents only when they add value and ownership is clear.
- Do not copy full project rules into agent-specific adapters.

## Safety Boundaries

- Do not store secrets in files, docs, logs, or chat.
- Do not delete, migrate, overwrite, publish, charge, message, or change production data without confirmation.
- Do not modify payment, user, order, permission, billing, credential, or external publication behavior without confirmation.
- Do not use mock data as proof of real integration.

## Definition Of Done

- Requested behavior implemented or blocker recorded.
- Verifier run after the final change, or limitation recorded.
- Critic checked false-pass risk.
- `active-task.md`, `current-state.md`, `change-log.md`, and source docs updated only when durable state changed.
- Remaining risk is explicit.
