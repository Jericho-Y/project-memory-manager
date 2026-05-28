# Risk Pack

Purpose: Optional risk documents for security, permissions, production data, payment, and release risk.
Read when: Work touches auth, payment, permissions, user data, production, secrets, or public release.
Skip when: The task is low risk and has no security or production boundary.

Create only the files that contain real facts:

```text
docs/00-project-memory/security-rules.md
docs/04-technical/security-permissions.md
docs/07-decisions/risks.md
docs/07-decisions/decision-log.md
```

Record required confirmations, rollback plans, and verification evidence.
