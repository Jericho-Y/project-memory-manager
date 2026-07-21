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
  scripts/pmm-task.sh
  scripts/pmm-preflight.sh
  scripts/lib/pmm-state.sh
  tests/pmm-runtime-contract.sh
```

Non-maintainer users can install by downloading or copying the repository into that directory. They do not need to run `scripts/sync-local-skill.sh`.

PowerShell users can run the ordinary install helper from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-local-skill.ps1 -SkillsRoot <SKILLS_ROOT>
```

Pass the skills root, not the `pmm` directory itself; the helper creates `<SKILLS_ROOT>/pmm`. If `<SKILLS_ROOT>/pmm` already exists, the helper stops unless `-Force` is passed. `-Force` replaces managed `pmm` docs, templates, metadata, helper files, and runtime tests; use it only when you intentionally want to refresh that install.

The PowerShell helper installs the complete package, but the v0.5 runtime helpers are Bash scripts. Running `pmm-task.sh`, `pmm-doctor.sh`, `recovery-status.sh`, `pmm-preflight.sh`, or the contract test on Windows requires a Bash environment with Git and `rg`; source hashing also requires `shasum` or `sha256sum`. Projects may still follow the Markdown contract manually when those tools are unavailable.

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
bash <SKILLS_ROOT>/pmm/scripts/pmm-doctor.sh --json <PROJECT_ROOT>
```

The checker reports missing Core Pack files, invalid or duplicate task state, same-branch concurrency, stale verifier evidence, overgrown hot-path files, and adapters that appear to copy task state. It is a validation aid, not a database, MCP service, indexer, or mandatory runtime dependency.

Use the lifecycle helper for structured v0.5 tasks:

```bash
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh status --project <PROJECT_ROOT>
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh integrate --project <PROJECT_ROOT> --id <WORK_ITEM_ID> --owner <PRIMARY_OWNER>
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh migrate --project <PROJECT_ROOT> --plan
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh migrate --project <PROJECT_ROOT> --dry-run
```

Legacy projects remain readable without conversion. Run `migrate --plan` to inspect candidates without changing files, then the dry-run before explicit apply. Automatic apply is limited to one unambiguous task/source/status and writes a project-local backup. Split overloaded multi-task files manually because the helper deliberately refuses to guess.

Maintainers can run the release gate after syncing or building an install:

```bash
bash scripts/pmm-preflight.sh --installed "$HOME/.codex/skills/pmm"
```
