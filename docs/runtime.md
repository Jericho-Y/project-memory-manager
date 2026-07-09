# Runtime Guide

Purpose: Single runtime guide for profile selection, context budget, self-evaluation, subagent routing, memory promotion, verifier choices, and legacy migration.
Read when: Starting, executing, verifying, recovering, or migrating a substantial `pmm` task.
Skip when: The task is a tiny one-off command or the active task already names a complete verifier and profile.

## Runtime Profiles

Use the smallest profile that can finish safely.

| Profile | Use when | Load by default | Write by default | Loop budget |
| --- | --- | --- | --- | --- |
| Pulse | Tiny edit, lookup, known-file correction | `AGENTS.md`, target files | Nothing unless facts change | 1 attempt |
| Sprint | Normal feature, bugfix, UI/API/docs change | hot path plus task source docs | `active-task.md`, changed source docs, decisions when durable | 2-3 attempts |
| Project | New project, major feature, unclear requirements | Core Pack plus needed optional packs | Core Pack, selected packs, decisions | staged attempts |
| Recovery | Interrupted, failed-retryable, compact-disconnected work | hot path, recovery rules, change log | `active-task.md`; archive when resolved | resume from checkpoint |
| Audit | Security, release, production, payment, public compatibility | exact artifacts, risk docs, verifier docs | risk, decision, and change records | no blind retries |

Lightweight modes:
- No PMM: Pulse-level work with no project-memory persistence.
- Pulse Card: short task card in an existing entrypoint/task record when scope and verifier are clear.
- Core Pack: Sprint+ work needing task state, durable facts, handoff, or multi-file verification.

## Context Budget

Spend context on the current decision.

| Layer | Load by default | Purpose |
| --- | --- | --- |
| Entry | `AGENTS.md` | project identity, safety, reading map |
| State | `current-state.md`, `active-task.md` | current facts and task contract |
| Verifier | `verifier-map.md` | checks and false-pass guards |
| Index | purpose headers and task maps | find the right source document |
| Task source | only docs required now | facts needed for this task |
| Cold path | history, failure patterns, release notes, old logs | use only for audits, repeated failures, migration, or history questions |

Read strategy:
1. Classify the task.
2. Read `AGENTS.md` and the selected hot path.
3. Search before opening long files.
4. Read purpose headers and relevant sections first.
5. Open full files only when editing, investigating ambiguity, or verifying risk.
6. Record selected docs once in `active-task.md`.

## Handoffs

Handoffs should include the project root, runtime profile, active-task path, task status, next concrete action, files already read, verifier still required, and safety or confirmation boundaries.

Handoffs should not include full document copies, secrets, private runtime details, old completed task history unrelated to the next action, active retry state copied into global memory, or agent-specific rules already present in `AGENTS.md`.

## Self-Eval Loop

Every substantial task follows:

```text
Classify -> Subagent Gate -> Load -> Contract -> Execute -> Verify -> Critique -> Repair -> Record -> Promote
```

The loop is operational. It should produce evidence and concise task state, not long reasoning logs.

`active-task.md` should cover:
- Runtime Profile, status, risk, loop budget, stop condition
- Objective, scope, allowed files, forbidden actions, source artifacts
- Agent Mode, delegated scopes, parent-owned path
- Harness, commands, tools, skills, environment notes
- Verifier, manual acceptance, evidence needed
- Critic, false-pass risk, repair state, next action
- Record, docs changed, remaining risk, memory-promotion decision

A task cannot be marked `done` without a verifier. If verification is impossible, use `executed-unverified` or `blocked` and record why.

## Subagent Gate

Use subagents only when they reduce risk, save useful context, or let independent work proceed in parallel.

| Mode | Use when | Default limit |
| --- | --- | --- |
| `solo` | tiny task, tightly coupled fix, unclear split, or no delegation support | 0 |
| `assisted` | one bounded side task can run while the parent owns the critical path | 1 |
| `parallel` | independent scopes can progress without overlapping files or decisions | 2 |
| `review-only` | implementation is done or nearly done and independent risk review is useful | 1 |

Before delegating, confirm:
- the parent can continue useful work
- the scope is concrete, bounded, and non-overlapping
- the result improves speed, coverage, or verification enough to justify context
- the parent can verify and integrate the result
- the prompt excludes secrets, tokens, production data, and unnecessary personal data

Do not delegate the immediate blocker on the parent critical path, vague research, tiny edits, or overlapping edits to the same files.

## Verifiers

A verifier must be specific enough to fail.

| Task type | Minimum verifier | Stronger verifier |
| --- | --- | --- |
| Skill or docs | line budgets, link/file checks, public safety script, `pmm-doctor` when project memory is involved | install sync smoke, release-note consistency |
| Shell scripts | syntax check, targeted dry run where safe | public safety plus isolated smoke |
| Frontend UI | page opens, core flow works, desktop/mobile visual check | browser screenshots, accessibility and interaction checks |
| Backend/API | endpoint or unit test, validation path check | success/failure/auth tests plus logs |
| Database | migration dry run or schema inspection | backup/rollback plan and staging validation |
| Auth/payment/permissions | explicit risk review and confirmation boundary | abuse/failure paths plus rollback notes |
| Deployment/release | release checklist, version consistency, rollback path | staged rollout and public artifact verification |
| Recovery | recovery-status helper, workspace inspection | resume from active task and verify no duplicate side effects |
| Agent compatibility | adapter review, startup path description | run or simulate each target agent entry path |

False-pass checks:
- Did the verifier run after the final change?
- Was any check deleted or weakened?
- Did docs/API/contracts change without source updates, or source change without docs/API updates?
- Did evidence come from real behavior rather than assumptions?
- Did high-risk work receive required confirmation?

## Repair

Classify failures before retrying:
- requirement gap
- source artifact missing
- build/test/lint/type failure
- behavior regression
- visual/layout failure
- integration/environment failure
- permission/safety boundary
- verifier missing or weak

Do not repeat the same command blindly. Inspect the failure, change the condition, or make the smallest reasonable fix first.

## Memory Promotion

Project facts live in the project. Agent-global memory may keep only stable pointers or preferences.

Store:
- current task and retry state in `active-task.md`
- completed summaries in `task-history.md`
- current phase and stable facts in `current-state.md`
- repeated failure rules in `failure-patterns.md`
- public release notes in `CHANGELOG.md`
- project entry pointers in adapters or very short global memory entries

Promote only durable facts: repeated user corrections, reused commands, safety boundaries, environment constraints, requirements, API/design/release facts, or failure patterns that should change future behavior.

Do not promote temporary paths, raw logs, full diffs, one-off guesses, completed retry counts, secrets, credentials, private chat content, or user-identifying operational details.

## Legacy Migration

Legacy v0.1 projects may have `docs/00-project-memory/task-ledger.md`. Migrate only when the user wants v0.2+ behavior or a substantial task starts and `active-task.md` or `verifier-map.md` is missing, stale, or empty.

Light migration steps:
1. Read `AGENTS.md`, `current-state.md`, legacy `task-ledger.md`, recovery rules, and change log.
2. Create missing Core Pack files from templates.
3. Move only the current active or retryable task into `active-task.md`.
4. Move useful completed summaries into `task-history.md`.
5. Move reusable repeated failures into `failure-patterns.md`.
6. Keep old product, design, engineering, risk, ops, and automation docs as optional packs.
7. Record a concise migration note in `change-log.md`.

Never delete `task-ledger.md` during migration without explicit project-owner approval.
