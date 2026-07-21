# Current State

Purpose: Snapshot of repository phase, active objective, current source-of-truth files, and remaining risks.
Read when: Resuming work, checking current repository status, or deciding next action.
Skip when: You only need static public installation instructions or release history.

## Status

The public repository is initialized and published as a generic Agent Skill repository.

## Active Objective

Maintain `pmm` v0.5.x as a compatibility-first, concurrency-aware task runtime that preserves one primary task, upgrades legacy project state without forced rewrites, isolates concurrent work, verifies evidence freshness, and passes the same contract in source and installed-package layouts.

## Current Source Of Truth

- Skill entrypoint: `SKILL.md`.
- Repository entrypoint and maintenance rules: `AGENTS.md`.
- Public overview: `README.md`; English mirror: `README.en.md`.
- Runtime behavior: `docs/runtime.md`.
- Installation: `docs/install.md`.
- Maintenance, release, automation, safety, compact recovery, and customization: `docs/maintenance.md`.
- Cross-agent compatibility: `docs/agent-compatibility.md`.
- Project-memory hot path: `docs/00-project-memory/active-task.md`, `docs/00-project-memory/verifier-map.md`, and `docs/07-decisions/change-log.md`.
- Templates: Core Pack under `templates/core/`, optional packs in `templates/optional-packs.md`, adapters under `templates/adapters/`, and concurrency templates under `templates/concurrency/`.
- Public safety rules: `scripts/public-safety-rules.conf`; scanner: `scripts/check-public-safety.sh`.
- Local skill sync: `scripts/sync-local-skill.sh`.
- Lightweight project checker: `scripts/pmm-doctor.sh`.
- Recovery status helper: `scripts/recovery-status.sh`.
- Structured task lifecycle: `scripts/pmm-task.sh`; shared state helpers: `scripts/lib/pmm-state.sh`.
- Release gate: `scripts/pmm-preflight.sh`.
- Runtime contract verification: `tests/pmm-runtime-contract.sh`.

## Current Facts

- Public releases use `VERSION`, `SKILL.md` frontmatter `version:`, public `CHANGELOG.md`, matching git tags, and GitHub Releases.
- `v0.5.1` is published from tag `v0.5.1` at source commit `53c3c46`; the operational task-close commit is `e7974d9`. The maintainer install was synced from public `main` and the installed-package contract passed at version `0.5.1`.
- Public release notes are bilingual: Chinese is primary, with English mirror coverage in `CHANGELOG.en.md` and release bodies when publishing.
- New generated projects should start with Core Pack only and add optional packs only when real facts exist.
- Product Pack uses project-root `PRD.md` as the default master requirements/product document.
- Optional packs now prefer one concise domain document before splitting into larger trees.
- Generated project memory must remain agent-neutral: `AGENTS.md` plus Core Pack is the source of truth, and adapters stay pointer-only.
- Subagent support is optional across runtimes; Agent Mode remains a recorded decision, not a mandatory capability.
- `active-task.md` is one primary-task slot; concurrent writers use separate branches/worktrees and work-item files, or remain queued.
- Structured state separates execution, verification, and delivery; successful code execution does not imply fresh verification or public release.
- Verification evidence is fresh only when the recorded source state matches and every later commit is operational-only; a source commit followed by a revert still requires re-verification.
- Same-machine lifecycle writes are serialized through a Git common-dir mutation lock and atomically committed as whole-file staged transactions; failure/signal cleanup removes temporary state, rolls back new claims, and restores interrupted takeover ownership. One clone permits one non-idle primary claim, including paused/blocked migration states, and Doctor/mutating commands require matching owner, branch, parent, and kind claim metadata.
- Same-host locks owned by dead processes are recovered safely; task claims still require explicit ownership or takeover.
- Work-item close retains its claim at `ready-to-integrate`; only the primary owner can integrate after the verified child commit is merged, and primary evidence is then invalidated.
- Closing preserves execution, verification, and delivery in task history, reserves the task ID against reuse, and queues unfinished delivery before releasing the task slot.
- `scripts/pmm-doctor.sh` requires the current project runtime by default; `--allow-legacy` is an explicit compatibility audit and the checker remains a static validator rather than enforcement across all agents.
- Before normal writes, the Upgrade Gate converges an unambiguous legacy or older-runtime project to the installed runtime, records `runtime-state.md`, updates only the managed `AGENTS.md` block, fills missing Core Pack files, and preserves project-owned content.
- Legacy single-task `active-task.md` and `task-ledger.md` remain readable for migration discovery, recovery, rollback, and ambiguity review. Automatic upgrade is backed up and transactional, refuses multi-task/source/status ambiguity, maps unverified or unknown work to paused review, and normalizes history-only or idle projects to the empty slot.
- Legacy parsing supports bulleted and bare fields, `## Task <id>` ledgers, Markdown code spans, verbose statuses, and empty active-task placeholders without deleting the original ledger.
- Doctor exposes stable JSON issue codes and compatibility/strict modes; lifecycle CLI exposes help, version, delivery, and read-only migration plans.
- Single-task migration supports official v0.1 ledger records and formal v0.2/v0.3 multi-section tasks, separates current fields from completed history, preserves objective/verifier/next-action values in the structured hot path, and leaves legacy source unchanged; marker-less history continues to reserve archived task IDs across reachable refs.
- Recovery merges sibling-worktree primary/work-item claims with project files, so uncommitted tasks remain discoverable by task ID.
- The runtime contract detects source-checkout and installed-package layouts, and `pmm-preflight.sh` runs both as one release gate so repository-only maintenance assertions do not create false installation failures.
- Local skill sync removes unmanaged files inside the dedicated local `pmm` skill directory after safety checks pass.
- The v0.5.1 source runtime contract passes all 359 assertions and the installed-package contract passes 358 assertions; public safety, Doctor, shell syntax, release preflight, tag, and GitHub Release verification are complete.
- Workflow examples remain under `docs/github-actions-drafts/` until workflow publication is explicitly reviewed and enabled.

## Remaining Risks

- Workflow examples are not active until moved into `.github/workflows/` with the right repository permissions.
- Auto-merge rules must stay conservative because this repository controls agent behavior.
- Runtime recovery depends on owned task files staying current and requires explicit task selection when multiple active candidates exist.
- Local task claims do not coordinate separate devices; cross-device writers must use distinct remote branches and intentional checkpoints.
- Windows installs include the complete package, but the runtime helpers require Bash, Git, `rg`, and a SHA-256 tool to execute.
- Real Claude Code, Hermes Agent, and OpenClaw end-to-end runtime tests have not been run locally; compatibility is based on documented adapter contracts and repository-level verification.
- This repository has no application frontend/backend, runtime auth, payment flow, database, or dependency manifest; security review covers repository scripts, docs, and automation boundaries only.
