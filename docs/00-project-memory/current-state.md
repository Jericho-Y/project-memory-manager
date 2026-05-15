# Current State

Purpose: Snapshot of repository phase, active objective, working facts, and remaining risks.
Read when: Resuming work, checking current repository status, or deciding next action.
Skip when: You only need static public installation instructions.

## Status

The public repository is initialized and published as a generic Codex skill repository.

## Active Objective

Maintain a safe public version of the `pmm` skill and keep local installations synchronized only after safety checks pass.

## Current Facts

- Public safety checks are enforced through `scripts/check-public-safety.sh`.
- The skill's public call name is `pmm`, displayed as `Project Memory Manager`.
- Public repository examples use the repository slug `pmm` with an owner placeholder.
- `README.md` is the default Simplified Chinese repository overview; `README.en.md` is the English mirror and both files link to each other for language switching.
- Local skill installation uses `<SKILLS_ROOT>/pmm`.
- Local skill sync is handled by `scripts/sync-local-skill.sh`.
- Local sync temporary files and backups default to `.project-runtime/` inside the repository.
- `scripts/recovery-status.sh` identifies active or retryable task ledger entries for recovery automation.
- Local skill sync includes `SKILL.md`, templates, the agent compatibility guide, compact recovery automation docs, and the recovery status helper.
- GitHub Actions workflow examples are stored under `docs/github-actions-drafts/` until workflow publishing is explicitly reviewed and enabled.
- A daily maintenance automation can check the public repo, evaluate low-risk PRs, and sync the local skill after validation.
- Compact disconnect recovery is documented under `docs/08-automation/compact-disconnect-recovery.md`.
- Project-owned files should include a short purpose header so agents can decide quickly whether to read them.
- Repository security review boundaries are documented under `docs/00-project-memory/security-rules.md`.
- Context and token reduction rules are documented in `docs/context-budget.md`; `SKILL.md` stays under a 500-line safety budget and links to that guide for detail.
- Public safety checks reject symlinks, committed `.env` files, blocked secret/key/archive/binary file types, and unexpected executable files outside reviewed scripts.
- Public safety checks verify required bilingual README links and the context-budget guide reference.
- Local skill sync validates broad path mistakes, rejects symlink sync paths, and requires the destination to be a dedicated `pmm` skill directory.
- Local skill sync includes `docs/context-budget.md` so installed skills keep the token-reduction protocol.
- Auto-merge draft rules require maintainer-applied labeling for external low-risk PRs and skip external `SKILL.md` changes for manual review.
- Cross-agent compatibility is documented in `docs/agent-compatibility.md`; `SKILL.md` is the Agent Skills entrypoint and generated `AGENTS.md` plus `docs/` is the portable project memory output.

## Remaining Risks

- Workflow examples are not active until moved into `.github/workflows/` with the right repository permissions.
- Auto-merge rules must stay conservative because this repository controls agent behavior.
- Runtime recovery can resume agent work only when the project task ledger is kept current.
- Context savings depend on generated projects keeping `project-index.md`, file purpose headers, and task ledgers current.
- This repository has no application frontend/backend, runtime auth, payment flow, database, or dependency manifest; scheduled security review covers repository scripts, docs, and automation boundaries only.
