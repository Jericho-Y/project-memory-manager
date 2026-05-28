# Scheduled Maintenance

Purpose: Source-of-truth procedure for safe scheduled repository maintenance and local sync.
Read when: Creating, auditing, or running scheduler/automation maintenance for this repository.
Skip when: Working on skill behavior unrelated to repository maintenance.

## Purpose

Keep maintenance logic inside the project folder. External scheduler or automation entries should point to this file instead of becoming the only source of truth.

## Safe Repository Maintenance

Use this procedure for a public skill repository:

1. Confirm the working directory is the intended repository.
2. Pull the default branch with fast-forward only.
3. Stop if local files are dirty or the branch cannot fast-forward.
4. Run the public safety check.
5. Inspect open pull requests.
6. Skip drafts, conflicts, failing checks, high-risk file changes, workflow changes, script changes, dependency changes, executable files, binary files, symlinks, deployment config, secrets, or environment config.
7. Auto-merge only low-risk documentation or template changes that match the repository policy and, for external contributors, have a maintainer-applied `safe-auto-merge` label.
8. Never auto-merge external `SKILL.md` changes; they affect agent behavior and require manual maintainer review.
9. Re-run the public safety check after merge or pull.
10. Confirm v0.2 docs, Core Pack templates, adapter templates, and recovery helpers are included in local sync.
11. Sync local installations only after checks pass.
12. Report what changed, what was skipped, and remaining risk.

## Local Sync Boundary

Local sync may update only a dedicated `pmm` skill directory. It must not overwrite unrelated projects, global configuration, credentials, memories, or production files, and sync paths must not be symlinks.
