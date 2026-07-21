# Maintenance Guide

Purpose: Single guide for repository publication, automation, safety review, local sync, compact recovery prompts, and customization boundaries.
Read when: Publishing, syncing, automating, recovering after compact disconnect, reviewing security, or adapting the skill for an organization.
Skip when: Editing only project-memory templates or task-local docs with no publication, automation, or safety impact.

## Public Safety

Run before publication or completion claims:

```bash
bash scripts/check-public-safety.sh
bash scripts/pmm-doctor.sh .
git diff --check
```

For script changes, also run:

```bash
bash -n scripts/*.sh
bash scripts/pmm-preflight.sh
```

Required controls:
- reject secrets, credentials, private paths, private infrastructure, symlinks, committed `.env` files, blocked key/archive/binary file types, and unexpected executables
- keep public safety rule lists in `scripts/public-safety-rules.conf`
- keep maintainer-local markers in `.project-runtime/public-safety-local-rules.conf`
- keep examples generic with placeholders or `example.com`
- keep `LICENSE` in the root and README license links short

Security review scope for this repository is public content safety, scripts, local sync, automation policy, and static runtime checks. There is no app frontend, backend service, database, payment flow, auth flow, or dependency manifest unless those are added later.

## Release Checklist

Before a public release:
- check `git status` and review `git diff`
- stage only intended files
- update `VERSION`, `SKILL.md` frontmatter, and public changelog entries
- run public safety, shell syntax, `pmm-doctor`, and whitespace checks
- push to a branch and let CI run before merge
- tag with a matching semantic version, for example `v0.3.0`
- publish a GitHub Release from the tag only when the version is intended as formal public release
- run `bash scripts/pmm-preflight.sh --installed <SKILLS_ROOT>/pmm` after local sync so source and installed-package contracts both pass

Release notes:
- GitHub Release titles use the full display name, for example `Project Memory Manager v0.3.0`
- Chinese is the primary body when the repository overview is bilingual
- English mirrors should be inside a collapsible `<details>` block
- use concise changelog-style sections and omit empty sections
- include a `Full Changelog` compare link for normal releases, or a source tag link for the first public release
- write Chinese release notes as natural release copy, not direct English translation
- avoid generic standalone language headings such as `中文说明` or `English`
- keep routine verification logs in project memory or release-prep records, not in public release bodies

Contract checks:
- `SKILL.md` stays concise and points to `docs/runtime.md`, `docs/agent-compatibility.md`, and template docs
- lifecycle mutations run the Upgrade Gate; `runtime-state.md`, the managed `AGENTS.md` block, and legacy migration behavior stay covered by the runtime contract
- Core Pack templates exist and hot-path templates stay compact
- adapter templates exist for Claude Code, Hermes, OpenClaw/OpenCode, and Codex nested scopes
- `scripts/recovery-status.sh` supports v0.2 `active-task.md` and legacy `task-ledger.md`
- local sync includes installed docs, templates, metadata, and helper scripts
- PowerShell installer remains ordinary-install only and does not fetch remote code or perform maintainer sync

## Automation Boundaries

Workflow examples live under `docs/github-actions-drafts/`. Move them into `.github/workflows/` only after explicit maintainer review and repository permission checks.

Safe repository maintenance:
1. Confirm the intended repository.
2. Pull the default branch with fast-forward only.
3. Stop if local files are dirty or the branch cannot fast-forward.
4. Run public safety checks.
5. Inspect open pull requests.
6. Skip drafts, conflicts, failing checks, high-risk files, workflows, scripts, dependencies, executables, binaries, symlinks, deployment config, secrets, or environment config.
7. Auto-merge only low-risk documentation or template changes that match policy and, for external contributors, have a maintainer-applied `safe-auto-merge` label.
8. Never auto-merge external `SKILL.md` changes.
9. Re-run checks after merge or pull.
10. Sync local installs only after checks pass.
11. Report changes, skips, and remaining risk.

Local GitHub intake automation may produce read-only reports under `.project-runtime/github-intake/`. It must not merge, approve, request changes publicly, label, close, or comment unless explicitly authorized.

Skill evolution automation may produce read-only roadmap reports under `.project-runtime/skill-evolution/`. It must not edit files, commit, push, release, activate workflows, change GitHub settings, merge PRs, or publicly comment.

## Local Skill Sync

GitHub Actions cannot safely update a local machine. Maintainers use:

```bash
REPO_URL=https://github.com/<owner>/project-memory-manager.git bash scripts/sync-local-skill.sh
```

The sync script clones checked public `main`, runs safety checks, rejects symlinks and unexpected scripts, backs up the existing install, and syncs only into a dedicated `<SKILLS_ROOT>/pmm` directory. It must never overwrite unrelated projects, global config, credentials, memories, production files, or symlink targets.

Ordinary users should use the install guidance in `docs/install.md` instead of maintainer sync.

## Compact Disconnect Recovery

Use this path when a runtime reports a remote compact, context persistence, or stream disconnect failure.

Recovery prompt:

```text
Open the project root and read AGENTS.md first. Then read docs/00-project-memory/current-state.md, docs/00-project-memory/active-task.md, docs/00-project-memory/recovery-rules.md, and docs/07-decisions/change-log.md. If active-task.md is missing in a legacy project, read docs/00-project-memory/task-ledger.md instead.

If scripts/recovery-status.sh exists, run it from the project root.

Continue only if the active task or legacy task ledger contains a task with status active or failed-retryable. If no such task exists and there are no partial edits, running side effects, or new risks, stop without adding durable noise. Resume from Next Concrete Action only when recovery is needed.

Before retrying any command, inspect the workspace for partial edits, partial command output, running processes, generated files, migrations, deployments, or external side effects.

Do not perform payment, production data, credential, permission, publication, destructive, or customer-visible actions without explicit project-owner confirmation.

When work continues or a durable follow-up is found, update active-task.md with the interruption, checkpoint, next action, retry count, and verification status before stopping.
```

## Customization

Replace placeholders such as `<PROJECTS_ROOT>` and `<SKILLS_ROOT>` with organization-specific paths outside public docs.

Use `templates/server-inventory.example.md` only as a shape reference. Keep real server inventories private and ignored by Git.

If an agent runtime lacks specialized skills or subagents, keep the project memory, verification, and recovery rules and skip unavailable integrations.

Do not remove confirmation for production data, payment, credentials, external publication, or customer-visible actions unless a separate safety control exists.
