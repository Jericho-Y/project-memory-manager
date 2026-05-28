# Current State

Purpose: Snapshot of repository phase, active objective, working facts, and remaining risks.
Read when: Resuming work, checking current repository status, or deciding next action.
Skip when: You only need static public installation instructions.

## Status

The public repository is initialized and published as a generic Codex skill repository.

## Active Objective

Maintain `pmm` v0.2.1 as a low-context, cross-agent project runtime with Self-Eval Loop, Core Pack templates, adapter templates, legacy migration, and synchronized public documentation.

## Current Facts

- Public safety checks are enforced through `scripts/check-public-safety.sh`.
- Public releases use `VERSION`, `SKILL.md` frontmatter `version:`, public `CHANGELOG.md`, matching git tags, and GitHub Releases.
- GitHub Release titles use the full public project name, for example `Project Memory Manager v0.2.0`.
- GitHub Release notes are bilingual for this repository: Chinese is the primary body, and the English mirror is kept in a collapsible details block.
- Public GitHub Release notes use concise changelog-style sections such as added, changed, maintenance, compatibility, and upgrade notes; routine verification command lists stay in internal release records.
- Normal public releases include a `Full Changelog` compare link; the first public release links to the source tag.
- Chinese release notes should read like native release copy; avoid generic language labels such as `中文说明` and standalone language headings such as `English`.
- `v0.2.0` introduces Runtime Profiles, Core Pack templates, optional packs, Self-Eval Loop docs, memory promotion rules, verifier recipes, and agent adapter templates.
- `v0.2.1` adds `docs/legacy-migration.md` so v0.1 projects using `task-ledger.md` can be lightly upgraded into the v0.2 hot path instead of remaining in compatibility-only mode.
- New projects should use `docs/00-project-memory/active-task.md` as the current-task hot path and keep completed history in `task-history.md`.
- This repository now has its own `docs/00-project-memory/active-task.md` and `docs/00-project-memory/verifier-map.md`; legacy `task-ledger.md` remains as historical maintenance record.
- Legacy `task-ledger.md` remains supported as a v0.1 bridge, especially for existing projects that have not migrated.
- The repository uses the root `LICENSE` file for MIT licensing, and README files link to it for public users.
- The skill's public call name is `pmm`, displayed as `Project Memory Manager`.
- Public repository examples use the repository slug `pmm` with an owner placeholder.
- `README.md` is the default Simplified Chinese repository overview; `README.en.md` is the English mirror and both files link to each other for language switching.
- Local skill installation uses `<SKILLS_ROOT>/pmm`.
- Local skill sync is handled by `scripts/sync-local-skill.sh`.
- Local sync temporary files and backups default to `.project-runtime/` inside the repository.
- `scripts/recovery-status.sh` identifies active or retryable task entries from `active-task.md` or legacy `task-ledger.md`.
- Local skill sync includes `SKILL.md`, templates, runtime/self-eval/memory/verifier docs, the agent compatibility guide, compact recovery automation docs, and the recovery status helper.
- Local skill sync includes the legacy migration guide so installed skills can upgrade v0.1 project outputs into the v0.2 execution path.
- Local skill sync includes `LICENSE`, `VERSION`, and `CHANGELOG.md` so installed skill copies preserve license and release metadata.
- GitHub Actions workflow examples are stored under `docs/github-actions-drafts/` until workflow publishing is explicitly reviewed and enabled.
- A daily maintenance automation can check the public repo, evaluate low-risk PRs, and sync the local skill after validation.
- A local GitHub intake automation can check open PRs and issues every few hours, generate read-only triage reports under `.project-runtime/github-intake/`, and must not merge, label, close, approve, or publicly comment without explicit owner authorization.
- A local skill evolution automation can review `pmm` every three days for upgrade opportunities and write read-only roadmap reports under `.project-runtime/skill-evolution/`; it must not edit, commit, push, release, activate workflows, or change GitHub state.
- Compact disconnect recovery is documented under `docs/08-automation/compact-disconnect-recovery.md`.
- Project-owned files should include a short purpose header so agents can decide quickly whether to read them.
- Repository security review boundaries are documented under `docs/00-project-memory/security-rules.md`.
- Context and token reduction rules are documented in `docs/context-budget.md`; `SKILL.md` stays under a 360-line safety budget and links to focused docs for detail.
- Public safety checks reject symlinks, committed `.env` files, blocked secret/key/archive/binary file types, and unexpected executable files outside reviewed scripts.
- Public safety checks verify required bilingual README links, the context-budget guide reference, and version consistency across `VERSION`, `SKILL.md`, and `CHANGELOG.md`.
- Public safety checks require the root `LICENSE` file and README license links.
- Local skill sync validates broad path mistakes, rejects symlink sync paths, and requires the destination to be a dedicated `pmm` skill directory.
- Local skill sync includes `docs/context-budget.md` so installed skills keep the token-reduction protocol.
- Local skill sync removes unmanaged files inside the dedicated local `pmm` skill directory so stale local files do not survive a sync.
- Auto-merge draft rules require maintainer-applied labeling for external low-risk PRs and skip external `SKILL.md` changes for manual review.
- Cross-agent compatibility is documented in `docs/agent-compatibility.md`; `SKILL.md` is the Agent Skills entrypoint and generated `AGENTS.md` plus the Core Pack is the portable project memory output.
- `pmm` now keeps generated project instructions project-specific, gates PRD/requirements/source reviews on concrete source artifacts, and requires subagent role and ownership boundaries before spawning when subagent work is authorized.
- The 2026-05-20 skill optimization release passed repository-wide security review, was pushed to public `main`, and was synced into the local `pmm` skill installation from public `main`.
- `v0.1.0` is the first formal public release version and is published as a GitHub Release.
- `v0.2.0` passed public safety, shell syntax, diff whitespace, recovery-status, active-task recovery smoke, local sync smoke checks, public push, matching tag publication, GitHub Release publication, and local installed skill sync.
- `v0.2.1` is a patch release to make v0.1-to-v0.2 project migration an explicit installed skill workflow.
- The `v0.1.0` and `v0.2.0` GitHub Release titles and notes were updated after publication to use the formal project name, native Chinese primary copy, collapsible English mirrors, concise changelog-style sections, and public links to source or full changelog without routine internal verification logs.

## Remaining Risks

- Workflow examples are not active until moved into `.github/workflows/` with the right repository permissions.
- Auto-merge rules must stay conservative because this repository controls agent behavior.
- Runtime recovery can resume agent work only when `active-task.md` or a legacy task ledger is kept current.
- Context savings depend on generated projects keeping hot-path files small and avoiding task state in agent adapters or global memories.
- Real Claude Code, Hermes Agent, and OpenClaw end-to-end runtime tests were not run locally; compatibility is based on documented adapter contracts and repository-level verification.
- This repository has no application frontend/backend, runtime auth, payment flow, database, or dependency manifest; scheduled security review covers repository scripts, docs, and automation boundaries only.
