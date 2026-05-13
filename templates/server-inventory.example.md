# Server Inventory Example

Purpose: Placeholder-only shape reference for private server inventory documents.
Read when: Creating a private server inventory for a project.
Skip when: No server, deployment, or production access context is needed.

Do not commit a real server inventory. Copy this file to a private, ignored location and replace placeholders locally.

```markdown
# Server Inventory

Purpose: Private server access and deployment boundary map.
Read when: Deployment, operations, logs, or server access are needed.
Skip when: Work has no server or production dependency.

## <server-alias>

- Purpose: <production | staging | development>
- Environment: <cloud/vendor/region>
- Host/IP: <host-or-ip>
- SSH Port: <port>
- Login User: <user>
- Deployment Path: <deploy-root>
- Service Name: <service-name>
- Log Location: <log-path>
- Credential Reference: <local-secure-storage-reference>
```

Never store plaintext passwords, API keys, private keys, tokens, or database URLs here.
