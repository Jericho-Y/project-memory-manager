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

## Repository

- Check `git status`.
- Review `git diff`.
- Confirm only intended files are staged.
- Push to a branch and let CI run before merge.

## Automation

- Do not auto-merge workflow or script changes from untrusted contributors.
- Do not sync local skills from a branch that failed checks.
- Keep local sync backups.
