# Subagent Routing

Purpose: Defines the lightweight gate for deciding whether a task should use solo execution, assisted subagents, parallel subagents, or review-only subagents.
Read when: Starting a non-trivial task, delegating work, or reviewing whether subagents would save context or improve evidence.
Skip when: The task is a tiny known-file edit, one-off command, or the agent runtime has no delegation capability and solo mode is obvious.

## Goal

Use subagents when they reduce risk, save useful context, or let independent work happen in parallel. Do not use them as a ritual.

## Agent Modes

| Mode | Use when | Default limit |
| --- | --- | --- |
| `solo` | Tiny task, tightly coupled fix, unclear split, or no subagent support | 0 subagents |
| `assisted` | One bounded side task can run while the parent owns the critical path | 1 subagent |
| `parallel` | Two or more independent scopes can progress without overlapping files or decisions | 2 subagents by default |
| `review-only` | Implementation is done or nearly done and an independent risk check is valuable | 1 reviewer |

Use more than two subagents only for broad Project or Audit work with clear scopes and an explicit integration plan.

## Gate

Ask these questions before delegating:

1. Can the parent continue useful work while the subagent runs?
2. Is the delegated scope concrete, bounded, and non-overlapping?
3. Will the result improve speed, coverage, or verification enough to justify the extra context?
4. Can the parent verify and integrate the result before claiming done?
5. Does the prompt avoid secrets, private tokens, production data, and unnecessary personal data?

If any answer is no, use `solo` or make the split smaller.

## Good Delegation

- map unfamiliar code while the parent prepares the task contract
- review a patch for regressions while the parent updates docs
- inspect docs, links, or version consistency while the parent edits source
- split frontend, backend, tests, and docs only when ownership is disjoint

## Avoid Delegation

- tiny edits or single-file changes
- the exact next blocker on the parent critical path
- vague research with no expected output
- multiple agents editing the same files
- sensitive credentials, payment, production data, or external-publication decisions

## Active Task Record

Record the decision in `active-task.md`:

```text
Agent Mode:
- Mode: solo | assisted | parallel | review-only
- Reason:
- Delegated Scopes:
- Parent-Owned Path:
```

When the runtime has no subagent tool, record `solo` or use the field as a manual handoff plan. The project source of truth remains `AGENTS.md` and the Core Pack, not any subagent's private memory.
