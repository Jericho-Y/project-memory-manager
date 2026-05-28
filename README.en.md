# Project Memory Manager (`pmm`)

Language: [简体中文](README.md) | English

Current version: `v0.2.2`. See [CHANGELOG.en.md](CHANGELOG.en.md). The Chinese primary changelog is [CHANGELOG.md](CHANGELOG.md).
License: [MIT License](LICENSE).

Purpose: Public overview, installation guide, runtime model, compatibility strategy, and safety model for this skill repository.
Read when: Evaluating, installing, publishing, or first learning this skill.
Skip when: You already know the repository and only need a specific implementation file.

`pmm` is a low-context, cross-agent project runtime packaged as an Agent Skill for long-lived software projects. Its job is not to generate more project documentation; it gives agents a compact runtime contract for executing, verifying, critiquing, repairing, and recovering work with the minimum useful context.

The core v0.2.0 output is:

- `AGENTS.md`: the single project entrypoint for durable facts and collaboration rules.
- Core Pack: compact hot-path files such as `current-state.md`, `active-task.md`, `verifier-map.md`, and `change-log.md`.
- Self-Eval Loop: Task, Harness, Verifier, Critic, Repair, and Record for substantial work.
- Agent adapters: Codex, Claude Code, Hermes Agent, and OpenClaw/OpenCode point to the same project facts instead of copying separate memories.
- Memory promotion rules: promote durable facts only; keep active task state out of global memory.

Use it for commercial apps, websites, mini programs, SaaS products, desktop tools, AI products, large features, long-lived maintenance work, and tasks that need cross-agent handoff, recovery, or strict verification.
Skip it for one-off commands, tiny edits, throwaway demos, or tasks that do not need durable project memory or a verification loop.

## What's New In v0.2.0

`v0.2.0` positions `pmm` as a low-context agent execution runtime:

- Runtime Profiles: `Pulse`, `Sprint`, `Project`, `Recovery`, and `Audit` decide how much context to load.
- Core Pack: new projects start with the minimum project memory instead of a full commercial document tree.
- Optional Packs: product, design, engineering, risk, ops, and automation docs are created only when needed.
- Self-Eval Loop: substantial tasks use a `Task -> Harness -> Verifier -> Critic -> Repair -> Record` contract.
- Current task hot path: `active-task.md` and `verifier-map.md` replace the old hot-path ledger pattern.
- Cold history: completed work moves to `task-history.md`; reusable repeated failures move to `failure-patterns.md`.
- Agent adapters: Claude Code, Hermes Agent, OpenClaw/OpenCode, and Codex use short shims that point to the same project memory.
- Legacy bridge: v0.1 projects using `task-ledger.md` still work, but new projects should prefer `active-task.md`.

The v0.1.0 capabilities for requirements, project memory, verification, recovery, and document skeletons are still supported, but in v0.2.0 they become optional packs and legacy bridges. The default path is no longer to create a full document tree; start with the Core Pack and Self-Eval Loop, then add product, design, engineering, risk, ops, or automation docs only when the project has real facts that need them.

## What's New In v0.2.2

`v0.2.2` adds Subagent Routing Gate. At task start, agents choose `solo`, `assisted`, `parallel`, or `review-only`. Tiny tasks stay solo. Complex tasks, independent review, or clearly separable frontend/backend/test/docs work can use subagents when ownership is clear.

This does not require every agent runtime to support subagents. Codex-style runtimes can delegate when available. Claude Code, Hermes, OpenClaw, and other runtimes can record the same field as a task split or manual handoff plan.

## What's New In v0.2.1

`v0.2.1` adds the missing legacy migration path. When a project was created with the v0.1 `task-ledger.md`, new `pmm` runs should not stop at compatibility reading. If the user wants v0.2 behavior or a substantial task is starting, follow [docs/legacy-migration.md](docs/legacy-migration.md) to lightly create the `active-task.md`, `verifier-map.md`, and related hot-path files.

Read more:

- [docs/runtime-profiles.md](docs/runtime-profiles.md)
- [docs/self-eval-loop.md](docs/self-eval-loop.md)
- [docs/context-budget.md](docs/context-budget.md)
- [docs/agent-compatibility.md](docs/agent-compatibility.md)
- [docs/subagent-routing.md](docs/subagent-routing.md)
- [docs/legacy-migration.md](docs/legacy-migration.md)
- [docs/memory-promotion.md](docs/memory-promotion.md)
- [docs/verifier-recipes.md](docs/verifier-recipes.md)

## Core Model

`pmm` has three layers:

```text
Canonical Project Memory
  AGENTS.md + docs/00-project-memory/*

Agent Adapter Layer
  CLAUDE.md / HERMES.md / OpenClaw project card / nested AGENTS.md

Self-Eval Runtime
  Task / Agent Mode / Harness / Verifier / Critic / Repair / Record
```

The project folder is the source of truth. Agent-native memory should store only stable preferences or a short pointer to the project entrypoint, not current task state.

## Runtime Profiles

| Profile | Use for | Load by default |
| --- | --- | --- |
| Pulse | Small edits, lookups, known-file fixes | `AGENTS.md` plus target files |
| Sprint | Normal features, bug fixes, UI/API changes | Core Pack plus task source docs |
| Project | New projects, unclear requirements, long-lived product setup | Core Pack plus selected Optional Packs |
| Recovery | Interrupted work, retryable failures, compact disconnect recovery | hot path plus recovery/change docs |
| Audit | Security, release, production, payment, permissions, public compatibility | exact source artifacts plus risk/verifier docs |

## Core Pack

New projects start with:

```text
AGENTS.md
docs/00-project-memory/current-state.md
docs/00-project-memory/active-task.md
docs/00-project-memory/verifier-map.md
docs/07-decisions/change-log.md
```

Cold-path files are created only when useful:

```text
docs/00-project-memory/task-history.md
docs/00-project-memory/failure-patterns.md
```

Templates live in [templates/core](templates/core).

## Optional Packs

Use packs only when the current task needs them:

- [templates/packs/product-pack.md](templates/packs/product-pack.md): product behavior, PRD, flows, acceptance.
- [templates/packs/design-pack.md](templates/packs/design-pack.md): IA, page map, UI/UX, content.
- [templates/packs/engineering-pack.md](templates/packs/engineering-pack.md): architecture, API, database, integrations.
- [templates/packs/risk-pack.md](templates/packs/risk-pack.md): security, permissions, payment, production, risks.
- [templates/packs/ops-pack.md](templates/packs/ops-pack.md): deployment, monitoring, support, releases.
- [templates/packs/automation-pack.md](templates/packs/automation-pack.md): scheduled checks, heartbeat, long-running recovery.

Do not create empty placeholder files just to match a tree.

## Self-Eval Loop

Substantial tasks should define this contract in `active-task.md`:

```text
Task: objective, scope, risk, allowed/forbidden actions
Agent Mode: solo / assisted / parallel / review-only
Harness: tools, skills, subagents, commands, environment
Verifier: required checks, evidence, manual acceptance
Critic: true pass/fail, missing evidence, false-pass risk
Repair: failure class, attempts, next fix
Record: final status, docs changed, memory promotion decision
```

A task without a verifier cannot be marked `done`. Mark it `executed-unverified` or `blocked` instead.

## Installation

Place this repository in the target agent's skills directory and keep the directory name `pmm`:

```text
<SKILLS_ROOT>/pmm/
  SKILL.md
  VERSION
  CHANGELOG.md
  LICENSE
  docs/
  templates/
  scripts/recovery-status.sh
```

Maintainers should run:

```bash
bash scripts/check-public-safety.sh
```

The local sync script clones the public repository, runs safety checks, and syncs only into a dedicated `pmm` skill directory. Never point it at a broad directory.

## Quick Start

1. Install or copy the `pmm` skill.
2. Create project-root `AGENTS.md` from [templates/core/AGENTS.md](templates/core/AGENTS.md).
3. Create the Core Pack: `current-state.md`, `active-task.md`, `verifier-map.md`, and `change-log.md`.
4. Pick a Runtime Profile for the task.
5. Define Task/Agent Mode/Harness/Verifier in `active-task.md`.
6. Execute, verify, critique, and repair if needed.
7. Write back only durable facts; archive useful completed summaries to `task-history.md`.

## Agent Compatibility

`pmm` output is agent-neutral. If an agent cannot load `SKILL.md`, it can still follow `AGENTS.md` and the Core Pack.

- Codex: reads `AGENTS.md` natively; use nested `AGENTS.md` for scoped directory rules.
- Claude Code: use [templates/adapters/CLAUDE.md](templates/adapters/CLAUDE.md) to import `AGENTS.md`.
- Hermes Agent: prefer direct `AGENTS.md`; use [templates/adapters/HERMES.md](templates/adapters/HERMES.md) only as a short shim.
- OpenClaw/OpenCode: use [templates/adapters/openclaw-project-card.md](templates/adapters/openclaw-project-card.md) as a workspace pointer.

See [docs/agent-compatibility.md](docs/agent-compatibility.md).

## Safety Model

Do not commit real secrets, production credentials, private server inventory, customer data, payment keys, deployment tokens, private chat logs, or local paths that identify a private environment.

The project owner must confirm:

- real payment, refund, billing, or transaction actions
- production data deletion, migration, or overwrite
- credential, permission, user, order, or billing configuration changes
- external publication, messaging, app store submission, or other user-visible action

## Repository Maintenance

Before publishing, run at minimum:

```bash
bash scripts/check-public-safety.sh
bash -n scripts/*.sh
git diff --check
```

Public releases must update:

- `VERSION`
- `SKILL.md` frontmatter `version:`
- [CHANGELOG.md](CHANGELOG.md)
- [CHANGELOG.en.md](CHANGELOG.en.md)
- Chinese and English README mirrors
- local sync coverage

See [docs/release-checklist.md](docs/release-checklist.md).
