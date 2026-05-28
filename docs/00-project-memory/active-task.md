# Active Task

Purpose: Current repository maintenance task contract, verifier, and recovery checkpoint.
Read when: Starting, executing, verifying, or recovering the current repository task.
Skip when: Doing a read-only lookup that does not change repository state.

## Status

- Runtime Profile: Audit
- Task ID: 2026-05-28-pmm-v0.2-runtime-upgrade
- Source Request: Upgrade `pmm` with low-context optimization, Self-Eval Loop, cross-agent adapters, and GitHub documentation.
- Status: done
- Risk Level: normal
- Loop Budget: 3
- Current Attempt: 1
- Stop Condition: v0.2 files, docs, scripts, checks, local sync validation, commit, GitHub push, tag, GitHub Release, and local installed skill sync complete.

## Task

- Objective: publish-ready `pmm` v0.2.0 upgrade.
- Scope: skill instructions, templates, installed docs, README mirrors, changelog, recovery/sync/safety scripts, example project, and project memory.
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

- Required Checks: `bash scripts/check-public-safety.sh`; `bash -n scripts/*.sh`; `git diff --check`; recovery-status on repository and v0.2 example; local sync smoke test.
- Manual Acceptance: README mirrors explain v0.2 for GitHub users; adapters stay pointer-only.
- Evidence Needed: command results and changed-file summary.

## Critic

- Pass/Fail: pass.
- Missing Evidence: real Claude Code, Hermes Agent, and OpenClaw runtime end-to-end tests were not run locally.
- False-Pass Risk: installed skill copy could miss new docs or adapters if sync whitelist is wrong.
- Next Action: monitor real compatibility feedback from Claude Code, Hermes Agent, and OpenClaw users.

## Repair

- Last Failure: initial safety check caught README trailing whitespace.
- Failure Class: formatting.
- Attempted Fix: removed trailing whitespace and reran checks.
- Next Concrete Action: monitor future usage for compatibility drift, recovery false positives, or overgrown project docs.

## Record

- Verification Evidence: public safety check passed; shell syntax check passed; `git diff --check` passed; repository and example recovery checks passed; active-task recovery smoke passed; local sync smoke test passed; public push, tag, GitHub Release, and installed-skill sync completed.
- Docs Updated: `SKILL.md`, `VERSION`, README mirrors, public changelog, runtime/self-eval/memory/verifier docs, compatibility docs, context budget, templates, scripts, example project, and project memory.
- Remaining Risk: real Claude Code, Hermes, and OpenClaw runtime end-to-end tests are not run locally.
- Memory Promotion Decision: v0.2 contract changes recorded in project memory and public changelog.
- Last Updated: 2026-05-28
