# Agent Compatibility

Purpose: Compatibility map for using `pmm` across Agent Skills, AGENTS.md, Claude Code, Hermes Agent, OpenClaw/OpenCode-style agents, and similar coding agents.
Read when: Installing this skill in another agent, adding an adapter, or reviewing cross-agent behavior.
Skip when: Maintaining only repository automation or public safety scripts.

## Compatibility Position

`pmm` has three compatibility surfaces:

- Skill package: `SKILL.md` plus installed docs, templates, and helper scripts.
- Project memory: project root `AGENTS.md` plus project-local Core Pack docs.
- Adapter layer: small runtime-specific files or memory entries that point back to project memory.

Project memory is the source of truth. Adapters route agents to that source; they do not copy it.

The Core Pack is a routing surface, not a mandatory full-file startup import. Agents reuse content already supplied in their current context, keep an ephemeral read set, and load only the relevant task/state/verifier sections. Adapters must not force repeated full Core Pack reads or standalone plan files that duplicate `active-task.md`.

Subagent Routing Gate is portable as a decision record, not as a guaranteed runtime feature. If the agent supports subagents, it may delegate within the recorded boundaries. If it does not, it records `solo` mode or uses the field as a manual handoff plan.

Workspace Gate is portable as a safety contract. Every agent must treat `active-task.md` as one primary-task slot. A concurrent writer either queues or uses a separate branch/worktree plus `docs/00-project-memory/work-items/<task-id>.md`; agents that cannot establish that isolation must run tasks sequentially. Agents first reuse a matching current-branch claim instead of creating another worktree. The Bash lifecycle CLI can auto-route a default `start` from a different active, checked-out worktree to a child work item, but manual adapters must preserve the same parent, branch, and fail-closed checks.

The `pmm.task/v1` frontmatter remains human-readable Markdown. Agents may update it with `scripts/pmm-task.sh` or preserve the same field contract manually. CLI mutations require an explicit owner and recorded branch; a Git common-dir lock serializes local lifecycle changes, simultaneous starts receive a bounded retry, whole-file staged transactions prevent partial task updates, and short-lived locks recover only when a same-host recorded process is dead. Interrupted takeover restores the claim owner matching the durable task file, and Doctor rejects missing or mismatched non-idle claims. One clone allows one non-idle primary claim, archived task IDs from structured or marker-less legacy history are not reusable, and post-verification source commits invalidate evidence even if reverted or moved into an operational path later. Recovery reads sibling-worktree primary and work-item claims to locate uncommitted tasks. Claims improve same-machine coordination but are not distributed and do not replace remote branch ownership across devices. A verified child remains `ready-to-integrate` until the primary owner proves its commit was merged, runs `integrate`, and re-verifies the primary task.

## Adapter Contract

Installation path convention:
- Ordinary installs place the skill at `<SKILLS_ROOT>/pmm` for any runtime.
- Maintainer sync targets only the same `<SKILLS_ROOT>/pmm` directory.
- Runtime-specific helper skills, including Codex-only routing helpers, are optional execution aids and must not be required by generated project memory.

Every adapter must state:
- which runtime loads it
- which canonical project entrypoint to read
- which hot-path files to read for active tasks
- that subagent support is optional and parent verification remains required
- which memory stores must not receive active task state
- what to do when the runtime cannot load `pmm` as a skill

Adapters must be short. If an adapter grows, move the content back into `AGENTS.md` or project docs.

## Agent Matrix

| Agent family | Skill entry | Project entry | Adapter |
| --- | --- | --- | --- |
| Codex / Agent Skills clients | `<SKILLS_ROOT>/pmm/SKILL.md` | `AGENTS.md` | optional nested `AGENTS.md` for subdirectories |
| Claude Code | `<SKILLS_ROOT>/pmm/SKILL.md` or project skill dir | `CLAUDE.md` importing `AGENTS.md` | `templates/adapters/CLAUDE.md` |
| Hermes Agent | Hermes skill folder if supported | `AGENTS.md`; `.hermes.md` or `HERMES.md` only as shim | `templates/adapters/HERMES.md` |
| OpenClaw/OpenCode-style agents | agent-specific skill import if available | `AGENTS.md` | `templates/adapters/openclaw-project-card.md` |
| Other coding agents | optional `SKILL.md` support | `AGENTS.md` | short project card or handoff prompt |

## Codex

Codex reads `AGENTS.md` files and supports nested project instructions. Keep root `AGENTS.md` concise and put directory-specific rules in nested `AGENTS.md` files only when they are truly scoped.

For Codex:
- canonical entry: `AGENTS.md`
- active task: `docs/00-project-memory/active-task.md`
- concurrent task: `docs/00-project-memory/work-items/<task-id>.md` on an isolated branch/worktree
- verifier map: `docs/00-project-memory/verifier-map.md`
- optional adapter: `templates/adapters/codex-subdir-AGENTS.md`

## Claude Code

Claude Code reads `CLAUDE.md`. If the project uses `AGENTS.md`, create a short `CLAUDE.md` that imports it:

```markdown
# Claude Code

@AGENTS.md

## Adapter

- Treat `AGENTS.md` as canonical.
- Read `docs/00-project-memory/active-task.md` only when starting or resuming a task.
- Refuse to append a second task; queue it or use an isolated work item.
- Do not copy project docs into this file.
```

Do not import the entire Core Pack by default. Extra imports increase startup context and can make stale state harder to detect.

## Hermes Agent

Hermes supports multiple project context files, and a Hermes-specific file may win before `AGENTS.md`. Prefer letting Hermes load `AGENTS.md` directly. If `.hermes.md` or `HERMES.md` is required, keep it as a shim:

```text
Use AGENTS.md as the canonical project entrypoint.
Read active-task.md only when starting, resuming, or verifying a task.
Use a separate branch/worktree and work-item file for a concurrent writer.
Do not copy active task state into Hermes MEMORY.md.
```

Hermes global memory is small and curated. Store only stable project pointers or conventions there.

## OpenClaw / OpenCode-Style Agents

OpenClaw-style agents often have a workspace memory with `AGENTS.md`, `MEMORY.md`, daily notes, and heartbeat files. Do not copy a project's Core Pack into that global workspace memory.

Use a project card:

```text
Project:
Path:
Canonical entry: AGENTS.md
Current task: docs/00-project-memory/active-task.md
Concurrent task: docs/00-project-memory/work-items/<task-id>.md
Verifier map: docs/00-project-memory/verifier-map.md
```

Store task state in the project folder. Global memory may keep only the pointer and stable conventions.

## Legacy Compatibility And Upgrade

`pmm` v0.1-v0.3 projects may use `task-ledger.md` or unstructured `active-task.md`. Before normal writes, v0.5.1 agents run:

```bash
bash <SKILLS_ROOT>/pmm/scripts/pmm-task.sh upgrade --project <PROJECT_ROOT> --auto --owner <AGENT_ID>
```

The Upgrade Gate:
1. detects v0.1 ledgers, v0.2/v0.3 sectioned tasks, and unmarked v0.4/v0.5 structured projects
2. backs up every existing file that it will change
3. writes the installed version to `docs/00-project-memory/runtime-state.md`
4. updates only the marker-managed PMM Runtime block in `AGENTS.md` and preserves user-owned content
5. migrates exactly one unambiguous current contract, or creates an idle slot for a history-only project
6. preserves v0.2/v0.3 objective, verifier, and next-action fields in the structured hot path
7. fails closed without project writes on multiple tasks, competing sources, conflicting statuses, or a newer project runtime

After the gate succeeds, current runtime state is authoritative. Compatibility readers remain available only for migration discovery, recovery, rollback, and explicit ambiguity review. Doctor rejects an old project by default with `PROJECT_UPGRADE_REQUIRED`; `--allow-legacy` is an audit mode, not a normal execution mode.

The old `migrate --plan`, `--dry-run`, and `--apply` interface remains supported. `migrate --apply` now also writes the current runtime state and managed `AGENTS.md` block. It still counts task fields rather than ledger section headings, keeps completed history cold, refuses ambiguous input, preserves the source ledger, and reserves task IDs found in marker-less history.

Do not delete legacy ledgers without explicit project-owner approval.

## Compatibility Checklist

Before claiming cross-agent compatibility:
- `SKILL.md` frontmatter has a valid lowercase `name`, version, and clear description.
- `AGENTS.md` remains usable as a standalone project rule file.
- Core Pack references `active-task.md` and `verifier-map.md`.
- `active-task.md` is documented as one primary-task slot, not a task list.
- Concurrent writers require separate branches/worktrees and work-item files.
- One clone rejects multiple non-idle primary claims, and archived task IDs are never reused.
- Work items retain ownership through merge and explicit primary-owner integration; child close alone is not project completion.
- Structured state keeps execution, verification, and delivery independent.
- Normal mutations run the Upgrade Gate and converge an unambiguous legacy project to the installed runtime.
- Legacy `active-task.md` and `task-ledger.md` remain readable only for migration, recovery, rollback, and compatibility audit paths.
- `migrate --apply` remains backward compatible and also records the current runtime version.
- Active task templates include Agent Mode without requiring subagent support.
- Legacy `task-ledger.md` behavior is documented if supported.
- Claude, Hermes, OpenClaw/OpenCode, and Codex adapter paths are documented.
- Adapters point to project memory instead of copying it.
- Agent-global memory is not used for active task state.
- Installed docs and templates are included in local sync.
- Installed helpers include `pmm-task.sh`, `pmm-state.sh`, Doctor, Recovery, and the runtime contract test.
- Installed helpers include `pmm-preflight.sh`; maintainers can run it with `--installed <SKILLS_ROOT>/pmm` to prove source and package contracts together.
- `bash scripts/check-public-safety.sh` passes.
