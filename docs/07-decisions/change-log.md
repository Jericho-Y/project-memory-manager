# Change Log

Purpose: Chronological record of durable repository behavior and maintenance changes.
Read when: You need recent change history or must update the record after state-changing work.
Skip when: You only need current instructions and no historical context.

## 2026-07-23

- Added an enforceable low-I/O runtime contract: reuse current context, keep the session read set ephemeral, inspect headings before bounded large-file reads, and avoid standalone plan/evidence artifacts that duplicate task state and source.
- Reduced `SKILL.md` from 16,598 bytes / 280 lines to 12,314 bytes / 192 lines before final wording updates, with a 14 KiB contract limit to prevent regression.
- Bounded maintainer-sync backups to the newest three timestamped `pmm-*` install snapshots by default while preserving unrelated upgrade and migration anchors.
- Expanded the source runtime contract to 371 passing assertions and verified invalid retention values plus symlinked backup storage fail before modifying the installed skill.

## 2026-07-21

- Implemented the `pmm` v0.5.1 Upgrade Gate so old project content is upgraded to the installed runtime before normal writes rather than remaining indefinitely in legacy execution mode.
- Added project runtime markers, managed `AGENTS.md` blocks, transactional all-file backups and rollback, ambiguity/future-version refusal, history-only idle convergence, deterministic legacy task IDs, and automatic lifecycle gating.
- Kept compatibility readers and `migrate --apply` for migration discovery, recovery, rollback, and audit while making current runtime state authoritative after a successful upgrade; Doctor now requires that upgrade by default.
- Expanded the source runtime contract to 359 passing assertions, including automatic upgrade, idempotency, concurrent upgrade, transaction failure, lifecycle upgrade, and child-worktree claim reuse.
- Released `pmm` v0.5.0, synced the maintainer install from public `main`, and verified the source and real installed-package layouts before closing the primary task.
- Prepared `pmm` v0.5.0 as a compatibility-first upgrade: added read-only per-contract migration plans, strict source/status ambiguity refusal, stable Doctor JSON codes, delivery CLI, global help/version, and a source-plus-installed release preflight.
- Expanded legacy parsing and Recovery for real project shapes: bare fields, `## Task <id>` headings, code spans, trailing whitespace, verbose status text, empty active-task placeholders, completed/deferred history, duplicate conflicting status fields, and explicit missing task IDs.
- Preserved downgrade safety: old ledgers remain readable and unchanged, migration apply creates a project-local backup, conflicting state becomes paused review or refuses apply, and installed package verification uses the same runtime contract as the source checkout.

## 2026-07-18

- Released the v0.4.1 installed-contract hotfix: the same 233-assertion contract now validates repository-maintenance sources in a checkout and actual shipped runtime files in an installed package, without changing v0.4.0 lifecycle or legacy compatibility behavior.
- Upgraded the public runtime contract to `pmm` v0.4.0: `active-task.md` is one primary-task slot, while concurrent writers use isolated branches/worktrees and work-item files.
- Added `pmm.task/v1` three-axis state, lifecycle CLI, shared state helpers, local same-machine claims, Git HEAD/source-hash evidence freshness, Doctor v2, Recovery v2, and explicit legacy migration.
- Preserved backward compatibility for unstructured single-task `active-task.md` and `task-ledger.md`; ambiguous multi-task migration is diagnostic-only and never rewrites the source file.
- Added runtime contract tests and expanded Bash/PowerShell install, public safety, templates, bilingual docs, and release metadata for the v0.4 package.
- Added Git common-dir mutation serialization, strict owner/branch/claim checks, parent-child close/start exclusion, failed-write rollback, delivery queue preservation, ledger-source migration, stronger Doctor invariants, and fail-closed source hashing after independent review.
- Added the post-review integration gate: uncommitted primary state is discoverable from sibling worktrees through shared claims; verified children remain `ready-to-integrate` until merged and accepted by the primary owner; primary verification is invalidated after integration.
- Added fail-closed untracked hashing, safe same-host orphan-lock recovery, non-active Recovery markers, and valid done/idle/paused/blocked legacy migration behavior.
- Closed the final v0.4 concurrency and false-pass gaps: common-dir primary uniqueness now includes paused/blocked migration states, Doctor fails multiple primary claims, archived IDs are reserved across local worktrees, and evidence freshness inspects each post-verification commit so source changes cannot be hidden by revert.
- Completed the v0.4 compatibility and transaction hardening: official v0.1 ledger fields and marker-less history remain recognized across refs, sibling-worktree claims participate in Recovery, source-to-operational-path renames cannot hide stale evidence, and whole-file lifecycle transactions remove temporary state and roll back new claims after failure or signal.
- Closed final release-review gaps: interrupted takeover restores the claim owner matching the durable task file; ledger parsing counts individual current-task records while leaving completed history cold; Doctor fails missing or mismatched primary claims; and Recovery discovers uncommitted sibling-worktree primary as well as child claims.
- Preserved formal v0.2/v0.3 multi-section migration fields by treating Status, Task, Verifier, and Repair headings as one contract and verifying objective, required checks, and next action before the appended legacy-source section.

## 2026-07-09

- Consolidated the public document set: runtime/profile/context/self-eval/subagent/verifier/memory/migration guidance now lives in `docs/runtime.md`; release/automation/safety/sync/recovery/customization guidance now lives in `docs/maintenance.md`; optional pack templates now live in `templates/optional-packs.md`.
- Reduced generated optional-pack defaults to one concise domain document before splitting product, design, engineering, risk, operations, or automation details.
- Changed Product Pack defaults so generated projects use project-root `PRD.md` as the master requirements/product document, while `docs/02-product/*` remains optional split detail.

## 2026-05-29

- Added `pmm` v0.3.0 maintenance work: lightweight `scripts/pmm-doctor.sh`, ordinary install guidance, No PMM / Pulse Card / Core Pack usage tiers, and configurable public safety rules.
- Clarified that Codex-specific routing helpers are local execution aids only; generated `pmm` project memory must remain usable by Claude, Hermes, OpenClaw, and other agents without those helpers.

## 2026-05-28

- Renamed the public GitHub repository slug from `Project-Memory-Manager` to `project-memory-manager` while keeping the display name `Project Memory Manager` and skill call name `pmm`.
- Added `pmm` v0.2.2 Subagent Routing Gate so tasks choose `solo`, `assisted`, `parallel`, or `review-only` before broad work, with detailed delegation rules later consolidated into `docs/runtime.md`.
- Added `pmm` v0.2.1 legacy migration workflow so v0.1 projects using `task-ledger.md` can enter the v0.2 hot path with `active-task.md` and `verifier-map.md` instead of only being compatibility-read.
- Began `pmm` v0.2.0 upgrade from a full document-tree controller to a low-context project runtime with Runtime Profiles, Core Pack templates, optional packs, and Self-Eval Loop.
- Added project-memory templates for `active-task.md`, `verifier-map.md`, `task-history.md`, and `failure-patterns.md`, while keeping legacy `task-ledger.md` compatibility.
- Added adapter templates for Claude Code, Hermes Agent, OpenClaw/OpenCode-style agents, and Codex nested scopes.
- Updated context budget, agent compatibility, recovery, release checklist, README mirrors, public changelog, local sync coverage, and public safety checks for the v0.2 contract surface.
- Updated the `v0.1.0` and `v0.2.0` GitHub Release titles and notes to use formal project naming, native Chinese primary copy, collapsible English mirrors, concise changelog-style sections, and source/full-changelog links; added release checklist rules for future release titles, bilingual writing quality, and keeping routine verification logs out of public Release bodies.
- Added a safe local GitHub intake automation boundary for read-only PR and issue triage reports without public comments, labels, closes, approvals, or merges.
- Added a safe local skill evolution automation boundary for read-only upgrade opportunity reports without edits, commits, pushes, releases, workflow activation, or GitHub state changes.
- Tuned the skill evolution automation cadence from daily to every three days to reduce noise while the project has low public traffic.

## 2026-05-20

- Added usage-driven `pmm` guidance for keeping generated `AGENTS.md` files project-specific, requiring concrete source artifacts before PRD/requirements/source reviews, and defining subagent role and ownership boundaries before authorized subagent work.
- Tightened local skill sync so unmanaged files inside the dedicated local `pmm` skill directory are removed during sync, preventing stale local skill files from surviving.
- Completed the 2026-05-20 optimization release with repository-wide security review, public `main` push, public repository visibility verification, and local skill sync from public `main`.
- Added formal public versioning with `VERSION`, `SKILL.md` frontmatter version, public `CHANGELOG.md`, release checklist rules, sync coverage, and public safety validation for version consistency.
- Published formal release `v0.1.0` and synced the local `pmm` skill installation with the release version files.
- Clarified MIT license visibility in README files and added release/public-safety checks that require the root `LICENSE` file and README license links.
- Added `LICENSE` to local skill sync coverage so installed skill copies preserve license terms.

## 2026-05-15

- Added context-budget guidance and updated `SKILL.md`, templates, README files, compatibility notes, local sync, and public safety checks so `pmm` reduces context and token use through staged reading and concise durable updates; the guidance later consolidated into `docs/runtime.md`.
- Added no-op recovery guidance so routine recovery checks that find no active task, drift, or follow-up do not create task-ledger noise.

## 2026-05-14

- Changed the default repository overview to Simplified Chinese in `README.md`, added `README.en.md`, and added language switch links between the two files.
- Added cross-agent compatibility guidance for Claude Code, Hermes, OpenCode/OpenClaw-style agents, and other AGENTS.md-aware coding agents.
- Added the Agent Skills `compatibility` frontmatter to `SKILL.md` and documented that generated `AGENTS.md` plus project-local `docs/` are the portable project memory output.
- Updated the project document skeleton with optional Claude Code, Hermes, and OpenCode/OpenClaw compatibility shims.
- Expanded local skill sync to include `docs/agent-compatibility.md`.

## 2026-05-13

- Completed scheduled security review for the public `pmm` repository; no frontend/backend application code, dependencies, committed secrets, auth flow, payment flow, or database layer were present.
- Added repository-specific security rules for recurring reviews, local sync boundaries, and auto-merge policy.
- Hardened public safety checks to use per-run temp files and reject symlinks, committed `.env` files, and unexpected executable files outside reviewed scripts.
- Hardened local skill sync with destination path validation, symlink rejection, and cloned-repository symlink/executable checks before `rsync --delete`.
- Tightened the auto-merge workflow draft so external PRs require a maintainer-applied `safe-auto-merge` label and external `SKILL.md` changes remain manual review only.
- Published the sanitized public repository structure.
- Added safety scanning and local skill sync scripts.
- Added automation documentation and GitHub Actions workflow examples as non-active drafts.
- Added root project memory so future agents can load and maintain this repository consistently.
- Added project-local runtime storage rules for temporary files, backups, and automation source prompts.
- Added remote compact stream disconnect recovery rules and recovery automation prompt.
- Added file-purpose header requirements so future agents can skip irrelevant files faster.
- Expanded local skill sync to include compact recovery automation docs and `scripts/recovery-status.sh`.
- Renamed the public skill call name and repository references to `pmm`, displayed as `Project Memory Manager`.
