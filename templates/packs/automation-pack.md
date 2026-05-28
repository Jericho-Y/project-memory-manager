# Automation Pack

Purpose: Optional automation documents for scheduled checks, heartbeats, and long-running recovery.
Read when: The project needs timed follow-up, recurring checks, or automatic recovery.
Skip when: The task ends in the current session and no automation is needed.

Create only the files that contain real facts:

```text
docs/08-automation/compact-disconnect-recovery.md
docs/08-automation/scheduled-maintenance.md
docs/08-automation/agent-runbook.md
```

Automation prompts must be self-contained and must stop when `active-task.md` is done, blocked, or requires confirmation.
