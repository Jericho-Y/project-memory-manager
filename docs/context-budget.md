# Context Budget

Purpose: Token and context-use rules for using `pmm` without loading unnecessary project history.
Read when: Starting, resuming, delegating, or optimizing a project-memory workflow.
Skip when: The task is a tiny one-off command or the needed source file is already known.

## Goal

Keep durable project memory useful without turning every task into a full-document reread. Agents should spend context on the current decision, not on repeating stable background.

## Budget Layers

| Layer | Load by default | Purpose |
| --- | --- | --- |
| Entry | `AGENTS.md` | Confirms project identity, reading order, active task, and safety boundaries. |
| State | `current-state.md`, `task-ledger.md` | Confirms current facts, checkpoint, next action, and recovery status. |
| Index | `project-index.md`, file headers, table of contents | Finds the right source document without reading every document. |
| Task source | Only docs listed for the task type | Supplies the facts needed for the current work. |
| Deep source | Full files, logs, specs, or history | Use only when editing, investigating ambiguity, or verifying a risky change. |

## Reading Strategy

1. Classify the task: read-only lookup, tiny edit, substantial implementation, recovery, security, deployment, or high-risk action.
2. Read the minimum entry and state files.
3. Use the task reading map to choose source documents.
4. Search for keywords before reading long documents.
5. Read headings, Purpose / Read when / Skip when, and current sections first.
6. Open full files only when a change, ambiguity, or verification need requires it.
7. Record selected docs once in `task-ledger.md`; do not repeat the same list every turn unless the task changes.

## Writing Strategy

- Store durable facts as concise deltas: what changed, current state, verification, remaining risk.
- Prefer pointers to files and sections over copied excerpts.
- Keep `AGENTS.md` short and link to docs for details.
- Keep task ledger entries operational: status, checkpoint, next action, retry count, and verification.
- Avoid recording routine no-op checks unless they reveal drift or create a follow-up.

## Handoffs

Handoffs should include:

- project path or repository root
- task status and next concrete action
- files already read
- files to read next
- verification still required
- safety or confirmation boundaries

Handoffs should not include:

- full document copies
- secrets or private runtime details
- old completed task history unrelated to the next action
- agent-specific rules that already live in `AGENTS.md`

## When to Spend More Context

Use broader reading when:

- auth, payment, permission, deployment, production data, or user data is involved
- source documents disagree
- a task failed and root cause is unknown
- changing shared templates, safety rules, or automation
- preparing public release notes or compatibility guarantees

## Maintenance Checks

When this repository changes, keep the context budget intact:

- `SKILL.md` stays concise and links to this file for detail.
- README files mention the context-budget behavior without duplicating this guide.
- Local sync includes this file when it is referenced by `SKILL.md`.
- Public safety checks verify the required context-budget file and bilingual README links exist.
