# Current State

Purpose: Snapshot of repository phase, active objective, working facts, and remaining risks.
Read when: Resuming work, checking current repository status, or deciding next action.
Skip when: You only need static public installation instructions.

## Status

The public repository is initialized and published as a generic Codex skill repository.

## Active Objective

Maintain a safe public version of the `project-requirements-system` skill and keep local installations synchronized only after safety checks pass.

## Current Facts

- Public safety checks are enforced through `scripts/check-public-safety.sh`.
- Local skill sync is handled by `scripts/sync-local-skill.sh`.
- Local sync temporary files and backups default to `.project-runtime/` inside the repository.
- `scripts/recovery-status.sh` identifies active or retryable task ledger entries for recovery automation.
- Local skill sync includes `SKILL.md`, templates, compact recovery automation docs, and the recovery status helper.
- GitHub Actions workflow examples are stored under `docs/github-actions-drafts/` until workflow publishing is explicitly reviewed and enabled.
- A daily maintenance automation can check the public repo, evaluate low-risk PRs, and sync the local skill after validation.
- Compact disconnect recovery is documented under `docs/08-automation/compact-disconnect-recovery.md`.
- Project-owned files should include a short purpose header so agents can decide quickly whether to read them.

## Remaining Risks

- Workflow examples are not active until moved into `.github/workflows/` with the right repository permissions.
- Auto-merge rules must stay conservative because this repository controls agent behavior.
- Runtime recovery can resume agent work only when the project task ledger is kept current.
