# Active Task

Purpose: Current repository maintenance task contract, verifier, and recovery checkpoint.
Read when: Starting, executing, verifying, or recovering the current repository task.
Skip when: Doing a read-only lookup that does not change repository state.

## Status

- Runtime Profile: Sprint
- Task ID: 2026-07-09-doc-simplification
- Source Request: Reduce the number of project documents and optimize each remaining document's responsibility.
- Status: done
- Risk Level: normal
- Loop Budget: 3
- Current Attempt: 1
- Stop Condition: overlapping runtime, maintenance, and optional-pack docs are consolidated; references and safety/sync rules are updated; verification passed.

## Task

- Objective: make the public `pmm` documentation set smaller and easier to route without weakening runtime, compatibility, safety, install, or verification behavior.
- Scope: consolidate runtime guidance, maintenance guidance, and optional-pack templates; update source references, safety rules, sync/install coverage, README mirrors, and project memory.
- Allowed Files or Areas: public docs, templates, scripts that enforce required docs/sync coverage, README mirrors, `SKILL.md`, `AGENTS.md`, changelogs, and project memory.
- Forbidden Actions: workflow publishing, repository visibility changes, destructive git history edits, private paths, secrets, real local install sync, or changing behavior outside documentation/template routing.
- Source Artifacts: user request, current repository files, `pmm` skill rules, repository verifier map, and read-only document audit subagent.

## Harness

- Tools: shell, apply_patch, git, local safety scripts.
- Skills: repository `pmm` rules.
- Agent Mode: assisted
- Delegated Scopes: read-only document structure audit and post-change review.
- Parent-Owned Path: implementation, integration, script/rule updates, and final verification.
- Agents or Roles: document-audit subagent and review subagent.
- Commands: `bash scripts/check-public-safety.sh`, `bash -n scripts/*.sh`, `bash scripts/pmm-doctor.sh .`, `git diff --check`, and targeted stale-reference searches.
- Environment Notes: repository is public and must remain generic; no real local paths, credentials, private domains, or user-specific machine details.

## Verifier

- Required Checks: `bash scripts/check-public-safety.sh`; `bash -n scripts/*.sh`; `bash scripts/pmm-doctor.sh .`; `git diff --check`; stale-reference search for deleted docs and old optional-pack paths.
- Manual Acceptance: the remaining docs have clear responsibilities; the installed skill still includes needed runtime, maintenance, compatibility, install, templates, and helpers.
- Evidence Needed: command results, changed/deleted/added-file summary, subagent review summary, and remaining risk.

## Critic

- Pass/Fail: pass.
- Missing Evidence: no real local install sync was run because this task did not update the user's installed skill.
- False-Pass Risk: low; stale path scans, public safety rules, sync includes, local Markdown links, and independent review found no blocking issue.
- Next Action: optional local sync smoke when preparing a release or updating an installed skill.

## Repair

- Last Failure: none.
- Failure Class: none.
- Attempted Fix: not applicable.
- Next Concrete Action: none.

## Record

- Verification Evidence: `bash scripts/check-public-safety.sh` passed; `bash -n scripts/*.sh` passed; `bash scripts/pmm-doctor.sh .` passed; `git diff --check` passed; stale-reference search for deleted docs returned no matches outside historical `task-ledger.md`; Markdown local link check passed across 36 Markdown files; read-only review subagent found no blocking issue.
- Docs Updated: `docs/runtime.md`, `docs/maintenance.md`, `templates/optional-packs.md`, `AGENTS.md`, `SKILL.md`, README mirrors, changelog mirrors, project memory, safety rules, sync script, and template router.
- Remaining Risk: real installed skill sync was not executed; local private marker extensions remain maintainer-local through `.project-runtime/public-safety-local-rules.conf` if needed.
- Memory Promotion Decision: record durable simplified-document behavior in project memory only; no global memory promotion.
- Last Updated: 2026-07-09
