# Document Skeletons

Purpose: Router for `pmm` v0.2.0 project-memory templates.
Read when: Bootstrapping a project or selecting which template pack to create.
Skip when: Maintaining only repository scripts, release files, or public docs.

`pmm` v0.2.0 uses small template packs instead of one large default document tree. Start with the Core Pack and add optional packs only when the active runtime profile needs them.

## Core Pack

Always create the Core Pack for substantial projects:

```text
AGENTS.md                                  -> templates/core/AGENTS.md
docs/00-project-memory/current-state.md   -> templates/core/current-state.md
docs/00-project-memory/active-task.md     -> templates/core/active-task.md
docs/00-project-memory/verifier-map.md    -> templates/core/verifier-map.md
docs/07-decisions/change-log.md           -> templates/core/change-log.md
```

Recommended cold-path files:

```text
docs/00-project-memory/task-history.md     -> templates/core/task-history.md
docs/00-project-memory/failure-patterns.md -> templates/core/failure-patterns.md
```

Use `active-task.md` for the current task only. Archive completed or blocked tasks to `task-history.md` when they matter later.

## Optional Packs

Create optional packs only when facts exist and the profile needs them:

| Pack | Template | Use when |
| --- | --- | --- |
| Product | `templates/optional-packs.md` | product behavior, PRD, flows, acceptance |
| Design | `templates/optional-packs.md` | UI, UX, IA, page map, copy |
| Engineering | `templates/optional-packs.md` | architecture, API, database, integration |
| Risk | `templates/optional-packs.md` | security, auth, payment, permissions, production |
| Ops | `templates/optional-packs.md` | deployment, monitoring, support, release ops |
| Automation | `templates/optional-packs.md` | heartbeats, scheduled checks, long-running recovery |

Product Pack uses project-root `PRD.md` as the default master document. Split details into `docs/02-product/*` only when the project has enough product facts to justify separate files.

Do not create empty placeholder files just to match a tree. A missing optional pack is better than stale empty docs.

## Agent Adapters

Use adapters when a target agent has its own instruction or memory entrypoint:

| Agent | Template | Rule |
| --- | --- | --- |
| Claude Code | `templates/adapters/CLAUDE.md` | imports `AGENTS.md`; do not copy project docs |
| Hermes Agent | `templates/adapters/HERMES.md` | points back to `AGENTS.md` when Hermes loads it first |
| OpenClaw | `templates/adapters/openclaw-project-card.md` | short workspace pointer, not full project state |
| Codex nested scope | `templates/adapters/codex-subdir-AGENTS.md` | directory-specific overrides only |

Adapters are not sources of truth. They route agents to `AGENTS.md` and the Core Pack.

## Runtime Mapping

| Runtime profile | Create by default | Read by default |
| --- | --- | --- |
| Pulse | none beyond existing project entry | `AGENTS.md`, target files |
| Sprint | Core Pack | `AGENTS.md`, `current-state.md`, `active-task.md`, `verifier-map.md` |
| Project | Core Pack plus selected optional packs | Core Pack plus task source docs |
| Recovery | Core Pack plus recovery rules when needed | hot path plus recovery/change docs |
| Audit | Core Pack plus Risk/Ops docs as needed | exact artifacts, risk docs, verifier docs |

See `docs/runtime.md` for profile details.

## Self-Eval Contract

For substantial tasks, `active-task.md` must include:

```text
Task -> Agent Mode -> Harness -> Verifier -> Critic -> Repair -> Record
```

See `docs/runtime.md`.

## Migration From v0.1.x

Existing projects with `task-ledger.md` remain compatible. For lower context use:

1. Move the current task into `active-task.md`.
2. Move completed summaries into `task-history.md`.
3. Move repeated lessons into `failure-patterns.md`.
4. Keep `task-ledger.md` only as a legacy archive or compatibility bridge.

Use `docs/runtime.md` for the full workflow. The migration is light: it creates the v0.2 hot path and keeps old files available for history.
