# Project Memory Manager

Purpose: Project entrypoint and highest-priority maintenance instructions for this repository.
Read when: Opening this repository, changing the skill, updating automation, or recovering interrupted work.
Skip when: Never skip during repository work.

## Project Role

This repository publishes the `pmm` Agent Skill. Its job is to help agents create low-context project memory, self-evaluating task execution, verification rules, recovery checkpoints, adapter shims, and safety boundaries for commercial-grade software projects.

## Current Phase

Public repository is initialized and open source. The active objective is to publish and maintain `pmm` v0.2.0 as a low-context, cross-agent project runtime with Self-Eval Loop, Core Pack templates, adapter templates, and trusted local sync.

## Mandatory Reading Order

1. `AGENTS.md`
2. `SKILL.md`
3. `README.md`
4. `docs/context-budget.md`
5. `docs/agent-compatibility.md`
6. `docs/00-project-memory/current-state.md`
7. `docs/00-project-memory/recovery-rules.md`
8. Relevant template, script, or documentation files for the task

## Task Reading Map

| Task type | Read |
| --- | --- |
| Skill behavior change | `SKILL.md`, `templates/document-skeletons.md`, `templates/core/`, `templates/packs/`, `templates/adapters/`, `docs/runtime-profiles.md`, `docs/self-eval-loop.md`, `docs/memory-promotion.md`, `docs/verifier-recipes.md`, `docs/context-budget.md`, `docs/agent-compatibility.md`, `docs/00-project-memory/current-state.md` |
| Agent compatibility review | `SKILL.md`, `README.md`, `docs/agent-compatibility.md`, `templates/adapters/`, `scripts/sync-local-skill.sh` |
| Public release or repository setup | `README.md`, `SECURITY.md`, `docs/release-checklist.md`, `docs/automation.md` |
| Automation or sync change | `docs/automation.md`, `scripts/check-public-safety.sh`, `scripts/sync-local-skill.sh` |
| Recovery or compact failure handling | `docs/00-project-memory/recovery-rules.md`, `docs/08-automation/compact-disconnect-recovery.md`, `scripts/recovery-status.sh` |
| Example project update | `examples/generic-app/AGENTS.md`, related example docs |
| Safety or privacy review | `SECURITY.md`, `docs/00-project-memory/security-rules.md`, `scripts/check-public-safety.sh`, `docs/07-decisions/change-log.md` |

## Project-Local Storage

- Keep all durable project files inside this repository.
- Put project memory, recovery rules, automation source prompts, and maintenance notes under `docs/`.
- Put temporary clones, local backups, logs, and checkpoints under `.project-runtime/` or `tmp/`; these paths are ignored by Git.
- External Codex or scheduler configuration may exist outside the repo only as a pointer back to the source-of-truth prompt in `docs/08-automation/`.

## Execution Rules

- Keep the public repo generic. Do not add personal names, private domains, local absolute paths, server inventory, credentials, or real production details.
- Do not weaken `scripts/check-public-safety.sh` without a clear reason and verification.
- Do not auto-merge changes to workflows, scripts, dependencies, executable files, secrets, or deployment configuration.
- Keep `SKILL.md` concise and put reusable details into `templates/` or `docs/`.
- Keep agent adapters pointer-only; do not copy full project docs or current task state into them.
- Keep v0.2 hot-path templates compact: `AGENTS.md`, `active-task.md`, and `verifier-map.md` should route work instead of becoming archives.
- If behavior changes, update `docs/00-project-memory/current-state.md` and `docs/07-decisions/change-log.md`.
- Treat remote compact stream disconnects as recoverable interruptions; resume from project-local active-task checkpoints instead of relying on chat context.

## Verification Rules

Before claiming completion, run the public safety check:

```bash
bash scripts/check-public-safety.sh
```

For repository configuration work, also confirm git status is clean and the public GitHub repository is still public.

## High-Risk Boundaries

Require maintainer confirmation before:

- publishing `.github/workflows/**`
- changing auto-merge rules
- deleting or rewriting git history
- changing repository visibility
- adding credentials, production paths, or private environment details
- changing local sync behavior to overwrite anything outside the skill directory
