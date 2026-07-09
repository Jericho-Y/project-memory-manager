# Verifier Map

Purpose: Repository-specific verifier map for public `pmm` skill maintenance.
Read when: Selecting checks for skill, docs, template, script, sync, or release work.
Skip when: A task already has a complete verifier and no repository behavior changes.

## Default Checks

- Skill behavior: `bash scripts/check-public-safety.sh`, `bash scripts/pmm-doctor.sh .`, version consistency, line-budget checks.
- Scripts: `bash -n scripts/*.sh`, targeted smoke run when safe.
- Documentation: README mirror consistency, required links, changelog entry, no private markers.
- Templates: required Core Pack and adapter files exist, hot-path templates remain compact.
- Subagent routing: `docs/runtime.md` has Agent Mode guidance, `active-task.md` has Agent Mode fields, and docs keep routing detail out of the hot path.
- Recovery: `bash scripts/recovery-status.sh .` and an active-task example smoke test.
- Local sync: run `scripts/sync-local-skill.sh` against a local checked repository or public `main` after commit; if claiming the local installed skill was updated, verify `<LOCAL_SKILL_DIR>/VERSION`, `<LOCAL_SKILL_DIR>/SKILL.md`, and every newly added installed file.
- Install/runtime checker: `docs/install.md` is linked from README mirrors and `scripts/pmm-doctor.sh` passes on this repository.
- Release: `git diff --check`, clean intended diff, tag/release verification when publishing.

## False-Pass Guards

- Do not publish a version when `VERSION`, `SKILL.md`, and `CHANGELOG.md` disagree.
- Do not claim v0.2 compatibility unless local sync includes new docs and adapter templates.
- Do not treat isolated sync smoke as proof that the user's real local skill install was updated.
- Do not treat adapter prose as enough; templates and safety checks must enforce pointer-only adapters.
- Do not claim subagent support as mandatory across agents; it is a recorded mode with runtime-specific execution.
- Do not describe `pmm-doctor` as enforcement across all agents; it is a static checker and validation aid.
- Do not delete legacy `task-ledger.md` support without a migration note.
