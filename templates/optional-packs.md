# Optional Packs

Purpose: Consolidated optional document-pack templates for product, design, engineering, risk, operations, and automation facts.
Read when: A project needs more than the Core Pack and has real facts for a specialized area.
Skip when: The task can be handled by Core Pack or target files only.

Create optional documents only when they contain real facts. Prefer one concise source document per domain first; split only after the document has enough stable facts to justify it. Missing optional packs are better than stale empty placeholders.

## Product

Use project-root `PRD.md` as the default master requirements/product document. Split narrower files only when they add concrete detail:

```text
PRD.md
docs/02-product/user-personas.md
docs/02-product/user-flows.md
docs/02-product/feature-list.md
docs/02-product/acceptance-criteria.md
```

Each file should state current facts, open questions, and acceptance criteria.

## Design

Use when UI, navigation, layout, interaction, or copy changes are part of the task:

```text
docs/design.md
```

Prefer concrete behavior, IA, page map, layout rules, interaction states, and content rules over taste-based descriptions. Split into `docs/03-design/*` only for large products.

## Engineering

Use when architecture, API, database, integration, or shared technical contracts change:

```text
docs/architecture.md
```

Keep architecture, API, database, and integration contracts concise. Point to implementation files instead of copying code. Split into `docs/04-technical/*` only when contracts are independently maintained.

## Risk

Use when work touches auth, payment, permissions, user data, production, secrets, or public release:

```text
docs/risk.md
```

Record security boundaries, permissions, production data, payment risk, required confirmations, rollback plans, and verification evidence. Split security, risks, and decision logs only when separate ownership exists.

## Operations

Use when deployment, support, monitoring, analytics, or release operations change:

```text
docs/operations.md
```

Keep deployment, monitoring, analytics, support, admin operations, release notes, rollback, and recovery instructions actionable. Split into delivery/operations files only when the project has ongoing ops ownership.

## Automation

Use when the project needs timed follow-up, recurring checks, or automatic recovery:

```text
docs/maintenance.md
```

Automation prompts must be self-contained, resolve an explicit task ID, and stop on ambiguity. They must respect execution, verification, and delivery as separate states: blocked execution, stale/failed verification, or a delivery confirmation wait require different handling. Split scheduled checks, heartbeat prompts, and runbooks only when they are independently operated.
