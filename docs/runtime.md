# Runtime Guide

Purpose: Runtime contract for profile selection, workspace ownership, structured task state, self-evaluation, verification, recovery, and legacy migration.
Read when: Starting, executing, verifying, recovering, migrating, or coordinating a substantial `pmm` task.
Skip when: The task is a tiny one-off command with no durable state.

## Runtime Profiles

Use the smallest profile that can finish safely.

| Profile | Use when | Load by default | Write by default | Loop budget |
| --- | --- | --- | --- | --- |
| Pulse | Tiny edit, lookup, known-file correction | `AGENTS.md`, target files | Nothing unless facts change | 1 attempt |
| Sprint | Normal feature, bugfix, UI/API/docs change | `AGENTS.md`, owned task, relevant state/verifier sections, task source | Owned task file and changed source docs | 2-3 attempts |
| Project | New project, major feature, unclear requirements | Core Pack plus needed optional packs | Core Pack, selected packs, decisions | staged attempts |
| Recovery | Interrupted, retryable, compact-disconnected work | Owned task, recovery rules, change log | Owned task file | resume from checkpoint |
| Audit | Security, release, production, payment, public compatibility | Exact artifacts, risk docs, verifier docs | Risk, decision, and change records | no blind retries |

Lightweight modes:
- No PMM: Pulse-level work with no project-memory persistence.
- Pulse Card: a short task card in an existing task record when scope and verifier are clear.
- Core Pack: Sprint+ work needing durable state, handoff, or multi-file verification.

## Upgrade Gate

Before a substantial task can write project state, run:

```bash
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh upgrade --project . --auto --owner <agent-id>
```

The gate is project-level and idempotent. It compares `docs/00-project-memory/runtime-state.md` with the installed `VERSION`, rejects a project created by a newer runtime, and otherwise upgrades the project in one common-directory-locked transaction. The transaction stages all outputs before commit, backs up every existing file it will rewrite, preserves non-managed `AGENTS.md` content, and rolls back files and provisional claims after a failure or signal.

An upgrade writes `runtime-state.md`, the marker-managed PMM block in `AGENTS.md`, and only missing Core Pack files. It converts one unambiguous legacy current task, derives a deterministic `legacy-<sha256-prefix>` ID when the old title is not a valid structured ID, and creates an idle primary slot for history-only projects. Multiple tasks, active-task/ledger source conflicts, repeated conflicting statuses, newer runtime markers, and invalid managed markers fail closed with no project-state writes.

`runtime-state.md` is durable project metadata, not a default hot-path reading file. Compatibility readers remain available for migration discovery, recovery, rollback, and manual ambiguity review; ordinary lifecycle writes require the current runtime state.

## Workspace Gate

Run this before Subagent Gate or any write:

1. Read the primary `active-task.md` and its `task_id`, owner, branch, status, and allowed scope.
2. Inspect the current Git branch/worktree, dirty file names, and work-item names/claims; open another work item only when ownership or overlap is relevant.
3. Decide whether the request continues the primary task, queues new work, or needs a branch-isolated child work item.
4. Refuse two active writers in one branch/worktree.
5. Run overlapping source scopes sequentially even if different conversations or Agents are available.

A matching current-branch claim means the workspace is already isolated: continue or resume that task instead of creating or switching worktrees. A default `start` in another active, checked-out worktree auto-routes to a work item under the active primary. It does not auto-route on the primary branch, from an already claimed child branch, or when the primary is paused, blocked, missing, stale, or not checked out.

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
- A context already on its claimed branch continues there; PMM activation alone is not a reason to invoke another worktree-routing skill.
- One branch/worktree owns at most one active work item, even when task IDs differ.
- The primary task cannot close while a child work-item claim remains active.
- A new conversation resumes only after it identifies the exact task ID and ownership.
- Scheduled automation receives a task ID and stops on ambiguity, ownership conflict, blocked state, or confirmation boundary.

Local claims and a short-lived mutation lock are stored in the Git common directory. The lock serializes lifecycle writes across local worktrees; simultaneous `start` commands use a bounded five-second retry so the later isolated starter can observe and join the primary as a work item, while other mutations keep immediate busy failure. Each task-file mutation is staged as a complete file and atomically replaced, while failure or a signal cleans temporary files, rolls back an uncommitted new claim, and restores an interrupted takeover to the owner matching the durable task file. Task and branch metadata preserve ownership after the command exits, and Doctor fails a non-idle task whose owner/branch/parent/kind claim is missing or mismatched. Exactly one non-idle primary claim may exist in one clone, including a migrated `paused` or `blocked` task; a same-worktree second primary, non-idle migration, or unsafe auto-route fails closed. Closed and integrated task IDs are recorded in append-only history plus a same-clone archive marker and cannot be reused; compatibility checks also inspect structured and marker-less legacy history reachable from local heads, remotes, and tags, de-duplicate identical blobs, and fail closed if ref inspection cannot complete. A later command safely recovers a same-host lock whose recorded PID is no longer alive, and Doctor reports that condition. Neither mechanism is a distributed lock. Across devices, use one remote branch per work item, push checkpoints intentionally, and never assume local ownership state exists elsewhere.

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

`start`, `checkpoint`, `verify`, `resume`, `close`, `integrate`, and delivery mutations automatically run the Upgrade Gate before their normal ownership and task checks. `status` remains read-only. Use `upgrade --auto` directly when you want to complete the project transition before starting work.

Start one primary task:

```bash
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh start \
  --project . --id feature-a --title "Feature A" --owner agent-a \
  --scope "src/feature-a" --verifier "run focused tests"
```

If an active primary already owns another checked-out worktree, the same default `start` command in the current unclaimed, checked-out worktree creates `work-items/<id>.md`, records the active primary as `parent_task_id`, and emits `TASK_AUTO_ROUTED`. This convenience does not create, switch, or delete worktrees. If the current branch already has a matching claim, use `status`, `checkpoint`, or `resume` for that task instead of calling `start` again.

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

## I/O And Context Budget

Spend reads, writes, disk, and model context on the current decision.

| Layer | Load by default | Purpose |
| --- | --- | --- |
| Entry | `AGENTS.md` | project identity, safety, reading map |
| State | owned task; relevant `current-state.md` sections | current contract and needed stable facts |
| Verifier | relevant `verifier-map.md` section when the task lacks complete checks | checks and false-pass guards |
| Task source | only docs/source required now | current implementation facts |
| Cold path | queue, history, failures, old logs | selection, audit, repeated failure, migration |

Apply this I/O Gate:

1. Reuse content already present in the current context and keep an ephemeral in-session read set. Do not persist that cache or reopen unchanged content.
2. Use `rg`, file metadata, purpose headers, and headings before broad reads. Before opening a text file over 200 lines or 32 KiB, inspect its size and headings, then read only the relevant ranges.
3. Batch independent metadata/search checks and cap command output. Keep raw logs only when audit or recovery requires them; otherwise retain a short result summary.
4. Do not create a separate plan, spec, handoff, or evidence artifact when the owned task file and target source already contain the needed facts. A specialized skill may add one only when the user or project explicitly requires a durable standalone artifact.
5. Update the owned task in place at meaningful state transitions. Do not append commentary transcripts, repeated file lists, or unchanged checkpoints.
6. Put necessary temporary logs and generated evidence under ignored `.project-runtime/<task-id>/` or `tmp/<task-id>/`; remove disposable task output after verification and preserve only required rollback or audit anchors.

The hot path is a routing set, not an instruction to load every file fully. Do not load every work item, completed task, historical log, or release note to resume one task.

## Self-Eval Loop

Every substantial task follows:

```text
Classify -> Upgrade Gate -> Workspace Gate -> Subagent Gate -> Load -> Contract -> Execute -> Verify -> Critique -> Repair -> Record -> Promote
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

Legacy `active-task.md` and `task-ledger.md` remain readable for compatibility and recovery. Normal writes first run the Upgrade Gate; these migration commands remain backward-compatible explicit APIs:

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
- `migrate --apply` also writes the current `runtime-state.md` and managed `AGENTS.md` block, so task conversion cannot leave a project in an older runtime mode.
- Never delete a legacy `task-ledger.md` without project-owner approval.

## Memory Promotion

Keep active execution, retry state, claims, temporary paths, and raw logs project-local. Store completed summaries in `task-history.md`, stable phase facts in `current-state.md`, repeated failures in `failure-patterns.md`, and durable decisions in `change-log.md`. Agent-global memory keeps only stable cross-project preferences or a short project-entry pointer.
