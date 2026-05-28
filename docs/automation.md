# Automation

Purpose: Explains repository automation, safe auto-merge boundaries, and local skill sync.
Read when: Updating automation, PR checks, auto-merge policy, or local sync behavior.
Skip when: Working only on project-memory templates or skill wording unrelated to automation.

## Daily Repository Check

Use a local scheduler, Codex automation, or GitHub Actions to run a daily repository check.
Workflow examples are available under `docs/github-actions-drafts/`. Move them into
`.github/workflows/` only after the repository account has permission to publish
workflows and after reviewing the auto-merge policy.

Keep the source-of-truth maintenance procedure in `docs/08-automation/scheduled-maintenance.md`. External automation entries should point back to that file so project logic stays in the project folder.

## GitHub Intake Automation

A local Codex automation may monitor open pull requests and issues for this repository.
The safe default is read-only triage:

- classify open PRs by risk and changed-file surface
- classify open issues as bug, feature request, documentation, question, security-sensitive, or unclear
- recommend owner actions
- write timestamped local reports under `.project-runtime/github-intake/`
- avoid secrets, tokens, private paths, and customer data in reports

The intake automation must not merge PRs, approve PRs, request changes publicly, add labels,
close issues, or post public comments unless the project owner explicitly authorizes that
behavior later.

## Skill Evolution Review

A local Codex automation may periodically review whether `pmm` itself should evolve.
The safe default is read-only planning:

- check whether `SKILL.md`, README files, docs, templates, examples, and scripts still match the current public positioning
- look for opportunities to reduce hot-path context, remove duplicated guidance, improve templates, improve recovery, or clarify verification behavior
- incorporate local GitHub intake reports when they exist
- classify recommendations by priority and likely version impact
- write timestamped reports under `.project-runtime/skill-evolution/`

The evolution automation must not edit files, commit changes, push, publish releases,
activate workflows, change repository settings, merge PRs, or publicly comment. It should
produce a candidate roadmap only; implementation remains a separate maintainer-approved task.

The safe auto-merge policy should merge low-risk pull requests only when:

- the pull request is not a draft
- checks pass
- changed files are in allowed paths
- no workflow, script, binary, dependency, or executable file changed
- external pull requests have a maintainer-applied `safe-auto-merge` label
- external pull requests that change `SKILL.md` are skipped for manual review even when labeled

This keeps automation useful without allowing unreviewed changes to CI, scripts, dependencies, or executable payloads.

## Local Skill Sync

GitHub Actions cannot safely update a local machine. Use a local scheduler or agent automation to run:

```bash
bash scripts/sync-local-skill.sh
```

The script:

1. clones the public repository into a temporary directory
2. checks out `main`
3. runs public safety checks
4. rejects symlinks and unexpected executable/script files
5. validates the destination is a dedicated `pmm` skill directory
6. backs up the existing local skill
7. syncs the approved skill files, templates, runtime/self-eval/memory/verifier docs, compatibility guide, context-budget guide, recovery docs, and recovery helper
8. removes unmanaged files inside the dedicated local `pmm` skill directory so stale local files do not survive a sync

By default, temporary sync files and local backups are placed under `.project-runtime/` in this repository, which is ignored by Git.

Set these environment variables if needed:

```bash
REPO_URL=https://github.com/<owner>/pmm.git
LOCAL_SKILL_DIR=<SKILLS_ROOT>/pmm
```

## Compact Disconnect Recovery

The compact disconnect recovery procedure lives in `docs/08-automation/compact-disconnect-recovery.md`.

When a runtime reports a remote compact stream disconnect, recovery automation should read the project-local active task or legacy task ledger, continue only from `Next Concrete Action`, and stop if the next action is high-risk or requires project-owner confirmation.
