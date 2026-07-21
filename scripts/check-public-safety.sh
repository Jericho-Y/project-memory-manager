#!/usr/bin/env bash
# Purpose: Scan the public repository for private markers, secret-like content, and blocked file types.
# Read when: Publishing, auditing, or debugging public safety checks.
# Skip when: The task is unrelated to release safety or repository publication.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/pmm-safety.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

rules_file="scripts/public-safety-rules.conf"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

is_allowed_script_file() {
  local file="$1"
  local allowed

  for allowed in "${PUBLIC_SAFETY_ALLOWED_SCRIPT_FILES[@]}"; do
    if [[ "$file" == "$allowed" || "$file" == "./$allowed" ]]; then
      return 0
    fi
  done

  return 1
}

printf 'Running public safety checks...\n'

[[ -f "$rules_file" ]] || fail "missing public safety rules config: $rules_file"
# shellcheck source=scripts/public-safety-rules.conf
source "$rules_file"
bash -n "$rules_file"

local_rules_file="${PUBLIC_SAFETY_LOCAL_RULES_FILE:-.project-runtime/public-safety-local-rules.conf}"
if [[ -f "$local_rules_file" ]]; then
  bash -n "$local_rules_file"
  # shellcheck source=/dev/null
  source "$local_rules_file"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git diff --check
fi

for file in "${PUBLIC_SAFETY_REQUIRED_FILES[@]}"; do
  [[ -f "$file" ]] || fail "missing required file: $file"
done

for check in "${PUBLIC_SAFETY_REFERENCE_CHECKS[@]}"; do
  file="${check%%:*}"
  expected="${check#*:}"
  if ! rg -q -F "$expected" "$file"; then
    fail "$file must reference $expected"
  fi
done

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "VERSION must use semantic version format, for example 0.1.0"
rg -q "^version: $version$" SKILL.md || fail "SKILL.md version must match VERSION"
rg -q "^runtime_version: $version$" templates/core/runtime-state.md || fail "runtime-state template version must match VERSION"
rg -q -F -- "- Managed runtime version: \`$version\`." templates/core/AGENTS.md || fail "AGENTS template managed runtime version must match VERSION"
rg -q "^## v$version " CHANGELOG.md || fail "CHANGELOG.md must include an entry for v$version"
rg -q "^## v$version " CHANGELOG.en.md || fail "CHANGELOG.en.md must include an entry for v$version"
rg -q --pcre2 '\p{Han}' CHANGELOG.md || fail "CHANGELOG.md must be the Chinese primary changelog"

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

rg -q -F "Agent Mode" templates/core/active-task.md || fail "templates/core/active-task.md must include Agent Mode fields"
rg -q -F "Agent Mode" docs/runtime.md || fail "docs/runtime.md must include Agent Mode in the task contract"
rg -q -F "Subagent Gate" SKILL.md || fail "SKILL.md must include the Subagent Gate hot-path rule"

for adapter in templates/adapters/*.md; do
  adapter_lines="$(wc -l < "$adapter" | tr -d '[:space:]')"
  if (( adapter_lines > 80 )); then
    fail "$adapter exceeds 80 lines; adapters must stay pointer-only"
  fi
  if rg -n --pcre2 '(?i)(task history|full project rules|complete project docs|retry count:|current checkpoint:)' "$adapter" >/dev/null; then
    fail "$adapter appears to contain copied task state or broad project rules"
  fi
done

for pattern in "${PUBLIC_SAFETY_FORBIDDEN_PATTERNS[@]}"; do
  if rg -n --hidden \
    --glob '!scripts/check-public-safety.sh' \
    --glob '!scripts/public-safety-rules.conf' \
    --glob '!.git/**' \
    --glob '!.project-runtime/**' \
    --glob '!tmp/**' \
    "$pattern" . >"$tmp_dir/private-markers.txt"; then
    cat "$tmp_dir/private-markers.txt" >&2
    fail "forbidden private marker found: $pattern"
  fi
done

for pattern in "${PUBLIC_SAFETY_SECRET_PATTERNS[@]}"; do
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
    -not -path './tmp/*' |
    while IFS= read -r file; do
      if ! is_allowed_script_file "$file"; then
        printf '%s\n' "$file"
      fi
    done
)"

if [[ -n "$unexpected_executable_files" ]]; then
  printf '%s\n' "$unexpected_executable_files" >&2
  fail "unexpected executable file present"
fi

unexpected_script_files="$(
  find . -type f \( -name '*.sh' -o -name '*.ps1' -o -name '*.py' -o -name '*.js' -o -name '*.ts' \) \
    -not -path './.git/*' \
    -not -path './.project-runtime/*' \
    -not -path './tmp/*' |
    while IFS= read -r file; do
      if ! is_allowed_script_file "$file"; then
        printf '%s\n' "$file"
      fi
    done
)"

if [[ -n "$unexpected_script_files" ]]; then
  printf '%s\n' "$unexpected_script_files" >&2
  fail "unexpected script file present"
fi

blocked_files="$(
  for pattern in "${PUBLIC_SAFETY_BLOCKED_FILE_PATTERNS[@]}"; do
    find . -type f -name "$pattern" \
      -not -path './.git/*' \
      -not -path './.project-runtime/*' \
      -not -path './tmp/*'
  done | sort -u
)"

if [[ -n "$blocked_files" ]]; then
  printf '%s\n' "$blocked_files" >&2
  fail "blocked file type present"
fi

printf 'Public safety checks passed.\n'
