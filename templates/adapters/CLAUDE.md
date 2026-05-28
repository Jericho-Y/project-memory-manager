# Claude Code

Purpose: Minimal Claude Code adapter for a project that uses `pmm`.
Read when: Claude Code starts in this repository.
Skip when: Another Claude Code project memory file already imports `AGENTS.md`.

@AGENTS.md

## Claude Code Adapter

- Treat `AGENTS.md` as the canonical project entrypoint.
- Read `docs/00-project-memory/active-task.md` only when starting, resuming, or verifying a task.
- Do not copy project docs into this file; update project-local docs instead.
- Do not store current task state in Claude auto memory.
