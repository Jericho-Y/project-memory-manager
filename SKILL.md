---
name: pmm
description: Use when a software project or large feature spans multiple sessions, agents, branches, recovery checkpoints, or verification stages and needs durable project-local task state; skip one-off, tiny, single-session work.
version: 0.5.1
compatibility: Agent Skills SKILL.md format; durable project output is AGENTS.md plus project-local docs, usable by Codex, Claude Code, Hermes Agent, OpenClaw/OpenCode-style agents, and other AGENTS.md-aware coding agents. No runtime dependencies.
---

# Project Memory Manager

Purpose: Define a low-context project memory runtime with self-evaluating execution, recovery, verification, and cross-agent adapters.
Read when: Starting, structuring, continuing, recovering, or maintaining a long-lived project or this skill.
Skip when: The task is a one-off command, tiny edit, or unrelated to durable project memory.

## Operating Model

`pmm` is a portable project runtime, not a documentation generator. It keeps project facts in the project folder and lets each agent runtime use a small adapter to find the same source of truth.

Priority: workspace/project instructions -> `pmm` -> specialized execution skills -> tool docs. `AGENTS.md` is the canonical project entrypoint; agent-specific files are short adapters that point to it instead of copying project rules.

## Runtime Profiles

Classify every non-trivial task before reading broadly. Use the smallest profile that can complete the work safely.

| Profile | Use when | Default hot path | Writes durable memory |
| --- | --- | --- | --- |
| Pulse | Small edit, lookup, focused fix, low risk | `AGENTS.md`, target files | Only if a durable fact changes |
| Sprint | Feature, bugfix, UI/API change, normal risk | `AGENTS.md`, owned task, relevant state/verifier sections, task source | Yes |
| Project | New project, major feature, incomplete requirements | Core pack plus needed packs | Yes |
| Recovery | Interrupted, failed, compact-disconnected, or retryable task | `AGENTS.md`, `current-state.md`, `active-task.md`, `recovery-rules.md`, `change-log.md` | Yes |
| Audit | Security, release, deployment, auth, payment, production data, public compatibility | Risk docs plus exact source artifacts | Yes |

Runtime details live in `docs/runtime.md`.

## Hot Path

The hot path is a routing set, not a command to reopen every file in full:

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

Reuse any hot-path content already supplied in the current context. Use `task-history.md`, `failure-patterns.md`, product/design/technical docs, and release history only when the active task requires them. Search headings and purpose headers before reading full files.

Before substantial writes in an existing project, run the Upgrade Gate: `pmm-task.sh upgrade --project . --auto --owner <agent-id>`. It writes `runtime-state.md`, updates only the marker-managed PMM block in `AGENTS.md`, fills missing Core Pack files, and converts exactly one unambiguous legacy current task. History-only projects receive an idle slot. Multi-task, source, or status ambiguity fails closed before any project file changes. Compatibility reading remains available only for migration discovery, recovery, rollback, and manual ambiguity review.

## Core Pack And Optional Packs

New substantial projects start with the Core Pack only:

```text
AGENTS.md
docs/00-project-memory/current-state.md
docs/00-project-memory/active-task.md
docs/00-project-memory/verifier-map.md
docs/07-decisions/change-log.md
```

`runtime-state.md` is generated metadata outside the default read path. Add Product, Design, Engineering, Risk, Ops, or Automation files only when facts require them; see `templates/optional-packs.md`. For tiny work, use No PMM or a Pulse Card instead of creating the Core Pack.

## Self-Eval Loop

Every substantial execution task uses this loop:

```text
Classify -> Upgrade Gate -> Workspace Gate -> Subagent Gate -> Load -> Contract -> Execute -> Verify -> Critique -> Repair -> Record -> Promote
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

Machine state uses `pmm.task/v1` frontmatter with independent execution, verification, and delivery axes.

Use `scripts/pmm-task.sh` for lifecycle changes. Mutations require the recorded owner and branch, use serialized whole-file transactions, and keep one non-idle primary claim per clone. `verify` binds evidence to the current Git HEAD and source hash. Work items remain `ready-to-integrate` until the primary owner merges, integrates, and re-verifies them. Full lifecycle, claim, archive, and rollback rules live in `docs/runtime.md`.

Verifier first: a task without fresh evidence cannot close. Critic rejects skipped checks, weakened validation, mock evidence, stale source state, and unverified completion claims. Full lifecycle and status rules live in `docs/runtime.md`.

## Memory Promotion

Keep active tasks, retries, temporary paths, raw logs, and transient failures out of agent-global memory. Promote only durable corrections, conventions, stable commands, safety/release constraints, or repeated failure patterns; prefer project-local facts and keep global memory to a short pointer or cross-project preference.

## Cross-Agent Compatibility

Generated memory must remain useful across AGENTS.md-aware tools. `AGENTS.md` and the Core Pack are canonical; adapters stay pointer-only; subagents are optional. Legacy task files remain readable for migration/recovery but ambiguous state is never rewritten automatically. See `docs/agent-compatibility.md`.

## Task Start Protocol

For any non-trivial task:
1. Identify the project root and project `AGENTS.md`.
2. Pick the runtime profile.
3. Run the Upgrade Gate with the installed runtime; stop without writes on task/source/status ambiguity or a newer project runtime.
4. Load only the profile-specific hot-path sections not already present in the current context.
5. Run the Workspace Gate: inspect the primary task, owner, branch/worktree, allowed scope, and active work items.
6. Start or resume exactly one owned task file. Queue unrelated work; use a separate branch/worktree for a child work item.
7. Choose Agent Mode: `solo`, `assisted`, `parallel`, or `review-only`.
8. Define Task, Agent Mode, Harness, Verifier, Loop Budget, Stop Condition, and risk level.
9. Select specialized skills or subagents only when they add value and ownership is clear.
10. Execute directly unless the user asked only for analysis or a high-risk confirmation is needed.

Ask the project owner only for decisions involving cost, production data, destructive changes, credentials, publication, external messaging, legal/business identity, or product direction.

## Reading Rules

Use `docs/runtime.md` for full context-budget rules.

Default:
- Start from `AGENTS.md`, the owned task, and only the hot-path sections required by the selected profile.
- Use the task reading map in `AGENTS.md`.
- Keep an in-session read set; do not reopen unchanged content already present in the current context.
- Before opening a text file over 200 lines or 32 KiB, inspect its size and headings, then read only the relevant ranges.
- Read purpose headers and relevant sections first.
- Do not load historical logs, completed tasks, or release notes unless the current task needs them.
- Do not persist the in-session read set or command transcript.
- Do not create a separate plan, spec, handoff, or evidence file when the owned task file and target source already hold the needed facts.
- Store raw command output only when required for audit or recovery; otherwise keep a bounded summary and discard temporary output.

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

On interruption, reuse current context, then load the recovery profile and run `scripts/recovery-status.sh`. Resolve an exact task ID and ownership, inspect partial side effects and evidence freshness, and resume from `Next Concrete Action`; never guess among candidates.

No-op recovery checks should stop cleanly without durable noise when no active or failed-retryable task exists and no drift is found.

## Documentation Update Rules

After substantial work, batch one compact update to the owned task, changed source-of-truth docs, `current-state.md`, and `change-log.md` only where durable facts changed. Close through `pmm-task.sh`; child items still require merge, primary-owner integration, and fresh primary verification.

Do not rewrite durable docs for commentary, progress narration, repeated checkpoints with no state change, read-only lookups, tiny wording edits, one-off commands, or no-op recovery checks.

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

When improving `pmm`, turn repeated friction into a concise generic rule or check, propagate behavior across templates/docs/README mirrors/sync/changelog, and prefer enforcement over prose. Never encode private project data.

## Common Mistakes

- Creating full document trees, duplicate plans/evidence, or large adapters by default.
- Reopening unchanged content or persisting raw reads, logs, and commentary.
- Mixing active state with history or appending multiple tasks to `active-task.md`.
- Allowing overlapping writers or releasing a child before merge/integration.
- Collapsing execution, verification, and delivery or reusing stale evidence.
- Weakening safety/verifiers or treating hidden agent memory as source of truth.
