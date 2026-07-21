# Changelog

Purpose: English mirror of the public release notes for the `pmm` skill.
Read when: You need the English version of [CHANGELOG.md](CHANGELOG.md).
Skip when: The Chinese primary changelog is sufficient.

This project follows semantic versioning for public skill releases.

## v0.5.0 - 2026-07-21

### Added

- Added read-only per-contract `migrate --plan`; `--dry-run` remains the strict validation gate and `--apply` still accepts only one clear current task.
- Added global `pmm-task.sh --help`, `--version`, and evidence-backed `delivery` read/write commands.
- Added `scripts/pmm-preflight.sh` to run source and installed-package contracts, shell syntax, Doctor, public safety, and version consistency as one release gate.
- Doctor JSON messages now expose stable `code` values, with default legacy compatibility mode and explicit `--require-structured` enforcement.

### Fixed

- Fixed duplicate counting of `Task ID` plus `Task`, Markdown code-span and trailing-space parsing, empty `active-task.md` placeholders hiding real ledgers, and bare-field `## Task <id>` ledgers being missed.
- Aligned Recovery, Doctor, and Migration for completed history, completed deferred work, conflicting repeated `Status` fields, and verbose prose statuses. Unknown or conflicting state now enters paused review, and conflicting state refuses automatic apply.
- Fixed explicit missing Recovery task IDs returning success, code-span task IDs in legacy history being reusable, and empty legacy record columns shifting parser fields.

### Compatibility And Upgrade

- Legacy projects remain readable without forced rewrites. Run `migrate --plan` and `--dry-run` first; the legacy ledger is retained and apply creates a project-local backup.
- An empty legacy `active-task.md` placeholder now falls back to the ledger, while two current legacy sources fail closed instead of being guessed.
- Bash sync and PowerShell install include the new preflight helper, and release validation covers both source-checkout and minimal installed-package layouts.

## v0.4.1 - 2026-07-18

### Fixed

- Fixed the installed runtime contract test treating repository-maintenance files as installed runtime dependencies. The contract now distinguishes source checkouts from installed packages: source mode still validates maintainer sync and public-safety configuration, while installed mode validates the lifecycle CLI, shared library, Doctor, Recovery, concurrency templates, and the contract test actually shipped in the package.
- Kept the v0.4.0 runtime and legacy-project compatibility behavior unchanged; this patch only corrects post-install self-validation.

## v0.4.0 - 2026-07-18

### Added

- Added `pmm.task/v1` structured task state with independent execution, verification, and delivery axes.
- Added `scripts/pmm-task.sh` and a shared state library for start, status, checkpoint, verify, resume, close, integrate, and safe migration lifecycle commands.
- Added branch/worktree-isolated work-item and task-queue templates for multi-conversation collaboration in one project.
- Doctor v2 now validates task identity, state enums, branch ownership, and evidence freshness, with optional JSON output.
- Recovery v2 now supports explicit task selection, legacy status normalization, `task-ledger.md` fallback, sibling-worktree primary/work-item claim discovery, paused/blocked/pending-integration recovery, and ambiguity refusal.
- Added 233 runtime contract assertions covering legacy status migration, official v0.1 ledger current/history selection, v0.2/v0.3 multi-section field preservation, stale evidence, untracked hash failure, same/cross-worktree simultaneous starts, paused primary reservation, parent/child close races, worktree parent discovery, explicit integration, post-verification source commit/revert/rename refusal, cross-Git-ref marker-less archived-ID reuse refusal with fail-closed ref inspection, orphan-lock recovery, owner/branch/claim boundaries, interrupted takeover rollback, delivery preservation, transactional rollback, signal-time temp cleanup, and package completeness.

### Changed

- `active-task.md` is now explicitly a singleton primary-task slot and must not accumulate multiple feature contracts.
- Verification evidence is bound to the current Git HEAD and source hash. Freshness is checked commit by commit, so a source commit still requires re-verification after a later revert.
- Lifecycle writes are serialized through a Git common-dir mutation lock and atomically committed as whole-file staged transactions. Failure or a signal cleans temporary files, rolls back an uncommitted new claim, and restores an interrupted takeover to the owner matching the task file. Mutating commands must match the recorded owner, branch, and complete claim, while a short-lived lock left by a dead same-host process is safely recovered.
- Work-item close now enters `ready-to-integrate` and retains its claim. The primary owner can integrate only after the verified commit is merged, then must reverify the primary task.
- Primary close archives execution, verification, and delivery state, and routes unfinished delivery into the task queue.
- One clone permits one non-idle primary claim; paused/blocked tasks retain the slot, and archived primary/work-item task IDs cannot be reused.
- Bash maintainer sync and the ordinary PowerShell installer now include the lifecycle CLI, shared library, concurrency templates, and contract test.
- Legacy single-task `active-task.md` and `task-ledger.md` files remain readable; migration is optional and ambiguous multi-task files are never rewritten automatically.

### Security

- Concurrent writers on one branch/worktree are refused. Cross-device coordination still requires remote branch ownership because local claims are not distributed locks.
- Applying a single-task migration creates a project-local backup and never deletes the legacy ledger automatically.
- Legacy `done` migrates to paused when fresh v0.4 evidence is unavailable, while legacy `idle` becomes the canonical empty slot instead of an invalid false completion.
- Legacy ledgers identify current contracts per task field and keep completed history cold; zero or multiple current tasks refuse automatic migration.
- Git diff, tracked/untracked source hashing, or task-file write failures fail closed and preserve or roll back claims instead of recording false evidence or orphan state. Renaming source into an operational path cannot bypass post-verification freshness checks.

## v0.3.1 - 2026-07-09

### Changed

- Simplified the public documentation set by consolidating runtime profiles, context budget, self-evaluation, subagent routing, verifier recipes, memory promotion, and legacy migration into [docs/runtime.md](docs/runtime.md).
- Consolidated release checks, automation boundaries, safety maintenance, local sync boundaries, compact recovery prompts, and customization guidance into [docs/maintenance.md](docs/maintenance.md).
- Consolidated product, design, engineering, risk, operations, and automation optional-pack templates into [templates/optional-packs.md](templates/optional-packs.md), with one domain document preferred before splitting.
- Updated public safety checks and local skill sync rules to validate the consolidated document entrypoints.

## v0.3.0 - 2026-05-29

### Added

- Added `scripts/pmm-doctor.sh` to check project Core Pack files, `active-task.md` verifier fields, hot-path line budgets, and pointer-only adapters.
- Added [docs/install.md](docs/install.md) and `scripts/install-local-skill.ps1` to distinguish ordinary installation from maintainer sync and document the cross-platform `<SKILLS_ROOT>/pmm` layout.
- Added No PMM, Pulse Card, and Core Pack guidance so tiny tasks are not forced into the full project-memory workflow.

### Changed

- Moved public safety required files, reference checks, generic forbidden markers, secret-like patterns, allowed scripts, and blocked file types into `scripts/public-safety-rules.conf`, with `.project-runtime/public-safety-local-rules.conf` available for uncommitted private markers.
- Local skill sync now includes `docs/install.md` and `scripts/pmm-doctor.sh`.

## v0.2.2 - 2026-05-28

### Added

- Subagent Routing Gate for deciding whether a task should run as `solo`, `assisted`, `parallel`, or `review-only`.
- Subagent routing guidance with bounded delegation rules, default limits, sensitive-data guardrails, and active-task recording guidance; this content was later consolidated into [docs/runtime.md](docs/runtime.md).
- `Agent Mode` fields in the Core Pack `active-task.md` template.

### Changed

- Self-Eval Loop now starts with a lightweight subagent decision before broad loading or execution.
- Runtime profile and context-budget docs now keep subagent routing cold-path so tiny tasks do not pay extra token cost.
- Cross-agent compatibility docs clarify that subagent support is optional; agents without subagent tools record solo mode or a manual handoff plan.

## v0.2.1 - 2026-05-28

### Added

- Legacy migration guide for using v0.2 execution features in projects created with v0.1 `task-ledger.md`.
- Explicit rule that compatibility mode is not enough when the user wants v0.2 behavior: create the Core Pack hot path, migrate only the current task into `active-task.md`, and keep old history cold.

### Changed

- `SKILL.md`, context-budget guidance, agent compatibility notes, and template router now point to the legacy migration workflow.
- Local sync and public safety checks now include legacy migration guidance; this content was later consolidated into [docs/runtime.md](docs/runtime.md).

## v0.2.0 - 2026-05-28

### Added

- Runtime Profiles: Pulse, Sprint, Project, Recovery, and Audit for task-sized context loading.
- Core Pack templates for `AGENTS.md`, `current-state.md`, `active-task.md`, `verifier-map.md`, `task-history.md`, `failure-patterns.md`, and `change-log.md`.
- Optional pack templates for product, design, engineering, risk, operations, and automation docs.
- Self-Eval Loop contract: Task, Harness, Verifier, Critic, Repair, Record, and memory-promotion decision.
- Adapter templates for Claude Code, Hermes Agent, OpenClaw/OpenCode-style agents, and Codex nested instruction scopes.
- New installed docs for runtime profiles, self-evaluation, memory promotion, and verifier recipes.

### Changed

- `SKILL.md` is now a low-context runtime router instead of a full document-tree controller.
- New projects should use `active-task.md` as the hot current-task path.
- `task-ledger.md` remains a legacy bridge for v0.1 projects, but completed history should move to `task-history.md`.
- Context budget rules now separate hot-path state from cold history and repeated failure records.
- Agent compatibility guidance now treats runtime-specific files as adapters, not sources of truth.
- Recovery helper supports both v0.2 `active-task.md` and legacy `task-ledger.md`.

### Operations

- Public safety checks now validate v0.2 docs, Core Pack templates, adapter templates, and line budgets.
- Local skill sync now includes runtime, self-eval, memory-promotion, verifier docs, and adapter templates.

## v0.1.0 - 2026-05-20

First formal public release of `pmm`.

### Added

- Durable project memory protocol built around project `AGENTS.md` plus project-local `docs/`.
- Requirements, current-state, task-ledger, decision, automation, recovery, security, and verification document skeletons.
- Agent compatibility guidance for Codex, Claude Code, Hermes, OpenCode/OpenClaw-style agents, and other `AGENTS.md`-aware agents.
- Context budget protocol for staged reading and concise durable updates.
- Source-artifact gate for PRD, requirements, screenshot, design, document, and source review tasks.
- Subagent role and ownership boundary guidance for authorized parallel agent work.
- Compact-disconnect recovery guidance and recovery-status helper.
- Public safety check for private markers, blocked file types, unexpected executables, symlinks, and documentation drift.
- Local skill sync script with destination guards, safety checks, managed-file cleanup, and local backup behavior.

### Security

- Repository-wide security scan completed with no reportable findings for the public skill repository.
