# Installation And Sync

Purpose: Ordinary installation and maintainer sync guidance for the `pmm` skill.
Read when: Installing the skill into an agent runtime, checking Windows/macOS/Linux layout, or updating local sync behavior.
Skip when: You are only using an already installed skill inside a project.

## Ordinary Install

Place this repository in the target agent skills root and keep the directory name `pmm`:

```text
<SKILLS_ROOT>/pmm/
```

Use the same logical layout on every platform:

```text
<SKILLS_ROOT>/pmm/       # macOS / Linux
<SKILLS_ROOT>\pmm\       # Windows
```

Minimum useful install:

```text
<SKILLS_ROOT>/pmm/
  SKILL.md
  VERSION
  CHANGELOG.md
  LICENSE
  docs/
  templates/
  scripts/recovery-status.sh
  scripts/pmm-doctor.sh
```

Non-maintainer users can install by downloading or copying the repository into that directory. They do not need to run `scripts/sync-local-skill.sh`.

PowerShell users can run the ordinary install helper from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-local-skill.ps1 -SkillsRoot <SKILLS_ROOT>
```

Pass the skills root, not the `pmm` directory itself; the helper creates `<SKILLS_ROOT>/pmm`. If `<SKILLS_ROOT>/pmm` already exists, the helper stops unless `-Force` is passed. `-Force` replaces managed `pmm` docs, templates, metadata, and helper files; use it only when you intentionally want to refresh that install.

## Maintainer Sync

`scripts/sync-local-skill.sh` is a maintainer tool. It clones a checked public repository, runs public safety checks, backs up the existing local skill directory, and syncs only into a dedicated `<SKILLS_ROOT>/pmm` target.

Set the public repository URL before running it if the default placeholder is still present:

```bash
REPO_URL=https://github.com/<owner>/project-memory-manager.git bash scripts/sync-local-skill.sh
```

Run the public safety check before publishing or syncing:

```bash
bash scripts/check-public-safety.sh
```

Do not point `LOCAL_SKILL_DIR` at a broad directory. The sync script requires the destination path to end in `/pmm` and rejects symlink targets.

## Project Runtime Check

Installed users may run the lightweight checker against a project:

```bash
bash <SKILLS_ROOT>/pmm/scripts/pmm-doctor.sh <PROJECT_ROOT>
```

The checker reports missing Core Pack files, missing verifier fields, overgrown hot-path files, and adapters that appear to copy task state. It is a validation aid, not a database, MCP service, indexer, or mandatory runtime dependency.
