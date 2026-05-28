#!/usr/bin/env bash
# Purpose: Safely sync the checked public skill files into a local skills directory.
# Read when: Updating local skill sync behavior or diagnosing local installation issues.
# Skip when: Working only on public documentation or templates.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/<owner>/pmm.git}"
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
[[ -f LICENSE ]] || fail "LICENSE missing after clone"
[[ -d templates ]] || fail "templates directory missing after clone"
[[ -f docs/agent-compatibility.md ]] || fail "agent compatibility guide missing after clone"
[[ -f docs/context-budget.md ]] || fail "context budget guide missing after clone"
[[ -f docs/runtime-profiles.md ]] || fail "runtime profiles guide missing after clone"
[[ -f docs/legacy-migration.md ]] || fail "legacy migration guide missing after clone"
[[ -f docs/self-eval-loop.md ]] || fail "self-eval loop guide missing after clone"
[[ -f docs/memory-promotion.md ]] || fail "memory promotion guide missing after clone"
[[ -f docs/verifier-recipes.md ]] || fail "verifier recipes guide missing after clone"
[[ -f scripts/recovery-status.sh ]] || fail "recovery status helper missing after clone"

if find . -type f \( -name '*.sh' -o -name '*.py' -o -name '*.js' -o -name '*.ts' \) \
  -not -path './scripts/check-public-safety.sh' \
  -not -path './scripts/sync-local-skill.sh' \
  -not -path './scripts/recovery-status.sh' \
  -not -path './.git/*' | rg .; then
  fail "unexpected executable/script file found outside allowed scripts"
fi

if find . -type f -perm -111 \
  -not -path './scripts/check-public-safety.sh' \
  -not -path './scripts/sync-local-skill.sh' \
  -not -path './scripts/recovery-status.sh' \
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
  --include='LICENSE' \
  --include='templates/' \
  --include='templates/***' \
  --include='docs/' \
  --include='docs/agent-compatibility.md' \
  --include='docs/context-budget.md' \
  --include='docs/runtime-profiles.md' \
  --include='docs/legacy-migration.md' \
  --include='docs/self-eval-loop.md' \
  --include='docs/memory-promotion.md' \
  --include='docs/verifier-recipes.md' \
  --include='docs/08-automation/' \
  --include='docs/08-automation/***' \
  --include='scripts/' \
  --include='scripts/recovery-status.sh' \
  --exclude='*' \
  "$WORKDIR/" "$LOCAL_SKILL_DIR/"

[[ -f "$LOCAL_SKILL_DIR/SKILL.md" ]] || fail "local sync did not produce SKILL.md"
[[ -f "$LOCAL_SKILL_DIR/VERSION" ]] || fail "local sync did not produce VERSION"
[[ -f "$LOCAL_SKILL_DIR/CHANGELOG.md" ]] || fail "local sync did not produce CHANGELOG.md"
[[ -f "$LOCAL_SKILL_DIR/LICENSE" ]] || fail "local sync did not produce LICENSE"
[[ -f "$LOCAL_SKILL_DIR/templates/document-skeletons.md" ]] || fail "local sync did not produce document skeleton template"
[[ -f "$LOCAL_SKILL_DIR/templates/core/active-task.md" ]] || fail "local sync did not produce active-task template"
[[ -f "$LOCAL_SKILL_DIR/templates/core/verifier-map.md" ]] || fail "local sync did not produce verifier-map template"
[[ -f "$LOCAL_SKILL_DIR/templates/adapters/CLAUDE.md" ]] || fail "local sync did not produce Claude adapter template"
[[ -f "$LOCAL_SKILL_DIR/templates/adapters/HERMES.md" ]] || fail "local sync did not produce Hermes adapter template"
[[ -f "$LOCAL_SKILL_DIR/docs/agent-compatibility.md" ]] || fail "local sync did not produce agent compatibility guide"
[[ -f "$LOCAL_SKILL_DIR/docs/context-budget.md" ]] || fail "local sync did not produce context budget guide"
[[ -f "$LOCAL_SKILL_DIR/docs/runtime-profiles.md" ]] || fail "local sync did not produce runtime profiles guide"
[[ -f "$LOCAL_SKILL_DIR/docs/legacy-migration.md" ]] || fail "local sync did not produce legacy migration guide"
[[ -f "$LOCAL_SKILL_DIR/docs/self-eval-loop.md" ]] || fail "local sync did not produce self-eval loop guide"
[[ -f "$LOCAL_SKILL_DIR/docs/memory-promotion.md" ]] || fail "local sync did not produce memory promotion guide"
[[ -f "$LOCAL_SKILL_DIR/docs/verifier-recipes.md" ]] || fail "local sync did not produce verifier recipes guide"
[[ -f "$LOCAL_SKILL_DIR/scripts/recovery-status.sh" ]] || fail "local sync did not produce recovery helper"

printf 'Synced pmm to %s\n' "$LOCAL_SKILL_DIR"
