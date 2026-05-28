# Runtime Profiles

Purpose: Defines the `pmm` runtime profiles and the minimum context each profile should load.
Read when: Starting a task, reducing context use, or deciding which project-memory pack to create.
Skip when: The active task profile is already recorded and no profile change is needed.

## Goal

Use the smallest runtime profile that can complete the task safely. Profiles control what the agent reads, writes, verifies, and promotes to durable memory.

Profiles also guide Agent Mode. Smaller profiles prefer `solo`; broader or riskier profiles may use `assisted`, `parallel`, or `review-only` when delegation has clear value and ownership.

## Profiles

| Profile | Scope | Load by default | Write by default | Loop budget |
| --- | --- | --- | --- | --- |
| Pulse | Tiny edit, lookup, known-file change | `AGENTS.md`, target files | Nothing unless facts change | 1 attempt |
| Sprint | Normal feature, bugfix, UI/API change | `AGENTS.md`, `current-state.md`, `active-task.md`, `verifier-map.md`, task source docs | `active-task.md`, `change-log.md`, source docs touched | 2-3 attempts |
| Project | New project, major feature, unclear requirements | Core Pack plus needed optional packs | Core Pack, selected packs, decisions | staged attempts |
| Recovery | Interrupted, failed, compact-disconnected, or retryable work | `AGENTS.md`, `current-state.md`, `active-task.md`, `recovery-rules.md`, `change-log.md` | `active-task.md`; archive when resolved | resume from checkpoint |
| Audit | Security, release, deployment, auth, payment, production, public compatibility | Exact source artifacts, risk docs, verifier docs | risk/decision/change records | no blind retries |

## Profile Selection

Use `Pulse` when the user asks for a small edit, one command, a simple explanation, or a known-file correction that does not alter project direction.

Use `Sprint` for most implementation tasks. This is the default for normal commercial software work.

Use `Project` only when the project needs requirements, architecture, planning, or a larger durable document system.

Use `Recovery` when there is an active or failed-retryable task, a compact/stream disconnect, partial edits, or ambiguous previous state.

Use `Audit` when the task touches high-risk boundaries, public release, repo publishing, compatibility promises, or security-sensitive behavior.

## Agent Mode Defaults

- Pulse: `solo`.
- Sprint: `solo`, `assisted`, or `review-only`.
- Project: `assisted` or `parallel` when scopes are independent.
- Recovery: `solo` unless a bounded diagnostic or review subagent reduces risk.
- Audit: `review-only` is encouraged for public, security, release, or compatibility claims when the runtime supports it.

## Pack Rules

Start with the Core Pack:

```text
AGENTS.md
docs/00-project-memory/current-state.md
docs/00-project-memory/active-task.md
docs/00-project-memory/verifier-map.md
docs/07-decisions/change-log.md
```

Create optional packs only when the current profile needs them. Do not create empty business, design, engineering, operations, or automation docs just to match a large tree.

## Profile Changes

Record profile changes in `active-task.md` when:
- the work becomes high risk
- a small task becomes a multi-file implementation
- a failed task moves into recovery
- a design or product question requires broader source docs
- a release or public compatibility claim needs audit evidence

## Anti-Patterns

- Starting a Pulse task by reading every project document.
- Creating the full commercial document tree before the project has facts to fill it.
- Keeping old completed tasks in the hot path.
- Using Recovery when there is no active task and no drift.
- Treating Audit as a way to block progress instead of a way to require evidence.
