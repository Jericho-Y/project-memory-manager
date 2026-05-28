# Self-Eval Loop

Purpose: Defines the self-evaluating execution loop used by `pmm` tasks.
Read when: Starting implementation, recovering a failed task, or judging whether a task is done.
Skip when: The task is a tiny read-only lookup with no durable state change.

## Loop

Every substantial task follows:

```text
Classify -> Load -> Contract -> Execute -> Verify -> Critique -> Repair -> Record -> Promote
```

The loop is operational, not a reflective essay. It should produce evidence and a concise task state.

## Task Contract

Store the current task in `docs/00-project-memory/active-task.md`.

Required fields:
- Runtime Profile
- Objective
- Scope
- Risk Level
- Allowed Files or Areas
- Forbidden Actions
- Source Artifacts
- Selected Skills or Agents
- Verifier
- Loop Budget
- Stop Condition
- Current Attempt
- Last Failure
- Next Concrete Action
- Verification Evidence
- Critic Result
- Memory Promotion Decision

## Verifier First

A task cannot be marked `done` without a verifier. If no verifier exists, define the smallest practical verifier before execution.

Acceptable verifier types:
- command-based checks
- browser/manual smoke checks
- screenshot or artifact review
- static inspection against acceptance criteria
- release or safety scripts
- human acceptance points that are explicitly marked as pending

If verification is impossible, mark the task `executed-unverified` or `blocked` and record the reason.

## Critic Gate

The critic step checks whether the work truly satisfies the verifier.

Reject false passes:
- tests were skipped but reported as done
- failing checks were removed or weakened
- tests were changed to match broken behavior
- mock data was treated as real integration evidence
- UI changed without valid product state
- logs or screenshots are missing when the verifier required them
- user-facing behavior was not exercised
- high-risk action lacks confirmation or rollback notes

## Repair Rules

Repair is allowed only after a failure is classified.

Failure classes:
- requirement gap
- source artifact missing
- build/test/lint/type failure
- behavior regression
- visual/layout failure
- integration/environment failure
- permission/safety boundary
- verifier missing or weak

Do not repeat the same command blindly. Change the condition, inspect the failure, or make the smallest reasonable fix first.

Default retry budget:
- Pulse: 1 attempt
- Sprint: up to 3 attempts
- Recovery: continue from recorded checkpoint
- Audit: no blind retries; require evidence and confirmation when high risk

## Record

Record only what helps the next agent:
- final status
- evidence
- failed attempts and root cause
- next concrete action
- remaining risk
- source docs changed

Do not store raw logs, long outputs, full diffs, or one-off scratch notes in the hot path.

## Promote

Promote a lesson to durable rules only when it is reusable. See `docs/memory-promotion.md`.
