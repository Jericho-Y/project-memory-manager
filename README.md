# Project Memory Manager（pmm）

语言：简体中文 | [English](README.en.md)

当前版本：`v0.2.0`，详见 [CHANGELOG.md](CHANGELOG.md)。
协议： [MIT License](LICENSE)。

Purpose: 本仓库的公开说明、安装指南、运行模型、兼容策略和安全模型。
Read when: 评估、安装、发布或首次了解这个 skill 仓库时阅读。
Skip when: 已经熟悉仓库结构，只需要查看某个具体实现文件。

`pmm` 是一个用于长期软件项目的 Agent Skill。它把项目记忆、任务执行、自我评测、验证证据、恢复检查点和跨 Agent 兼容规则放到项目目录里，而不是依赖临时聊天上下文或某个 Agent 的私有记忆。

适用场景：商业级 app、网站、小程序、SaaS、桌面工具、AI 产品、较大的功能链路、长期维护项目。
不适用场景：一次性命令、极小改动、临时 demo、无需项目记忆的短任务。

## v0.2.0 关键变化

`v0.2.0` 把 `pmm` 从“项目文档管理 skill”升级为低上下文 Agent 执行 runtime：

- Runtime Profiles：`Pulse`、`Sprint`、`Project`、`Recovery`、`Audit`，按任务风险和复杂度决定读写范围。
- Core Pack：新项目默认只创建最小项目记忆，不再默认生成完整商业文档树。
- Optional Packs：产品、设计、工程、风险、运维、自动化文档按需创建。
- Self-Eval Loop：每个重要任务都有 `Task -> Harness -> Verifier -> Critic -> Repair -> Record` 合同。
- 当前任务热路径：新增 `active-task.md` 和 `verifier-map.md`，历史任务迁到 `task-history.md`。
- 失败模式沉淀：重复问题进入 `failure-patterns.md`，避免每次从零排查。
- Agent adapters：Claude Code、Hermes Agent、OpenClaw/OpenCode、Codex 都通过轻量 shim 指向同一份项目事实源。
- Legacy bridge：旧项目的 `task-ledger.md` 仍兼容，但新项目优先使用 `active-task.md`。

详细说明见：

- [docs/runtime-profiles.md](docs/runtime-profiles.md)
- [docs/self-eval-loop.md](docs/self-eval-loop.md)
- [docs/context-budget.md](docs/context-budget.md)
- [docs/agent-compatibility.md](docs/agent-compatibility.md)
- [docs/memory-promotion.md](docs/memory-promotion.md)
- [docs/verifier-recipes.md](docs/verifier-recipes.md)

## 核心概念

`pmm` 的项目记忆分三层：

```text
Canonical Project Memory
  AGENTS.md + docs/00-project-memory/*

Agent Adapter Layer
  CLAUDE.md / HERMES.md / OpenClaw project card / nested AGENTS.md

Self-Eval Runtime
  Task / Harness / Verifier / Critic / Repair / Record
```

项目事实始终以项目目录为准。Agent 自带记忆只保存稳定偏好或项目入口指针，不保存当前任务状态。

## Runtime Profiles

| Profile | 适合任务 | 默认读取 |
| --- | --- | --- |
| Pulse | 小改动、查找、已知文件修正 | `AGENTS.md` + 目标文件 |
| Sprint | 普通功能、Bug 修复、UI/API 改动 | Core Pack + 任务源文档 |
| Project | 新项目、需求不清、长期产品搭建 | Core Pack + 选定 Optional Packs |
| Recovery | 中断恢复、失败重试、compact 断线续跑 | hot path + recovery/change docs |
| Audit | 安全、发布、生产、支付、权限、公开兼容性 | 精确源材料 + 风险/验证文档 |

## Core Pack

新项目默认只需要：

```text
AGENTS.md
docs/00-project-memory/current-state.md
docs/00-project-memory/active-task.md
docs/00-project-memory/verifier-map.md
docs/07-decisions/change-log.md
```

冷路径文件按需创建：

```text
docs/00-project-memory/task-history.md
docs/00-project-memory/failure-patterns.md
```

模板在 [templates/core](templates/core)。

## Optional Packs

根据项目阶段按需使用：

- [templates/packs/product-pack.md](templates/packs/product-pack.md)：产品、PRD、用户流、验收标准。
- [templates/packs/design-pack.md](templates/packs/design-pack.md)：IA、页面地图、UI/UX、文案。
- [templates/packs/engineering-pack.md](templates/packs/engineering-pack.md)：架构、API、数据库、集成。
- [templates/packs/risk-pack.md](templates/packs/risk-pack.md)：安全、权限、支付、生产、风险。
- [templates/packs/ops-pack.md](templates/packs/ops-pack.md)：部署、监控、支持、发布。
- [templates/packs/automation-pack.md](templates/packs/automation-pack.md)：定时检查、心跳、长任务恢复。

不要为空白占位创建整棵文档树。没有事实的文档先不要建。

## Self-Eval Loop

重要任务都应该在 `active-task.md` 里写清楚：

```text
Task: 目标、范围、风险、允许/禁止动作
Harness: 工具、skills、子代理、命令、环境
Verifier: 必跑检查、证据、人工验收点
Critic: 是否真通过、缺什么证据、是否假通过
Repair: 失败类型、尝试次数、下一步修复
Record: 最终状态、文档变更、是否沉淀记忆
```

没有 verifier 的任务不能标记为 `done`，只能标记为 `executed-unverified` 或 `blocked`。

## 安装

把仓库放入目标 Agent 的 skills 目录，目录名保持为 `pmm`：

```text
<SKILLS_ROOT>/pmm/
  SKILL.md
  VERSION
  CHANGELOG.md
  LICENSE
  docs/
  templates/
  scripts/recovery-status.sh
```

本仓库维护者可使用：

```bash
bash scripts/check-public-safety.sh
```

本地同步脚本会先克隆公开仓库、运行安全检查，再同步到专用 `pmm` skill 目录。不要把同步目标设置成宽泛目录。

## 快速上手

1. 安装或复制 `pmm` skill。
2. 在项目根目录创建 `AGENTS.md`，使用 [templates/core/AGENTS.md](templates/core/AGENTS.md)。
3. 创建 Core Pack：`current-state.md`、`active-task.md`、`verifier-map.md`、`change-log.md`。
4. 按任务选择 Runtime Profile。
5. 在 `active-task.md` 写下 Task/Harness/Verifier。
6. 执行、验证、Critic 检查、失败修复。
7. 完成后只把耐久事实写回项目文档，历史归档到 `task-history.md`。

## Agent 兼容性

`pmm` 的项目输出是 Agent 中立的。即使某个 Agent 不能加载 `SKILL.md`，也可以读取 `AGENTS.md` 和 Core Pack。

- Codex：原生读取 `AGENTS.md`，可用 nested `AGENTS.md` 做子目录规则。
- Claude Code：使用 [templates/adapters/CLAUDE.md](templates/adapters/CLAUDE.md) 导入 `AGENTS.md`。
- Hermes Agent：优先让 Hermes 读取 `AGENTS.md`；如果必须使用 Hermes context 文件，用 [templates/adapters/HERMES.md](templates/adapters/HERMES.md) 做短 shim。
- OpenClaw/OpenCode：使用 [templates/adapters/openclaw-project-card.md](templates/adapters/openclaw-project-card.md) 作为 workspace 指针。

兼容矩阵见 [docs/agent-compatibility.md](docs/agent-compatibility.md)。

## 安全模型

不要提交真实 secrets、生产凭据、私有服务器 inventory、客户数据、支付密钥、部署 token、私密聊天日志或能识别个人工作环境的本机路径。

以下动作必须由项目负责人确认：

- 真实支付、退款、计费或交易动作
- 生产数据删除、迁移或覆盖
- 凭据、权限、用户、订单或账单配置变更
- 外部发布、消息发送、应用商店提交或其他用户可见动作

## 仓库维护

发布前至少运行：

```bash
bash scripts/check-public-safety.sh
bash -n scripts/*.sh
git diff --check
```

公开版本必须同步更新：

- `VERSION`
- `SKILL.md` frontmatter `version:`
- [CHANGELOG.md](CHANGELOG.md)
- README 中文/英文镜像
- 本地同步覆盖范围

更多发布要求见 [docs/release-checklist.md](docs/release-checklist.md)。
