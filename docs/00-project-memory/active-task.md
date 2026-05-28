# Active Task

Purpose: Current repository maintenance task contract, verifier, and recovery checkpoint.
Read when: Starting, executing, verifying, or recovering the current repository task.
Skip when: Doing a read-only lookup that does not change repository state.

## Status

- Runtime Profile: Audit
- Task ID: 2026-05-28-pmm-v0.2.1-legacy-migration
- Source Request: Make v0.1 project outputs usable through v0.2 execution features instead of only compatibility reading.
- Status: done
- Risk Level: normal
- Loop Budget: 3
- Current Attempt: 1
- Stop Condition: legacy migration docs, installed sync, public release, and local installed skill validation complete.

## Task

- Objective: publish-ready `pmm` v0.2.1 patch release for v0.1-to-v0.2 light migration.
- Scope: skill instructions, migration docs, README mirrors, changelog, safety/sync scripts, release checklist, and project memory.
- Allowed Files or Areas: public skill repository files.
- Forbidden Actions: secrets, private paths, workflow publishing, repository visibility changes, destructive git history edits.
- Source Artifacts: current repository files and public agent compatibility requirements.

## Harness

- Tools: shell, apply_patch, git, local safety scripts, subagent read-only review.
- Skills: pmm, codex-subagent-router fallback guidance.
- Agents or Roles: architecture review and documentation review subagents.
- Commands: public safety check, shell syntax check, diff whitespace check, recovery-status checks, local sync smoke test.
- Environment Notes: repository is public and must remain generic.

## Verifier

- Required Checks: `bash scripts/check-public-safety.sh`; `bash -n scripts/*.sh`; `git diff --check`; local sync smoke test; installed version and legacy guide check.
- Manual Acceptance: README and release notes explain that v0.1 outputs can be lightly migrated into v0.2 execution behavior.
- Evidence Needed: command results and changed-file summary.

## Critic

- Pass/Fail: pass.
- Missing Evidence: real external v0.1 project migration was not run in this turn.
- False-Pass Risk: installed skill copy could miss `docs/legacy-migration.md` if sync whitelist is wrong.
- Next Action: monitor the first real v0.1 project migration and refine the guide if needed.

## Repair

- Last Failure: none.
- Failure Class: none.
- Attempted Fix: not applicable.
- Next Concrete Action: monitor first real migrated project for missing fields or confusing steps.

## Record

- Verification Evidence: public safety check passed; shell syntax check passed; `git diff --check` passed; line budgets passed; public push, tag, GitHub Release, local sync, installed version check, and installed legacy guide check completed.
- Docs Updated: `SKILL.md`, `VERSION`, `CHANGELOG.md`, README mirrors, `docs/legacy-migration.md`, context budget, agent compatibility, template router, sync/safety scripts, release checklist, and project memory.
- Remaining Risk: real legacy project migration has not been tested against an external v0.1 project in this turn.
- Memory Promotion Decision: record v0.2.1 migration behavior in project memory and public changelog.
- Last Updated: 2026-05-28
