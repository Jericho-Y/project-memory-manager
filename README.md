# Project Memory Manager（pmm）

语言：简体中文 | [English](README.en.md)

当前版本：`v0.5.0`，详见 [CHANGELOG.md](CHANGELOG.md)；英文镜像见 [CHANGELOG.en.md](CHANGELOG.en.md)。
协议： [MIT License](LICENSE)。

用途：本仓库的公开说明、安装指南、运行模型、兼容策略和安全模型。
阅读时机：评估、安装、发布或首次了解这个 skill 仓库时阅读。
跳过时机：已经熟悉仓库结构，只需要查看某个具体实现文件。

`pmm` 是一个面向长期软件项目的低上下文、跨 Agent 项目运行时（Agent Skill）。它的目标不是生成更多项目文档，而是让 Agent 在最少必要上下文里持续执行、验证、批判、修复和恢复任务。

`v0.5.0` 的核心输出是：

- `AGENTS.md`：项目事实和协作规则的唯一入口。
- Core Pack：`current-state.md`、`active-task.md`、`verifier-map.md`、`change-log.md` 等最小热路径文件。
- Self-Eval Loop：让任务有明确的 Task、Harness、Verifier、Critic、Repair、Record。
- Agent adapters：让 Codex、Claude Code、Hermes Agent、OpenClaw/OpenCode 读取同一份项目事实，而不是各自复制一套记忆。
- Memory promotion rules：只沉淀耐久事实，不把当前任务状态塞进全局记忆。
- Task Runtime：`active-task.md` 保持一个主任务；并发写入使用独立 branch/worktree 和 work-item，验证证据绑定当前 Git HEAD 与源码状态。

适用场景：商业级 app、网站、小程序、SaaS、桌面工具、AI 产品、较大的功能链路、长期维护项目，以及需要跨 Agent 接手、断线恢复或严格验证的任务。
不适用场景：一次性命令、极小改动、临时 demo、无需项目记忆或验证闭环的短任务。

## v0.5.0 兼容升级

`v0.5.0` 重点保证旧项目能继续执行并安全升级：

- `migrate --plan` 先只读列出候选，`--dry-run` 再验证，只有一个明确当前任务且来源/状态无冲突时才允许 `--apply`。
- 兼容带/不带 bullet 的旧字段、`## Task <id>` ledger、Markdown code span、verbose prose 状态和空 `active-task.md` 占位。
- Completed history 保持冷路径；未知或冲突状态进入 `paused` 复核，重复冲突 `Status` 不会被自动激活或迁移。
- Doctor 默认报告 legacy 兼容与升级建议，`--require-structured` 可用于严格门禁；JSON 输出包含稳定 issue code。
- `pmm-task.sh` 增加全局帮助、版本和 delivery 命令；`pmm-preflight.sh` 同时验证源码与已安装包。
- 升级不会删除旧 `task-ledger.md`；apply 前创建项目本地备份。

## v0.4.0 关键变化

`v0.4.0` 修复同一项目在多个对话或 Agent 中并行开发时，`active-task.md` 被追加成多任务列表的问题：

- `active-task.md` 是单一主任务槽位，不再承载多个功能合同。
- `pmm.task/v1` frontmatter 分开记录执行、验证和交付状态。
- `scripts/pmm-task.sh` 提供 start、status、checkpoint、verify、resume、close、integrate 和 migrate 生命周期。
- 并发写任务必须使用独立 branch/worktree 和 `work-items/<task-id>.md`；同分支并发会被拒绝。
- 同机生命周期写入通过 Git common-dir lock 串行化并整文件原子提交；失败或 signal 会清理临时文件、回滚新 claim，并恢复中断 takeover 的原 owner。同一 clone 只允许一个非 idle primary claim，paused/blocked 任务也持续占槽。
- 已归档 `task_id` 不可复用，包括旧版无 marker 的历史记录；verify 后任何触及源码的 commit 都会使证据失效，即使后续 revert 或将源码 rename 到运行时文档路径。
- Doctor v2 检查任务唯一性、状态、完整 claim、分支所有权和证据新鲜度，并支持 `--json`。
- Recovery v2 兼容旧状态和 `task-ledger.md`，可从 sibling worktree 的共享 claim 发现未提交主任务或子任务；多个可恢复任务时要求显式 `--task-id`。
- 旧项目无需立即迁移；ledger 按任务字段区分当前任务与 completed 历史，只有一个当前任务时才允许 dry-run 后显式迁移。
- work-item close 只进入 `ready-to-integrate` 并保留 claim；合并后由主任务 owner 执行 integrate，再重验主任务。主任务 close 才会完成归档，并将未完成 delivery 放入 task queue。

## v0.3.1 维护更新

`v0.3.1` 精简公开文档结构：运行档位、上下文预算、自我评测、子代理、验证、记忆沉淀和旧项目迁移统一到 [docs/runtime.md](docs/runtime.md)；发布、自动化、安全维护和 compact 恢复统一到 [docs/maintenance.md](docs/maintenance.md)；可选包模板统一到 [templates/optional-packs.md](templates/optional-packs.md)。

## v0.3.0 维护更新

`v0.3.0` 增加轻量运行检查和更清晰的安装边界：普通用户可以直接把 skill 放到 `<SKILLS_ROOT>/pmm`，维护者同步脚本继续作为维护工具；`scripts/pmm-doctor.sh` 可检查项目 Core Pack、verifier、热路径行数和 adapter 是否保持指针式。

同时补充 `No PMM`、`Pulse Card`、`Core Pack` 三档轻量使用建议，避免小任务被迫创建完整项目记忆。

## v0.2.0 关键变化

`v0.2.0` 的公开定位是低上下文 Agent 执行 runtime：

- Runtime Profiles：`Pulse`、`Sprint`、`Project`、`Recovery`、`Audit`，按任务风险和复杂度决定读写范围。
- Core Pack：新项目默认只创建最小项目记忆，不再默认生成完整商业文档树。
- Optional Packs：产品、设计、工程、风险、运维、自动化文档按需创建。
- Self-Eval Loop：每个重要任务都有 `Task -> Harness -> Verifier -> Critic -> Repair -> Record` 合同。
- 当前任务热路径：新增 `active-task.md` 和 `verifier-map.md`，历史任务迁到 `task-history.md`。
- 失败模式沉淀：重复问题进入 `failure-patterns.md`，避免每次从零排查。
- Agent adapters：Claude Code、Hermes Agent、OpenClaw/OpenCode、Codex 都通过轻量 shim 指向同一份项目事实源。
- Legacy bridge：旧项目的 `task-ledger.md` 仍兼容，但新项目优先使用 `active-task.md`。

`v0.1.0` 的需求、项目记忆、验证、恢复和文档骨架能力仍然保留，但在 `v0.2.0` 中变成按需启用的 Optional Packs 和 legacy bridge。默认路径不再是创建完整文档树，而是先用 Core Pack 和 Self-Eval Loop 支撑任务执行，再根据真实项目需要补充产品、设计、工程、风险、运维或自动化文档。

## v0.2.2 维护更新

`v0.2.2` 增加 Subagent Routing Gate：任务开始时先判断用 `solo`、`assisted`、`parallel` 还是 `review-only`。小任务默认不启用子代理；复杂任务、独立复查、前后端/测试/文档能分工时，才按边界启动或记录子代理计划。

这套规则不会强制所有 Agent 都支持子代理。Codex 等支持子代理的运行时可以按记录执行；Claude Code、Hermes、OpenClaw 或其他不支持的运行时，可以把它当作任务拆分和人工交接字段。

## v0.2.1 维护更新

`v0.2.1` 补齐旧项目升级路径：如果项目是用 `v0.1.0` 产生的 `task-ledger.md`，新版 `pmm` 不应该只停留在兼容读取，而应该在用户需要 v0.2 能力或开始重要任务时，按 [docs/runtime.md](docs/runtime.md) 轻量创建 `active-task.md`、`verifier-map.md` 等热路径文件。

详细说明见：

- [docs/install.md](docs/install.md)
- [docs/runtime.md](docs/runtime.md)
- [docs/agent-compatibility.md](docs/agent-compatibility.md)
- [docs/maintenance.md](docs/maintenance.md)

## 核心概念

`pmm` 的项目记忆分三层：

```text
Canonical Project Memory
  AGENTS.md + docs/00-project-memory/*

Agent Adapter Layer
  CLAUDE.md / HERMES.md / OpenClaw project card / nested AGENTS.md

Self-Eval Runtime
  Task / Agent Mode / Harness / Verifier / Critic / Repair / Record
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

- [templates/optional-packs.md](templates/optional-packs.md)：产品（默认总文档为项目根目录 `PRD.md`）、设计、工程、风险、运维和自动化可选文档。

不要为空白占位创建整棵文档树。没有事实的文档先不要建。

## Self-Eval Loop

重要任务都应该在自己拥有的 `active-task.md` 或 work-item 文件里写清楚：

```text
Task: 目标、范围、风险、允许/禁止动作
Agent Mode: solo / assisted / parallel / review-only
Harness: 工具、skills、子代理、命令、环境
Verifier: 必跑检查、证据、人工验收点
Critic: 是否真通过、缺什么证据、是否假通过
Repair: 失败类型、尝试次数、下一步修复
Record: 最终状态、文档变更、是否沉淀记忆
```

没有 verifier 或新鲜证据的任务不能关闭。执行受阻时使用 `execution_status: blocked`；验证未完成或失败时使用 `verification_status: pending` 或 `failed`。

`active-task.md` 始终只保留一个主任务。第二个写入对话应排队，或切到独立 branch/worktree 后使用 [templates/concurrency/work-item.md](templates/concurrency/work-item.md)。work-item 验证后仍需合并、由主任务 owner 执行 `integrate`，并重新验证主任务；生命周期命令和迁移方式见 [docs/runtime.md](docs/runtime.md)。

## 安装

### 普通安装（Agent 用户）

将仓库放入目标 Agent 的技能目录，目录名保持为 `pmm`：

```text
<SKILLS_ROOT>/pmm/
```

`<SKILLS_ROOT>` 为该运行时的技能根目录（Windows / macOS / Linux 均使用同一规则）：

```text
<SKILLS_ROOT>/pmm/            # macOS / Linux
<SKILLS_ROOT>\pmm\       # Windows
```

最小安装目录：

```text
<SKILLS_ROOT>/pmm/
  SKILL.md
  VERSION
  CHANGELOG.md
  LICENSE
  docs/
  templates/
  scripts/recovery-status.sh
  scripts/pmm-doctor.sh
  scripts/pmm-task.sh
  scripts/pmm-preflight.sh
  scripts/lib/pmm-state.sh
  tests/pmm-runtime-contract.sh
```

### 维护者同步

仓库维护者在变更公开仓库后，可使用同步脚本将变更同步到本地 `<SKILLS_ROOT>/pmm`：

```bash
bash scripts/sync-local-skill.sh
```

同步前请先执行：

```bash
bash scripts/check-public-safety.sh
```

详细说明见 [docs/install.md](docs/install.md)。

Windows 或 PowerShell 用户也可以使用普通安装脚本：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-local-skill.ps1 -SkillsRoot <SKILLS_ROOT>
```

## 快速上手

1. 安装或复制 `pmm` skill 到 `<SKILLS_ROOT>/pmm`。
2. 在项目根目录创建 `AGENTS.md`，使用 [templates/core/AGENTS.md](templates/core/AGENTS.md)。
3. 创建 Core Pack：`current-state.md`、`active-task.md`、`verifier-map.md`、`change-log.md`。
4. 按任务选择 Runtime Profile。
5. 运行 Workspace Gate；`active-task.md` 已有主任务时，不追加第二个任务。
6. 使用 `scripts/pmm-task.sh start` 启动主任务；并发写任务先创建独立 branch/worktree，再启动 work-item。
7. 执行、验证、Critic 检查、失败修复，并用 `verify` 记录新鲜证据。
8. 运行 `bash <SKILLS_ROOT>/pmm/scripts/pmm-doctor.sh <PROJECT_ROOT>` 检查状态、分支和 verifier。
9. work-item 使用 `close` 进入待集成，合并后由主任务 owner 执行 `integrate` 并重验；主任务最后使用 `close` 归档。

### 轻量使用建议

- No PMM：极小、单文件、低风险任务，可不启用 PMM。
- Pulse Card：目标与验收足够明确的短任务，只在已有入口或当前任务记录里写最小任务卡，不为它新建完整 Core Pack。
- Core Pack：涉及可复用事实、跨文件变更、或需要持续验证/交接时，按完整 Core Pack 热路径推进。

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
bash -n scripts/*.sh scripts/lib/*.sh tests/*.sh
bash tests/pmm-runtime-contract.sh
bash scripts/pmm-doctor.sh .
git diff --check
```

公开版本必须同步更新：

- `VERSION`
- `SKILL.md` frontmatter `version:`
- [CHANGELOG.md](CHANGELOG.md)
- [CHANGELOG.en.md](CHANGELOG.en.md)
- README 中文/英文镜像
- 本地同步覆盖范围

更多发布、自动化和安全维护要求见 [docs/maintenance.md](docs/maintenance.md)。
