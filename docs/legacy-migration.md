# Legacy Migration

Purpose: Convert a `pmm` v0.1 project into the v0.2 runtime hot path without losing old project memory.
Read when: A project has legacy `task-ledger.md` and should use v0.2 execution features.
Skip when: The project already has a current `active-task.md` and `verifier-map.md`.

## Goal

Compatibility is not enough. A v0.1 project should be able to use v0.2 features after a light migration:

- low-context hot path
- `active-task.md` current-task contract
- `verifier-map.md` verification map
- `task-history.md` for completed work
- `failure-patterns.md` for reusable repeated failures
- optional packs only when real project facts require them

Do not delete the legacy `task-ledger.md` during migration unless the project owner explicitly asks.

## When To Run

Run this migration when:

- the project has `docs/00-project-memory/task-ledger.md`
- `docs/00-project-memory/active-task.md` is missing, stale, or empty
- the user asks to use v0.2 behavior in an older project
- a substantial task is about to start in an older project

Do not run it for tiny one-off commands.

## Inputs

Read only what is needed:

```text
AGENTS.md
docs/00-project-memory/current-state.md
docs/00-project-memory/task-ledger.md
docs/00-project-memory/recovery-rules.md
docs/07-decisions/change-log.md
```

Search before opening broader product, design, engineering, or automation docs.

## Migration Steps

1. Confirm the project root and read `AGENTS.md`.
2. Check whether `active-task.md` and `verifier-map.md` already exist.
3. If they are missing, create them from the Core Pack templates.
4. Extract only the current active or retryable task from `task-ledger.md` into `active-task.md`.
5. Move compact completed-task summaries into `task-history.md` only when they are useful for future work.
6. Move repeated reusable failures into `failure-patterns.md` only when they are likely to happen again.
7. Keep old requirements, product, design, engineering, risk, ops, and automation docs as optional packs.
8. Add a short note in `change-log.md` that the project now has the v0.2 hot path.

## Active Task Mapping

When extracting the current task from `task-ledger.md`, map it into:

```text
Task: objective, scope, risk, allowed files, forbidden actions
Harness: tools, skills, agents, commands, environment
Verifier: checks, evidence, manual acceptance
Critic: pass/fail, missing evidence, false-pass risk
Repair: attempts, last failure, next fix
Record: final status, docs changed, memory promotion decision
```

If the legacy entry does not contain enough information, mark missing parts explicitly instead of inventing them.

## Safety Rules

- Do not rewrite the whole legacy document tree.
- Do not delete `task-ledger.md`.
- Do not migrate old completed tasks into hot-path files.
- Do not promote active task state into agent-global memory.
- Do not mark the migration complete unless `active-task.md` has a verifier.

## Done When

The project can start the next substantial task by reading:

```text
AGENTS.md
docs/00-project-memory/current-state.md
docs/00-project-memory/active-task.md
docs/00-project-memory/verifier-map.md
```

and only opening old `task-ledger.md` for history, audit, or unresolved legacy details.
