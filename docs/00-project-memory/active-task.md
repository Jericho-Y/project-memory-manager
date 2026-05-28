# Active Task

Purpose: Current repository maintenance task contract, verifier, and recovery checkpoint.
Read when: Starting, executing, verifying, or recovering the current repository task.
Skip when: Doing a read-only lookup that does not change repository state.

## Status

- Runtime Profile: Sprint
- Task ID: 2026-05-28-pmm-v0.2.2-subagent-routing
- Source Request: Add a default lightweight subagent decision gate without increasing token cost for small tasks.
- Status: done
- Risk Level: normal
- Loop Budget: 3
- Current Attempt: 1
- Stop Condition: subagent routing docs, templates, README mirrors, checks, and local installed skill sync complete.

## Task

- Objective: publish-ready `pmm` v0.2.2 patch release for lightweight subagent routing.
- Scope: skill instructions, subagent routing docs, active-task template, README mirrors, changelog, safety/sync scripts, release checklist, examples, and project memory.
- Allowed Files or Areas: public skill repository files.
- Forbidden Actions: secrets, private paths, workflow publishing, repository visibility changes, destructive git history edits.
- Source Artifacts: current repository files, user request, and subagent read-only consistency review.

## Harness

- Tools: shell, apply_patch, git, local safety scripts, subagent read-only review.
- Skills: pmm, codex-subagent-router fallback guidance.
- Agent Mode: assisted
- Delegated Scopes: read-only documentation consistency review.
- Parent-Owned Path: main implementation, verification, integration, commit/push decision.
- Agents or Roles: documentation review subagent.
- Commands: public safety check, shell syntax check, diff whitespace check, recovery-status checks, local sync smoke test.
- Environment Notes: repository is public and must remain generic.

## Verifier

- Required Checks: `bash scripts/check-public-safety.sh`; `bash -n scripts/*.sh`; `git diff --check`; local sync smoke test; installed version and subagent routing guide check.
- Manual Acceptance: README explains subagent routing as a lightweight decision, not forced delegation.
- Evidence Needed: command results and changed-file summary.

## Critic

- Pass/Fail: pass.
- Missing Evidence: real Claude Code, Hermes, and OpenClaw runtime delegation behavior was not executed locally.
- False-Pass Risk: low; hot-path files remain within line budget and installed sync includes `docs/subagent-routing.md`.
- Next Action: monitor real task usage for over-delegation or under-delegation and tune defaults if repeated friction appears.

## Repair

- Last Failure: none.
- Failure Class: none.
- Attempted Fix: not applicable.
- Next Concrete Action: monitor first few substantial tasks using Agent Mode and refine docs only if the rule causes confusion or token waste.

## Record

- Verification Evidence: public safety check passed; shell syntax check passed; `git diff --check` passed; repository recovery check detected the active task before completion; example recovery smoke test passed; local skill sync smoke test passed; installed version and subagent routing guide checks passed.
- Docs Updated: `SKILL.md`, `VERSION`, `CHANGELOG.md`, README mirrors, `docs/subagent-routing.md`, self-eval, context budget, runtime profiles, agent compatibility, verifier map, release checklist, templates, examples, sync/safety scripts, and project memory.
- Remaining Risk: actual benefit depends on agent runtime support and whether future tasks have cleanly separable scopes.
- Memory Promotion Decision: record v0.2.2 subagent routing behavior in project memory and public changelog.
- Last Updated: 2026-05-28
