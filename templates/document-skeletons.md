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
docs/00-project-memory/runtime-state.md   -> templates/core/runtime-state.md
docs/00-project-memory/active-task.md     -> templates/core/active-task.md
docs/00-project-memory/verifier-map.md    -> templates/core/verifier-map.md
docs/07-decisions/change-log.md           -> templates/core/change-log.md
```

Recommended cold-path files:

```text
docs/00-project-memory/task-history.md     -> templates/core/task-history.md
docs/00-project-memory/failure-patterns.md -> templates/core/failure-patterns.md
```

`runtime-state.md` records the installed project runtime version but stays outside the default reading hot path. Use `active-task.md` for the current task only. Archive completed or blocked tasks to `task-history.md` when they matter later.

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

## Upgrade From Older Projects

Before substantial writes, run:

```bash
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh upgrade --project . --auto --owner <agent-id>
```

The Upgrade Gate creates a backup, writes the current `runtime-state.md`, installs the managed `AGENTS.md` runtime block, fills only missing Core Pack files, and converts one unambiguous current legacy task. It creates an idle slot for history-only projects and refuses multiple tasks, source conflicts, or conflicting statuses without changing project state.

Compatibility readers remain available for recovery, rollback, and ambiguity review. They are not the normal execution mode after the Upgrade Gate succeeds.
