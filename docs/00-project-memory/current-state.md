# Current State

Purpose: Snapshot of repository phase, active objective, current source-of-truth files, and remaining risks.
Read when: Resuming work, checking current repository status, or deciding next action.
Skip when: You only need static public installation instructions or release history.

## Status

The public repository is initialized and published as a generic Agent Skill repository.

## Active Objective

Maintain `pmm` v0.3.1 as a low-context, cross-agent project runtime with Self-Eval Loop, Subagent Routing Gate, Core Pack templates, adapter templates, lightweight runtime checks, trusted local sync, and a reduced public document set.

## Current Source Of Truth

- Skill entrypoint: `SKILL.md`.
- Repository entrypoint and maintenance rules: `AGENTS.md`.
- Public overview: `README.md`; English mirror: `README.en.md`.
- Runtime behavior: `docs/runtime.md`.
- Installation: `docs/install.md`.
- Maintenance, release, automation, safety, compact recovery, and customization: `docs/maintenance.md`.
- Cross-agent compatibility: `docs/agent-compatibility.md`.
- Project-memory hot path: `docs/00-project-memory/active-task.md`, `docs/00-project-memory/verifier-map.md`, and `docs/07-decisions/change-log.md`.
- Templates: Core Pack under `templates/core/`, optional packs in `templates/optional-packs.md`, adapters under `templates/adapters/`.
- Public safety rules: `scripts/public-safety-rules.conf`; scanner: `scripts/check-public-safety.sh`.
- Local skill sync: `scripts/sync-local-skill.sh`.
- Lightweight project checker: `scripts/pmm-doctor.sh`.
- Recovery status helper: `scripts/recovery-status.sh`.

## Current Facts

- Public releases use `VERSION`, `SKILL.md` frontmatter `version:`, public `CHANGELOG.md`, matching git tags, and GitHub Releases.
- Public release notes are bilingual: Chinese is primary, with English mirror coverage in `CHANGELOG.en.md` and release bodies when publishing.
- New generated projects should start with Core Pack only and add optional packs only when real facts exist.
- Product Pack uses project-root `PRD.md` as the default master requirements/product document.
- Optional packs now prefer one concise domain document before splitting into larger trees.
- Generated project memory must remain agent-neutral: `AGENTS.md` plus Core Pack is the source of truth, and adapters stay pointer-only.
- Subagent support is optional across runtimes; Agent Mode remains a recorded decision, not a mandatory capability.
- `scripts/pmm-doctor.sh` is a static checker and validation aid, not enforcement across all agents.
- Local skill sync removes unmanaged files inside the dedicated local `pmm` skill directory after safety checks pass.
- Workflow examples remain under `docs/github-actions-drafts/` until workflow publication is explicitly reviewed and enabled.

## Remaining Risks

- Workflow examples are not active until moved into `.github/workflows/` with the right repository permissions.
- Auto-merge rules must stay conservative because this repository controls agent behavior.
- Runtime recovery depends on `active-task.md` or legacy `task-ledger.md` staying current.
- Real Claude Code, Hermes Agent, and OpenClaw end-to-end runtime tests have not been run locally; compatibility is based on documented adapter contracts and repository-level verification.
- This repository has no application frontend/backend, runtime auth, payment flow, database, or dependency manifest; security review covers repository scripts, docs, and automation boundaries only.
