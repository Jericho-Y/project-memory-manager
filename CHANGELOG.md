# 更新日志

用途：记录 `pmm` skill 的公开版本变化。
阅读时机：查看不同公开版本之间改了什么。
跳过时机：只需要内部维护历史时，读取 `docs/07-decisions/change-log.md`。

本项目遵循语义化版本。中文是主更新日志；英文镜像见 [CHANGELOG.en.md](CHANGELOG.en.md)。

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
