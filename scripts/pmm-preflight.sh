#!/usr/bin/env bash
# Purpose: Run the release gate for both a pmm source checkout and an installed package.
# Read when: Preparing a public release or proving that the local installed skill matches it.
# Skip when: Performing a project-local task check with no package or publication change.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
installed_root=""

usage() {
  cat <<'EOF'
Usage:
  pmm-preflight.sh [--installed PATH]

Runs the source checkout contract, public safety, Doctor, shell syntax, and
version checks. When --installed is supplied, runs the same runtime contract
against that installed package and verifies its version and shipped files.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --installed) installed_root="${2:-}"; shift 2 ;;
    -h | --help) usage; exit 0 ;;
    *) printf 'ERROR: unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ -n "$installed_root" ]]; then
  installed_root="$(cd "$installed_root" && pwd)"
fi

version="$(tr -d '[:space:]' <"$repo_root/VERSION")"
[[ "$(sed -n 's/^version: //p' "$repo_root/SKILL.md" | head -1)" == "$version" ]] || {
  printf 'ERROR: source VERSION and SKILL.md version disagree\n' >&2
  exit 1
}

if [[ ! -f "$repo_root/scripts/check-public-safety.sh" ]]; then
  [[ -z "$installed_root" ]] || {
    printf 'ERROR: --installed is available only from a source checkout\n' >&2
    exit 2
  }
  bash -n \
    "$repo_root/scripts/recovery-status.sh" \
    "$repo_root/scripts/pmm-doctor.sh" \
    "$repo_root/scripts/pmm-task.sh" \
    "$repo_root/scripts/pmm-preflight.sh" \
    "$repo_root/scripts/lib/pmm-state.sh" \
    "$repo_root/tests/pmm-runtime-contract.sh"
  bash "$repo_root/tests/pmm-runtime-contract.sh"
  printf 'PMM_PREFLIGHT_INSTALLED_PASS path=%s version=%s\n' "$repo_root" "$version"
  exit 0
fi

printf 'PMM_PREFLIGHT source=%s version=%s\n' "$repo_root" "$version"
bash -n \
  "$repo_root/scripts/check-public-safety.sh" \
  "$repo_root/scripts/recovery-status.sh" \
  "$repo_root/scripts/pmm-doctor.sh" \
  "$repo_root/scripts/pmm-task.sh" \
  "$repo_root/scripts/pmm-preflight.sh" \
  "$repo_root/scripts/lib/pmm-state.sh" \
  "$repo_root/tests/pmm-runtime-contract.sh"
bash "$repo_root/tests/pmm-runtime-contract.sh"
bash "$repo_root/scripts/check-public-safety.sh"
bash "$repo_root/scripts/pmm-doctor.sh" "$repo_root"

if [[ -n "$installed_root" ]]; then
  [[ -f "$installed_root/VERSION" ]] || { printf 'ERROR: installed VERSION is missing\n' >&2; exit 1; }
  [[ "$(tr -d '[:space:]' <"$installed_root/VERSION")" == "$version" ]] || {
    printf 'ERROR: installed VERSION does not match source %s\n' "$version" >&2
    exit 1
  }
  for file in \
    SKILL.md VERSION CHANGELOG.md CHANGELOG.en.md \
    scripts/pmm-task.sh scripts/pmm-doctor.sh scripts/recovery-status.sh \
    scripts/lib/pmm-state.sh tests/pmm-runtime-contract.sh; do
    [[ -f "$installed_root/$file" ]] || {
      printf 'ERROR: installed package is missing %s\n' "$file" >&2
      exit 1
    }
  done
  bash -n \
    "$installed_root/scripts/recovery-status.sh" \
    "$installed_root/scripts/pmm-doctor.sh" \
    "$installed_root/scripts/pmm-task.sh" \
    "$installed_root/scripts/pmm-preflight.sh" \
    "$installed_root/scripts/lib/pmm-state.sh" \
    "$installed_root/tests/pmm-runtime-contract.sh"
  bash "$installed_root/tests/pmm-runtime-contract.sh"
  bash "$installed_root/scripts/pmm-doctor.sh" "$repo_root"
  printf 'PMM_PREFLIGHT_INSTALLED_PASS path=%s version=%s\n' "$installed_root" "$version"
fi

printf 'PMM_PREFLIGHT_PASS version=%s\n' "$version"
