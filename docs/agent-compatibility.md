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

## Adapter Contract

Every adapter must state:
- which runtime loads it
- which canonical project entrypoint to read
- which hot-path files to read for active tasks
- which memory stores must not receive active task state
- what to do when the runtime cannot load `pmm` as a skill

Adapters must be short. If an adapter grows, move the content back into `AGENTS.md` or project docs.

## Agent Matrix

| Agent family | Skill entry | Project entry | Adapter |
| --- | --- | --- | --- |
| Codex / Agent Skills clients | `<skills-root>/pmm/SKILL.md` | `AGENTS.md` | optional nested `AGENTS.md` for subdirectories |
| Claude Code | `~/.claude/skills/pmm/SKILL.md` or project skill dir | `CLAUDE.md` importing `AGENTS.md` | `templates/adapters/CLAUDE.md` |
| Hermes Agent | Hermes skill folder if supported | `AGENTS.md`; `.hermes.md` or `HERMES.md` only as shim | `templates/adapters/HERMES.md` |
| OpenClaw/OpenCode-style agents | agent-specific skill import if available | `AGENTS.md` | `templates/adapters/openclaw-project-card.md` |
| Other coding agents | optional `SKILL.md` support | `AGENTS.md` | short project card or handoff prompt |

## Codex

Codex reads `AGENTS.md` files and supports nested project instructions. Keep root `AGENTS.md` concise and put directory-specific rules in nested `AGENTS.md` files only when they are truly scoped.

For Codex:
- canonical entry: `AGENTS.md`
- active task: `docs/00-project-memory/active-task.md`
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
- Do not copy project docs into this file.
```

Do not import the entire Core Pack by default. Extra imports increase startup context and can make stale state harder to detect.

## Hermes Agent

Hermes supports multiple project context files, and a Hermes-specific file may win before `AGENTS.md`. Prefer letting Hermes load `AGENTS.md` directly. If `.hermes.md` or `HERMES.md` is required, keep it as a shim:

```text
Use AGENTS.md as the canonical project entrypoint.
Read active-task.md only when starting, resuming, or verifying a task.
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
Verifier map: docs/00-project-memory/verifier-map.md
```

Store task state in the project folder. Global memory may keep only the pointer and stable conventions.

## Legacy Compatibility

`pmm` v0.1 projects may use `task-ledger.md`. v0.2 agents should:
1. prefer `active-task.md` when present
2. fall back to `task-ledger.md` when `active-task.md` is absent
3. migrate the current task into `active-task.md` when practical
4. archive completed entries into `task-history.md`

Do not delete legacy ledgers without explicit project-owner approval.

## Compatibility Checklist

Before claiming cross-agent compatibility:
- `SKILL.md` frontmatter has a valid lowercase `name`, version, and clear description.
- `AGENTS.md` remains usable as a standalone project rule file.
- Core Pack references `active-task.md` and `verifier-map.md`.
- Legacy `task-ledger.md` behavior is documented if supported.
- Claude, Hermes, OpenClaw/OpenCode, and Codex adapter paths are documented.
- Adapters point to project memory instead of copying it.
- Agent-global memory is not used for active task state.
- Installed docs and templates are included in local sync.
- `bash scripts/check-public-safety.sh` passes.
