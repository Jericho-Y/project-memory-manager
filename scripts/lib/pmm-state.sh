#!/usr/bin/env bash
# Purpose: Shared dependency-free state helpers for pmm task lifecycle, Doctor, and Recovery.
# Read when: Changing structured task state, evidence freshness, migration, or local claims.
# Skip when: The task only changes public prose with no runtime behavior.

pmm_now() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

pmm_hash_stream() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    printf 'ERROR: shasum or sha256sum is required\n' >&2
    return 1
  fi
}

pmm_file_hash() {
  local file="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  else
    return 1
  fi
}

pmm_frontmatter_value() {
  local file="$1"
  local key="$2"
  [[ -f "$file" ]] || return 1
  awk -v key="$key" '
    NR == 1 && $0 == "---" { inside=1; next }
    inside && $0 == "---" { exit }
    inside && index($0, key ":") == 1 {
      value=substr($0, length(key) + 2)
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      if (value ~ /^".*"$/ || value ~ /^'"'"'.*'"'"'$/) {
        value=substr(value, 2, length(value) - 2)
      }
      print value
      exit
    }
  ' "$file"
}

pmm_has_schema() {
  local file="$1"
  [[ "$(pmm_frontmatter_value "$file" pmm_schema 2>/dev/null || true)" == 'pmm.task/v1' ]]
}

pmm_has_runtime_schema() {
  local file="$1"
  [[ "$(pmm_frontmatter_value "$file" pmm_schema 2>/dev/null || true)" == 'pmm.runtime/v1' ]]
}

pmm_version_compare() {
  local left="$1"
  local right="$2"
  local left_major left_minor left_patch right_major right_minor right_patch
  [[ "$left" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$right" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  IFS=. read -r left_major left_minor left_patch <<EOF
$left
EOF
  IFS=. read -r right_major right_minor right_patch <<EOF
$right
EOF
  if (( 10#$left_major < 10#$right_major )); then
    printf '%s\n' -1
  elif (( 10#$left_major > 10#$right_major )); then
    printf '%s\n' 1
  elif (( 10#$left_minor < 10#$right_minor )); then
    printf '%s\n' -1
  elif (( 10#$left_minor > 10#$right_minor )); then
    printf '%s\n' 1
  elif (( 10#$left_patch < 10#$right_patch )); then
    printf '%s\n' -1
  elif (( 10#$left_patch > 10#$right_patch )); then
    printf '%s\n' 1
  else
    printf '%s\n' 0
  fi
}

pmm_validate_scalar() {
  local label="$1"
  local value="$2"
  if [[ -z "$value" || "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
    printf 'ERROR: %s must be a non-empty single-line value\n' "$label" >&2
    return 1
  fi
}

pmm_validate_id() {
  local value="$1"
  [[ "$value" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{1,79}$ ]]
}

pmm_execution_status_valid() {
  case "$1" in
    idle | queued | active | paused | blocked | ready-to-integrate | done) return 0 ;;
    *) return 1 ;;
  esac
}

pmm_verification_status_valid() {
  case "$1" in
    pending | partial | passed | stale | failed | not-required) return 0 ;;
    *) return 1 ;;
  esac
}

pmm_delivery_status_valid() {
  case "$1" in
    not-requested | waiting-confirmation | ready | deployed | released) return 0 ;;
    *) return 1 ;;
  esac
}

pmm_normalize_legacy_status() {
  local value
  value="$(printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:].]*$//' -e 's/^`//' -e 's/`$//' | tr '[:upper:]' '[:lower:]')"
  value="$(printf '%s' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:].]*$//' -e 's/^`//' -e 's/`$//')"
  value="${value%.}"
  case "$value" in
    ambiguous | conflict) printf 'ambiguous\n' ;;
    active | 'in progress' | in-progress | working | failed-retryable) printf 'active\n' ;;
    paused | on-hold | 'on hold') printf 'paused\n' ;;
    blocked | failed-blocked) printf 'blocked\n' ;;
    done | complete | completed | 'code-complete locally' | 'complete locally') printf 'done\n' ;;
    idle | none) printf 'idle\n' ;;
    *blocked* | *'blocked by'* | *'waiting on'* | *'waiting for'*) printf 'blocked\n' ;;
    *paused* | *'on hold'* | *deferred*) printf 'paused\n' ;;
    *'code-complete'* | *'code complete'* | *'complete locally'* | *'done locally'* | \
      *'done on '* | *'complete on '* | *'completed on '* | *released*) printf 'done\n' ;;
    *'in progress'* | *'under implementation'* | *'in development'* | *'currently working'*) printf 'active\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

pmm_legacy_contract_records() {
  local file="$1"
  awk '
    function clean(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (value ~ /^`.*`$/) value=substr(value, 2, length(value) - 2)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    function trim(value) {
      return clean(value)
    }
    function normalize(value, normalized) {
      normalized=tolower(trim(value))
      sub(/[.]+$/, "", normalized)
      if (normalized ~ /^`.*`$/) normalized=substr(normalized, 2, length(normalized) - 2)
      sub(/[.]+$/, "", normalized)
      if (normalized ~ /^(done|completed|complete|closed|code-complete locally|complete locally)$/) return "done"
      if (normalized ~ /blocked|blocked by|waiting on|waiting for/) return "blocked"
      if (normalized ~ /paused|on hold|deferred/) return "paused"
      if (normalized ~ /code[- ]complete|complete locally|done locally|done on |complete on |completed on |released/) return "done"
      if (normalized ~ /in progress|under implementation|in development|currently working/) return "active"
      if (normalized ~ /^(active|in-progress|working|failed-retryable)$/) return "active"
      if (normalized ~ /^(blocked|failed-blocked)$/) return "blocked"
      if (normalized ~ /^(paused|on-hold)$/) return "paused"
      if (normalized ~ /^(idle|none)$/) return "idle"
      return "unknown"
    }
    function is_contract_section(value) {
      return value ~ /^(Status|Task|Harness|Verifier|Critic|Repair|Record|Agent Mode|Required Evidence|Next Action)$/
    }
    function section_kind(value) {
      if (value == "Active Task") return "active"
      if (value == "Completed Tasks") return "history"
      if (value == "Blocked Tasks" || value == "Deferred Follow-Up") return "pending"
      if (value ~ /^Task[[:space:]]+/) return "ledger-task"
      return "current"
    }
    function reset_contract() {
      has_task=0
      has_id=0
      has_task_field=0
      task_id=""
      task=""
      status=""
      status_seen=0
      status_normalized=""
      status_conflict=0
    }
    function flush_contract(value, label, kind) {
      if (!has_task) return
      label=(task_id != "" ? task_id : (heading == "Active Task" && task != "" ? task : (heading != "" ? heading : task)))
      kind=section_kind(heading)
      normalized_status=(status_conflict ? "ambiguous" : normalize(status))
      print label "\t" (heading != "" ? heading : "-") "\t" (status != "" ? status : "-") "\t" normalized_status "\t" kind "\t" start_line
      reset_contract()
    }
    /^## / {
      next_heading=substr($0, 4)
      next_heading=clean(next_heading)
      if (!is_contract_section(next_heading)) {
        flush_contract()
        heading=next_heading
        if (next_heading ~ /^Task[[:space:]]+/) {
          task_id=substr(next_heading, 6)
          task_id=clean(task_id)
          has_task=1
          has_id=1
          start_line=NR
        }
      } else if (next_heading == "Active Task") {
        flush_contract()
        heading=next_heading
        has_task=1
        start_line=NR
      }
      next
    }
    /^[[:space:]]*-?[[:space:]]*Task ID:/ {
      if (has_task && (has_id || has_task_field)) flush_contract()
      task_id=$0
      sub(/^[[:space:]]*-?[[:space:]]*Task ID:[[:space:]]*/, "", task_id)
      task_id=clean(task_id)
      if (task_id != "") { has_task=1; start_line=NR }
      has_id=1
      next
    }
    /^[[:space:]]*-?[[:space:]]*Task:/ {
      value=$0
      sub(/^[[:space:]]*-?[[:space:]]*Task:[[:space:]]*/, "", value)
      value=clean(value)
      if (value == "") next
      if (has_task && has_task_field) flush_contract()
      task=value
      has_task=1
      has_task_field=1
      start_line=NR
      next
    }
    /^[[:space:]]*-?[[:space:]]*Status:/ {
      if (!has_task) { has_task=1; start_line=NR }
      status=$0
      sub(/^[[:space:]]*-?[[:space:]]*Status:[[:space:]]*/, "", status)
      status=clean(status)
      current_status_normalized=normalize(status)
      if (status_seen == 0) {
        status_normalized=current_status_normalized
      } else if (current_status_normalized != status_normalized) {
        status_conflict=1
      }
      status_seen++
      next
    }
    END { flush_contract() }
  ' "$file"
}

pmm_set_frontmatter() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp
  [[ -f "$file" ]] || return 1
  [[ "$(sed -n '1p' "$file")" == '---' ]] || return 1
  tmp="${file}.tmp.$$"
  awk -v key="$key" -v value="$value" '
    NR == 1 && $0 == "---" { inside=1; print; next }
    inside && $0 == "---" {
      if (!updated) print key ": " value
      inside=0
      print
      next
    }
    inside && index($0, key ":") == 1 {
      if (!updated) print key ": " value
      updated=1
      next
    }
    { print }
  ' "$file" >"$tmp"
  mv "$tmp" "$file"
}

pmm_replace_bullet() {
  local file="$1"
  local label="$2"
  local value="$3"
  local tmp="${file}.tmp.$$"
  awk -v prefix="- ${label}:" -v value="$value" '
    !updated && index($0, prefix) == 1 {
      print prefix " " value
      updated=1
      next
    }
    { print }
    END {
      if (!updated) print prefix " " value
    }
  ' "$file" >"$tmp"
  mv "$tmp" "$file"
}

pmm_git_head() {
  git -C "$1" rev-parse HEAD 2>/dev/null || printf 'none\n'
}

pmm_git_branch() {
  local branch
  branch="$(git -C "$1" branch --show-current 2>/dev/null || true)"
  if [[ -n "$branch" ]]; then
    printf '%s\n' "$branch"
  else
    printf 'detached\n'
  fi
}

pmm_operational_path() {
  case "$1" in
    docs/00-project-memory/active-task.md | \
      docs/00-project-memory/runtime-state.md | \
      docs/00-project-memory/task-history.md | \
      docs/00-project-memory/task-queue.md | \
      docs/00-project-memory/work-items/* | \
      docs/07-decisions/change-log.md | \
      .project-runtime/* | tmp/*) return 0 ;;
    *) return 1 ;;
  esac
}

pmm_strip_managed_runtime_block() {
  awk '
    $0 == "<!-- pmm-runtime:start -->" { skipping=1; next }
    skipping && $0 == "<!-- pmm-runtime:end -->" { skipping=0; next }
    skipping { next }
    /^[[:space:]]*$/ { blanks++; next }
    {
      while (blanks > 0) { print ""; blanks-- }
      print
    }
  '
}

pmm_agents_unmanaged_matches_head() {
  local root="$1"
  local current="$root/AGENTS.md"
  local current_hash head_hash
  [[ -f "$current" ]] || return 1
  current_hash="$(pmm_strip_managed_runtime_block <"$current" | pmm_hash_stream)" || return 1
  head_hash="$(git -C "$root" show HEAD:AGENTS.md 2>/dev/null | pmm_strip_managed_runtime_block | pmm_hash_stream)" || return 1
  [[ "$current_hash" == "$head_hash" ]]
}

pmm_source_hash() {
  local root="$1"
  local hash
  local -a pipeline_status
  if ! git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'none\n'
    return 0
  fi

  hash="$(
    set -o pipefail
    {
      cd "$root" || exit 1
      git diff HEAD --no-ext-diff --binary -- . \
        ':(exclude)AGENTS.md' \
        ':(exclude)docs/00-project-memory/active-task.md' \
        ':(exclude)docs/00-project-memory/runtime-state.md' \
        ':(exclude)docs/00-project-memory/task-history.md' \
        ':(exclude)docs/00-project-memory/task-queue.md' \
        ':(exclude)docs/00-project-memory/work-items/**' \
        ':(exclude)docs/07-decisions/change-log.md' || exit 1
      if ! pmm_agents_unmanaged_matches_head "$root"; then
        printf 'unmanaged-agents:'
        pmm_strip_managed_runtime_block <AGENTS.md | pmm_hash_stream || exit 1
      fi
      git ls-files --others --exclude-standard -z |
        while IFS= read -r -d '' file; do
          pmm_operational_path "$file" && continue
          printf 'untracked:%s:' "$file"
          pmm_file_hash "$file" || exit 1
        done
      pipeline_status=("${PIPESTATUS[@]}")
      (( pipeline_status[0] == 0 && pipeline_status[1] == 0 )) || exit 1
    } | pmm_hash_stream
  )" || {
    printf 'ERROR: unable to hash the current Git source state\n' >&2
    return 1
  }
  printf '%s\n' "$hash"
}

pmm_source_is_clean() {
  local root="$1"
  local file
  local -a pipeline_status
  git -C "$root" diff --quiet HEAD -- . \
    ':(exclude)AGENTS.md' \
    ':(exclude)docs/00-project-memory/active-task.md' \
    ':(exclude)docs/00-project-memory/runtime-state.md' \
    ':(exclude)docs/00-project-memory/task-history.md' \
    ':(exclude)docs/00-project-memory/task-queue.md' \
    ':(exclude)docs/00-project-memory/work-items/**' \
    ':(exclude)docs/07-decisions/change-log.md' || return 1
  pmm_agents_unmanaged_matches_head "$root" || return 1
  git -C "$root" ls-files --others --exclude-standard -z |
    while IFS= read -r -d '' file; do
      pmm_operational_path "$file" || exit 1
    done
  pipeline_status=("${PIPESTATUS[@]}")
  (( pipeline_status[0] == 0 && pipeline_status[1] == 0 ))
}

pmm_evidence_is_fresh() {
  local root="$1"
  local file="$2"
  local expected_head expected_hash current_head
  expected_head="$(pmm_frontmatter_value "$file" verification_head 2>/dev/null || true)"
  expected_hash="$(pmm_frontmatter_value "$file" verification_source_hash 2>/dev/null || true)"
  [[ -n "$expected_head" && "$expected_head" != 'none' ]] || return 1
  [[ -n "$expected_hash" && "$expected_hash" != 'none' ]] || return 1
  current_head="$(pmm_git_head "$root")"
  if [[ "$expected_head" != "$current_head" ]]; then
    git -C "$root" merge-base --is-ancestor "$expected_head" "$current_head" 2>/dev/null || return 1
    pmm_git_range_is_operational "$root" "$expected_head" "$current_head" || return 1
  fi
  [[ "$expected_hash" == "$(pmm_source_hash "$root")" ]]
}

pmm_git_range_is_operational() {
  local root="$1"
  local from="$2"
  local to="$3"
  local commits commit parent file
  local -a pipeline_status
  git -C "$root" merge-base --is-ancestor "$from" "$to" 2>/dev/null || return 1
  commits="$(git -C "$root" rev-list --reverse "$from..$to" -- 2>/dev/null)" || return 1
  while IFS= read -r commit; do
    [[ -n "$commit" ]] || continue
    parent="$(git -C "$root" rev-parse "$commit^1" 2>/dev/null)" || return 1
    git -C "$root" diff --no-renames --name-only -z "$parent" "$commit" -- |
      while IFS= read -r -d '' file; do
        pmm_operational_path "$file" || exit 1
      done
    pipeline_status=("${PIPESTATUS[@]}")
    (( pipeline_status[0] == 0 && pipeline_status[1] == 0 )) || return 1
  done <<<"$commits"
}

pmm_ready_evidence_is_fresh_on_branch() {
  local root="$1"
  local file="$2"
  local branch expected_head expected_hash branch_tip empty_hash
  [[ "$(pmm_frontmatter_value "$file" task_kind 2>/dev/null || true)" == 'work-item' ]] || return 1
  [[ "$(pmm_frontmatter_value "$file" execution_status 2>/dev/null || true)" == 'ready-to-integrate' ]] || return 1
  branch="$(pmm_frontmatter_value "$file" branch 2>/dev/null || true)"
  expected_head="$(pmm_frontmatter_value "$file" verification_head 2>/dev/null || true)"
  expected_hash="$(pmm_frontmatter_value "$file" verification_source_hash 2>/dev/null || true)"
  [[ -n "$branch" && "$branch" != 'none' && -n "$expected_head" && "$expected_head" != 'none' ]] || return 1
  branch_tip="$(git -C "$root" rev-parse "refs/heads/$branch" 2>/dev/null || true)"
  [[ -n "$branch_tip" ]] || return 1
  empty_hash="$(printf '' | pmm_hash_stream)" || return 1
  [[ "$expected_hash" == "$empty_hash" ]] || return 1
  git -C "$root" merge-base --is-ancestor "$expected_head" "$branch_tip" 2>/dev/null || return 1
  pmm_git_range_is_operational "$root" "$expected_head" "$branch_tip"
}

pmm_legacy_contract_count() {
  local file="$1"
  local mode="${2:-all}"
  local id heading raw normalized section line count=0
  while IFS=$'\t' read -r id heading raw normalized section line; do
    [[ -n "$id" ]] || continue
    [[ "$section" != 'history' ]] || continue
    if [[ "$mode" != 'current' || ("$normalized" == 'ambiguous' && "$section" != 'history') || "$section" == 'active' || \
      ("$section" == 'ledger-task' && "$raw" != '-' && "$normalized" != 'done') || \
      ("$section" != 'history' && "$section" != 'ledger-task' && "$normalized" != 'done') ]]; then
      count=$((count + 1))
    fi
  done < <(pmm_legacy_contract_records "$file")
  printf '%s\n' "$count"
}

pmm_legacy_contract_field() {
  local file="$1"
  local mode="${2:-all}"
  local wanted="$3"
  awk -v mode="$mode" -v wanted="$wanted" '
    function clean(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (value ~ /^`.*`$/) value=substr(value, 2, length(value) - 2)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    function normalize(value, normalized) {
      normalized=tolower(clean(value))
      gsub(/[.]+$/, "", normalized)
      if (normalized ~ /^`.*`$/) normalized=substr(normalized, 2, length(normalized) - 2)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", normalized)
      gsub(/[.]+$/, "", normalized)
      if (normalized ~ /^(done|completed|complete|closed|code-complete locally|complete locally)$/) return "done"
      if (normalized ~ /blocked|blocked by|waiting on|waiting for/) return "blocked"
      if (normalized ~ /paused|on hold|deferred/) return "paused"
      if (normalized ~ /code[- ]complete|complete locally|done locally|done on |complete on |completed on |released/) return "done"
      if (normalized ~ /in progress|under implementation|in development|currently working/) return "active"
      return normalized
    }
    function is_contract_section(value) {
      return value ~ /^(Status|Task|Harness|Verifier|Critic|Repair|Record|Agent Mode|Required Evidence|Next Action)$/
    }
    function reset_contract() {
      has_task=0
      has_id=0
      has_task_field=0
      task_id=""
      task=""
      status=""
      objective=""
      source_request=""
      verifier=""
      next_action=""
      status_seen=0
      status_normalized=""
      status_conflict=0
    }
    function title_value() {
      if (task_id != "") return task_id
      if (heading != "" && heading !~ /^(Active Task|Completed Tasks|Blocked Tasks|Deferred Follow-Up|Status|Task|Harness|Verifier|Critic|Repair|Record|Agent Mode|Required Evidence|Next Action)$/) return heading
      return task
    }
    function selected() {
      return has_task && heading != "Completed Tasks" && (status_conflict || mode != "current" || normalize(status) != "done" || heading == "Active Task")
    }
    function flush_contract(value) {
      if (found || !selected()) {
        reset_contract()
        return
      }
      if (wanted == "title") value=title_value()
      else if (wanted == "objective") value=(objective != "" ? objective : (source_request != "" ? source_request : (task != "" ? task : title_value())))
      else if (wanted == "status") value=(status_conflict ? "ambiguous" : status)
      else if (wanted == "verifier") value=verifier
      else if (wanted == "next") value=next_action
      print value
      found=1
      exit
    }
    /^## / {
      next_heading=substr($0, 4)
      next_heading=clean(next_heading)
      if (!is_contract_section(next_heading)) {
        flush_contract()
        heading=next_heading
        if (next_heading ~ /^Task[[:space:]]+/) {
          task_id=clean(substr(next_heading, 6))
          has_task=1
          has_id=1
        }
      } else if (next_heading == "Active Task") {
        flush_contract()
        heading=next_heading
        has_task=1
      }
      next
    }
    /^[[:space:]]*-?[[:space:]]*Task ID:/ {
      if (has_task && (has_id || has_task_field)) flush_contract()
      task_id=$0
      sub(/^[[:space:]]*-?[[:space:]]*Task ID:[[:space:]]*/, "", task_id)
      task_id=clean(task_id)
      if (task_id != "") {
        has_task=1
        has_id=1
      }
      next
    }
    /^[[:space:]]*-?[[:space:]]*Task:/ {
      value=$0
      sub(/^[[:space:]]*-?[[:space:]]*Task:[[:space:]]*/, "", value)
      value=clean(value)
      if (value == "") next
      if (has_task && has_task_field) flush_contract()
      task=value
      has_task=1
      has_task_field=1
      next
    }
    /^[[:space:]]*-?[[:space:]]*Status:/ { if (!has_task) has_task=1; status=$0; sub(/^[[:space:]]*-?[[:space:]]*Status:[[:space:]]*/, "", status); status=clean(status); current_status_normalized=normalize(status); if (status_seen == 0) status_normalized=current_status_normalized; else if (current_status_normalized != status_normalized) status_conflict=1; status_seen++; next }
    /^[[:space:]]*-?[[:space:]]*Objective:/ && has_task { objective=$0; sub(/^[[:space:]]*-?[[:space:]]*Objective:[[:space:]]*/, "", objective); objective=clean(objective); next }
    /^[[:space:]]*-?[[:space:]]*[Ss]ource [Rr]equest:/ && has_task { source_request=$0; sub(/^[[:space:]]*-?[[:space:]]*[Ss]ource [Rr]equest:[[:space:]]*/, "", source_request); source_request=clean(source_request); next }
    /^[[:space:]]*-?[[:space:]]*(Verifier|Required Checks):/ && has_task { verifier=$0; sub(/^[[:space:]]*-?[[:space:]]*(Verifier|Required Checks):[[:space:]]*/, "", verifier); verifier=clean(verifier); next }
    /^[[:space:]]*-?[[:space:]]*(Next Concrete Action|Next Action):/ && has_task { next_action=$0; sub(/^[[:space:]]*-?[[:space:]]*(Next Concrete Action|Next Action):[[:space:]]*/, "", next_action); next }
    END { if (!found) flush_contract() }
  ' "$file"
}

pmm_legacy_title() {
  pmm_legacy_contract_field "$1" "${2:-all}" title
}

pmm_task_file() {
  local root="$1"
  local id="$2"
  local active="$root/docs/00-project-memory/active-task.md"
  local work_item="$root/docs/00-project-memory/work-items/$id.md"
  if [[ -f "$active" && "$(pmm_frontmatter_value "$active" task_id 2>/dev/null || true)" == "$id" ]]; then
    printf '%s\n' "$active"
  elif [[ -f "$work_item" && "$(pmm_frontmatter_value "$work_item" task_id 2>/dev/null || true)" == "$id" ]]; then
    printf '%s\n' "$work_item"
  else
    return 1
  fi
}

pmm_claim_root() {
  local root="$1"
  local common
  common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null || true)"
  if [[ -n "$common" ]]; then
    if [[ "$common" == /* ]]; then
      printf '%s/pmm-claims\n' "$common"
    else
      printf '%s/%s/pmm-claims\n' "$root" "$common"
    fi
  else
    printf '%s/.project-runtime/pmm/claims\n' "$root"
  fi
}

pmm_history_has_task_id() {
  local id="$1"
  shift
  awk -v id="$id" '
    $0 == "<!-- pmm-task-id: " id " -->" { found=1 }
    /^- Task ID:/ {
      value=$0
      sub(/^- Task ID:[[:space:]]*/, "", value)
      sub(/[[:space:]]+$/, "", value)
      if (value ~ /^`.*`$/) value=substr(value, 2, length(value) - 2)
      if (value == id) found=1
    }
    ($1 == "##" || $1 == "###") &&
      $2 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ && $3 == id { found=1 }
    END { exit(found ? 0 : 1) }
  ' "$@"
}

pmm_task_id_is_archived() {
  local root="$1"
  local id="$2"
  local history archive_dir refs ref ref_entry blob history_content history_status seen_blobs='|'
  history="$root/docs/00-project-memory/task-history.md"
  archive_dir="$(pmm_claim_root "$root")/.archived/$id"
  if [[ -f "$history" ]]; then
    if pmm_history_has_task_id "$id" "$history"; then
      return 0
    else
      history_status=$?
      (( history_status == 1 )) || return 2
    fi
  fi
  [[ ! -d "$archive_dir" ]] || return 0
  refs="$(git -C "$root" for-each-ref --format='%(refname)' refs/heads refs/remotes refs/tags 2>/dev/null)" || return 2
  while IFS= read -r ref; do
    [[ -n "$ref" ]] || continue
    ref_entry="$(git -C "$root" ls-tree "$ref" -- docs/00-project-memory/task-history.md 2>/dev/null)" || return 2
    [[ -n "$ref_entry" ]] || continue
    blob="$(printf '%s\n' "$ref_entry" | awk 'NR == 1 { print $3 }')"
    [[ "$blob" =~ ^[0-9a-fA-F]{40,64}$ ]] || return 2
    [[ "$seen_blobs" != *"|$blob|"* ]] || continue
    seen_blobs="${seen_blobs}${blob}|"
    history_content="$(git -C "$root" cat-file blob "$blob" 2>/dev/null)" || return 2
    if pmm_history_has_task_id "$id" <<<"$history_content"; then
      return 0
    else
      history_status=$?
      (( history_status == 1 )) || return 2
    fi
  done <<<"$refs"
  return 1
}

pmm_task_id_archive() {
  local root="$1"
  local id="$2"
  local archive_root archive_dir
  archive_root="$(pmm_claim_root "$root")/.archived"
  archive_dir="$archive_root/$id"
  mkdir -p "$archive_root" || return 1
  mkdir "$archive_dir" 2>/dev/null || [[ -d "$archive_dir" ]]
}

pmm_claim_acquire() {
  local root="$1"
  local id="$2"
  local owner="$3"
  local branch="${4:-unknown}"
  local parent="${5:-none}"
  local kind="${6:-unknown}"
  local claim_root claim_dir existing existing_branch existing_parent existing_kind
  claim_root="$(pmm_claim_root "$root")"
  claim_dir="$claim_root/$id"
  mkdir -p "$claim_root"
  if mkdir "$claim_dir" 2>/dev/null; then
    printf '%s\n' "$owner" >"$claim_dir/owner"
    printf '%s\n' "$branch" >"$claim_dir/branch"
    printf '%s\n' "$parent" >"$claim_dir/parent"
    printf '%s\n' "$kind" >"$claim_dir/kind"
    return 0
  fi
  existing="$(sed -n '1p' "$claim_dir/owner" 2>/dev/null || printf 'unknown')"
  existing_branch="$(sed -n '1p' "$claim_dir/branch" 2>/dev/null || printf 'unknown')"
  existing_parent="$(sed -n '1p' "$claim_dir/parent" 2>/dev/null || printf 'unknown')"
  existing_kind="$(sed -n '1p' "$claim_dir/kind" 2>/dev/null || printf 'unknown')"
  [[ "$existing" == "$owner" && "$existing_branch" == "$branch" && "$existing_parent" == "$parent" && "$existing_kind" == "$kind" ]]
}

pmm_claim_matches() {
  local root="$1"
  local id="$2"
  local owner="$3"
  local branch="$4"
  local parent="$5"
  local kind="$6"
  local claim_dir
  claim_dir="$(pmm_claim_root "$root")/$id"
  [[ -d "$claim_dir" ]] || return 1
  [[ "$(sed -n '1p' "$claim_dir/owner" 2>/dev/null || true)" == "$owner" ]] || return 1
  [[ "$(sed -n '1p' "$claim_dir/branch" 2>/dev/null || true)" == "$branch" ]] || return 1
  [[ "$(sed -n '1p' "$claim_dir/parent" 2>/dev/null || true)" == "$parent" ]] || return 1
  [[ "$(sed -n '1p' "$claim_dir/kind" 2>/dev/null || true)" == "$kind" ]]
}

pmm_claim_value() {
  local root="$1"
  local id="$2"
  local field="$3"
  local claim_dir
  case "$field" in
    owner | branch | parent | kind) ;;
    *) return 1 ;;
  esac
  claim_dir="$(pmm_claim_root "$root")/$id"
  [[ -d "$claim_dir" && -f "$claim_dir/$field" ]] || return 1
  sed -n '1p' "$claim_dir/$field"
}

pmm_claim_primary_task() {
  local root="$1"
  local claim_root claim_dir claimed_parent claimed_kind found=''
  claim_root="$(pmm_claim_root "$root")"
  [[ -d "$claim_root" ]] || return 1
  for claim_dir in "$claim_root"/*; do
    [[ -d "$claim_dir" ]] || continue
    claimed_parent="$(sed -n '1p' "$claim_dir/parent" 2>/dev/null || true)"
    claimed_kind="$(sed -n '1p' "$claim_dir/kind" 2>/dev/null || true)"
    if [[ "$claimed_parent" == 'none' && "$claimed_kind" == 'primary' ]]; then
      [[ -z "$found" ]] || return 2
      found="$(basename "$claim_dir")"
    fi
  done
  [[ -n "$found" ]] || return 1
  printf '%s\n' "$found"
}

pmm_claim_task_for_branch() {
  local root="$1"
  local branch="$2"
  local claim_root claim_dir claimed_branch
  claim_root="$(pmm_claim_root "$root")"
  [[ -d "$claim_root" ]] || return 1
  for claim_dir in "$claim_root"/*; do
    [[ -d "$claim_dir" ]] || continue
    claimed_branch="$(sed -n '1p' "$claim_dir/branch" 2>/dev/null || true)"
    if [[ "$claimed_branch" == "$branch" ]]; then
      basename "$claim_dir"
      return 0
    fi
  done
  return 1
}

pmm_claim_children() {
  local root="$1"
  local parent="$2"
  local claim_root claim_dir claimed_parent claimed_kind
  claim_root="$(pmm_claim_root "$root")"
  [[ -d "$claim_root" ]] || return 0
  for claim_dir in "$claim_root"/*; do
    [[ -d "$claim_dir" ]] || continue
    claimed_parent="$(sed -n '1p' "$claim_dir/parent" 2>/dev/null || true)"
    claimed_kind="$(sed -n '1p' "$claim_dir/kind" 2>/dev/null || true)"
    if [[ "$claimed_parent" == "$parent" && "$claimed_kind" == 'work-item' ]]; then
      basename "$claim_dir"
    fi
  done
}

pmm_claim_work_items() {
  local root="$1"
  local claim_root claim_dir claimed_kind
  claim_root="$(pmm_claim_root "$root")"
  [[ -d "$claim_root" ]] || return 0
  for claim_dir in "$claim_root"/*; do
    [[ -d "$claim_dir" ]] || continue
    claimed_kind="$(sed -n '1p' "$claim_dir/kind" 2>/dev/null || true)"
    [[ "$claimed_kind" == 'work-item' ]] || continue
    basename "$claim_dir"
  done
}

pmm_claim_release() {
  local root="$1"
  local id="$2"
  local claim_dir
  claim_dir="$(pmm_claim_root "$root")/$id"
  [[ -d "$claim_dir" ]] || return 0
  rm -f "$claim_dir/owner" "$claim_dir/branch" "$claim_dir/parent" "$claim_dir/kind"
  rmdir "$claim_dir" 2>/dev/null
}

pmm_mutation_lock_acquire() {
  local root="$1"
  local lock_id="$2"
  local claim_root lock_dir owner_dir host
  claim_root="$(pmm_claim_root "$root")"
  lock_dir="$claim_root/.mutation-lock"
  mkdir -p "$claim_root"
  if ! mkdir "$lock_dir" 2>/dev/null; then
    pmm_mutation_lock_recover "$root" || return 1
    mkdir "$lock_dir" 2>/dev/null || return 1
  fi
  owner_dir="$lock_dir/$lock_id"
  if ! mkdir "$owner_dir" 2>/dev/null; then
    rmdir "$lock_dir" 2>/dev/null || true
    return 1
  fi
  host="$(uname -n)"
  if ! printf '%s\n' "$host" >"$owner_dir/host" || ! printf '%s\n' "$$" >"$owner_dir/pid"; then
    rm -f "$owner_dir/host" "$owner_dir/pid"
    rmdir "$owner_dir" 2>/dev/null || true
    rmdir "$lock_dir" 2>/dev/null || true
    return 1
  fi
}

pmm_mutation_lock_release() {
  local root="$1"
  local lock_id="$2"
  local lock_dir owner_dir
  lock_dir="$(pmm_claim_root "$root")/.mutation-lock"
  [[ -d "$lock_dir" ]] || return 0
  owner_dir="$lock_dir/$lock_id"
  [[ -d "$owner_dir" ]] || return 1
  rm -f "$owner_dir/host" "$owner_dir/pid"
  rmdir "$owner_dir" 2>/dev/null || return 1
  rmdir "$lock_dir" 2>/dev/null
}

pmm_mutation_lock_owner() {
  local root="$1"
  local lock_dir owner_dir found=''
  lock_dir="$(pmm_claim_root "$root")/.mutation-lock"
  [[ -d "$lock_dir" ]] || return 1
  for owner_dir in "$lock_dir"/*; do
    [[ -d "$owner_dir" ]] || continue
    [[ -z "$found" ]] || return 2
    found="$owner_dir"
  done
  [[ -n "$found" ]] || return 1
  printf '%s\n' "$found"
}

pmm_mutation_lock_is_orphan() {
  local root="$1"
  local lock_dir owner_dir recorded_host recorded_pid
  lock_dir="$(pmm_claim_root "$root")/.mutation-lock"
  [[ -d "$lock_dir" ]] || return 1
  owner_dir="$(pmm_mutation_lock_owner "$root" 2>/dev/null || true)"
  if [[ -z "$owner_dir" ]]; then
    [[ -z "$(find "$lock_dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]] || return 1
    pmm_path_is_old "$lock_dir" 5
    return
  fi
  recorded_host="$(sed -n '1p' "$owner_dir/host" 2>/dev/null || true)"
  recorded_pid="$(sed -n '1p' "$owner_dir/pid" 2>/dev/null || true)"
  if [[ -z "$recorded_host" || -z "$recorded_pid" ]]; then
    pmm_path_is_old "$owner_dir" 5
    return
  fi
  [[ "$recorded_host" == "$(uname -n)" && "$recorded_pid" =~ ^[0-9]+$ ]] || return 1
  ! kill -0 "$recorded_pid" 2>/dev/null
}

pmm_path_is_old() {
  local path="$1"
  local minimum_age="$2"
  local modified now
  modified="$(stat -f '%m' "$path" 2>/dev/null || true)"
  [[ "$modified" =~ ^[0-9]+$ ]] || modified="$(stat -c '%Y' "$path" 2>/dev/null || true)"
  now="$(date '+%s')"
  [[ "$modified" =~ ^[0-9]+$ && "$now" =~ ^[0-9]+$ ]] || return 1
  (( now - modified >= minimum_age ))
}

pmm_mutation_lock_recover() {
  local root="$1"
  local claim_root lock_dir owner_dir stale_dir owner_id
  pmm_mutation_lock_is_orphan "$root" || return 1
  claim_root="$(pmm_claim_root "$root")"
  lock_dir="$claim_root/.mutation-lock"
  owner_dir="$(pmm_mutation_lock_owner "$root" 2>/dev/null || true)"
  pmm_mutation_lock_is_orphan "$root" || return 1
  if [[ -z "$owner_dir" ]]; then
    rmdir "$lock_dir" 2>/dev/null
    return
  fi
  owner_id="$(basename "$owner_dir")"
  stale_dir="$claim_root/.mutation-lock-stale-$owner_id-$$"
  mv "$owner_dir" "$stale_dir" 2>/dev/null || return 1
  if ! rmdir "$lock_dir" 2>/dev/null; then
    mv "$stale_dir" "$owner_dir" 2>/dev/null || true
    return 1
  fi
  rm -f "$stale_dir/host" "$stale_dir/pid"
  rmdir "$stale_dir" 2>/dev/null || return 1
}

pmm_json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/[[:cntrl:]]/ /g'
}
