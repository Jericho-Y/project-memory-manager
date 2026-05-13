# Change Log

Purpose: Chronological record of durable repository behavior and maintenance changes.
Read when: You need recent change history or must update the record after state-changing work.
Skip when: You only need current instructions and no historical context.

## 2026-05-14

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
