# Task Queue

Purpose: Optional queue for work that is not the single current primary task.
Read when: Selecting the next task, scheduling work items, or separating delivery waits from active development.
Skip when: The project has no queued, paused, or confirmation-gated work.

## Ready

| Task ID | Parent | Priority | Readiness | Dependencies | Suggested Branch | Scope |
| --- | --- | --- | --- | --- | --- | --- |

## Waiting

| Task ID | Reason | Owner | Earliest Resume Condition | Delivery State |
| --- | --- | --- | --- | --- |

## Rules

- The queue is not an execution checkpoint; each started item gets its own task file.
- New conversations add work here instead of appending task contracts to `active-task.md`.
- `ready-to-integrate`, deployment, review, and release waits remain separate from active implementation.
- Dependencies and confirmation boundaries must be explicit before an item starts.
