# Release Checklist

Purpose: Checklist for safely publishing or updating the public repository.
Read when: Preparing a release, public push, or repository configuration change.
Skip when: Doing local-only project memory or template edits with no publication.

Use this before publishing changes to this repository.

## Public Safety

- Run `bash scripts/check-public-safety.sh`.
- Confirm no private paths, domains, server aliases, credential references, or personal identifiers are present.
- Confirm examples use placeholders or `example.com`.
- Confirm no real `.env`, token, key, certificate, or memory export is present.
- Confirm `LICENSE` is present, GitHub detects the intended license, and README files link to it.

## Repository

- Check `git status`.
- Review `git diff`.
- Confirm only intended files are staged.
- Push to a branch and let CI run before merge.

## Versioning

- Update `VERSION` for every public behavior change.
- Update the `version:` field in `SKILL.md` to match `VERSION`.
- Add a public entry to `CHANGELOG.md` describing user-visible additions, changes, fixes, and security notes.
- Create and push a matching git tag, for example `v0.1.0`.
- Publish a GitHub Release from the matching tag when the version is intended as a formal public release.
- GitHub Release notes must be bilingual when the repository overview is bilingual: Chinese first, English mirror second, with equivalent sections for highlights, verification, and known limitations.

## v0.2 Contract Surface

- Confirm runtime profile docs exist: `docs/runtime-profiles.md`.
- Confirm Self-Eval docs exist: `docs/self-eval-loop.md`, `docs/verifier-recipes.md`, `docs/memory-promotion.md`.
- Confirm Core Pack templates exist: `active-task.md`, `verifier-map.md`, `task-history.md`, and `failure-patterns.md`.
- Confirm adapter templates exist for Claude Code, Hermes, OpenClaw/OpenCode, and Codex nested scopes.
- Confirm `scripts/recovery-status.sh` supports both v0.2 `active-task.md` and v0.1 legacy `task-ledger.md`.
- Confirm local sync includes all installed docs, templates, and recovery helper scripts.

## License

- Keep the repository license in the root `LICENSE` file.
- Keep README license sections short and link to `LICENSE`.
- Do not change the license family without maintainer confirmation, because it affects downstream reuse rights.

## Automation

- Do not auto-merge workflow or script changes from untrusted contributors.
- Do not sync local skills from a branch that failed checks.
- Keep local sync backups.
