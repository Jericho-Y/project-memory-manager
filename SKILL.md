---
name: pmm
description: Use when a software project or large feature spans multiple sessions, agents, branches, recovery checkpoints, or verification stages and needs durable project-local task state; skip one-off, tiny, single-session work.
version: 0.4.0
compatibility: Agent Skills SKILL.md format; durable project output is AGENTS.md plus project-local docs, usable by Codex, Claude Code, Hermes Agent, OpenClaw/OpenCode-style agents, and other AGENTS.md-aware coding agents. No runtime dependencies.
---

# Project Memory Manager

Purpose: Define a low-context project memory runtime with self-evaluating execution, recovery, verification, and cross-agent adapters.
Read when: Starting, structuring, continuing, recovering, or maintaining a long-lived project or this skill.
Skip when: The task is a one-off command, tiny edit, or unrelated to durable project memory.

## Operating Model

`pmm` is a portable project runtime, not a documentation generator. It keeps project facts in the project folder and lets each agent runtime use a small adapter to find the same source of truth.

Use this priority:

```text
workspace/project instructions -> pmm -> specialized execution skills -> tool docs
```

The canonical project entrypoint is always:

```text
AGENTS.md
```

Agent-specific files such as `CLAUDE.md`, `.hermes.md`, OpenClaw workspace notes, or handoff prompts are adapters. They should point to `AGENTS.md` and hot project-memory files instead of copying full project rules.

## Runtime Profiles

Classify every non-trivial task before reading broadly. Use the smallest profile that can complete the work safely.

| Profile | Use when | Default hot path | Writes durable memory |
| --- | --- | --- | --- |
| Pulse | Small edit, lookup, focused fix, low risk | `AGENTS.md`, target files | Only if a durable fact changes |
| Sprint | Feature, bugfix, UI/API change, normal risk | `AGENTS.md`, `current-state.md`, `active-task.md`, task source docs | Yes |
| Project | New project, major feature, incomplete requirements | Core pack plus needed packs | Yes |
| Recovery | Interrupted, failed, compact-disconnected, or retryable task | `AGENTS.md`, `current-state.md`, `active-task.md`, `recovery-rules.md`, `change-log.md` | Yes |
| Audit | Security, release, deployment, auth, payment, production data, public compatibility | Risk docs plus exact source artifacts | Yes |

Runtime details live in `docs/runtime.md`.

## Hot Path

Use the hot path before opening broad docs:

```text
AGENTS.md
docs/00-project-memory/current-state.md
docs/00-project-memory/active-task.md
docs/00-project-memory/verifier-map.md
```

`active-task.md` is one primary task slot, not a task list. When a second conversation or Agent needs independent write access, run the Workspace Gate in `docs/runtime.md`: use a separate branch/worktree and `docs/00-project-memory/work-items/<task-id>.md`, or queue the work. Never append another task contract to `active-task.md`.

Load these only when concurrency or scheduling exists:

```text
docs/00-project-memory/work-items/<task-id>.md
docs/00-project-memory/task-queue.md
```

Use `task-history.md`, `failure-patterns.md`, product/design/technical docs, and release history only when the active task requires them. Search headings and purpose headers before reading full files.

For existing projects that still use `task-ledger.md`, keep compatibility reading available. If the project wants structured v0.4 behavior, run the migration dry-run in `docs/runtime.md`; migration counts individual task fields, converts exactly one current task, keeps completed history cold, preserves v0.2/v0.3 multi-section objective/verifier/next-action fields, and refuses zero-current or multi-current ledgers without rewriting them.

## Core Pack And Optional Packs

New projects start with the Core Pack only:

```text
AGENTS.md
docs/00-project-memory/current-state.md
docs/00-project-memory/active-task.md
docs/00-project-memory/verifier-map.md
docs/07-decisions/change-log.md
```

Add optional packs only when the work needs them:

| Pack | Add when |
| --- | --- |
| Product | Product behavior, PRD, user flows, acceptance criteria |
| Design | IA, UI, copy, visual system, page map |
| Engineering | Architecture, API, database, integrations |
| Risk | Security, auth, payment, permissions, production data, risks |
| Ops | Deployment, monitoring, support, release operations |
| Automation | Heartbeats, scheduled checks, compact recovery, long-running tasks |

Templates live under `templates/core/`, `templates/optional-packs.md`, and `templates/adapters/`. `templates/document-skeletons.md` is a router, not a dump of every document body.

For tiny work, do not force the Core Pack. Use No PMM for one-off low-risk changes, or a Pulse Card in an existing entrypoint/task record when a short objective and verifier are enough.

## Self-Eval Loop

Every substantial execution task uses this loop:

```text
Classify -> Workspace Gate -> Subagent Gate -> Load -> Contract -> Execute -> Verify -> Critique -> Repair -> Record -> Promote
```

Workspace Gate checks the primary task, owner, branch/worktree, source scope, and active work items before any write. Two active writers never share one branch/worktree; overlapping scopes run sequentially.

Subagent Gate is a lightweight decision, not a default fan-out. Use solo mode for tiny or tightly coupled work. Use assisted, parallel, or review-only mode only when the subtask is bounded, useful, and has clear ownership. Details live in `docs/runtime.md`.

Record the task contract in `active-task.md`:

```text
Task: objective, scope, risk, allowed files, forbidden actions
Agent Mode: solo, assisted, parallel, or review-only; reason; delegated scopes
Harness: tools, skills, agents, commands, environment
Verifier: checks, evidence, manual acceptance
Critic: pass/fail, missing evidence, false-pass risk
Repair: attempts, last failure, next fix
Record: final status, docs changed, memory promotion decision
```

Machine state uses `pmm.task/v1` frontmatter with three independent axes:
- `execution_status`: `idle`, `queued`, `active`, `paused`, `blocked`, `ready-to-integrate`, `done`
- `verification_status`: `pending`, `partial`, `passed`, `stale`, `failed`, `not-required`
- `delivery_status`: `not-requested`, `waiting-confirmation`, `ready`, `deployed`, `released`

Use `scripts/pmm-task.sh` for lifecycle changes. Every mutation requires the recorded owner and branch; only explicit `resume --takeover` changes ownership. Local lifecycle writes are serialized through the Git common directory and committed as whole-file staged transactions; failures and signals clean temporary state, roll back uncommitted new claims, and restore an interrupted takeover to the claim owner matching the durable task file. One non-idle primary claim is permitted across local worktrees, so paused and blocked primary tasks retain that slot. Doctor requires every non-idle task file to have a complete matching claim. Archived task IDs cannot be reused, including IDs found in marker-less legacy history reachable from local refs. `verify` binds evidence to the current Git HEAD and source hash and fails closed on Git/hash errors; any later source-touching commit makes evidence stale even if another commit reverts it or renames the source into an operational path. A work-item `close` keeps its claim and moves it to `ready-to-integrate`; after the verified commit is merged, the primary owner runs `integrate`, re-verifies the primary task, and only then closes it. Primary close preserves all three state axes in history and queues unfinished delivery follow-up.

Verifier first: a task without a verifier and fresh evidence cannot close. Record blocked execution with `execution_status: blocked`; record incomplete or failed verification with `verification_status: pending` or `failed`.

Critic must check for false completion:
- skipped checks reported as passed
- tests changed to fit broken behavior
- deleted or weakened validation
- mock data used as proof of real integration
- surface UI changed while product state is invalid
- unverified behavior described as verified

Full loop, verifier, repair, and promotion details live in `docs/runtime.md`.

## Memory Promotion

Keep operational task state out of agent-global memory. Do not promote active task details, retry state, temporary paths, transient failures, raw logs, or one-off decisions into Claude auto memory, Hermes `MEMORY.md`, OpenClaw `MEMORY.md`, Codex global instructions, or similar stores.

Promote only durable facts:
- repeated user corrections
- project conventions future agents must know
- stable commands or environment constraints
- safety, release, or production rules
- repeated failure patterns that should alter future behavior

When memory is promoted, prefer project-local files first. Agent-global memory should hold only a short pointer to the project entrypoint or a stable cross-project preference. See `docs/runtime.md`.

## Cross-Agent Compatibility

Generated project memory must remain useful across Codex, Claude Code, Hermes Agent, OpenClaw/OpenCode-style agents, and AGENTS.md-aware tools.

Rules:
- `AGENTS.md` is the canonical project entrypoint.
- `CLAUDE.md`, `.hermes.md`, OpenClaw project cards, and handoffs are adapters.
- Adapters cite paths and startup behavior; they do not copy full docs.
- Structured state is optional for legacy projects: old single-task `active-task.md` and `task-ledger.md` remain readable. Run `pmm-task.sh migrate --dry-run` before conversion; ambiguous multi-task files are never rewritten automatically.
- Subagent routing is best-effort: agents with subagent tools may delegate; agents without them record solo mode or a manual handoff.
- Root `AGENTS.md` stays short; specialized instructions belong in nested `AGENTS.md` files or task docs.
- Do not rely on a single agent's hidden or global memory to preserve project state.
- If an agent cannot load `pmm` as a skill, it should still be able to follow `AGENTS.md` and the Core Pack.

Compatibility details live in `docs/agent-compatibility.md`.

## Task Start Protocol

For any non-trivial task:
1. Identify the project root and project `AGENTS.md`.
2. Pick the runtime profile.
3. Read the hot path for that profile.
4. Run the Workspace Gate: inspect the primary task, owner, branch/worktree, allowed scope, and active work items.
5. Start or resume exactly one owned task file. Queue unrelated work; use a separate branch/worktree for a child work item.
6. Choose Agent Mode: `solo`, `assisted`, `parallel`, or `review-only`.
7. Define Task, Agent Mode, Harness, Verifier, Loop Budget, Stop Condition, and risk level.
8. Select specialized skills or subagents only when they add value and ownership is clear.
9. Execute directly unless the user asked only for analysis or a high-risk confirmation is needed.

Ask the project owner only for decisions involving cost, production data, destructive changes, credentials, publication, external messaging, legal/business identity, or product direction.

## Reading Rules

Use `docs/runtime.md` for full context-budget rules.

Default:
- Start from `AGENTS.md` and hot path files.
- Use the task reading map in `AGENTS.md`.
- Search before opening long files.
- Read purpose headers and relevant sections first.
- Do not load historical logs, completed tasks, or release notes unless the current task needs them.
- Record selected docs once in the owned primary task or work-item file; do not repeat the same list every turn.

## Verification Rules

Verification is evidence, not confidence. Choose checks from `verifier-map.md` or `docs/runtime.md`.

Default expectations:
- Code: focused tests, build, typecheck, lint, or executable smoke validation.
- Frontend: open the page, test the core flow, inspect desktop/mobile layout, and capture evidence when practical.
- Backend: verify endpoints, validation, auth, persistence, error paths, and logs.
- Docs/skills: run repository safety checks, version consistency checks, link/file existence checks, and line-budget checks.
- Project memory: run `scripts/pmm-doctor.sh <PROJECT_ROOT>` when a lightweight Core Pack consistency check is useful.
- High risk: verify success and failure paths, rollback plan, and confirmation boundary.

If verification cannot run, record why, what risk remains, and the next best check.

## Recovery Rules

Recovery uses project-local state, not chat history.

When a task is interrupted or compact/disconnect occurs:
1. Read `AGENTS.md`.
2. Read `current-state.md`, `active-task.md`, `recovery-rules.md`, and `change-log.md`.
3. Run `scripts/recovery-status.sh` if available.
4. If multiple candidates exist, pass `--task-id`; never guess which task owns the workspace.
5. Inspect branch/worktree ownership, partial side effects, source state, and evidence freshness before repeating commands.
6. Continue from the owned task's `Next Concrete Action`.
7. Update the owned task file before stopping if work remains.

No-op recovery checks should stop cleanly without durable noise when no active or failed-retryable task exists and no drift is found.

## Documentation Update Rules

After substantial or state-changing work, update:
- `docs/00-project-memory/current-state.md`
- the owned `active-task.md`, work-item file, or legacy `task-ledger.md`
- `docs/07-decisions/change-log.md`
- any changed source-of-truth docs

For completed primary tasks, use `pmm-task.sh close` or move the compact result to `task-history.md`. A child work item must pass through `ready-to-integrate`, merge, and primary-owner `integrate` before its claim is released. Restore `active-task.md` to `idle`; preserve all three state axes in history and keep confirmation/release waits in the optional task queue.

Do not update durable docs for read-only lookups, tiny wording edits, one-off commands, or no-op recovery checks unless they create a durable decision, blocker, drift finding, or follow-up.

## Safety Rules

Never:
- store secrets, API keys, passwords, tokens, merchant keys, or private production values in docs, memory, logs, or chat
- delete, migrate, overwrite, or publish production data without explicit confirmation
- change payment, billing, permission, order, user, or credential behavior without confirmation
- publish externally, send messages, charge money, or trigger real transactions without confirmation
- use mock data as proof of real integration
- modify unrelated files just to make a task easier

High-risk tasks require a rollback or recovery plan, minimal change scope, validation evidence, and risk records.

## Usage-Driven Improvement

When improving `pmm` itself:
- inspect recent active-task/task-history, change-log, recovery outcomes, and repeated user corrections
- convert repeated friction into a concise rule, template, verifier, adapter, or script check
- keep public behavior generic; do not encode private project names, local paths, credentials, or one-user-only details
- propagate behavior changes across `SKILL.md`, templates, installed docs, README mirrors, safety checks, sync scope, and changelog
- prefer enforceable checks over long prose

## Common Mistakes

- Making a full document tree the default for every task.
- Letting `AGENTS.md`, `CLAUDE.md`, `.hermes.md`, or global memory become large archives.
- Mixing current task state with historical task logs.
- Appending multiple feature headings to `active-task.md`.
- Starting a second writer in the same branch/worktree.
- Treating code-complete, verification-complete, deployment, and release as one status.
- Reusing verification evidence after HEAD or source state changed.
- Releasing a work item before its verified commit is merged and accepted by the primary owner.
- Claiming completion without a verifier.
- Copying project docs into agent-specific adapters.
- Promoting transient task state into global agent memory.
- Treating one agent's memory system as the project source of truth.
- Weakening safety or verification to reduce context.
