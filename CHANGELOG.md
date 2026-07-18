# 更新日志

用途：记录 `pmm` skill 的公开版本变化。
阅读时机：查看不同公开版本之间改了什么。
跳过时机：只需要内部维护历史时，读取 `docs/07-decisions/change-log.md`。

本项目遵循语义化版本。中文是主更新日志；英文镜像见 [CHANGELOG.en.md](CHANGELOG.en.md)。

## v0.4.1 - 2026-07-18

### 修复

- 修复安装包内置的运行时合同测试把仓库维护文件误当成安装依赖的问题。合同测试现在会区分源码仓库与已安装包：源码模式继续校验 maintainer sync 和 public-safety 配置，安装模式校验实际安装的生命周期 CLI、共享库、Doctor、Recovery、并发模板和测试文件。
- 保持 `v0.4.0` 运行时和旧项目兼容行为不变；本补丁只修正安装后自检。

## v0.4.0 - 2026-07-18

### 新增

- 新增 `pmm.task/v1` 结构化任务状态，独立记录执行、验证和交付状态。
- 新增 `scripts/pmm-task.sh` 生命周期命令与共享状态库，支持 start、status、checkpoint、verify、resume、close、integrate 和安全迁移。
- 新增 branch/worktree 隔离的 work-item 与 task-queue 模板，支持同一项目的多对话协作。
- Doctor v2 新增任务唯一性、状态枚举、分支所有权、证据新鲜度检查和 JSON 输出。
- Recovery v2 新增显式任务选择、旧状态归一化、`task-ledger.md` 回退、sibling worktree primary/work-item claim 发现、paused/blocked/待集成恢复和歧义拒绝。
- 新增 233 项运行时合同测试，覆盖 legacy 状态迁移、官方 v0.1 ledger 当前/历史任务筛选、v0.2/v0.3 多区段字段保留、证据失效、未跟踪文件 hash 失败、同/跨 worktree 并发 start、paused 主任务占槽、父子关闭竞态、worktree parent 发现、显式集成、verify 后源码 commit/revert/rename 拒绝、跨 Git ref 的 marker-less 历史任务 ID 复用拒绝与 ref 检查 fail-closed、孤儿锁恢复、owner/branch/claim 边界、takeover 中断回滚、delivery 保留、事务回滚、signal 临时文件清理和安装包完整性。

### 调整

- `active-task.md` 明确为单一主任务槽位，不再允许追加多个功能合同。
- 验证证据绑定当前 Git HEAD 和源码 hash；逐 commit 检查 verify 后的历史，源码 commit 即使随后 revert 也必须重新验证。
- 生命周期写入通过 Git common-dir mutation lock 串行化，并以整文件 staged transaction 原子提交；失败或 signal 会清理临时文件、回滚尚未提交的新 claim，并使中断的 takeover 恢复到与任务文件一致的 owner。变更命令必须匹配 owner、branch 和完整 claim，同机死亡进程遗留的短锁会安全恢复。
- work-item close 改为进入 `ready-to-integrate` 并保留 claim；主任务 owner 仅在 verified commit 已合并时才能 integrate，之后必须重验主任务。
- primary close 将 execution、verification、delivery 三轴写入历史，并把未完成 delivery 放入 task queue。
- 同一 clone 只允许一个非 idle primary claim；paused/blocked 任务持续占槽，已归档 primary/work-item `task_id` 不可复用。
- Bash 维护者同步与 PowerShell 普通安装都包含 lifecycle CLI、共享库、并发模板和合同测试。
- 旧版单任务 `active-task.md` 和 `task-ledger.md` 保持可读；迁移是显式可选操作，多任务歧义文件不会自动改写。

### 安全

- 同一 branch/worktree 的并发写入会被拒绝；跨设备协作仍必须使用远端分支所有权，不能把本地 claim 当作分布式锁。
- 单任务迁移 apply 前创建项目本地备份，自动迁移不会删除 legacy ledger。
- legacy `done` 在缺少 v0.4 新鲜证据时迁移为 paused，legacy `idle` 迁移为标准空槽，避免生成 Doctor 会拒绝的假完成状态。
- legacy ledger 按每条任务字段识别当前合同，忽略 completed 历史；零当前任务或多个当前任务都会拒绝自动迁移。
- Git diff、tracked/untracked source hash 或任务文件写入失败时 fail-closed，并保留或回滚 claim，不能产生假验证或孤儿状态；源码 rename 到 operational path 也不能绕过 verify 后的 freshness 检查。

## v0.3.1 - 2026-07-09

### 调整

- 精简公开文档结构：将运行档位、上下文预算、自我评测、子代理路由、验证配方、记忆沉淀和旧项目迁移合并到 [docs/runtime.md](docs/runtime.md)。
- 将发布检查、自动化边界、安全维护、local sync 边界、compact 恢复提示和定制说明合并到 [docs/maintenance.md](docs/maintenance.md)。
- 将产品、设计、工程、风险、运维和自动化可选包模板合并到 [templates/optional-packs.md](templates/optional-packs.md)，并默认优先使用单一领域文档，必要时再拆分。
- 更新公开安全检查和本地 skill 同步规则，改为校验合并后的文档入口。

## v0.3.0 - 2026-05-29

### 新增

- 新增 `scripts/pmm-doctor.sh`，用于检查项目 Core Pack、`active-task.md` verifier、热路径行数和 adapter 是否保持指针式。
- 新增 [docs/install.md](docs/install.md) 和 `scripts/install-local-skill.ps1`，区分普通用户安装和维护者同步，并说明 Windows/macOS/Linux 的通用 `<SKILLS_ROOT>/pmm` 目录约定。
- 新增 `No PMM`、`Pulse Card`、`Core Pack` 三档轻量使用建议，避免小任务被迫创建完整项目记忆。

### 调整

- 将 public safety 的必备文件、引用检查、通用禁止 marker、secret-like pattern、允许脚本和禁用文件类型拆到 `scripts/public-safety-rules.conf`，并支持 `.project-runtime/public-safety-local-rules.conf` 承载不提交的私有 marker。
- 本地 skill 同步纳入 `docs/install.md` 和 `scripts/pmm-doctor.sh`。

## v0.2.2 - 2026-05-28

### 新增

- 增加 Subagent Routing Gate，用于判断任务应使用 `solo`、`assisted`、`parallel` 还是 `review-only`。
- 新增子代理路由说明，说明子代理边界、默认数量上限、敏感信息限制和 `active-task.md` 记录方式；该内容后续合并进 [docs/runtime.md](docs/runtime.md)。
- Core Pack 的 `active-task.md` 模板新增 `Agent Mode` 字段。

### 调整

- Self-Eval Loop 改为先做轻量子代理判断，再进入加载、执行、验证和修复。
- Runtime Profile 和上下文预算文档明确：子代理规则是冷路径，小任务不为它额外消耗上下文。
- 跨 Agent 兼容说明明确：子代理能力是可选能力；不支持子代理的 Agent 记录 `solo` 或人工交接计划即可。

## v0.2.1 - 2026-05-28

### 新增

- 新增旧项目轻量迁移说明，帮助 `v0.1` 时代使用 `task-ledger.md` 的项目进入 `v0.2` 执行热路径。
- 明确当用户需要 `v0.2` 能力时，不能只停留在兼容读取；应创建 Core Pack 热路径，把当前任务迁移到 `active-task.md`，历史保持冷路径。

### 调整

- `SKILL.md`、上下文预算、Agent 兼容说明和模板路由都指向旧项目迁移流程。
- 本地同步和公开安全检查纳入旧项目迁移说明；该内容后续合并进 [docs/runtime.md](docs/runtime.md)。

## v0.2.0 - 2026-05-28

### 新增

- Runtime Profiles：Pulse、Sprint、Project、Recovery、Audit，用任务规模和风险决定读取范围。
- Core Pack 模板：`AGENTS.md`、`current-state.md`、`active-task.md`、`verifier-map.md`、`task-history.md`、`failure-patterns.md` 和 `change-log.md`。
- Optional Packs：产品、设计、工程、风险、运维和自动化文档模板。
- Self-Eval Loop 合同：Task、Harness、Verifier、Critic、Repair、Record 和记忆沉淀判断。
- Claude Code、Hermes Agent、OpenClaw/OpenCode 风格 Agent 和 Codex nested scope 的适配模板。
- 运行档位、自我评测、记忆沉淀和验证配方文档。

### 调整

- `SKILL.md` 从完整文档树控制器改为低上下文项目运行时路由器。
- 新项目优先使用 `active-task.md` 作为当前任务热路径。
- `task-ledger.md` 保留为 `v0.1` 旧项目兼容桥，完成历史应逐步移到 `task-history.md`。
- 上下文预算规则区分热路径状态、冷历史和重复失败记录。
- Agent 兼容说明将运行时专用文件定位为适配器，不再作为事实源。
- 恢复脚本同时支持 `v0.2` 的 `active-task.md` 和旧版 `task-ledger.md`。

### 运维

- 公开安全检查覆盖 `v0.2` 文档、Core Pack 模板、适配模板和行数预算。
- 本地 skill 同步纳入运行档位、自我评测、记忆沉淀、验证配方和适配模板。

## v0.1.0 - 2026-05-20

第一个正式公开版本。

### 新增

- 基于项目 `AGENTS.md` 和项目本地 `docs/` 的长期项目记忆协议。
- 需求、当前状态、任务台账、决策、自动化、恢复、安全和验证文档骨架。
- Codex、Claude Code、Hermes、OpenCode/OpenClaw 风格 Agent 和其他支持 `AGENTS.md` 的 Agent 兼容说明。
- 分阶段读取和精简记录的上下文预算协议。
- PRD、需求、截图、设计、文档和源码评审任务的来源材料门槛。
- 授权并行 Agent 工作时的角色和文件边界说明。
- compact 断线恢复说明和 `recovery-status.sh` 辅助脚本。
- 公开安全检查，用于检查私有标记、禁用文件类型、异常可执行文件、符号链接和文档漂移。
- 本地 skill 同步脚本，包含目标目录保护、安全检查、托管文件清理和本地备份。

### 安全

- 已完成公开 skill 仓库范围内的安全扫描，没有发现需要披露的问题。
