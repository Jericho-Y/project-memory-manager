# Hermes Project Context

Purpose: Minimal Hermes adapter for a project that uses `pmm`.
Read when: Hermes loads project context and this file is selected ahead of `AGENTS.md`.
Skip when: Hermes is already loading `AGENTS.md` directly.

Use `AGENTS.md` as the canonical project entrypoint.

Read hot-path files only when needed:
- `docs/00-project-memory/current-state.md`
- `docs/00-project-memory/active-task.md`
- `docs/00-project-memory/verifier-map.md`

Do not copy active task state into Hermes `MEMORY.md`. Global memory may keep only a short pointer to this project.
