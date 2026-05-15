---
name: pmm
description: Use when starting, structuring, continuing, or taking over a commercial software project, app, website, mini program, SaaS, desktop tool, or large feature that needs durable requirements, project memory, autonomous execution, verification, and safety controls.
compatibility: Agent Skills SKILL.md format; durable project output is AGENTS.md plus docs, usable by Codex, Claude Code, Hermes, OpenCode/OpenClaw-style agents, and other AGENTS.md-aware coding agents. No runtime dependencies.
---

# Project Memory Manager

Purpose: Define the durable requirements, project memory, recovery, verification, and safety protocol for commercial-grade projects.
Read when: Starting, structuring, continuing, recovering, or maintaining a long-lived software project or this skill.
Skip when: The task is a one-off command, tiny edit, or unrelated to project memory.

## Overview

Build serious projects around durable requirements and project memory, not transient chat context. The agent owns execution end to end, while the project owner confirms high-risk decisions.

## When to Use

Use this skill when the project owner:
- Starts a new app, website, mini program, SaaS, desktop tool, AI product, commercial project, or large feature.
- Gives only an idea, theme, screenshot, rough requirement, or market direction.
- Asks for requirements, PRD, technical plan, roadmap, or project documents.
- Wants future agents to know what to read before executing.
- Continues an existing project whose durable memory or requirements are incomplete.

Do not use for one-off shell tasks, tiny edits, throwaway demos, or tasks that clearly do not need project memory.

## Core Principle

Every project must have a first memory file at the project root:

```text
AGENTS.md
```

`AGENTS.md` is the highest-priority project entrypoint. It should point to detailed documents under `docs/` instead of becoming a dumping ground.

When creating the document system, use `templates/document-skeletons.md` for the default section skeletons.

## Efficiency Defaults

- Read only the global/project memory needed to identify the project, task, risks, and source-of-truth docs.
- Prefer project `AGENTS.md`, `current-state.md`, and `task-ledger.md` over broad memory scans after the project is identified.
- Select task-specific docs from the reading map; do not load the full requirements tree by default.
- Record selected docs and selected execution skills once in `task-ledger.md`; reuse that checkpoint until the task changes.
- Use subagents for independent workstreams only when the project owner has authorized subagent execution and write scopes are disjoint.
- Keep documentation updates concise: current state, changed facts, verification, and remaining risk.
- Optimize for forward progress, but never weaken safety, verification, or secret-handling rules.

## Context Budget Protocol

Default to staged reading: entrypoint first, then indexes and purpose headers, then targeted sections, then full files only when editing or resolving ambiguity. Use `docs/context-budget.md` for the full token-reduction rules.

- Do not paste or duplicate large docs into task ledgers, handoffs, PR descriptions, or agent-specific shims; record file paths, section names, checkpoints, and concise deltas.
- Search before reading broad files when the target fact has keywords.
- Keep `AGENTS.md` and `SKILL.md` as routers, not archives. Move detailed reusable guidance into directly linked docs or templates.
- No-op recovery checks should stop cleanly without creating new ledger entries or commits.

## Usage-Driven Improvement Loop

When improving this skill from real use:
- Inspect recent `task-ledger.md`, `change-log.md`, recovery outcomes, and repeated user corrections.
- Convert repeated friction into one of: a core `SKILL.md` rule, a template change, a recovery rule, a safety check, or an automation note.
- Prefer small enforceable checks over long prose when drift can be detected by script.
- Keep public behavior generic; do not encode private project names, local paths, credentials, or one-user-only details.
- Propagate behavior changes to all affected surfaces: `SKILL.md`, templates, compatibility docs, README language mirrors, sync scope, and project memory.
- Record only durable lessons. Do not add task-ledger entries for routine read-only checks that find no active task, no drift, and no follow-up.

## Enforcement Layers

This skill works best through three layers:
- Workspace rule: a workspace-level `AGENTS.md` tells agents when to use this skill.
- Skill trigger: use this skill whenever the user starts, continues, structures, or rescues a commercial-grade project.
- Project memory: each project root `AGENTS.md` records the required reading path, active task, recovery checkpoint, and documentation update rules.

If any layer is missing in an existing project, retrofit the missing layer before doing substantial implementation.

## Agent Compatibility

The durable project output must stay usable outside Codex. Treat `SKILL.md` as the optional Agent Skills entrypoint and project `AGENTS.md` plus `docs/` as the canonical cross-agent output.

For Claude Code, Hermes, OpenCode/OpenClaw-style agents, and other AGENTS.md-aware clients, follow `docs/agent-compatibility.md`. Use short shims that point back to `AGENTS.md`; do not duplicate project rules into agent-specific files.

## Compatibility With Other Skills

This skill is the project-level controller. It should not replace specialized execution skills. Use this priority:

```text
Workspace/project instructions -> pmm -> specialized task skills -> tool-specific docs
```

When another skill applies, run the project memory protocol first, then use the specialized skill, then update the project documents.

| Other skill type | How to combine |
| --- | --- |
| Planning skills | Use for implementation-plan quality. Save durable plan facts into `roadmap.md`, `task-breakdown.md`, and relevant source docs. |
| Plan execution skills | Use when a written plan exists. Still record active task, checkpoint, retries, and final status in `task-ledger.md`. |
| Subagent workflows | Use only when the environment allows subagents and the project owner authorized parallel/subagent work. Record workstream ownership in `task-breakdown.md` and verify outputs before accepting them. |
| TDD skills | Use for features, bug fixes, refactors, and behavior changes. TDD satisfies part of verification, but does not replace project document updates. |
| Systematic debugging skills | Use for bugs, build failures, test failures, and unexpected behavior before attempting fixes. Record root cause and fix outcome in `change-log.md`. |
| Completion verification skills | Use before claiming completion. Evidence strengthens this skill's Definition of Done. |
| Security skills | Use for threat modeling, scans, or fixes. Security findings must update `security-rules.md`, `security-permissions.md`, `risks.md`, and `decision-log.md` when relevant. |
| UI/design skills | Use for frontend or design work. Durable design decisions must update `ui-ux-guidelines.md`, `page-map.md`, or `content-guidelines.md`. |
| Deployment skills | Use for platform-specific deployment. Production boundaries, rollback, and verification must still be recorded in project memory. |

Conflict resolution:
- Safety rules win over speed.
- Project memory and documentation updates are mandatory even if a specialized skill does not mention them.
- Specialized verification can add requirements, but cannot weaken this skill's verification, recovery, or security rules.
- If a specialized skill says to stop on a blocker, mark the task `failed-blocked` or `blocked` in `task-ledger.md` before asking the project owner.
- If a specialized skill suggests subagents but the active environment forbids spawning agents without explicit authorization, do not spawn subagents until authorized.
- Do not copy large specialized skill content into project docs. Reference it and record only project-specific outcomes.

## Execution Skill Auto-Selection

During preflight, automatically decide whether a specialized execution skill should be used. Record selected skills in `task-ledger.md` under `Selected Execution Skills`.

Use this decision table:

| Situation | Select |
| --- | --- |
| Creating or editing a skill | skill-writing workflow |
| Turning requirements into a multi-step implementation plan | planning workflow |
| Executing a written implementation plan in the current session | plan-execution workflow |
| Written plan has independent workstreams and subagents are authorized | subagent-driven workflow |
| Implementing a feature, bugfix, refactor, or behavior change | TDD workflow |
| Bug, test failure, build failure, unexpected behavior, or repeated failure | systematic debugging before fixing |
| About to claim work is complete, fixed, passing, or ready | verification-before-completion gate |
| Finishing a branch, preparing commit/PR/release handoff | branch-finishing workflow |

Selection rules:
- Use the smallest relevant set; do not load specialized skills just because they exist.
- If debugging and TDD both apply, debug first to find root cause, then add or adjust tests before fixing.
- Completion verification is a gate, not a replacement for this skill's document updates.
- If subagent workflows are useful but not authorized, record the option in `task-breakdown.md` and continue locally or ask for authorization.
- If no specialized skill adds value, continue with this skill's project-memory workflow only.

## Default Project Location

Create new projects under a configured project root, for example:

```text
<PROJECTS_ROOT>/<english-kebab-case-project-name>
```

Use English kebab-case names. Put temporary output under a dedicated temp folder:

```text
<PROJECTS_ROOT>/Temp
```

Never mix code, documents, assets, and temporary output without clear directories.

## Project-Local File Storage

All project-related durable files must live inside the project folder. Do not leave plans, recovery prompts, task ledgers, generated docs, acceptance notes, or automation source prompts only in chat, global memory, downloads, or ad hoc folders.

Use this storage model:
- `AGENTS.md` for the project entrypoint.
- `docs/` for requirements, decisions, project memory, automation prompts, and operating notes.
- `assets/` for project-owned design or media assets, when needed.
- `tmp/` or `.project-runtime/` for ignored local runtime files such as temporary clones, logs, checkpoints, and backups.

If an external runtime stores configuration outside the project, keep the source-of-truth prompt or procedure under `docs/08-automation/` and let the external configuration only point back to that file.

## File Purpose Headers

Every project-owned document, script, workflow, and template should start with a short header that lets future agents decide whether to read or skip the file before spending tokens on full content.

For Markdown files, use:

```markdown
Purpose: What this file is for.
Read when: When an agent should open it.
Skip when: When it is not relevant.
```

For scripts or config files, use the same three fields as comments near the top. Keep the header factual and under 5 lines. Do not include secrets, local private paths, or volatile implementation details in headers.

## Required Document Tree

For each new commercial-grade project, create or maintain:

```text
AGENTS.md
docs/
  00-project-memory/
    project-index.md
    current-state.md
    task-ledger.md
    execution-rules.md
    recovery-rules.md
    verification-rules.md
    security-rules.md
    glossary.md
  01-business/
    project-brief.md
    business-model.md
    success-metrics.md
    competitor-analysis.md
  02-product/
    prd.md
    user-personas.md
    user-flows.md
    feature-list.md
    acceptance-criteria.md
  03-design/
    information-architecture.md
    page-map.md
    ui-ux-guidelines.md
    content-guidelines.md
  04-technical/
    technical-architecture.md
    api-spec.md
    database-design.md
    security-permissions.md
    integration-plan.md
  05-delivery/
    roadmap.md
    task-breakdown.md
    test-plan.md
    launch-checklist.md
  06-operations/
    analytics-events.md
    admin-operations.md
    customer-support.md
    release-notes.md
  07-decisions/
    decision-log.md
    open-questions.md
    risks.md
    change-log.md
  08-automation/
    compact-disconnect-recovery.md
    scheduled-maintenance.md
```

For genuinely tiny tasks, the minimum allowed set is `AGENTS.md`, `docs/00-project-memory/current-state.md`, and `docs/07-decisions/change-log.md`. Record the reason for using the minimum set.

## AGENTS.md Required Content

`AGENTS.md` must include:
- Project name and one-sentence positioning.
- Current phase and current top objective.
- Mandatory reading order.
- Task-type reading map.
- Execution ownership and high-risk confirmation boundaries.
- Safety rules and no-go actions.
- Current blockers that require the project owner.
- Active task ledger and recovery checkpoint.
- Current production/server/domain boundaries, if known.
- Recent important decisions.
- Documentation update rules after substantial or state-changing tasks.

Keep `AGENTS.md` concise. Link detailed facts to `docs/`.

## Task Start Protocol

For every new project or substantial new task:
- Create or update `AGENTS.md` first.
- Record the current task, objective, status, and required reading path in `AGENTS.md`.
- Create or update an active task entry in `docs/00-project-memory/task-ledger.md`.
- Record the current checkpoint, next action, retry count, and verification requirement before long-running work.
- If this is an existing project, read existing docs before changing the memory entry.
- If this is an existing project without the full project memory document set, add missing memory/recovery/verification/safety docs first, then continue the requested task.
- If the task changes after execution begins, update `AGENTS.md` and `current-state.md` so future agents do not follow stale instructions.
- Do not leave project memory behind the actual project state.

## Task-Type Reading Map

Before executing, read `AGENTS.md`, then read the relevant docs:

| Task type | Required docs |
| --- | --- |
| Product scope, feature behavior, user flows | `prd.md`, `feature-list.md`, `user-flows.md`, `acceptance-criteria.md` |
| UI, layout, copy, navigation | `information-architecture.md`, `page-map.md`, `ui-ux-guidelines.md`, `content-guidelines.md` |
| Frontend implementation | product docs, design docs, `technical-architecture.md`, `api-spec.md` |
| Backend/API/database | `technical-architecture.md`, `api-spec.md`, `database-design.md`, `security-permissions.md` |
| Auth, permissions, payment, user data, orders | business docs, product docs, `security-permissions.md`, `security-rules.md`, `risks.md` |
| Deployment or production operations | `launch-checklist.md`, `integration-plan.md`, `security-rules.md`, `risks.md`, private server inventory if the project references one |
| Testing or bug fixing | `current-state.md`, `test-plan.md`, `acceptance-criteria.md`, `change-log.md` |
| Roadmap or agent splitting | `roadmap.md`, `task-breakdown.md`, `current-state.md`, `open-questions.md` |
| Resuming interrupted or failed work | `current-state.md`, `task-ledger.md`, `recovery-rules.md`, `change-log.md`, task-specific docs |

If a relevant document is missing or stale, update it before relying on it.

## Autonomous Execution Rules

Agents should directly handle:
- Creating the project structure and project memory documents.
- Turning rough ideas into commercial requirements, assumptions, and open questions.
- Designing product flows, technical architecture, task breakdown, and validation plans.
- Implementing features, fixing bugs, adding tests, running checks, and iterating until usable.
- Updating project memory and requirement documents after substantial or state-changing work.

Do not stop at analysis when the task is actionable. Ask the project owner only when a decision affects cost, safety, production data, external publication, credentials, legal/business identity, or product direction.

## Preflight Self-Check

Before substantial execution, confirm:
- The project root and project `AGENTS.md` are identified.
- The active task is recorded in `task-ledger.md`.
- Required docs for the task type have been read or marked missing.
- Applicable execution skills have been selected or intentionally skipped.
- The task is classified as low-risk, normal-risk, or high-risk.
- No destructive, paid, production, credential, publication, user-data, order, or permission action will occur without project-owner confirmation.
- Existing user changes are protected and unrelated files are out of scope.

If the preflight fails, fix the project memory or request the minimum required confirmation before continuing.

## Verification Loop

Every implementation task follows:

```text
Read memory -> read task docs -> execute -> self-test -> fix -> test again -> update docs -> report
```

Default verification:
- Code: run focused tests, build checks, type checks, or minimum executable validation.
- Frontend: verify the page opens, core flows work, and mobile/desktop layout has no obvious breakage.
- Backend: verify endpoints, validation, auth, database reads/writes, errors, and logs.
- Payment/auth/permissions/data deletion: test success and failure paths.
- Deployment: verify service status, domain, environment variables, logs, and rollback path.

If verification is impossible, record why, what risk remains, and what should be checked next.

## Definition of Done

A substantial or state-changing task is not done until:
- Requested behavior is implemented or the blocker is recorded.
- Focused verification has been run, or the reason it cannot run is recorded.
- Any failure retries and final status are recorded in `task-ledger.md`.
- Changed requirements, API, database, design, security, delivery, or operations facts are updated in the matching docs.
- `current-state.md` and `change-log.md` are updated.
- The final response states what changed, what was verified, and any remaining risk.

For read-only investigations, tiny wording edits, one-off commands, or tasks that do not change project state, record nothing unless the result creates a durable decision, blocker, or follow-up task.

## Failure Recovery and Auto-Continuation

Use recoverable task execution for any substantial task.

Maintain `docs/00-project-memory/task-ledger.md` with one active task entry:
- Task ID and source request.
- Current status: `active`, `blocked`, `failed-retryable`, `failed-blocked`, or `done`.
- Documents already read.
- Selected execution skills.
- Current checkpoint.
- Next concrete action.
- Retry count.
- Last error or interruption reason.
- Verification status.
- Last updated timestamp.

Within an active session:
- Retry transient command, network, dependency, build, and test failures up to 2 times after diagnosing and making the smallest reasonable correction.
- After each failed attempt, update the task ledger with the observed error, attempted fix, and next action.
- Never blindly repeat the same failing command without changing the condition or learning something.
- If the same failure remains after 2 retries, mark `failed-blocked`, record the blocker, and ask the project owner only if no safe next action exists.

After an interruption, crash, aborted turn, or context loss:
- Read `AGENTS.md`.
- Read `current-state.md`, `task-ledger.md`, `recovery-rules.md`, and `change-log.md`.
- Resume from `Next concrete action`, not from the beginning.
- Check whether any command, migration, deploy, or external action may have partially completed before retrying.
- If state is ambiguous, inspect the workspace and logs first; do not assume success or failure.
- If the recovery status check finds no `active` or `failed-retryable` task and no drift, stop without adding a new ledger entry. No-op recovery checks should not create durable noise.

For long-running work, create a checkpoint before each major step:
- Before editing many files.
- Before running migrations or deploys.
- Before starting a dev server or long build.
- Before handing work to subagents.
- Before ending the turn while work remains.

## Remote Compact Failure Recovery

Treat this exact error as a retryable interruption, not as a completed or failed task:

```text
Error running remote compact task: stream disconnected before completion: error sending request for url (https://chatgpt.com/backend-api/codex/responses/compact)
```

When it appears, the next agent turn or heartbeat must:
- Read project `AGENTS.md`.
- Read `docs/00-project-memory/current-state.md`, `docs/00-project-memory/task-ledger.md`, `docs/00-project-memory/recovery-rules.md`, and `docs/07-decisions/change-log.md`.
- If available, run the project recovery status helper to detect active or retryable tasks.
- Resume from `Next Concrete Action`, not from chat history.
- Inspect workspace state before repeating commands, because edits or external actions may have partially completed.
- Update `task-ledger.md` with `Last Error or Interruption` set to the compact failure and status `active` or `failed-retryable`.
- Stop and request confirmation if the next step is high-risk or non-idempotent.

For substantial tasks likely to outlive the current turn, create or update a heartbeat/scheduled recovery check before starting the risky or long-running section. The recovery check must read project-local docs and stop when no task is `active` or `failed-retryable`.

Automatic timed checks are allowed only when the runtime provides a safe heartbeat or scheduled automation. Use them for long tasks that may outlive the current turn. The heartbeat prompt must read `AGENTS.md` and `task-ledger.md`, continue only if a task is `active` or `failed-retryable`, and stop if the task is `done`, `blocked`, or high-risk confirmation is required.

Heartbeat prompt requirements:
- Name the exact project path.
- Say to read project `AGENTS.md`, `current-state.md`, `task-ledger.md`, `recovery-rules.md`, and `change-log.md`.
- Continue only from `Next concrete action`.
- Re-check whether partial side effects already happened.
- Do not perform non-retryable high-risk actions.
- Update the task ledger before stopping.

Do not auto-retry:
- Real payment, refund, billing, or transaction actions.
- Production data deletion, migration, overwrite, or destructive maintenance.
- Credential, permission, user, order, or production payment configuration changes.
- External publication, messaging, app store submission, or customer-visible actions.

Those require project-owner confirmation and a recorded rollback plan.

## Security and Accident Prevention

Never:
- Store passwords, API keys, merchant private keys, database passwords, or tokens in docs, memory, logs, or chat.
- Delete or migrate production data without explicit project-owner confirmation.
- Overwrite production files without reading existing files and having a rollback path.
- Change production payment, permission, user, order, or billing logic without explicit confirmation.
- Publish externally, send messages, charge money, or trigger real transactions without confirmation.
- Use mock data as if it were real verified data.
- Modify unrelated files just to make a task easier.

High-risk tasks require:
- Backup or rollback plan.
- Minimal change scope.
- Local or staging validation where possible.
- Clear impact statement.
- Entries in `docs/07-decisions/risks.md` and `docs/07-decisions/decision-log.md`.

## Documentation Update Rules

After every substantial or state-changing task, update:
- `docs/00-project-memory/current-state.md`
- `docs/00-project-memory/task-ledger.md`
- `docs/07-decisions/change-log.md`

Also update the relevant source document:
- Product behavior changed: update `prd.md`, `feature-list.md`, or `acceptance-criteria.md`.
- UI changed: update design docs.
- API/database changed: update technical docs.
- Security/permission/payment changed: update security docs and risks.
- Roadmap or scope changed: update roadmap, task breakdown, open questions, and `AGENTS.md` if the top objective changes.
- Skill or project-memory behavior changed: update templates, compatibility notes, README language mirrors, sync scope, and safety checks when they are affected.

Unresolved but non-blocking assumptions go to `open-questions.md`. Blocking decisions go to both `open-questions.md` and the blockers section of `AGENTS.md`.

## Common Mistakes

- Creating only a PRD and losing technical, security, and delivery context.
- Putting all detail into `AGENTS.md` instead of linking to dedicated docs.
- Asking too many technical questions that the agent can reasonably decide.
- Treating a task as done without running checks or recording unverified risk.
- Forgetting to update memory documents after substantial implementation.
- Writing secrets into documentation.
- Skipping existing project files and overwriting prior work.
