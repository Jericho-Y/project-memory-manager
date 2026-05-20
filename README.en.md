# Project Memory Manager

Language: [简体中文](README.md) | English

Purpose: Public overview, installation guide, safety model, and repository map for the skill.
Read when: Evaluating, installing, publishing, or onboarding to this skill repository.
Skip when: You already know the repository shape and need a specific implementation file.

A Codex skill for starting and continuing long-lived software projects with durable requirements, project memory, verification, recovery checkpoints, and safety controls.

It is designed for commercial-grade apps, websites, mini programs, SaaS products, desktop tools, AI products, and substantial feature work. It is not intended for one-off shell commands or throwaway demos.

## What It Does

- Creates a project-level `AGENTS.md` as the first memory entrypoint.
- Keeps `AGENTS.md` project-specific instead of duplicating global working style or personal preferences.
- Builds a structured `docs/` tree for business, product, design, technical, delivery, operations, and decision records.
- Defines which documents an agent should read for each task type.
- Requires concrete source material before reviewing PRDs, requirements, screenshots, designs, documents, or code.
- Reduces context and token use through context-budget rules: read entrypoints, indexes, and needed sections before full project history.
- Tracks active work in `docs/00-project-memory/task-ledger.md`.
- Supports interrupted-work recovery with checkpoints and retry limits.
- Provides a compact-disconnect recovery procedure for stream interruption failures.
- Requires short file-purpose headers so agents can skip irrelevant files quickly.
- Requires verification before completion claims.
- Keeps high-risk actions behind project-owner confirmation.

## Repository Contents

```text
.
  SKILL.md
  README.md
  README.en.md
  templates/
    document-skeletons.md
    server-inventory.example.md
  examples/
    generic-app/
  docs/
    00-project-memory/
      recovery-rules.md
      security-rules.md
    agent-compatibility.md
    context-budget.md
    customization-guide.md
    release-checklist.md
    automation.md
    08-automation/
      compact-disconnect-recovery.md
      scheduled-maintenance.md
  scripts/
    check-public-safety.sh
    recovery-status.sh
    sync-local-skill.sh
```

## Installation

Copy this repository into your local skills directory, or copy the core skill files into your agent's skill folder:

```text
<SKILLS_ROOT>/pmm/
  SKILL.md
  templates/
  docs/
    agent-compatibility.md
    context-budget.md
```

Then reference the skill when starting, structuring, continuing, or recovering a project.

## Agent Compatibility

`pmm` uses the Agent Skills `SKILL.md` format, but its generated project memory is intentionally agent-neutral: the canonical project output is root `AGENTS.md` plus project-local `docs/`.

- Codex and other Agent Skills clients can install `pmm/SKILL.md` directly.
- Claude Code can install it under a Claude skills directory and use a short `CLAUDE.md` shim that points back to `AGENTS.md`.
- Hermes can install it as a `SKILL.md` skill and cite project memory files in handoffs.
- OpenCode/OpenClaw-style agents can use the generated `AGENTS.md` directly even when they do not load the skill package.

See `docs/agent-compatibility.md` for the full compatibility map and shim examples.

## Basic Workflow

1. Start a new project or identify an existing project.
2. Create or update project root `AGENTS.md`.
3. Create the requirements document tree under `docs/`.
4. Record the active task in `docs/00-project-memory/task-ledger.md`.
5. For review tasks, confirm the concrete PRD, screenshot, design, document, or code source first.
6. Read only the task-specific source documents.
7. Execute, verify, retry if safe, and update project memory.
8. Record decisions, risks, and changes in `docs/07-decisions/`.

See `docs/context-budget.md` for the detailed context and token reduction strategy.

## Safety Model

Never commit real secrets, production credentials, private server inventories, customer data, payment keys, deployment tokens, private chat logs, or local machine paths.

Use placeholders such as:

- `<PROJECTS_ROOT>`
- `<SKILLS_ROOT>`
- `<server-alias>`
- `<production-domain>`
- `<credential-reference>`

High-risk actions require explicit project-owner confirmation:

- real payment, refund, billing, or transaction actions
- production data deletion or migration
- credential, permission, user, order, or billing configuration changes
- external publication, messaging, app store submission, or customer-visible actions

## Optional Execution Integrations

This skill can coordinate with specialized execution workflows such as planning, TDD, systematic debugging, completion verification, deployment, security review, and subagent-based execution with role boundaries.

The project memory protocol stays in charge: specialized workflows may add checks, but they should not weaken project memory, verification, recovery, or security requirements.

## Checks

Run the public safety check before publishing:

```bash
bash scripts/check-public-safety.sh
```

The check blocks common sensitive terms, local paths, private project names, private domains, executable payloads, and accidental secret-like content.

## Automation

This repository includes local automation helpers:

- `scripts/check-public-safety.sh`: public safety and secret-like content scan.
- `scripts/sync-local-skill.sh`: local-only sync helper for copying the checked main branch into a local skills directory.

GitHub Actions should not directly access your local machine. Use a local scheduler or agent automation to check pull requests, merge only safe changes, and run `scripts/sync-local-skill.sh` after main has been checked and merged.

## License

MIT
