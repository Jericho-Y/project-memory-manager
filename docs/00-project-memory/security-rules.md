# Security Rules

Purpose: Repository-specific security boundaries, automation controls, and recurring review scope.
Read when: Running a security review, changing scripts, changing automation, or publishing repository content.
Skip when: Editing unrelated public copy with no safety or automation impact.

## Scope

This repository does not contain an application frontend, backend service, database, payment flow, authentication flow, or runtime dependency manifest. Security reviews focus on public content safety, script execution boundaries, local sync safety, and automation policy.

## Required Controls

- Run `bash scripts/check-public-safety.sh` before publication or completion claims.
- Reject secrets, private paths, private infrastructure details, symlinks, committed `.env` files, blocked key/archive/binary file types, and unexpected executables.
- Sync local skill files only from checked `main` after public safety checks pass.
- Local sync destinations must be dedicated `pmm` skill directories and must not be symlinks.
- Do not auto-merge workflow, script, dependency, executable, binary, deployment, environment, or permission changes.
- External low-risk PRs require a maintainer-applied `safe-auto-merge` label.
- External `SKILL.md` changes require manual maintainer review because they can change agent behavior.

## Review Notes

For scheduled security reviews, separate findings into:

- Frontend: expected to be not applicable unless a real frontend app is added.
- Backend: expected to be not applicable unless a real backend/API service is added.
- Repository automation: scripts, GitHub Actions drafts, sync behavior, public safety scans, and release docs.

Record any durable security behavior change in `docs/00-project-memory/current-state.md`, `docs/00-project-memory/task-ledger.md`, and `docs/07-decisions/change-log.md`.
