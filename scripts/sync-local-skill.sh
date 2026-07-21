#!/usr/bin/env bash
# Purpose: Safely sync the checked public skill files into a local skills directory.
# Read when: Updating local skill sync behavior or diagnosing local installation issues.
# Skip when: Working only on public documentation or templates.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/<owner>/project-memory-manager.git}"
LOCAL_SKILL_DIR="${LOCAL_SKILL_DIR:-$HOME/.codex/skills/pmm}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_RUNTIME_DIR="${PROJECT_RUNTIME_DIR:-$repo_root/.project-runtime}"
TMP_ROOT="$PROJECT_RUNTIME_DIR/sync"
WORKDIR="$TMP_ROOT/repo"
BACKUP_ROOT="$PROJECT_RUNTIME_DIR/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require_absolute_dir_value() {
  local name="$1"
  local value="$2"

  [[ -n "$value" ]] || fail "$name must not be empty"
  [[ "$value" == /* ]] || fail "$name must be an absolute path"

  case "$value" in
    "/"|"$HOME"|"$HOME/"|"$repo_root"|"$repo_root/")
      fail "$name points to an unsafe broad directory: $value"
      ;;
  esac
}

require_absolute_dir_value "PROJECT_RUNTIME_DIR" "$PROJECT_RUNTIME_DIR"
require_absolute_dir_value "LOCAL_SKILL_DIR" "$LOCAL_SKILL_DIR"

case "$LOCAL_SKILL_DIR" in
  */pmm)
    ;;
  *)
    fail "LOCAL_SKILL_DIR must point to a dedicated pmm skill directory"
    ;;
esac

case "$WORKDIR" in
  "$PROJECT_RUNTIME_DIR"/sync/repo)
    ;;
  *)
    fail "internal sync workdir resolved outside the expected runtime directory"
    ;;
esac

if [[ -L "$LOCAL_SKILL_DIR" || -L "$PROJECT_RUNTIME_DIR" ]]; then
  fail "sync paths must not be symlinks"
fi

rm -rf "$WORKDIR"
mkdir -p "$TMP_ROOT" "$BACKUP_ROOT"

if [[ "$REPO_URL" == *"<owner>"* ]]; then
  fail "set REPO_URL to the public repository URL before syncing"
fi

git clone --depth 1 --branch main "$REPO_URL" "$WORKDIR"
cd "$WORKDIR"

bash scripts/check-public-safety.sh

if find . -type l -not -path './.git/*' | rg .; then
  fail "symlink found in cloned repository"
fi

[[ -f SKILL.md ]] || fail "SKILL.md missing after clone"
[[ -f VERSION ]] || fail "VERSION missing after clone"
[[ -f CHANGELOG.md ]] || fail "CHANGELOG.md missing after clone"
[[ -f CHANGELOG.en.md ]] || fail "CHANGELOG.en.md missing after clone"
[[ -f LICENSE ]] || fail "LICENSE missing after clone"
[[ -d templates ]] || fail "templates directory missing after clone"
[[ -f docs/agent-compatibility.md ]] || fail "agent compatibility guide missing after clone"
[[ -f docs/install.md ]] || fail "install guide missing after clone"
[[ -f docs/runtime.md ]] || fail "runtime guide missing after clone"
[[ -f docs/maintenance.md ]] || fail "maintenance guide missing after clone"
[[ -f scripts/recovery-status.sh ]] || fail "recovery status helper missing after clone"
[[ -f scripts/pmm-doctor.sh ]] || fail "pmm doctor helper missing after clone"
[[ -f scripts/pmm-task.sh ]] || fail "pmm task lifecycle helper missing after clone"
[[ -f scripts/pmm-preflight.sh ]] || fail "pmm release preflight helper missing after clone"
[[ -f scripts/lib/pmm-state.sh ]] || fail "pmm shared state library missing after clone"
[[ -f scripts/install-local-skill.ps1 ]] || fail "PowerShell install helper missing after clone"
[[ -f templates/concurrency/work-item.md ]] || fail "work-item template missing after clone"
[[ -f templates/concurrency/task-queue.md ]] || fail "task-queue template missing after clone"
[[ -f templates/core/runtime-state.md ]] || fail "runtime-state template missing after clone"
[[ -f tests/pmm-runtime-contract.sh ]] || fail "runtime contract test missing after clone"

if find . -type f \( -name '*.sh' -o -name '*.ps1' -o -name '*.py' -o -name '*.js' -o -name '*.ts' \) \
  -not -path './scripts/check-public-safety.sh' \
  -not -path './scripts/sync-local-skill.sh' \
  -not -path './scripts/recovery-status.sh' \
  -not -path './scripts/pmm-doctor.sh' \
  -not -path './scripts/pmm-task.sh' \
  -not -path './scripts/pmm-preflight.sh' \
  -not -path './scripts/lib/pmm-state.sh' \
  -not -path './scripts/install-local-skill.ps1' \
  -not -path './tests/pmm-runtime-contract.sh' \
  -not -path './.git/*' | rg .; then
  fail "unexpected executable/script file found outside allowed scripts"
fi

if find . -type f -perm -111 \
  -not -path './scripts/check-public-safety.sh' \
  -not -path './scripts/sync-local-skill.sh' \
  -not -path './scripts/recovery-status.sh' \
  -not -path './scripts/pmm-doctor.sh' \
  -not -path './scripts/pmm-task.sh' \
  -not -path './scripts/pmm-preflight.sh' \
  -not -path './scripts/lib/pmm-state.sh' \
  -not -path './scripts/install-local-skill.ps1' \
  -not -path './tests/pmm-runtime-contract.sh' \
  -not -path './.git/*' | rg .; then
  fail "unexpected executable file found outside allowed scripts"
fi

if [[ -d "$LOCAL_SKILL_DIR" ]]; then
  cp -R "$LOCAL_SKILL_DIR" "$BACKUP_ROOT/pmm-$STAMP"
fi

mkdir -p "$LOCAL_SKILL_DIR"
rsync -a --delete \
  --delete-excluded \
  --include='SKILL.md' \
  --include='VERSION' \
  --include='CHANGELOG.md' \
  --include='CHANGELOG.en.md' \
  --include='LICENSE' \
  --include='templates/' \
  --include='templates/***' \
  --include='docs/' \
  --include='docs/install.md' \
  --include='docs/agent-compatibility.md' \
  --include='docs/runtime.md' \
  --include='docs/maintenance.md' \
  --include='scripts/' \
  --include='scripts/lib/' \
  --include='scripts/lib/pmm-state.sh' \
  --include='scripts/recovery-status.sh' \
  --include='scripts/pmm-doctor.sh' \
  --include='scripts/pmm-task.sh' \
  --include='scripts/pmm-preflight.sh' \
  --include='scripts/install-local-skill.ps1' \
  --include='tests/' \
  --include='tests/pmm-runtime-contract.sh' \
  --exclude='*' \
  "$WORKDIR/" "$LOCAL_SKILL_DIR/"

[[ -f "$LOCAL_SKILL_DIR/SKILL.md" ]] || fail "local sync did not produce SKILL.md"
[[ -f "$LOCAL_SKILL_DIR/VERSION" ]] || fail "local sync did not produce VERSION"
[[ -f "$LOCAL_SKILL_DIR/CHANGELOG.md" ]] || fail "local sync did not produce CHANGELOG.md"
[[ -f "$LOCAL_SKILL_DIR/CHANGELOG.en.md" ]] || fail "local sync did not produce CHANGELOG.en.md"
[[ -f "$LOCAL_SKILL_DIR/LICENSE" ]] || fail "local sync did not produce LICENSE"
[[ -f "$LOCAL_SKILL_DIR/templates/document-skeletons.md" ]] || fail "local sync did not produce document skeleton template"
[[ -f "$LOCAL_SKILL_DIR/templates/optional-packs.md" ]] || fail "local sync did not produce optional packs template"
[[ -f "$LOCAL_SKILL_DIR/templates/core/active-task.md" ]] || fail "local sync did not produce active-task template"
[[ -f "$LOCAL_SKILL_DIR/templates/core/runtime-state.md" ]] || fail "local sync did not produce runtime-state template"
[[ -f "$LOCAL_SKILL_DIR/templates/core/verifier-map.md" ]] || fail "local sync did not produce verifier-map template"
[[ -f "$LOCAL_SKILL_DIR/templates/concurrency/work-item.md" ]] || fail "local sync did not produce work-item template"
[[ -f "$LOCAL_SKILL_DIR/templates/concurrency/task-queue.md" ]] || fail "local sync did not produce task-queue template"
[[ -f "$LOCAL_SKILL_DIR/templates/adapters/CLAUDE.md" ]] || fail "local sync did not produce Claude adapter template"
[[ -f "$LOCAL_SKILL_DIR/templates/adapters/HERMES.md" ]] || fail "local sync did not produce Hermes adapter template"
[[ -f "$LOCAL_SKILL_DIR/docs/agent-compatibility.md" ]] || fail "local sync did not produce agent compatibility guide"
[[ -f "$LOCAL_SKILL_DIR/docs/install.md" ]] || fail "local sync did not produce install guide"
[[ -f "$LOCAL_SKILL_DIR/docs/runtime.md" ]] || fail "local sync did not produce runtime guide"
[[ -f "$LOCAL_SKILL_DIR/docs/maintenance.md" ]] || fail "local sync did not produce maintenance guide"
[[ -f "$LOCAL_SKILL_DIR/scripts/recovery-status.sh" ]] || fail "local sync did not produce recovery helper"
[[ -f "$LOCAL_SKILL_DIR/scripts/pmm-doctor.sh" ]] || fail "local sync did not produce pmm doctor helper"
[[ -f "$LOCAL_SKILL_DIR/scripts/pmm-task.sh" ]] || fail "local sync did not produce pmm task lifecycle helper"
[[ -f "$LOCAL_SKILL_DIR/scripts/pmm-preflight.sh" ]] || fail "local sync did not produce pmm preflight helper"
[[ -f "$LOCAL_SKILL_DIR/scripts/lib/pmm-state.sh" ]] || fail "local sync did not produce pmm shared state library"
[[ -f "$LOCAL_SKILL_DIR/scripts/install-local-skill.ps1" ]] || fail "local sync did not produce PowerShell install helper"
[[ -f "$LOCAL_SKILL_DIR/tests/pmm-runtime-contract.sh" ]] || fail "local sync did not produce runtime contract test"

printf 'Synced pmm to %s\n' "$LOCAL_SKILL_DIR"
