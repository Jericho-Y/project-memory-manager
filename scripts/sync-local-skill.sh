#!/usr/bin/env bash
# Purpose: Safely sync the checked public skill files into a local skills directory.
# Read when: Updating local skill sync behavior or diagnosing local installation issues.
# Skip when: Working only on public documentation or templates.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/<owner>/project-requirements-system.git}"
LOCAL_SKILL_DIR="${LOCAL_SKILL_DIR:-$HOME/.codex/skills/project-requirements-system}"
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

rm -rf "$WORKDIR"
mkdir -p "$TMP_ROOT" "$BACKUP_ROOT"

if [[ "$REPO_URL" == *"<owner>"* ]]; then
  fail "set REPO_URL to the public repository URL before syncing"
fi

git clone --depth 1 --branch main "$REPO_URL" "$WORKDIR"
cd "$WORKDIR"

bash scripts/check-public-safety.sh

[[ -f SKILL.md ]] || fail "SKILL.md missing after clone"
[[ -d templates ]] || fail "templates directory missing after clone"
[[ -f scripts/recovery-status.sh ]] || fail "recovery status helper missing after clone"

if find . -type f \( -name '*.sh' -o -name '*.py' -o -name '*.js' -o -name '*.ts' \) \
  -not -path './scripts/check-public-safety.sh' \
  -not -path './scripts/sync-local-skill.sh' \
  -not -path './scripts/recovery-status.sh' \
  -not -path './.git/*' | rg .; then
  fail "unexpected executable/script file found outside allowed scripts"
fi

if [[ -d "$LOCAL_SKILL_DIR" ]]; then
  cp -R "$LOCAL_SKILL_DIR" "$BACKUP_ROOT/project-requirements-system-$STAMP"
fi

mkdir -p "$LOCAL_SKILL_DIR"
rsync -a --delete \
  --include='SKILL.md' \
  --include='templates/' \
  --include='templates/***' \
  --include='docs/' \
  --include='docs/08-automation/' \
  --include='docs/08-automation/***' \
  --include='scripts/' \
  --include='scripts/recovery-status.sh' \
  --exclude='*' \
  "$WORKDIR/" "$LOCAL_SKILL_DIR/"

[[ -f "$LOCAL_SKILL_DIR/SKILL.md" ]] || fail "local sync did not produce SKILL.md"
[[ -f "$LOCAL_SKILL_DIR/templates/document-skeletons.md" ]] || fail "local sync did not produce document skeleton template"
[[ -f "$LOCAL_SKILL_DIR/scripts/recovery-status.sh" ]] || fail "local sync did not produce recovery helper"

printf 'Synced project-requirements-system to %s\n' "$LOCAL_SKILL_DIR"
