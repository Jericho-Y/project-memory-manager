# Runtime Guide

Purpose: Runtime contract for profile selection, workspace ownership, structured task state, self-evaluation, verification, recovery, and legacy migration.
Read when: Starting, executing, verifying, recovering, migrating, or coordinating a substantial `pmm` task.
Skip when: The task is a tiny one-off command with no durable state.

## Runtime Profiles

Use the smallest profile that can finish safely.

| Profile | Use when | Load by default | Write by default | Loop budget |
| --- | --- | --- | --- | --- |
| Pulse | Tiny edit, lookup, known-file correction | `AGENTS.md`, target files | Nothing unless facts change | 1 attempt |
| Sprint | Normal feature, bugfix, UI/API/docs change | Hot path plus task source docs | Owned task file and changed source docs | 2-3 attempts |
| Project | New project, major feature, unclear requirements | Core Pack plus needed optional packs | Core Pack, selected packs, decisions | staged attempts |
| Recovery | Interrupted, retryable, compact-disconnected work | Owned task, recovery rules, change log | Owned task file | resume from checkpoint |
| Audit | Security, release, production, payment, public compatibility | Exact artifacts, risk docs, verifier docs | Risk, decision, and change records | no blind retries |

Lightweight modes:
- No PMM: Pulse-level work with no project-memory persistence.
- Pulse Card: a short task card in an existing task record when scope and verifier are clear.
- Core Pack: Sprint+ work needing durable state, handoff, or multi-file verification.

## Workspace Gate

Run this before Subagent Gate or any write:

1. Read the primary `active-task.md` and its `task_id`, owner, branch, status, and allowed scope.
2. Inspect the current Git branch/worktree, dirty files, and existing work items.
3. Decide whether the request continues the primary task, queues new work, or needs a branch-isolated child work item.
4. Refuse two active writers in one branch/worktree.
5. Run overlapping source scopes sequentially even if different conversations or Agents are available.

Use this model:

```text
current-state.md                         project phase and stable facts
active-task.md                           one primary integration task
work-items/<task-id>.md                  optional branch-isolated child task
task-queue.md                            optional queued/waiting work
task-history.md                          closed compact summaries
```

`active-task.md` is never a list. A new request does not append a second feature heading.

### Conversation And Agent Rules

- The parent/integration context owns `active-task.md`.
- A subagent that only researches or reviews returns results and does not edit task state.
- A writing child context uses a separate branch/worktree and its own work-item file.
- One branch/worktree owns at most one active work item, even when task IDs differ.
- The primary task cannot close while a child work-item claim remains active.
- A new conversation resumes only after it identifies the exact task ID and ownership.
- Scheduled automation receives a task ID and stops on ambiguity, ownership conflict, blocked state, or confirmation boundary.

Local claims and a short-lived mutation lock are stored in the Git common directory. The lock serializes lifecycle writes across local worktrees; each task-file mutation is staged as a complete file and atomically replaced, while failure or a signal cleans temporary files, rolls back an uncommitted new claim, and restores an interrupted takeover to the owner matching the durable task file. Task and branch metadata preserve ownership after the command exits, and Doctor fails a non-idle task whose owner/branch/parent/kind claim is missing or mismatched. Exactly one non-idle primary claim may exist in one clone, including a migrated `paused` or `blocked` task; a second primary `start` or non-idle migration fails closed. Closed and integrated task IDs are recorded in append-only history plus a same-clone archive marker and cannot be reused; compatibility checks also inspect structured and marker-less legacy history reachable from local heads, remotes, and tags, de-duplicate identical blobs, and fail closed if ref inspection cannot complete. A later command safely recovers a same-host lock whose recorded PID is no longer alive, and Doctor reports that condition. Neither mechanism is a distributed lock. Across devices, use one remote branch per work item, push checkpoints intentionally, and never assume local ownership state exists elsewhere.

## Structured Task State

`pmm.task/v1` uses YAML frontmatter for deterministic state and Markdown sections for human-readable contracts.

| Axis | Values | Meaning |
| --- | --- | --- |
| Execution | `idle`, `queued`, `active`, `paused`, `blocked`, `ready-to-integrate`, `done` | Work progress |
| Verification | `pending`, `partial`, `passed`, `stale`, `failed`, `not-required` | Evidence state |
| Delivery | `not-requested`, `waiting-confirmation`, `ready`, `deployed`, `released` | External delivery state |

Do not collapse these axes. Code can be `done`, verification `passed`, and delivery `waiting-confirmation` without remaining the current active development task.

Required machine fields:

```text
pmm_schema, task_id, parent_task_id, task_kind
execution_status, verification_status, delivery_status
owner, branch, base_sha, revision
verification_head, verification_source_hash, verified_at, updated_at
```

## Task Lifecycle CLI

Use the installed helper from the project root. Replace `<SKILLS_ROOT>` with the runtime's skill root.

Start one primary task:

```bash
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh start \
  --project . --id feature-a --title "Feature A" --owner agent-a \
  --scope "src/feature-a" --verifier "run focused tests"
```

Start a branch-isolated child work item after creating/switching to its branch/worktree. The parent claim is shared through the Git common directory, so the parent task file does not need an extra commit before a local worktree is created:

```bash
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh start \
  --project . --id feature-a-ui --parent feature-a --work-item \
  --title "Feature A UI" --owner agent-ui \
  --scope "src/ui" --verifier "run UI checks"
```

Checkpoint, verify, inspect, resume, and close a primary task:

```bash
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh checkpoint --project . --id feature-a --owner agent-a --next "Run focused tests"
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh verify --project . --id feature-a --owner agent-a --evidence "focused tests passed"
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh status --project . --id feature-a
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh resume --project . --id feature-a --owner agent-a
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh close --project . --id feature-a --owner agent-a

# Record or inspect delivery state before close.
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh delivery --project . --id feature-a \
  --owner agent-a --status ready --evidence "package prepared"
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh delivery --project . --id feature-a
```

Finish and integrate a child work item:

```bash
# On the child branch: commit source changes, verify, then mark the item ready.
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh verify --project . --id feature-a-ui --owner agent-ui --evidence "UI checks passed"
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh close --project . --id feature-a-ui --owner agent-ui
git add docs/00-project-memory/work-items/feature-a-ui.md && git commit -m "Mark feature-a-ui ready"

# Merge the child branch, then run this on the primary branch as its owner.
git merge feature-a-ui
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh integrate --project . --id feature-a-ui --owner agent-a
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh verify --project . --id feature-a --owner agent-a --evidence "post-integration checks passed"
```

Every mutating command requires `--owner` or `PMM_OWNER`, the recorded branch, and a matching local claim; only `resume --takeover` may change ownership. `verify` records HEAD and a hash of tracked/untracked source state while excluding operational task/history/queue files, and fails closed when Git or hashing fails. Freshness checks inspect every commit after the recorded verifier with rename detection disabled; a source-touching commit remains disqualifying when a later commit restores the same tree or moves the source into an operational path. `pmm-doctor.sh` also rejects multiple common-directory primary claims instead of treating them as an empty slot.

For a work item, `close` requires committed source plus fresh passed evidence and transitions to `ready-to-integrate` without deleting the file or releasing its claim. `integrate` runs on the primary branch, proves the child's verified commit is an ancestor of the primary HEAD, archives the child, releases its claim, and invalidates old primary evidence. Primary `close` refuses any active or pending-integration child, requires fresh post-integration evidence, archives all three axes, and queues `waiting-confirmation` or `ready` delivery follow-up.

Use `resume --takeover` only after confirming the previous writer stopped. It is an explicit task-ownership change; automatic dead-PID recovery applies only to the short-lived mutation lock, never to a task claim.

## Context Budget

Spend context on the current decision.

| Layer | Load by default | Purpose |
| --- | --- | --- |
| Entry | `AGENTS.md` | project identity, safety, reading map |
| State | `current-state.md`, owned task file | stable facts and current contract |
| Verifier | `verifier-map.md` | checks and false-pass guards |
| Task source | only docs/source required now | current implementation facts |
| Cold path | queue, history, failures, old logs | selection, audit, repeated failure, migration |

Search before opening long files. Record selected docs once in the owned task file. Do not load every work item or completed task to resume one task.

## Self-Eval Loop

Every substantial task follows:

```text
Classify -> Workspace Gate -> Subagent Gate -> Load -> Contract -> Execute -> Verify -> Critique -> Repair -> Record -> Promote
```

The task contract covers objective, scope, allowed/forbidden actions, owner, branch, Agent Mode, harness, verifier, loop budget, stop condition, repair state, next action, evidence, and remaining risk.

A task cannot close without a verifier and fresh evidence. If verification is incomplete or fails, use `verification_status: partial` or `failed`; if execution cannot continue, use `execution_status: blocked` and record why. A passed verifier becomes `stale` when HEAD or source state no longer matches its recorded evidence.

## Subagent Gate

Use subagents only when they reduce risk, save useful context, or let independent work proceed.

| Mode | Use when | Default limit |
| --- | --- | --- |
| `solo` | tiny or tightly coupled task | 0 |
| `assisted` | one bounded read/review side task | 1 |
| `parallel` | independent branch/worktree scopes | 2 |
| `review-only` | implementation needs independent risk review | 1 |

Do not delegate vague research, the immediate critical-path blocker, overlapping edits, or sensitive external decisions. The parent verifies and integrates all results.

## Verifiers

| Task type | Minimum verifier | Stronger verifier |
| --- | --- | --- |
| Skill/docs | line/link/version checks, public safety, Doctor | install sync and forward-test |
| Shell scripts | syntax plus focused fixture | isolated lifecycle/recovery smoke |
| Frontend | page/core flow, desktop/mobile visual check | screenshots, accessibility, interaction states |
| Backend/API | endpoint/unit validation | success/failure/auth/persistence checks |
| Database | dry run/schema inspection | backup, rollback, staging validation |
| Deployment | version and rollback checks | staged rollout and public artifact verification |
| Recovery | task-specific recovery status and workspace inspection | no-duplicate side-effect proof |

False-pass checks:
- Did verification run after the final source change?
- Does recorded HEAD/source hash still match?
- Was any check deleted or weakened?
- Did evidence come from real behavior rather than assumptions or mocks?
- Did high-risk work receive the required confirmation?

## Repair And Side Effects

Classify failures before retrying. Stop after the configured loop budget for the same acceptance point.

Before repeating deployment, migration, payment, publication, or other external actions, record whether the action was planned, attempted, succeeded, or rolled back. Recovery checks real side effects and rollback anchors before retrying; a chat interruption is not proof that an action did not complete.

## Recovery

Run:

```bash
bash <SKILLS_ROOT>/pmm/scripts/recovery-status.sh .
```

Recovery merges project files with primary and work-item claims from sibling worktrees, so an uncommitted task can still be located from the clone's shared Git state. If it returns `AMBIGUOUS_ACTIVE_TASKS`, inspect the candidates and rerun with `--task-id ID`. Never guess. Structured paused, blocked, queued, and ready-to-integrate tasks return explicit `RECOVERY_PAUSED`, `RECOVERY_BLOCKED`, `RECOVERY_QUEUED`, or `PENDING_INTEGRATION` markers instead of being mistaken for an empty slot. Before resuming, check ownership, branch/worktree, partial edits, running commands, external side effects, next action, and evidence freshness.

Legacy aliases such as `In progress` and `failed-retryable` remain recoverable. New files use the structured enum. A missing or conflicting legacy status is treated as `paused` review, never as permission to resume automatically. If an explicit `--task-id` does not match a candidate, Recovery returns `TASK_ID_NOT_FOUND` and fails closed.

## Legacy Migration

Legacy `active-task.md` and `task-ledger.md` remain readable. Migration is optional and explicit:

```bash
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh migrate --project . --plan
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh migrate --project . --dry-run
```

- When `active-task.md` is absent or is only an empty legacy placeholder, migration deterministically falls back to `task-ledger.md`; if both files contain current contracts, it stops with a source ambiguity instead of choosing one.
- One unambiguous legacy task may be converted with `--apply --id ID --owner OWNER` into a complete structured contract. Official v0.1 ledgers are counted per task field: completed history stays cold, an `Active Task` that is code-complete becomes `paused` for revalidation, and zero or multiple current contracts refuse migration.
- Formal v0.2/v0.3 section headings belong to one task contract; migration carries their objective, required checks, and next concrete action into the new structured hot path before appending the preserved legacy source.
- Legacy `done` without fresh v0.5 evidence becomes `paused` for revalidation; unknown or conflicting status becomes `paused` review; legacy `idle` becomes the canonical empty primary slot. `paused` and `blocked` remain recoverable.
- `migrate --plan` is read-only and prints one `MIGRATION_CANDIDATE` per current contract. `--dry-run` keeps the validation gate and refuses zero or multiple candidates; `--apply` creates a project-local backup and rejects conflicting `Status` fields.
- The migration source is backed up under `.project-runtime/pmm/backups/`; a legacy ledger remains unchanged.
- Multiple feature contracts return `MIGRATION_AMBIGUOUS` and remain unchanged.
- Never delete a legacy `task-ledger.md` without project-owner approval.

## Memory Promotion

Keep active execution, retry state, claims, temporary paths, and raw logs project-local. Store completed summaries in `task-history.md`, stable phase facts in `current-state.md`, repeated failures in `failure-patterns.md`, and durable decisions in `change-log.md`. Agent-global memory keeps only stable cross-project preferences or a short project-entry pointer.
