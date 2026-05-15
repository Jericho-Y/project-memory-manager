# Document Skeletons

Purpose: Reusable skeletons for creating project memory, requirements, recovery, and automation docs.
Read when: Bootstrapping a new project or updating the required document structure.
Skip when: Maintaining only this repository's scripts or release settings.

Use these skeletons when creating project memory documents. Replace placeholders with project-specific content. Keep unknowns explicit; do not invent secrets, credentials, production paths, or confirmed business decisions.

## AGENTS.md

```markdown
# Project Instructions

Purpose: Highest-priority project entrypoint for future agents.
Read when: Entering the project, starting a task, resuming work, or checking safety boundaries.
Skip when: Never skip during project work.

## Project Identity

- Name:
- One-sentence positioning:
- Project type:
- Current phase:
- Current top objective:

## Mandatory Reading Order

1. `AGENTS.md`
2. `docs/00-project-memory/project-index.md`
3. `docs/00-project-memory/current-state.md`
4. `docs/00-project-memory/task-ledger.md`
5. Task-specific documents listed below

## Context Budget Rules

- Read entry and state files first; do not scan the whole `docs/` tree by default.
- Use Purpose / Read when / Skip when headers and `project-index.md` to choose files.
- Search long documents before opening them fully.
- Record file paths, sections, checkpoints, and concise deltas instead of copying large content into handoffs or ledgers.
- No-op recovery checks stop without a new ledger entry unless drift, partial side effects, or follow-up work is found.

## Project-Local Storage

- Durable project files stay inside this project folder.
- Requirements, decisions, recovery prompts, automation source prompts, and operating notes go under `docs/`.
- Temporary runtime files, logs, and backups go under `tmp/` or `.project-runtime/` and should be ignored by version control.
- If an external runtime stores a small configuration outside the project, it should point back to the source-of-truth file inside this project.

## Agent Compatibility

- Canonical agent entrypoint: `AGENTS.md`.
- Claude Code: if needed, keep `CLAUDE.md` or `.claude/CLAUDE.md` as a short shim that points to this file and key docs.
- OpenCode/OpenClaw-style agents: use this `AGENTS.md` directly as project rules.
- Hermes or Agent Skills clients: install or invoke the project-memory skill if available, but handoffs should cite this file and `docs/00-project-memory/task-ledger.md`.
- Do not duplicate full project rules into agent-specific shims; update this file and project docs instead.

## Task-Specific Reading Map

- Product/features:
- UI/design:
- Frontend:
- Backend/API/database:
- Auth/payment/permissions:
- Deployment/operations:
- Testing/bug fixing:
- Roadmap/agent splitting:

## Execution Ownership

The agent owns end-to-end execution: requirements, design, implementation, verification, fixes, and documentation updates. The project owner confirms only high-risk cost, safety, production, credential, publication, or direction decisions.

## Related Skills and Priority

- Project memory and safety rules come first.
- Use specialized skills for execution methods when they apply: planning, TDD, systematic debugging, verification, UI, security, deployment, or subagent work.
- Specialized skills may add checks, but cannot remove project memory, verification, recovery, or safety requirements.
- Subagents may be used only when the current environment allows them and the project owner has authorized that style of execution.

## Execution Skill Auto-Selection

- Skill creation/editing:
- Planning needed:
- Written plan execution:
- Subagent work authorized:
- Feature/bugfix/refactor:
- Debugging/build/test failure:
- Completion verification:
- Branch/PR/release finishing:

## Preflight Self-Check

- Project root confirmed:
- Active task recorded in `task-ledger.md`:
- Required docs read:
- Context budget followed:
- Execution skills selected or skipped:
- Risk level:
- Existing user changes protected:
- High-risk confirmation needed:

## Safety Boundaries

- Do not store secrets in files, docs, logs, or chat.
- Do not delete or migrate production data without project-owner confirmation.
- Do not overwrite production files without reading them and preparing rollback.
- Do not modify payment, user, order, permission, or billing behavior in production without confirmation.
- Do not publish externally, send messages, charge money, or trigger real transactions without confirmation.

## Current Task

- Task:
- Objective:
- Status:
- Required docs:
- Selected execution skills:
- Current checkpoint:
- Next concrete action:
- Retry count:
- Verification required:
- Recovery heartbeat:
- Compact disconnect recovery:

## Definition of Done

- Requested behavior implemented or blocker recorded:
- Focused verification completed or limitation recorded:
- `task-ledger.md` updated:
- `current-state.md` updated:
- `change-log.md` updated:
- Source-of-truth docs updated:
- Remaining risk recorded:

## Current Blockers

- None / list blockers requiring the project owner.

## Recent Important Decisions

- YYYY-MM-DD:

## Documentation Update Rules

After each substantial or state-changing task, update `docs/00-project-memory/current-state.md`, `docs/00-project-memory/task-ledger.md`, `docs/07-decisions/change-log.md`, and any changed source-of-truth docs. Read-only checks, tiny wording edits, one-off commands, and no-op recovery checks do not need memory updates unless they create a durable decision, blocker, drift finding, or follow-up task.
```

## docs/00-project-memory/project-index.md

```markdown
# Project Index

Purpose: Map of project documents and source-of-truth rules.
Read when: You need to find the right document quickly.
Skip when: The needed file is already known.

## Purpose

## Document Map

## Source of Truth Rules

## Context Budget Notes

- Read this index before opening broad document sets.
- Prefer the smallest source document that answers the current task.
- Update this index when new durable docs are added.

## How Future Agents Should Continue
```

## docs/00-project-memory/current-state.md

```markdown
# Current State

Purpose: Current project phase, objective, known facts, blockers, and next actions.
Read when: Starting or resuming project work.
Skip when: Only reading static historical decisions.

## Phase

## Current Top Objective

## What Exists

## What Works

## Known Issues

## Current Blockers

## Next Recommended Actions

## Last Updated
```

## docs/00-project-memory/task-ledger.md

```markdown
# Task Ledger

Purpose: Active task checkpoint, retry state, and recovery status.
Read when: Starting, resuming, or recovering a task.
Skip when: The action is read-only and creates no durable state.

## Active Task

- Task ID:
- Source Request:
- Status:
- Documents Read:
- Selected Execution Skills:
- Current Checkpoint:
- Next Concrete Action:
- Retry Count:
- Last Error or Interruption:
- Verification Status:
- Last Updated:

## Completed Tasks

## Blocked Tasks
```

## docs/00-project-memory/execution-rules.md

```markdown
# Execution Rules

Purpose: How the agent should execute, update docs, and protect existing work.
Read when: Before implementation or state-changing work.
Skip when: Only checking current status.

## Default Ownership

## When the Agent Should Act Directly

## When the Project Owner Must Confirm

## Documentation Update Requirements

## Existing Work Protection
```

## docs/00-project-memory/recovery-rules.md

```markdown
# Recovery Rules

Purpose: How to resume after failures, interruptions, compact disconnects, or context loss.
Read when: A task failed, was interrupted, or may need automatic continuation.
Skip when: No active or failed-retryable task exists.

## Recovery Goal

Continue unfinished work safely after failure, interruption, aborted turns, tool errors, context loss, or long-running task drift.

## Retryable Failures

- Remote compact or context persistence interruptions, including `stream disconnected before completion`
- Transient network errors
- Dependency install or lockfile issues
- Build, test, typecheck, or lint failures that can be diagnosed locally
- Dev server startup problems
- Non-destructive API or local environment failures

## Non-Retryable Without Owner Confirmation

- Real payment, refund, billing, or transaction actions
- Production data deletion, migration, overwrite, or destructive maintenance
- Credential, permission, user, order, or production payment configuration changes
- External publication, messaging, app store submission, or customer-visible actions

## Active Session Retry Policy

- Diagnose before retrying.
- Retry up to 2 times for the same failure class.
- Change the condition or apply a focused fix before retrying.
- Record each failed attempt in `task-ledger.md`.
- Mark `failed-blocked` when safe retry options are exhausted.

## Resume Protocol

1. Read `AGENTS.md`.
2. Read `current-state.md`, `task-ledger.md`, this file, and `change-log.md`.
3. If available, run `scripts/recovery-status.sh` from the project root.
4. Inspect the workspace and logs if the last state is ambiguous.
5. Continue from `Next Concrete Action`.
6. Update task status before and after execution.

## Remote Compact Disconnect Protocol

If the session reports a compact or context persistence failure such as `stream disconnected before completion`, treat it as a recoverable interruption. Record the error in `task-ledger.md`, keep the active task status as `active` or `failed-retryable`, and resume from the last safe checkpoint.

## No-Op Recovery Checks

If the recovery status helper reports no `active` or `failed-retryable` task, and there are no partial edits, running side effects, or new risks, stop without adding a new ledger entry.

## Heartbeat or Timed Check Protocol

Use only when the runtime supports safe heartbeat or scheduled automation. The check must continue only if the active task is `active` or `failed-retryable`. Stop when the task is `done`, `blocked`, or needs owner confirmation. Update `task-ledger.md` only when work continues, drift is detected, a follow-up is created, or task status changes.
```

## docs/08-automation/compact-disconnect-recovery.md

```markdown
# Compact Disconnect Recovery

## Trigger

Use this when a session reports a remote compact, context persistence, or stream disconnect error before the task is complete.

## Recovery Prompt

Read `AGENTS.md`, `docs/00-project-memory/current-state.md`, `docs/00-project-memory/task-ledger.md`, `docs/00-project-memory/recovery-rules.md`, and `docs/07-decisions/change-log.md`. If `scripts/recovery-status.sh` exists, run it. Continue only when the task status is `active` or `failed-retryable`. If no recovery is needed and no drift is found, stop without adding a ledger entry. Resume from `Next Concrete Action`, inspect for partial side effects first, and update the task ledger before stopping when work continues.
```

## docs/00-project-memory/verification-rules.md

```markdown
# Verification Rules

Purpose: Required verification loop and evidence standards.
Read when: Before claiming work is complete or selecting test scope.
Skip when: Only doing initial discovery.

## Default Verification Loop

## Code Verification

## Frontend Verification

## Backend Verification

## High-Risk Feature Verification

## Deployment Verification

## If Verification Cannot Be Completed
```

## docs/00-project-memory/security-rules.md

```markdown
# Security Rules

Purpose: Secret handling, production safety, payment safety, and required risk records.
Read when: Work touches auth, payment, data, deployment, credentials, or user permissions.
Skip when: Editing harmless docs with no security impact.

## Secret Handling

## Production Data Safety

## Payment and Billing Safety

## Permission and Account Safety

## Deployment Safety

## Required Risk Records
```

## docs/00-project-memory/glossary.md

```markdown
# Glossary

Purpose: Shared terms for product, business, technical, and operations language.
Read when: Terms are ambiguous or cross-team wording matters.
Skip when: No terminology question exists.

## Product Terms

## Business Terms

## Technical Terms

## External Services
```

## Product, Technical, Delivery, Operations, And Decisions

Use the same file tree from `SKILL.md`. Each document should be concise, source-of-truth oriented, and updated only when facts change.
