# Context Budget

Purpose: Token and context-use rules for using `pmm` without loading unnecessary project history.
Read when: Starting, resuming, delegating, or optimizing a project-memory workflow.
Skip when: The task is a tiny one-off command or the needed source file is already known.

## Goal

Spend context on the current decision. Keep project memory useful without forcing every task to reread stable background or historical task logs.

## Budget Layers

| Layer | Load by default | Purpose |
| --- | --- | --- |
| Entry | `AGENTS.md` | Project identity, current objective, safety boundaries, reading map |
| State | `current-state.md`, `active-task.md` | Current facts, task contract, checkpoint, verifier, next action |
| Verifier | `verifier-map.md` | Required checks and evidence for this task |
| Index | purpose headers, task reading map | Find the right source document without broad reads |
| Task source | only docs required by the task | Facts needed for the current work |
| Cold path | `task-history.md`, `failure-patterns.md`, release notes, old logs | Use only for repeated failures, audits, migration, or history questions |

`task-ledger.md` is a v0.1 compatibility path. If it exists, read it only when `active-task.md` is missing, stale, explicitly referenced, or being migrated through `docs/legacy-migration.md`.

## Runtime Profiles

Use `docs/runtime-profiles.md` to choose Pulse, Sprint, Project, Recovery, or Audit.

Default context budgets:
- Pulse: `AGENTS.md` plus target files only.
- Sprint: hot path plus task source docs.
- Project: Core Pack plus selected optional packs.
- Recovery: hot path plus recovery/change docs.
- Audit: exact source artifacts plus risk/verifier docs.

## Reading Strategy

1. Classify the task.
2. Read `AGENTS.md`.
3. Read only the hot path for the selected profile.
4. Search before opening long files.
5. Read headings, Purpose / Read when / Skip when, and relevant sections first.
6. Open full files only when editing, investigating ambiguity, or verifying risk.
7. Record selected docs once in `active-task.md`; do not repeat the same list every turn unless the task changes.

## Delegation Budget

Subagent routing should reduce context pressure, not increase it. Keep the hot-path decision short:

- Pulse: `solo` by default.
- Sprint: `solo` or one `assisted`/`review-only` subagent when it clearly helps.
- Project or Audit: allow `parallel` only when scopes are independent and integration is explicit.
- Recovery: use subagents only for bounded diagnosis or independent review.

Open `docs/subagent-routing.md` only when delegation is plausible. Do not load it for tiny known-file edits.

## Writing Strategy

- Keep `AGENTS.md` short and project-specific.
- Keep `active-task.md` focused on one current task.
- Archive completed work in `task-history.md`, not in the hot path.
- Use `failure-patterns.md` only for reusable failure classes.
- Store durable facts as concise deltas: current state, evidence, remaining risk.
- Prefer pointers to files and sections over copied excerpts.
- Avoid recording routine no-op checks unless they reveal drift or create a follow-up.

## Handoffs

Handoffs should include:
- project path or repository root
- runtime profile
- active-task path
- task status and next concrete action
- files already read
- verifier still required
- safety or confirmation boundaries

Handoffs should not include:
- full document copies
- secrets or private runtime details
- old completed task history unrelated to the next action
- active retry state copied into agent-global memory
- agent-specific rules that already live in `AGENTS.md`

## When To Spend More Context

Use broader reading when:
- auth, payment, permission, deployment, production data, or user data is involved
- source documents disagree
- a task failed and root cause is unknown
- changing shared templates, safety rules, scripts, or automation
- preparing public release notes or compatibility guarantees
- migrating v0.1 projects from `task-ledger.md` to `active-task.md`

Use `docs/legacy-migration.md` for that migration. The goal is to enable v0.2 execution, not to rewrite the old project archive.

## Maintenance Checks

When this repository changes:
- `SKILL.md` stays concise and links to this file.
- README mirrors mention runtime profiles, Core Pack, adapters, and Self-Eval Loop without duplicating all docs.
- Local sync includes this file plus runtime/self-eval/memory/verifier docs.
- Subagent routing docs stay cold-path and README mirrors mention the feature without duplicating its rules.
- Public safety checks verify required v0.2 docs and templates exist.
- Line-budget checks keep hot-path files small enough for low-context agents.
