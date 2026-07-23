# Task History

Purpose: Append-only compact summaries of closed tasks.

## 2026-07-18 2026-07-18-pmm-v0.4-task-runtime

<!-- pmm-task-id: 2026-07-18-pmm-v0.4-task-runtime -->

- Status: done
- Parent Task: none
- Title: pmm v0.4.0 structured task runtime
- Execution State: done
- Verification State: passed
- Delivery State: released
- Verification Evidence: committed HEAD 374d3d7: runtime contract 233/233; shell syntax, public safety, Doctor text/JSON, Recovery, version, diff checks passed; independent review Critical=0 Important=0
- Closed At: 2026-07-18T15:15:04Z

## 2026-07-18 2026-07-18-pmm-v0.4.1-installed-contract

<!-- pmm-task-id: 2026-07-18-pmm-v0.4.1-installed-contract -->

- Status: done
- Parent Task: none
- Title: pmm v0.4.1 installed contract hotfix
- Execution State: done
- Verification State: passed
- Delivery State: released
- Verification Evidence: committed source, simulated install, isolated sync, and final local installed contracts each passed 233/233; public safety, Doctor text/JSON, shell syntax, version and diff checks passed; v0.4.1 Release is public and latest
- Closed At: 2026-07-18T15:34:53Z

## 2026-07-21 2026-07-21-pmm-v0.5-compat-runtime

<!-- pmm-task-id: 2026-07-21-pmm-v0.5-compat-runtime -->

- Status: done
- Parent Task: none
- Title: pmm v0.5 compatibility-first runtime
- Execution State: done
- Verification State: passed
- Delivery State: released
- Verification Evidence: source preflight 289/289; isolated and real local installed-package preflight 288/288; public safety passed; Doctor failures=0 warnings=0; shell syntax and diff checks passed; public v0.5.0 Release verified
- Closed At: 2026-07-21T07:17:49Z

## 2026-07-21 2026-07-21-pmm-v0.5.1-project-upgrade

<!-- pmm-task-id: 2026-07-21-pmm-v0.5.1-project-upgrade -->

- Status: done
- Parent Task: none
- Title: pmm v0.5.1 automatic project upgrade gate
- Execution State: done
- Verification State: passed
- Delivery State: released
- Verification Evidence: v0.5.1 release verification: source PMM_PREFLIGHT_PASS version=0.5.1; source contract tests=359 failures=0; installed package contract tests=358 failures=0; public safety passed; Doctor failures=0 warnings=0; shell syntax and git diff checks passed; tag v0.5.1 and GitHub Release published from commit 53c3c46.
- Closed At: 2026-07-21T08:55:59Z

## 2026-07-23 pmm-low-io-budget

<!-- pmm-task-id: pmm-low-io-budget -->

- Status: done
- Parent Task: none
- Title: 降低 PMM 文件读写与上下文额度成本
- Execution State: done
- Verification State: passed
- Delivery State: not-requested
- Verification Evidence: tests/pmm-runtime-contract.sh: 371 tests, 0 failures; public safety passed; Doctor 0 failures/0 warnings; shell syntax and git diff checks passed; SKILL.md 12314 bytes/192 lines
- Closed At: 2026-07-23T15:31:26Z

## 2026-07-23 pmm-worktree-auto-route

<!-- pmm-task-id: pmm-worktree-auto-route -->

- Status: done
- Parent Task: none
- Title: 修复多任务对话同时使用 PMM 的阻塞
- Execution State: done
- Verification State: passed
- Delivery State: not-requested
- Verification Evidence: HEAD 97b89f0: source runtime contract 377/377, public safety, Doctor, shell syntax, and diff check passed; synchronized installed package contract 362/362 and preflight passed.
- Closed At: 2026-07-23T15:59:05Z
