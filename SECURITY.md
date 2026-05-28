# 安全政策 / Security Policy

用途：说明本仓库的安全报告方式、公开发布边界和自动化安全要求。
阅读时机：发现疑似泄露、处理安全反馈、发布版本或检查公开仓库安全时阅读。
跳过时机：只修改与安全、发布或仓库维护无关的普通内容时可以跳过。

## 报告敏感信息

如果你发现本仓库中包含泄露的密钥、私有服务器信息、私有路径、Token、凭据或生产环境标识，请通过 GitHub private security advisory 或直接联系仓库维护者。

不要在公开 Issue 中提交、截图或复述敏感信息。

## 不应提交的内容

- 明文密码
- API Key 或 Token
- 私钥或证书
- 数据库连接字符串
- 真实服务器清单
- 生产环境部署路径
- 私有客户数据或支付数据
- 私有聊天记录或记忆导出
- 能识别个人或私有工作区的本机路径
- 可能重定向 skill 同步内容的符号链接
- 未审查脚本之外的异常可执行文件

## 自动化安全

本仓库的自动化应保持保守。来自不可信 Pull Request 的 workflow、脚本、可执行文件、二进制文件、依赖或权限变更，不应自动合并。

本地 skill 同步只能从通过公开安全检查后的 `main` 分支执行。同步目标必须是专用的 `pmm` skill 目录，不能是宽泛的项目目录、用户主目录或配置目录。

## English

Purpose: Security reporting policy and publish-safety expectations for this repository.
Read when: Reviewing disclosures, handling suspected leaks, or checking release safety.
Skip when: Working on normal skill behavior unrelated to security.

### Reporting Sensitive Data

If you find a leaked secret, private server detail, private path, token, credential, or production identifier in this repository, please open a private security advisory or contact the repository owner directly.

Do not open a public issue containing the secret.

### What Should Not Be Committed

- plaintext passwords
- API keys or tokens
- private keys or certificates
- database connection strings
- real server inventories
- production deployment paths
- private customer or payment data
- private chat logs or memory exports
- local machine paths that identify a person or private workspace
- symlinks that could redirect synced skill content
- unexpected executable files outside reviewed scripts

### Automation Safety

This repository's automation is intentionally conservative. It should not auto-merge workflow, script, executable, binary, dependency, or permission changes from untrusted pull requests.

Local skill synchronization should happen only from the checked `main` branch after public safety checks pass. The sync destination must be a dedicated `pmm` skill directory, not a broad project, home, or configuration directory.
