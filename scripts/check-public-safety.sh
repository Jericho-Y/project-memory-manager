#!/usr/bin/env bash
# Purpose: Scan the public repository for private markers, secret-like content, and blocked file types.
# Read when: Publishing, auditing, or debugging public safety checks.
# Skip when: The task is unrelated to release safety or repository publication.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/pmm-safety.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

printf 'Running public safety checks...\n'

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git diff --check
fi

required_files=(
  "VERSION"
  "CHANGELOG.md"
  "LICENSE"
  "SKILL.md"
  "README.md"
  "README.en.md"
  "SECURITY.md"
  "docs/agent-compatibility.md"
  "docs/context-budget.md"
  "docs/runtime-profiles.md"
  "docs/self-eval-loop.md"
  "docs/memory-promotion.md"
  "docs/verifier-recipes.md"
  "templates/document-skeletons.md"
  "templates/core/AGENTS.md"
  "templates/core/active-task.md"
  "templates/core/current-state.md"
  "templates/core/verifier-map.md"
  "templates/core/task-history.md"
  "templates/core/failure-patterns.md"
  "templates/adapters/CLAUDE.md"
  "templates/adapters/HERMES.md"
  "templates/adapters/openclaw-project-card.md"
  "templates/adapters/codex-subdir-AGENTS.md"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || fail "missing required file: $file"
done

readme_checks=(
  "README.md:README.en.md"
  "README.md:CHANGELOG.md"
  "README.md:LICENSE"
  "README.en.md:README.md"
  "README.en.md:CHANGELOG.md"
  "README.en.md:LICENSE"
  "README.md:docs/context-budget.md"
  "README.md:docs/runtime-profiles.md"
  "README.md:docs/self-eval-loop.md"
  "README.en.md:docs/context-budget.md"
  "README.en.md:docs/runtime-profiles.md"
  "README.en.md:docs/self-eval-loop.md"
  "SKILL.md:docs/context-budget.md"
  "SKILL.md:docs/runtime-profiles.md"
  "SKILL.md:docs/self-eval-loop.md"
  "SKILL.md:docs/memory-promotion.md"
  "SKILL.md:docs/verifier-recipes.md"
)

for check in "${readme_checks[@]}"; do
  file="${check%%:*}"
  expected="${check#*:}"
  if ! rg -q -F "$expected" "$file"; then
    fail "$file must reference $expected"
  fi
done

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "VERSION must use semantic version format, for example 0.1.0"
rg -q "^version: $version$" SKILL.md || fail "SKILL.md version must match VERSION"
rg -q "^## v$version " CHANGELOG.md || fail "CHANGELOG.md must include an entry for v$version"

skill_lines="$(wc -l < SKILL.md | tr -d '[:space:]')"
if (( skill_lines > 360 )); then
  fail "SKILL.md exceeds 360 lines; move detail to linked docs"
fi

template_lines="$(wc -l < templates/document-skeletons.md | tr -d '[:space:]')"
if (( template_lines > 160 )); then
  fail "templates/document-skeletons.md exceeds 160 lines; keep it as a router"
fi

active_task_template_lines="$(wc -l < templates/core/active-task.md | tr -d '[:space:]')"
if (( active_task_template_lines > 120 )); then
  fail "templates/core/active-task.md exceeds 120 lines; keep the hot path compact"
fi

for adapter in templates/adapters/*.md; do
  adapter_lines="$(wc -l < "$adapter" | tr -d '[:space:]')"
  if (( adapter_lines > 80 )); then
    fail "$adapter exceeds 80 lines; adapters must stay pointer-only"
  fi
  if rg -n --pcre2 '(?i)(task history|full project rules|complete project docs|retry count:|current checkpoint:)' "$adapter" >/dev/null; then
    fail "$adapter appears to contain copied task state or broad project rules"
  fi
done

forbidden_patterns=(
  'Jericho'
  '/Users/'
  'Desktop/Projects/Codex'
  'cnallvip'
  'cmallvip'
  'caseapp'
  'machouse'
  'singapore-server'
  '/www/wwwroot'
  'macOS Keychain: mac-mouse'
  'wechatminiprogram'
  'allvip'
)

for pattern in "${forbidden_patterns[@]}"; do
  if rg -n --hidden --glob '!scripts/check-public-safety.sh' --glob '!.git/**' --glob '!.project-runtime/**' --glob '!tmp/**' "$pattern" . >"$tmp_dir/private-markers.txt"; then
    cat "$tmp_dir/private-markers.txt" >&2
    fail "forbidden private marker found: $pattern"
  fi
done

secret_patterns=(
  '-----BEGIN (RSA |OPENSSH |EC |DSA |PRIVATE )?PRIVATE KEY-----'
  'sk-[A-Za-z0-9_-]{20,}'
  'gh[pousr]_[A-Za-z0-9_]{20,}'
  'xox[baprs]-[A-Za-z0-9-]{20,}'
  'AKIA[0-9A-Z]{16}'
  'password[[:space:]]*=[[:space:]]*["'\''][^"'\'']+["'\'']'
  'DATABASE_URL[[:space:]]*='
  'api[_-]?key[[:space:]]*=[[:space:]]*["'\''][^"'\'']+["'\'']'
  'token[[:space:]]*=[[:space:]]*["'\''][^"'\'']+["'\'']'
)

for pattern in "${secret_patterns[@]}"; do
  if rg -n --hidden --glob '!.git/**' --glob '!.project-runtime/**' --glob '!tmp/**' -e "$pattern" . >"$tmp_dir/secret-scan.txt"; then
    cat "$tmp_dir/secret-scan.txt" >&2
    fail "secret-like content found"
  fi
done

symlink_files="$(
  find . -type l \
    -not -path './.git/*' \
    -not -path './.project-runtime/*' \
    -not -path './tmp/*'
)"

if [[ -n "$symlink_files" ]]; then
  printf '%s\n' "$symlink_files" >&2
  fail "symlink present in public repository"
fi

unexpected_executable_files="$(
  find . -type f -perm -111 \
    -not -path './.git/*' \
    -not -path './.project-runtime/*' \
    -not -path './tmp/*' \
    -not -path './scripts/check-public-safety.sh' \
    -not -path './scripts/sync-local-skill.sh' \
    -not -path './scripts/recovery-status.sh'
)"

if [[ -n "$unexpected_executable_files" ]]; then
  printf '%s\n' "$unexpected_executable_files" >&2
  fail "unexpected executable file present"
fi

blocked_files="$(
  find . -type f \( \
    -name '.env' -o \
    -name '.env.*' -o \
    -name '*.pem' -o \
    -name '*.key' -o \
    -name '*.p12' -o \
    -name '*.crt' -o \
    -name '*.token' -o \
    -name '*.secret' -o \
    -name '*.zip' -o \
    -name '*.tar' -o \
    -name '*.gz' -o \
    -name '*.dylib' -o \
    -name '*.so' -o \
    -name '*.bin' \
  \) -not -path './.git/*' -not -path './.project-runtime/*' -not -path './tmp/*'
)"

if [[ -n "$blocked_files" ]]; then
  printf '%s\n' "$blocked_files" >&2
  fail "blocked file type present"
fi

printf 'Public safety checks passed.\n'
