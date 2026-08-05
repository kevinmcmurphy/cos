#!/usr/bin/env bash
# Deterministic Daily Board integration for the distributable cos:morning-sweep.
# Uses the existing klmc-agent-home/bin/board contract; it does not edit
# Board Markdown directly and does not invoke an LLM.

set -uo pipefail

err() { printf 'board-morning-sync: %s\n' "$*" >&2; }
fatal() { err "$*"; exit 1; }

resolve_repo_root() {
  local git_root=""
  if [ -n "${KLMC_REPO:-}" ] && [ -f "$KLMC_REPO/agents/registry.yaml" ]; then
    printf '%s\n' "$KLMC_REPO"
    return 0
  fi
  if [ -f "/Users/kevin/Projects/klmc-agent-home/agents/registry.yaml" ]; then
    printf '%s\n' "/Users/kevin/Projects/klmc-agent-home"
    return 0
  fi
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || git_root=""
  if [ -n "$git_root" ] && [ -f "$git_root/agents/registry.yaml" ]; then
    printf '%s\n' "$git_root"
    return 0
  fi
  if [ -f "$PWD/agents/registry.yaml" ]; then
    printf '%s\n' "$PWD"
    return 0
  fi
  return 1
}

et_date() { TZ=America/New_York date +%Y-%m-%d; }
yesterday_date() {
  TZ=America/New_York date -v-1d +%Y-%m-%d 2>/dev/null \
    || TZ=America/New_York date -d yesterday +%Y-%m-%d
}
et_time() { TZ=America/New_York date +%H:%M; }

section_lines() {
  awk '
    $0 == "## Waiting on Kevin" || $0 == "## In Progress" { open=1; next }
    /^## / { open=0 }
    open && /^- \[[^]]+\].*<!-- session:[^>]+ -->$/ { print }
  '
}

carry_forward() {
  local yesterday="$1" prior line agent marker body prefix carry_text keep
  local max_chars="${BOARD_MAX_TEXT_CHARS:-300}"
  [ -f "$REPO_ROOT/Board/$yesterday.md" ] || return 0
  prior="$(cd "$REPO_ROOT" && BOARD_REPO_ROOT="$REPO_ROOT" "$BOARD" show --date "$yesterday")" \
    || { err "could not read yesterday's existing board"; return 1; }

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    agent=$(printf '%s\n' "$line" | sed -nE 's/^- \[([^]]+)\].*/\1/p')
    marker=$(printf '%s\n' "$line" | sed -nE 's/.*<!-- session:([^>]+) -->.*/\1/p')
    body=$(printf '%s\n' "$line" | sed -nE 's/^- \[[^]]+\] (.*) <!-- session:[^>]+ -->$/\1/p')

    if [ -z "$agent" ] || [ -z "$body" ] \
      || ! printf '%s' "$marker" | grep -qE '^[A-Za-z0-9._:-]+$'; then
      err "skipping malformed carry-forward line"
      continue
    fi

    prefix="From ${agent}: "
    carry_text="${prefix}${body}"
    if [ "${#carry_text}" -gt "$max_chars" ]; then
      keep=$(( max_chars - ${#prefix} - 3 ))
      [ "$keep" -gt 0 ] || { err "agent attribution leaves no room under Board text cap"; return 1; }
      carry_text="${prefix}${body:0:$keep}..."
    fi

    (cd "$REPO_ROOT" && BOARD_REPO_ROOT="$REPO_ROOT" "$BOARD" upsert \
      --session "carry:${yesterday}:${marker}" \
      --agent mane \
      --section carried \
      --text "$carry_text") || return 1
  done <<EOF
$(section_lines <<< "$prior")
EOF
}

cmd_start() {
  local today yesterday path marker_text existed=0 carry_pending=0
  today="$(et_date)"
  yesterday="$(yesterday_date)" || fatal "cannot calculate yesterday in ET"
  path="$REPO_ROOT/Board/$today.md"
  [ -f "$path" ] && existed=1

  (cd "$REPO_ROOT" && BOARD_REPO_ROOT="$REPO_ROOT" "$BOARD" ensure-today >/dev/null) \
    || fatal "board ensure-today failed"

  if [ "$existed" -eq 0 ]; then carry_pending=1; fi
  if grep -qF "<!-- session:morning-sweep:${today} -->" "$path" \
    && grep -F "<!-- session:morning-sweep:${today} -->" "$path" | grep -qF "carry-forward pending"; then
    carry_pending=1
  fi

  marker_text="morning sweep started at $(et_time) ET"
  if [ "$carry_pending" -eq 1 ]; then marker_text="${marker_text}; carry-forward pending"; fi
  (cd "$REPO_ROOT" && BOARD_REPO_ROOT="$REPO_ROOT" "$BOARD" upsert \
    --session "morning-sweep:${today}" \
    --agent mane \
    --section progress \
    --text "$marker_text") \
    || fatal "could not write morning-sweep start marker"

  if [ "$carry_pending" -eq 1 ]; then
    carry_forward "$yesterday" || fatal "carry-forward failed"
    (cd "$REPO_ROOT" && BOARD_REPO_ROOT="$REPO_ROOT" "$BOARD" upsert \
      --session "morning-sweep:${today}" \
      --agent mane \
      --section progress \
      --text "morning sweep started at $(et_time) ET") \
      || fatal "could not clear carry-forward pending marker"
  fi
}

cmd_complete() {
  local priorities="" today path
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --priorities-stdin)
        [ "$#" -eq 1 ] || fatal "--priorities-stdin takes no value"
        IFS= read -r priorities || [ -n "$priorities" ] || fatal "priorities stdin is empty"
        if IFS= read -r _extra_priority_line; then fatal "priorities stdin must contain exactly one line"; fi
        shift
        ;;
      *) fatal "complete: unknown argument: $1" ;;
    esac
  done
  [ -n "$priorities" ] || fatal "complete: --priorities-stdin is required"
  case "$priorities" in *$'\n'*|*$'\r'*) fatal "complete: priorities must be one line" ;; esac

  today="$(et_date)"
  path="$REPO_ROOT/Board/$today.md"
  if [ -f "$path" ] \
    && grep -F "<!-- session:morning-sweep:${today} -->" "$path" | grep -qF "carry-forward pending"; then
    fatal "cannot complete while carry-forward is pending; retry start first"
  fi
  (cd "$REPO_ROOT" && BOARD_REPO_ROOT="$REPO_ROOT" "$BOARD" upsert \
    --session "priorities:${today}" \
    --agent mane \
    --section waiting \
    --text "Today's priorities: ${priorities}") \
    || fatal "could not write today's priorities"

  (cd "$REPO_ROOT" && BOARD_REPO_ROOT="$REPO_ROOT" "$BOARD" upsert \
    --session "morning-sweep:${today}" \
    --agent mane \
    --section done \
    --text "morning sweep completed at $(et_time) ET") \
    || fatal "could not mark morning sweep complete"
}

REPO_ROOT="$(resolve_repo_root)" || fatal "cannot find klmc-agent-home (set KLMC_REPO)"
BOARD="$REPO_ROOT/bin/board"
[ -x "$BOARD" ] || fatal "board CLI is unavailable or not executable: $BOARD"

case "${1:-}" in
  start) shift; [ "$#" -eq 0 ] || fatal "start takes no arguments"; cmd_start ;;
  complete) shift; cmd_complete "$@" ;;
  *) fatal "usage: board-morning-sync.sh {start|complete --priorities-stdin}" ;;
esac
