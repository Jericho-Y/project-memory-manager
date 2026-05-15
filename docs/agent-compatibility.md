# Agent Compatibility

Purpose: Compatibility map for using `pmm` across Agent Skills, AGENTS.md, Claude Code, Hermes, and OpenCode/OpenClaw-style agents.
Read when: Installing this skill in another agent, adding a compatibility shim, or reviewing cross-agent behavior.
Skip when: Maintaining only repository automation or public safety scripts.

## Compatibility Position

`pmm` has two separate compatibility surfaces:

- Skill package: `SKILL.md` plus optional `templates/`, `docs/`, and `scripts/` files. This is for Agent Skills-compatible clients.
- Project output: project root `AGENTS.md` plus project-local `docs/`. This is the durable, cross-agent source of truth after the skill has been used.

The project output is intentionally more portable than any single agent runtime. If an agent cannot load `pmm` as a skill, it can still follow the generated `AGENTS.md` and project documents.

## Agent Matrix

| Agent family | Skill entry | Project instruction entry | Compatibility status |
| --- | --- | --- | --- |
| Codex / Agent Skills clients | `<skills-root>/pmm/SKILL.md` | `AGENTS.md` | Native for this repository. |
| Claude Code | `~/.claude/skills/pmm/SKILL.md` or project `.claude/skills/pmm/SKILL.md` | `CLAUDE.md` or `.claude/CLAUDE.md` shim pointing to `AGENTS.md` | Compatible through Agent Skills plus a short project memory shim. |
| Hermes | `~/.hermes/skills/pmm/SKILL.md` | `AGENTS.md`, plus handoff prompts that cite `task-ledger.md` | Compatible through `SKILL.md`; keep handoffs project-local. |
| OpenCode / OpenClaw-style agents | Agent-specific skill import if available | `AGENTS.md` | Compatible through `AGENTS.md`; skill loading may require local conversion. |
| Other coding agents | Optional `SKILL.md` support | `AGENTS.md` | Use `AGENTS.md` as the stable fallback. |

## Required Compatibility Rules

- Keep `AGENTS.md` as the canonical project entrypoint.
- Do not duplicate full project rules into `CLAUDE.md`, OpenCode config, Hermes task files, or handoff prompts.
- Use shims that point back to `AGENTS.md` and project-local docs.
- Keep shims and handoffs context-light: cite paths, current checkpoint, and next action instead of copying project docs.
- Keep generated docs generic: use "agent" unless a rule is truly product-specific.
- Avoid runtime-specific channel names, tool names, local paths, private memory paths, credentials, or model names in public templates.
- If a specialized skill or command is unavailable in an agent, preserve the project-memory workflow and skip only that specialized execution helper.

## Optional Claude Code Shim

Use this only when Claude Code does not read the project `AGENTS.md` directly:

```markdown
# Project Instructions

Read `AGENTS.md` first. Treat it as the canonical project entrypoint.

@AGENTS.md
@docs/00-project-memory/current-state.md
@docs/00-project-memory/task-ledger.md
@docs/00-project-memory/recovery-rules.md
@docs/07-decisions/change-log.md
```

Keep the shim short. Update `AGENTS.md` and project docs, not the shim, when behavior changes.

## Optional OpenCode / OpenClaw Setup

OpenCode-style agents read `AGENTS.md` as project rules. For these agents:

1. Put `AGENTS.md` at the project root.
2. Keep project facts under `docs/`.
3. If an agent-specific config supports extra instruction files, point it to the same project-local docs instead of copying them.
4. If skill import is available, import `pmm` as a convenience only; do not make it the sole source of project truth.

## Optional Hermes Setup

Hermes can use `SKILL.md` skills and task handoffs. For Hermes:

1. Install or copy this repository as a `pmm` skill.
2. For project work, read the project root `AGENTS.md` first.
3. When delegating or resuming work, write handoff prompts that cite `AGENTS.md`, `current-state.md`, `task-ledger.md`, and the next concrete action.
4. Keep credentials and private runtime state out of skill files and handoff prompts.

## Compatibility Checklist

Before claiming cross-agent compatibility:

- `SKILL.md` frontmatter has a valid lowercase `name` and a clear `description`.
- `SKILL.md` avoids Codex-only assumptions in the core workflow.
- `AGENTS.md` remains usable as a standalone project rule file.
- Claude Code, Hermes, and OpenCode/OpenClaw-style agents have a documented entry path.
- Supporting docs referenced by `SKILL.md` are included in local sync.
- `bash scripts/check-public-safety.sh` passes.
