#!/usr/bin/env bash
# Purpose: Scan the public repository for private markers, secret-like content, and blocked file types.
# Read when: Publishing, auditing, or debugging public safety checks.
# Skip when: The task is unrelated to release safety or repository publication.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

printf 'Running public safety checks...\n'

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git diff --check
fi

required_files=(
  "SKILL.md"
  "README.md"
  "SECURITY.md"
  "templates/document-skeletons.md"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || fail "missing required file: $file"
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
  if rg -n --hidden --glob '!scripts/check-public-safety.sh' --glob '!.git/**' --glob '!.project-runtime/**' "$pattern" . >/tmp/project-requirements-system-scan.txt; then
    cat /tmp/project-requirements-system-scan.txt >&2
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
  if rg -n --hidden --glob '!.git/**' --glob '!.project-runtime/**' -e "$pattern" . >/tmp/project-requirements-system-secret-scan.txt; then
    cat /tmp/project-requirements-system-secret-scan.txt >&2
    fail "secret-like content found"
  fi
done

blocked_files="$(
  find . -type f \( \
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
  \) -not -path './.git/*' -not -path './.project-runtime/*'
)"

if [[ -n "$blocked_files" ]]; then
  printf '%s\n' "$blocked_files" >&2
  fail "blocked file type present"
fi

printf 'Public safety checks passed.\n'
