# Verifier Map

Purpose: Repository-specific verifier map for public `pmm` skill maintenance.
Read when: Selecting checks for skill, docs, template, script, sync, or release work.
Skip when: A task already has a complete verifier and no repository behavior changes.

## Default Checks

- Skill behavior: `bash tests/pmm-runtime-contract.sh`, `bash scripts/check-public-safety.sh`, `bash scripts/pmm-doctor.sh .`, version consistency, line-budget checks.
- Scripts: `bash -n scripts/*.sh scripts/lib/*.sh tests/*.sh`, targeted lifecycle smoke run when safe.
- Documentation: README mirror consistency, required links, changelog entry, no private markers.
- Templates: required Core Pack and adapter files exist, hot-path templates remain compact.
- Subagent routing: `docs/runtime.md` has Agent Mode guidance, `active-task.md` has Agent Mode fields, and docs keep routing detail out of the hot path.
- Structured tasks: test singleton primary state, separate state axes, simultaneous-start serialization, parent-close/child-start serialization, owner/branch/full-claim enforcement, interrupted-takeover rollback, failed-write rollback, uncommitted primary/child worktree discovery, ready-to-integrate retention, merged-commit acceptance, post-verification drift refusal, orphan-lock recovery, delivery preservation, stale evidence, close/archive, and JSON Doctor output.
- Recovery: `bash scripts/recovery-status.sh .`, legacy `In progress` normalization, `task-ledger.md` fallback, and ambiguous candidate refusal.
- Migration: dry-run first; verify active-task and task-ledger one-current-task backup/apply, completed-history exclusion, v0.2/v0.3 multi-section field preservation before Legacy Source, zero/multi-current no-write refusal, ledger preservation, and complete structured output.
- Local sync: run `scripts/sync-local-skill.sh` against a local checked repository or public `main` after commit; if claiming the local installed skill was updated, verify `<LOCAL_SKILL_DIR>/VERSION`, `<LOCAL_SKILL_DIR>/SKILL.md`, and every newly added installed file.
- Install/runtime checker: README mirrors link `docs/install.md`; Bash sync and PowerShell install include the CLI, shared library, concurrency templates, and contract test.
- Release: `git diff --check`, clean intended diff, tag/release verification when publishing.

## False-Pass Guards

- Do not publish a version when `VERSION`, `SKILL.md`, and `CHANGELOG.md` disagree.
- Do not claim v0.2 compatibility unless local sync includes new docs and adapter templates.
- Do not treat isolated sync smoke as proof that the user's real local skill install was updated.
- Do not treat adapter prose as enough; templates and safety checks must enforce pointer-only adapters.
- Do not claim subagent support as mandatory across agents; it is a recorded mode with runtime-specific execution.
- Do not describe `pmm-doctor` as enforcement across all agents; it is a static checker and validation aid.
- Do not delete legacy `task-ledger.md` support without a migration note.
- Do not treat `active-task.md` as a task list or allow two active writers on one branch/worktree.
- Do not close a task when verification evidence is missing or stale for the current HEAD/source hash.
- Do not force legacy migration or rewrite an ambiguous multi-task file automatically.
- Do not treat local claims as cross-device locks.
- Do not accept Git/hash failures as valid verifier evidence or release a claim before durable state transitions finish.
