# Compact Disconnect Recovery

Purpose: Recovery prompt and procedure for remote compact or stream disconnect failures.
Read when: The compact disconnect error appears or a heartbeat is deciding whether to resume work.
Skip when: There is no interrupted active task.

## Purpose

Recover unfinished work after a remote compact, context persistence, or stream disconnect failure without depending on chat history.

## Trigger

Use this recovery path when the session reports:

```text
Error running remote compact task: stream disconnected before completion: error sending request for url (https://chatgpt.com/backend-api/codex/responses/compact)
```

## Recovery Prompt

Use this prompt for a heartbeat, scheduled check, or the next agent turn:

```text
Open the project root and read AGENTS.md first. Then read docs/00-project-memory/current-state.md, docs/00-project-memory/task-ledger.md, docs/00-project-memory/recovery-rules.md, and docs/07-decisions/change-log.md.

If scripts/recovery-status.sh exists, run it from the project root.

Continue only if the task ledger contains a task with status active or failed-retryable. If no such task exists and there are no partial edits, running side effects, or new risks, stop without adding a new ledger entry. Resume from Next Concrete Action only when recovery is needed. Before retrying any command, inspect the workspace for partial edits, partial command output, running processes, generated files, migrations, deployments, or external side effects.

Do not perform payment, production data, credential, permission, publication, destructive, or customer-visible actions without explicit project-owner confirmation.

When work continues or a durable follow-up is found, update task-ledger.md with the compact disconnect as Last Error or Interruption, the current checkpoint, the next action, retry count, and verification status before stopping.
```

## Expected Task Ledger Fields

- Task ID
- Source Request
- Status
- Documents Read
- Selected Execution Skills
- Current Checkpoint
- Next Concrete Action
- Retry Count
- Last Error or Interruption
- Verification Status
- Last Updated
