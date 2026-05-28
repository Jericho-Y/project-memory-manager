# Memory Promotion

Purpose: Defines when task observations become durable project memory or agent-global memory.
Read when: Updating project memory, agent adapters, global memory, or repeated failure rules.
Skip when: The task has no durable learning or project-state change.

## Principle

Project facts live in the project. Agent-global memory is only an adapter cache or user preference store.

Do not preserve operational task state in Claude auto memory, Hermes `MEMORY.md`, OpenClaw `MEMORY.md`, Codex global instructions, or other global stores.

## Store Here

| Information | Store in |
| --- | --- |
| Current task, retry state, next action | `active-task.md` |
| Completed task summary | `task-history.md` |
| Current project phase and stable facts | `current-state.md` |
| Repeated failure type and future rule | `failure-patterns.md` |
| Requirements, design, API, security, ops facts | matching source docs |
| Public release notes | `CHANGELOG.md` |
| Cross-project personal preference | agent-global memory, if non-sensitive |
| Project entry pointer for an external agent | agent adapter or short global memory entry |

## Promote To Project Memory

Promote when:
- the user corrected the same behavior more than once
- a command, convention, or environment rule will be reused
- a failure pattern should change future verification
- a safety or production boundary changed
- a requirement, API, database, design, or release fact changed
- a future agent would make a bad decision without it

## Do Not Promote

Do not promote:
- temporary paths
- raw command output
- full diffs
- screenshots without durable meaning
- one-off debugging guesses
- active retry count after the task is done
- sensitive values, secrets, tokens, private keys, or credentials
- private chat contents or user-identifying operational details

## Agent-Global Memory

Use global memory only for compact, stable pointers:

```text
Project <name> uses pmm. Canonical entry: <project>/AGENTS.md. Current task state stays in project docs, not global memory.
```

If the agent-global memory has a tight size limit, keep only the pointer and stable command conventions. Never copy the active task contract into global memory.

## Failure Patterns

Use `failure-patterns.md` when a mistake is likely to recur. Each entry should include:
- pattern name
- symptom
- cause
- prevention rule
- verifier or script that catches it
- date first recorded

Archive old patterns only when they are obsolete and no longer apply.
