# Recovery Rules

Purpose: Rules for resuming unfinished work after interruption, compact failure, or context loss.
Read when: A task was interrupted, a compact stream error appears, or a heartbeat tries to continue work.
Skip when: The current task is complete and no recovery decision is needed.

## Recovery Goal

Continue unfinished work safely after interruption, compact failure, stream disconnect, tool error, aborted turn, or context loss. Recovery must use project-local files instead of relying on chat history.

## Project-Local Recovery State

The source of truth for recovery is inside this project folder:

- `AGENTS.md`
- `docs/00-project-memory/current-state.md`
- `docs/00-project-memory/task-ledger.md`
- `docs/00-project-memory/recovery-rules.md`
- `docs/07-decisions/change-log.md`
- `docs/08-automation/compact-disconnect-recovery.md`

Temporary recovery output, logs, local backups, and cloned checkouts belong in `.project-runtime/` or `tmp/`, not in unrelated folders.

## Retryable Interruptions

- Remote compact or context persistence errors.
- Stream disconnects before a task is complete.
- Transient network failures.
- Interrupted local commands that are safe to inspect and retry.
- Build, test, lint, typecheck, or local dependency failures that can be diagnosed.

## Remote Compact Disconnect Trigger

Treat this error as a recoverable interruption:

```text
Error running remote compact task: stream disconnected before completion: error sending request for url (https://chatgpt.com/backend-api/codex/responses/compact)
```

Do not restart from the beginning. Resume from the last safe checkpoint in `task-ledger.md`.

## Resume Protocol

1. Read `AGENTS.md`.
2. Read `current-state.md`, `task-ledger.md`, this file, and `change-log.md`.
3. Run `scripts/recovery-status.sh` if it exists.
4. Inspect the workspace and logs if the last state is ambiguous.
5. Continue from `Next Concrete Action`.
6. Re-check partial side effects before repeating commands.
7. Update `task-ledger.md` before stopping if work continues, state changes, drift is found, or a durable follow-up is created.

## No-Op Recovery Checks

If `scripts/recovery-status.sh` returns no active or retryable task, and workspace inspection shows no partial edits, no running side effects, and no new risk, stop without adding a new task-ledger entry. Routine no-op recovery checks should not create commits or durable noise.

## Retry Policy

- Retry the same failure class at most 2 times.
- Diagnose before retrying.
- Change the condition or apply a focused fix before retrying.
- Record each failed attempt, error, fix attempt, and next action in `task-ledger.md`.
- Mark the task `failed-blocked` when safe retries are exhausted.

## Non-Retryable Without Confirmation

- Real payment, refund, billing, or transaction actions.
- Production data deletion, migration, overwrite, or destructive maintenance.
- Credential, permission, user, order, or payment configuration changes.
- External publication, messaging, app store submission, or customer-visible actions.

## Heartbeat or Timed Check

Use a heartbeat or scheduled recovery check for long-running tasks when the runtime supports it. The check must:

- Read project-local memory files.
- Continue only if a task is `active` or `failed-retryable`.
- Stop when the task is `done`, `blocked`, or needs project-owner confirmation.
- Update `task-ledger.md` only when it resumes work, detects drift, creates a follow-up, or changes task status.
