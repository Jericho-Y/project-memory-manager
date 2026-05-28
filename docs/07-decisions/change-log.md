# Change Log

Purpose: Chronological record of durable repository behavior and maintenance changes.
Read when: You need recent change history or must update the record after state-changing work.
Skip when: You only need current instructions and no historical context.

## 2026-05-28

- Began `pmm` v0.2.0 upgrade from a full document-tree controller to a low-context project runtime with Runtime Profiles, Core Pack templates, optional packs, and Self-Eval Loop.
- Added project-memory templates for `active-task.md`, `verifier-map.md`, `task-history.md`, and `failure-patterns.md`, while keeping legacy `task-ledger.md` compatibility.
- Added adapter templates for Claude Code, Hermes Agent, OpenClaw/OpenCode-style agents, and Codex nested scopes.
- Updated context budget, agent compatibility, recovery, release checklist, README mirrors, public changelog, local sync coverage, and public safety checks for the v0.2 contract surface.
- Updated the `v0.1.0` and `v0.2.0` GitHub Release titles and notes to use formal project naming, native Chinese primary copy, collapsible English mirrors, and public change-log style content; added release checklist rules for future release titles, bilingual writing quality, and keeping routine verification logs out of public Release bodies.

## 2026-05-20

- Added usage-driven `pmm` guidance for keeping generated `AGENTS.md` files project-specific, requiring concrete source artifacts before PRD/requirements/source reviews, and defining subagent role and ownership boundaries before authorized subagent work.
- Tightened local skill sync so unmanaged files inside the dedicated local `pmm` skill directory are removed during sync, preventing stale local skill files from surviving.
- Completed the 2026-05-20 optimization release with repository-wide security review, public `main` push, public repository visibility verification, and local skill sync from public `main`.
- Added formal public versioning with `VERSION`, `SKILL.md` frontmatter version, public `CHANGELOG.md`, release checklist rules, sync coverage, and public safety validation for version consistency.
- Published formal release `v0.1.0` and synced the local `pmm` skill installation with the release version files.
- Clarified MIT license visibility in README files and added release/public-safety checks that require the root `LICENSE` file and README license links.
- Added `LICENSE` to local skill sync coverage so installed skill copies preserve license terms.

## 2026-05-15

- Added `docs/context-budget.md` and updated `SKILL.md`, templates, README files, compatibility notes, local sync, and public safety checks so `pmm` reduces context and token use through staged reading and concise durable updates.
- Added no-op recovery guidance so routine recovery checks that find no active task, drift, or follow-up do not create task-ledger noise.

## 2026-05-14

- Changed the default repository overview to Simplified Chinese in `README.md`, added `README.en.md`, and added language switch links between the two files.
- Added cross-agent compatibility guidance for Claude Code, Hermes, OpenCode/OpenClaw-style agents, and other AGENTS.md-aware coding agents.
- Added the Agent Skills `compatibility` frontmatter to `SKILL.md` and documented that generated `AGENTS.md` plus project-local `docs/` are the portable project memory output.
- Updated the project document skeleton with optional Claude Code, Hermes, and OpenCode/OpenClaw compatibility shims.
- Expanded local skill sync to include `docs/agent-compatibility.md`.

## 2026-05-13

- Completed scheduled security review for the public `pmm` repository; no frontend/backend application code, dependencies, committed secrets, auth flow, payment flow, or database layer were present.
- Added repository-specific security rules for recurring reviews, local sync boundaries, and auto-merge policy.
- Hardened public safety checks to use per-run temp files and reject symlinks, committed `.env` files, and unexpected executable files outside reviewed scripts.
- Hardened local skill sync with destination path validation, symlink rejection, and cloned-repository symlink/executable checks before `rsync --delete`.
- Tightened the auto-merge workflow draft so external PRs require a maintainer-applied `safe-auto-merge` label and external `SKILL.md` changes remain manual review only.
- Published the sanitized public repository structure.
- Added safety scanning and local skill sync scripts.
- Added automation documentation and GitHub Actions workflow examples as non-active drafts.
- Added root project memory so future agents can load and maintain this repository consistently.
- Added project-local runtime storage rules for temporary files, backups, and automation source prompts.
- Added remote compact stream disconnect recovery rules and recovery automation prompt.
- Added file-purpose header requirements so future agents can skip irrelevant files faster.
- Expanded local skill sync to include compact recovery automation docs and `scripts/recovery-status.sh`.
- Renamed the public skill call name and repository references to `pmm`, displayed as `Project Memory Manager`.
