# Project Memory Manager（项目记忆管理器）

语言：简体中文 | [English](README.en.md)

Purpose: 本仓库的公开说明、安装指南、安全模型和目录地图。
Read when: 评估、安装、发布或首次了解这个 skill 仓库时阅读。
Skip when: 已经熟悉仓库结构，只需要查看某个具体实现文件。

`pmm` 是一个用于启动和持续维护长期软件项目的 Agent Skill。它帮助 Agent 建立持久化需求、项目记忆、验证规则、恢复检查点和安全边界，避免项目只依赖临时聊天上下文。

它适用于商业级 app、网站、小程序、SaaS、桌面工具、AI 产品和较大的功能链路。不适合一次性命令、极小改动或临时 demo。

## 核心能力

- 创建项目级 `AGENTS.md`，作为所有 Agent 进入项目后的第一记忆入口。
- 让 `AGENTS.md` 保持项目特有规则，不复制全局协作习惯或个人偏好。
- 建立结构化 `docs/` 文档树，覆盖业务、产品、设计、技术、交付、运营和决策记录。
- 定义不同任务类型应该读取哪些文档。
- 要求 PRD、需求、截图、设计稿或文档审查前先定位真实源材料，不凭聊天摘要臆断。
- 通过 Context Budget 规则减少上下文占用：先读入口、索引和必要章节，不默认全量扫描项目历史。
- 使用 `docs/00-project-memory/task-ledger.md` 跟踪当前任务和恢复检查点。
- 支持中断恢复、重试边界和 compact/stream 断连后的续跑。
- 要求每个项目文档保留简短的 Purpose / Read when / Skip when 说明，降低未来 Agent 误读成本。
- 要求完成前进行验证，不能只凭主观判断宣称完成。
- 将生产、支付、权限、凭据、发布等高风险动作保留给项目负责人确认。

## 仓库内容

```text
.
  SKILL.md
  README.md
  README.en.md
  templates/
    document-skeletons.md
    server-inventory.example.md
  examples/
    generic-app/
  docs/
    00-project-memory/
      recovery-rules.md
      security-rules.md
    agent-compatibility.md
    context-budget.md
    customization-guide.md
    release-checklist.md
    automation.md
    08-automation/
      compact-disconnect-recovery.md
      scheduled-maintenance.md
  scripts/
    check-public-safety.sh
    recovery-status.sh
    sync-local-skill.sh
```

## 安装

可以把整个仓库复制到本地 skills 目录，也可以只复制核心 skill 文件到目标 Agent 的 skill 目录：

```text
<SKILLS_ROOT>/pmm/
  SKILL.md
  templates/
  docs/
    agent-compatibility.md
    context-budget.md
```

之后在启动、规划、接手、恢复或维护长期项目时引用 `pmm`。

## Agent 兼容性

`pmm` 使用 Agent Skills 的 `SKILL.md` 格式，但它生成的项目记忆是 Agent 中立的：真正稳定的项目入口是项目根目录的 `AGENTS.md` 加项目内 `docs/`。

- Codex 和其他 Agent Skills 客户端可以直接安装 `pmm/SKILL.md`。
- Claude Code 可以安装到 Claude skills 目录，并用一个很短的 `CLAUDE.md` shim 指向 `AGENTS.md`。
- Hermes 可以作为 `SKILL.md` skill 安装，并在 handoff 任务里引用项目记忆文件。
- OpenCode / OpenClaw 风格 Agent 即使不加载 skill 包，也可以直接读取生成后的 `AGENTS.md`。

完整兼容矩阵和 shim 示例见 `docs/agent-compatibility.md`。

## 基本流程

1. 启动新项目，或识别一个已有项目。
2. 创建或更新项目根目录 `AGENTS.md`。
3. 在 `docs/` 下创建需求、技术、交付、运营和决策文档树。
4. 在 `docs/00-project-memory/task-ledger.md` 记录当前任务。
5. 对审查类任务，先确认具体 PRD、截图、设计稿、文档或代码来源。
6. 只读取当前任务需要的源文档，不默认扫描整棵文档树。
7. 执行、验证、安全重试，并更新项目记忆。
8. 在 `docs/07-decisions/` 记录决策、风险和变更。

详细的上下文和 token 降耗策略见 `docs/context-budget.md`。

## 安全模型

不要提交真实 secrets、生产凭据、私有服务器 inventory、客户数据、支付密钥、部署 token、私密聊天日志或能识别个人工作环境的本机路径。

公共文档中使用占位符：

- `<PROJECTS_ROOT>`
- `<SKILLS_ROOT>`
- `<server-alias>`
- `<production-domain>`
- `<credential-reference>`

以下高风险动作必须由项目负责人确认：

- 真实支付、退款、计费或交易动作
- 生产数据删除或迁移
- 凭据、权限、用户、订单或账单配置变更
- 外部发布、消息发送、应用商店提交或其他用户可见动作

## 可选执行集成

`pmm` 可以协调规划、TDD、系统化调试、完成前验证、部署、安全审查和带角色边界的子代理并行执行等专用工作流。

项目记忆协议始终是上层控制器：专用执行工作流可以增加检查，但不能弱化项目记忆、验证、恢复或安全要求。

## 检查

发布前运行公开安全检查：

```bash
bash scripts/check-public-safety.sh
```

该检查会拦截常见敏感词、本机路径、私有项目名、私有域名、可执行载荷和疑似 secret 内容。

## 自动化

仓库包含本地自动化辅助脚本：

- `scripts/check-public-safety.sh`：公开安全和疑似 secret 内容扫描。
- `scripts/sync-local-skill.sh`：从已检查通过的 `main` 分支同步本地 skill 目录。

GitHub Actions 不应直接访问本机。使用本地 scheduler 或 Agent automation 检查 PR、只合并安全变更，并在 `main` 检查通过后运行 `scripts/sync-local-skill.sh`。

## License

MIT
