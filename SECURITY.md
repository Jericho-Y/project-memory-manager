# Security Policy

Purpose: Security reporting policy and publish-safety expectations for this repository.
Read when: Reviewing disclosures, handling suspected leaks, or checking release safety.
Skip when: Working on normal skill behavior unrelated to security.

## Reporting Sensitive Data

If you find a leaked secret, private server detail, private path, token, credential, or production identifier in this repository, please open a private security advisory or contact the repository owner directly.

Do not open a public issue containing the secret.

## What Should Not Be Committed

- plaintext passwords
- API keys or tokens
- private keys or certificates
- database connection strings
- real server inventories
- production deployment paths
- private customer or payment data
- private chat logs or memory exports
- local machine paths that identify a person or private workspace

## Automation Safety

This repository's automation is intentionally conservative. It should not auto-merge workflow, script, executable, binary, dependency, or permission changes from untrusted pull requests.

Local skill synchronization should happen only from the checked `main` branch after public safety checks pass.
