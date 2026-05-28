# Task Ledger

Purpose: Task checkpoint and recovery ledger for repository maintenance work.
Read when: Starting, resuming, or recovering any non-trivial task in this repository.
Skip when: Performing a read-only lookup that will not change state.

## 2026-05-28 GitHub Repository Slug Normalization

- Status: completed
- Objective: rename the public GitHub repository slug to lowercase `project-memory-manager` while preserving the display name `Project Memory Manager` and skill call name `pmm`.
- Selected docs: `docs/automation.md`, `scripts/sync-local-skill.sh`, `docs/00-project-memory/current-state.md`, `docs/07-decisions/change-log.md`
- Current checkpoint: GitHub repository slug and local `origin` remote have been updated; public Release links and local sync references use the lowercase slug.
- Next concrete action: monitor old GitHub redirects and future automation reports for stale `Project-Memory-Manager` references.
- Retry count: 0
- Last error or interruption: none.
- Verification status: passed public safety check, shell syntax check, diff whitespace check, remote-head check, open-PR query on new slug, GitHub Release link update, automation prompt update, push to `main`, and local skill sync.

## 2026-05-28 pmm v0.2.1 Legacy Migration Patch

- Status: completed
- Objective: make v0.1 project outputs usable through v0.2 execution features instead of only compatibility reading.
- Selected docs: `SKILL.md`, `VERSION`, `CHANGELOG.md`, `README.md`, `README.en.md`, `docs/legacy-migration.md`, `docs/context-budget.md`, `docs/agent-compatibility.md`, `templates/document-skeletons.md`, `scripts/check-public-safety.sh`, `scripts/sync-local-skill.sh`, `docs/00-project-memory/current-state.md`, `docs/07-decisions/change-log.md`
- Current checkpoint: v0.2.1 adds an explicit light migration workflow from legacy `task-ledger.md` projects into the v0.2 hot path with `active-task.md` and `verifier-map.md`.
- Next concrete action: monitor the first real migrated v0.1 project for missing fields or confusing steps.
- Retry count: 0
- Last error or interruption: none.
- Verification status: passed public safety check, shell syntax check, diff whitespace check, line-budget checks, public release, local sync, installed version check, and installed legacy guide check.

## 2026-05-28 pmm v0.2.0 Runtime Upgrade

- Status: completed
- Objective: upgrade `pmm` from a full document-tree controller to a low-context, cross-agent project runtime with Self-Eval Loop, Core Pack templates, adapter templates, verifier recipes, memory promotion rules, and GitHub-facing documentation.
- Selected docs: `AGENTS.md`, `SKILL.md`, `README.md`, `README.en.md`, `CHANGELOG.md`, `VERSION`, `docs/context-budget.md`, `docs/agent-compatibility.md`, `docs/runtime-profiles.md`, `docs/self-eval-loop.md`, `docs/memory-promotion.md`, `docs/verifier-recipes.md`, `templates/document-skeletons.md`, `templates/core/`, `templates/packs/`, `templates/adapters/`, `scripts/check-public-safety.sh`, `scripts/sync-local-skill.sh`, `scripts/recovery-status.sh`
- Selected execution skills: `pmm`, `codex-subagent-router`; read-only subagents were used for architecture and documentation review.
- Current checkpoint: v0.2 files, docs, templates, examples, scripts, public README mirrors, changelog, and repository memory have been updated, pushed, tagged, released, and synced into the local installed skill.
- Next concrete action: monitor real usage for compatibility drift, recovery false positives, overgrown project docs, or adapter confusion.
- Retry count: 1
- Last error or interruption: initial public safety check failed on README trailing whitespace; fixed and revalidated.
- Verification status: passed public safety check, shell syntax check, `git diff --check`, repository recovery-status check, example recovery-status check, active-task recovery smoke test, local sync smoke test, GitHub push, tag publication, GitHub Release publication, public-source local skill sync, and installed-version check.

## 2026-05-20 Usage-Driven Skill Optimization Review

- Status: completed
- Objective: review and improve `pmm` based on recent project use patterns, with emphasis on project-specific instructions, source-material intake before reviews, subagent role boundaries, and public safety.
- Selected docs: `AGENTS.md`, `SKILL.md`, `README.md`, `README.en.md`, `docs/automation.md`, `docs/agent-compatibility.md`, `docs/context-budget.md`, `docs/00-project-memory/current-state.md`, `docs/00-project-memory/task-ledger.md`, `docs/00-project-memory/recovery-rules.md`, `docs/00-project-memory/security-rules.md`, `templates/document-skeletons.md`, `scripts/check-public-safety.sh`
- Selected execution skills: `pmm`, `superpowers:using-superpowers`, `superpowers:writing-skills`, `superpowers:test-driven-development`, `superpowers:verification-before-completion`; Codex Security instructions were used as a safety review lens, with full repository security scan intentionally out of scope for this skill-optimization task.
- Current checkpoint: `SKILL.md`, `templates/document-skeletons.md`, README mirrors, `current-state.md`, and `change-log.md` now include the project-specific instruction rule, source artifact gate, and subagent role-boundary guidance.
- Next concrete action: monitor future usage for repeated review-intake misses, project `AGENTS.md` overgrowth, or subagent handoff ambiguity.
- Retry count: 0
- Last error or interruption: none.
- Verification status: passed public safety check, targeted guidance-anchor check, and `SKILL.md` 500-line budget check.

## 2026-05-20 Complete Skill Optimization Release

- Status: completed
- Objective: complete all previously deferred release steps: full repository security scan, commit and push, local skill sync, and final verification.
- Selected docs: `AGENTS.md`, `SKILL.md`, `README.md`, `README.en.md`, `SECURITY.md`, `docs/automation.md`, `docs/00-project-memory/current-state.md`, `docs/00-project-memory/task-ledger.md`, `docs/00-project-memory/recovery-rules.md`, `docs/00-project-memory/security-rules.md`, `docs/07-decisions/change-log.md`, `scripts/check-public-safety.sh`, `scripts/sync-local-skill.sh`, `scripts/recovery-status.sh`, workflow drafts under `docs/github-actions-drafts/`
- Selected execution skills: `pmm`, `codex-security:security-scan`, `superpowers:finishing-a-development-branch`, `superpowers:verification-before-completion`.
- Current checkpoint: full repository security scan completed with no reportable findings; skill optimization and local-sync cleanup commits were pushed to public `main`; local `pmm` skill was resynced from public `main` and now contains only managed whitelist files.
- Next concrete action: monitor future usage for repeated review-intake misses, project `AGENTS.md` overgrowth, stale local sync files, or subagent handoff ambiguity.
- Retry count: 0
- Last error or interruption: none.
- Verification status: passed repository-wide security scan, shell syntax check, public safety check, `git diff --check`, public repository visibility check, push to `main`, local skill sync from public `main`, local skill file diff checks, stale-file cleanup check, and final recovery-status check.

## 2026-05-20 Formal Versioning and Release Notes

- Status: completed
- Objective: add formal public version tracking and release notes so skill users can see which version they installed and what changed.
- Selected docs: `AGENTS.md`, `SKILL.md`, `README.md`, `README.en.md`, `VERSION`, `CHANGELOG.md`, `docs/release-checklist.md`, `docs/00-project-memory/current-state.md`, `docs/00-project-memory/task-ledger.md`, `docs/07-decisions/change-log.md`, `scripts/check-public-safety.sh`, `scripts/sync-local-skill.sh`
- Selected execution skills: `pmm`, `superpowers:finishing-a-development-branch`, `superpowers:verification-before-completion`.
- Current checkpoint: version files, public changelog, README links, release checklist rules, safety-check version validation, and local sync coverage have been committed and pushed; tag `v0.1.0` and GitHub Release were published; local `pmm` skill sync now includes `VERSION` and `CHANGELOG.md`.
- Next concrete action: increment `VERSION`, `SKILL.md` frontmatter version, and `CHANGELOG.md` for future public behavior changes before tagging a new release.
- Retry count: 0
- Last error or interruption: initial patch failed because README heading text did not match the expected patch context; corrected by applying patches against the actual file content.
- Verification status: passed public safety check, shell syntax check, version consistency checks, `git diff --check`, push to public `main`, tag push, GitHub Release verification, local skill sync, and installed-version check.

## 2026-05-20 License Visibility Check

- Status: completed
- Objective: confirm and clarify the open source license setup for public users.
- Selected docs: `LICENSE`, `README.md`, `README.en.md`, `docs/release-checklist.md`, `scripts/check-public-safety.sh`, `docs/00-project-memory/current-state.md`, `docs/07-decisions/change-log.md`
- Current checkpoint: repository already uses MIT License and GitHub detects it; README files now link to `LICENSE`; release checklist and public safety checks require license visibility; local skill sync now includes `LICENSE`.
- Next concrete action: keep MIT unless maintainer explicitly chooses a different license family.
- Retry count: 0
- Last error or interruption: none.
- Verification status: passed public safety check, README license-link check, GitHub license detection check, and local sync license coverage check; pending commit and push.

## 2026-05-15 Usage-Driven Skill Improvements

- Status: completed
- Objective: improve `pmm` based on recent real usage, focusing on reduced context/token use, reduced recovery noise, bilingual README drift prevention, and safer behavior-change propagation.
- Selected docs: `AGENTS.md`, `SKILL.md`, `README.md`, `README.en.md`, `docs/automation.md`, `docs/agent-compatibility.md`, `docs/context-budget.md`, `docs/00-project-memory/current-state.md`, `docs/00-project-memory/task-ledger.md`, `docs/00-project-memory/recovery-rules.md`, `docs/07-decisions/change-log.md`, `docs/08-automation/compact-disconnect-recovery.md`, `templates/document-skeletons.md`, `scripts/check-public-safety.sh`, `scripts/sync-local-skill.sh`
- Selected execution skills: `pmm`, `skill-creator`, `writing-skills`
- Current checkpoint: context-budget protocol, no-op recovery rules, bilingual README references, local sync scope, and public safety checks have been updated.
- Next concrete action: monitor future usage for places where generated project docs still grow too large or agents still read more files than needed.
- Retry count: 0
- Last error or interruption: none.
- Verification status: passed public safety check, shell syntax check, `git diff --check`, line-budget check, and recovery-status check after completion.

## 2026-05-15 Recovery Check

- Status: completed
- Objective: resume the current repository safely from project-local memory and determine whether any active or retryable task needs continuation.
- Selected docs: `AGENTS.md`, `SKILL.md`, `README.md`, `docs/automation.md`, `docs/00-project-memory/current-state.md`, `docs/00-project-memory/task-ledger.md`, `docs/00-project-memory/recovery-rules.md`, `docs/07-decisions/change-log.md`, `docs/08-automation/compact-disconnect-recovery.md`, `scripts/recovery-status.sh`
- Current checkpoint: recovery status returned no active or retryable task; `main` is aligned with `origin/main`; the public repository is still public.
- Next concrete action: start a new maintenance, compatibility, security, or release task only when requested or when automation finds a concrete issue.
- Retry count: 0
- Last error or interruption: none.
- Verification status: passed public safety check; no code, skill behavior, automation policy, or repository configuration changes were required.

## 2026-05-14 Chinese README Default

- Status: completed
- Objective: make the repository overview default to Chinese while preserving English documentation and language switching.
- Selected docs: `AGENTS.md`, `README.md`, `docs/00-project-memory/current-state.md`, `docs/00-project-memory/task-ledger.md`, `docs/07-decisions/change-log.md`, `scripts/check-public-safety.sh`
- Current checkpoint: `README.md` is now the Simplified Chinese default, `README.en.md` preserves the English mirror, and both files link to each other.
- Next concrete action: keep both README files synchronized when public overview content changes.
- Retry count: 0
- Last error or interruption: none.
- Verification status: passed public safety check, shell syntax check, `git diff --check`, and README language switch assertions.

## 2026-05-14 Agent Compatibility Review

- Status: completed
- Objective: check and improve `pmm` compatibility with mainstream coding agents including OpenClaw/OpenCode-style agents, Hermes, and Claude Code.
- Selected docs: `AGENTS.md`, `SKILL.md`, `README.md`, `templates/document-skeletons.md`, `docs/00-project-memory/current-state.md`, `docs/00-project-memory/task-ledger.md`, `docs/07-decisions/change-log.md`, `scripts/sync-local-skill.sh`
- Selected execution skills: `skill-creator`; local agent discovery notes and official Agent Skills, Claude Code, OpenCode, and Hermes documentation checked for compatibility mapping.
- Current checkpoint: compatibility guide, `SKILL.md` frontmatter, README install notes, project skeleton shims, and local sync scope updated.
- Next concrete action: monitor future agent format drift and update `docs/agent-compatibility.md` when a target agent changes its skill or instruction-file conventions.
- Retry count: 0
- Last error or interruption: none.
- Verification status: passed public safety check, shell syntax check, staged diff check, frontmatter/compatibility guide check, and local sync smoke test using `file://` clone into ignored `.project-runtime/`.

## 2026-05-13 Scheduled Security Review

- Status: completed
- Objective: review repository code and automation for auth, permission, secret, injection, privacy, dependency, and configuration risks.
- Selected docs: `AGENTS.md`, `SKILL.md`, `README.md`, `SECURITY.md`, `docs/automation.md`, `docs/00-project-memory/current-state.md`, `docs/00-project-memory/security-rules.md`, `docs/00-project-memory/recovery-rules.md`, `docs/07-decisions/change-log.md`, `scripts/check-public-safety.sh`, `scripts/sync-local-skill.sh`, `scripts/recovery-status.sh`, `docs/github-actions-drafts/ci.yml.example`, `docs/github-actions-drafts/daily-auto-merge.yml.example`
- Selected execution skills: `security-best-practices`; no frontend/backend framework references applied because this repository contains no frontend or backend application code.
- Current checkpoint: no application frontend/backend, dependencies, committed secrets, auth flow, payment flow, or database layer found; repository automation and sync hardening completed.
- Next concrete action: monitor future scheduled reviews and keep auto-merge/local sync boundaries conservative.
- Retry count: 0
- Last error or interruption: none.
- Verification status: passed `bash scripts/check-public-safety.sh`; passed `bash -n` for all scripts; local sync smoke test passed with ignored `.project-runtime/` destination; recovery status returns no active task after completion.

## 2026-05-13 Public Repository Setup

- Status: completed
- Objective: publish a sanitized public repository for the `pmm` skill.
- Selected docs: `SKILL.md`, `README.md`, `docs/automation.md`, `SECURITY.md`
- Verification: public safety check passed; repository published as public; local skill sync completed.
- Recovery checkpoint: use `git status`, run `bash scripts/check-public-safety.sh`, then inspect the public repository settings before continuing maintenance.

## 2026-05-13 Compact Recovery and File Headers

- Status: completed
- Objective: keep all project-related operating files inside the project folder and add compact disconnect recovery plus file-purpose headers.
- Selected docs: `AGENTS.md`, `SKILL.md`, `docs/automation.md`, `docs/00-project-memory/recovery-rules.md`, `templates/document-skeletons.md`
- Current checkpoint: recovery docs, project-local runtime storage, and file header rules added.
- Next concrete action: monitor daily automation and use recovery ledger for future interrupted tasks.
- Retry count: 0
- Last error or interruption: none
- Verification status: public safety check passed; file-purpose header scan passed; recovery status helper detected active task before completion and no active task after completion; local skill sync scope updated to include recovery docs and helper.

## 2026-05-13 Skill Rename

- Status: completed
- Objective: rename the skill, repository references, local sync path, and public documentation from the long descriptive name to `pmm`.
- Selected docs: `AGENTS.md`, `SKILL.md`, `README.md`, `docs/automation.md`, `docs/00-project-memory/current-state.md`, `docs/00-project-memory/recovery-rules.md`, `docs/07-decisions/change-log.md`
- Current checkpoint: repository text, sync script defaults, safety check temporary names, GitHub repository name, Git remote, and local skill installation have been updated to `pmm`.
- Next concrete action: publish the local commits when ready.
- Retry count: 0
- Last error or interruption: `skill-creator` registered path was unavailable locally, so repository-local maintenance rules were used.
- Verification status: public safety check passed; old-name scan passed except the intentional blocked-pattern entry inside `scripts/check-public-safety.sh`; GitHub repository and local `origin` point to `pmm`; local skill installation now exists at `<SKILLS_ROOT>/pmm`.

## 2026-05-13 Display Name Cleanup

- Status: completed
- Objective: keep the `pmm` call name and repository slug, but remove the acronym prefix from the public display name.
- Selected docs: `AGENTS.md`, `SKILL.md`, `README.md`, `docs/00-project-memory/current-state.md`, `docs/07-decisions/change-log.md`
- Current checkpoint: headings and display-name references changed to `Project Memory Manager`.
- Next concrete action: publish the local commits when ready.
- Retry count: 0
- Last error or interruption: none.
- Verification status: public safety check passed; local skill installation synced; GitHub repository description updated.
