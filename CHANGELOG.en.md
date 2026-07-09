# Changelog

Purpose: English mirror of the public release notes for the `pmm` skill.
Read when: You need the English version of [CHANGELOG.md](CHANGELOG.md).
Skip when: The Chinese primary changelog is sufficient.

This project follows semantic versioning for public skill releases.

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
