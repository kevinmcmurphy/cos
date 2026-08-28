#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYNC="$SCRIPT_DIR/../plugins/cos/scripts/board-morning-sync.sh"
TEST_TMP="$(mktemp -d)"
trap 'rm -rf "$TEST_TMP"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1"; }
assert_file_contains() {
  local file="$1" expected="$2" label="$3"
  if [ -f "$file" ] && grep -qF -- "$expected" "$file"; then pass "$label"; else fail "$label"; fi
}
assert_count() {
  local expected="$1" pattern="$2" file="$3" label="$4" actual
  actual=$(grep -cF -- "$pattern" "$file" 2>/dev/null || true)
  actual="${actual:-0}"
  if [ "$actual" = "$expected" ]; then pass "$label"; else fail "$label (got $actual, want $expected)"; fi
}

TODAY="$(TZ=America/New_York date +%Y-%m-%d)"
YESTERDAY="$(TZ=America/New_York date -v-1d +%Y-%m-%d 2>/dev/null || TZ=America/New_York date -d yesterday +%Y-%m-%d)"

new_fixture() {
  local root="$1"
  mkdir -p "$root/bin" "$root/agents" "$root/Board"
  : > "$root/agents/registry.yaml"
  cat > "$root/bin/board" <<'FAKE'
#!/usr/bin/env bash
set -eu
root="${BOARD_REPO_ROOT:?}"
today="$(TZ=America/New_York date +%Y-%m-%d)"
cmd="$1"; shift
case "$cmd" in
  ensure-today)
    path="$root/Board/$today.md"
    if [ ! -f "$path" ]; then
      cat > "$path" <<EOF
---
date: $today
status: open
created_by: session-start-fallback
closed_at: null
---

## Waiting on Kevin

## In Progress

## Done

## Carried Over
EOF
    fi
    printf '%s\n' "$path"
    ;;
  show)
    date="$today"
    if [ "${1:-}" = "--date" ]; then date="$2"; fi
    [ ! -f "$root/fail-show" ] || exit 1
    cat "$root/Board/$date.md"
    ;;
  upsert)
    session=""; agent=""; section=""; text=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --session) session="$2"; shift 2 ;;
        --agent) agent="$2"; shift 2 ;;
        --section) section="$2"; shift 2 ;;
        --text) text="$2"; shift 2 ;;
      esac
    done
    path="$root/Board/$today.md"
    if grep -q '^status: closed$' "$path"; then exit 1; fi
    [ "$agent" = "mane" ] || exit 1
    [ "${#text}" -le 300 ] || exit 1
    if [ -f "$root/fail-carry-once" ] && printf '%s' "$session" | grep -q '^carry:'; then
      rm "$root/fail-carry-once"
      exit 1
    fi
    case "$section" in
      waiting) header='## Waiting on Kevin' ;;
      progress) header='## In Progress' ;;
      done) header='## Done' ;;
      carried) header='## Carried Over' ;;
      *) exit 1 ;;
    esac
    marker="<!-- session:$session -->"
    line="- [$agent] $text $marker"
    awk -v marker="$marker" 'index($0, marker) == 0' "$path" > "$path.tmp"
    mv "$path.tmp" "$path"
    awk -v header="$header" -v line="$line" '{ print } $0 == header { print line }' "$path" > "$path.tmp"
    mv "$path.tmp" "$path"
    printf 'session=%s|agent=%s|section=%s|text=%s\n' "$session" "$agent" "$section" "$text" >> "$root/calls.log"
    ;;
  *) exit 2 ;;
esac
FAKE
  chmod +x "$root/bin/board"
}

if [ -e "$SYNC" ]; then
  pass "helper exists before behavior tests"
else
  fail "helper exists before behavior tests"
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi

# Fresh board: carry only yesterday's still-open Waiting/In Progress lines.
FIXTURE1="$TEST_TMP/fresh"
new_fixture "$FIXTURE1"
cat > "$FIXTURE1/Board/$YESTERDAY.md" <<EOF
---
date: $YESTERDAY
status: closed
---

## Waiting on Kevin
- [sarabi] approve launch plan <!-- session:wait-1 -->

## In Progress
- [mufasa] finish API design <!-- session:progress-1 -->

## Done
- [pumbaa] shipped fix <!-- session:done-1 -->

## Carried Over
EOF

KLMC_REPO="$FIXTURE1" "$SYNC" start
assert_file_contains "$FIXTURE1/Board/$TODAY.md" "## Carried Over" "start creates today's board"
assert_file_contains "$FIXTURE1/calls.log" "session=carry:$YESTERDAY:wait-1|agent=mane|section=carried|text=From sarabi: approve launch plan" "start carries Waiting line with source attribution"
assert_file_contains "$FIXTURE1/calls.log" "session=carry:$YESTERDAY:progress-1|agent=mane|section=carried|text=From mufasa: finish API design" "start carries In Progress line with source attribution"
assert_file_contains "$FIXTURE1/Board/$TODAY.md" "From sarabi: approve launch plan" "carry-forward populates today's actual Carried Over section"
assert_file_contains "$FIXTURE1/Board/$TODAY.md" "From mufasa: finish API design" "carry-forward writes every open source line"
assert_count 0 "session=carry:$YESTERDAY:done-1" "$FIXTURE1/calls.log" "start does not carry Done lines"
assert_file_contains "$FIXTURE1/calls.log" "session=morning-sweep:$TODAY|agent=mane|section=progress|text=morning sweep started" "start writes an observable in-progress marker"

KLMC_REPO="$FIXTURE1" "$SYNC" start
assert_count 1 "session=carry:$YESTERDAY:wait-1" "$FIXTURE1/calls.log" "second start does not repeat carry-forward"

printf '%s\n' "Client prep, pipeline follow-up, and unblock PR #637" | KLMC_REPO="$FIXTURE1" "$SYNC" complete --priorities-stdin
assert_file_contains "$FIXTURE1/calls.log" "session=priorities:$TODAY|agent=mane|section=waiting|text=Today's priorities: Client prep, pipeline follow-up, and unblock PR #637" "complete writes one priorities line"
assert_file_contains "$FIXTURE1/calls.log" "session=morning-sweep:$TODAY|agent=mane|section=done|text=morning sweep completed" "complete moves the run marker to Done"

# Existing board: never replay yesterday into Carried Over.
FIXTURE2="$TEST_TMP/existing"
new_fixture "$FIXTURE2"
BOARD_REPO_ROOT="$FIXTURE2" "$FIXTURE2/bin/board" ensure-today >/dev/null
cat > "$FIXTURE2/Board/$YESTERDAY.md" <<EOF
## Waiting on Kevin
- [sarabi] should not be replayed <!-- session:wait-2 -->
## In Progress
## Done
## Carried Over
EOF
KLMC_REPO="$FIXTURE2" "$SYNC" start
assert_count 0 "session=carry:" "$FIXTURE2/calls.log" "existing board skips carry-forward"

# A closed current-day board is never reopened or mutated.
FIXTURE3="$TEST_TMP/closed"
new_fixture "$FIXTURE3"
BOARD_REPO_ROOT="$FIXTURE3" "$FIXTURE3/bin/board" ensure-today >/dev/null
sed 's/^status: open$/status: closed/' "$FIXTURE3/Board/$TODAY.md" > "$FIXTURE3/Board/$TODAY.md.tmp"
mv "$FIXTURE3/Board/$TODAY.md.tmp" "$FIXTURE3/Board/$TODAY.md"
if KLMC_REPO="$FIXTURE3" "$SYNC" start >/dev/null 2>&1; then
  fail "closed board rejects morning start"
else
  pass "closed board rejects morning start"
fi
assert_count 0 "session=morning-sweep:" "$FIXTURE3/calls.log" "closed board receives no run marker"

# Maximum-length source text is truncated with attribution, not rejected.
FIXTURE4="$TEST_TMP/max-text"
new_fixture "$FIXTURE4"
LONG_TEXT="$(printf '%300s' '' | tr ' ' x)"
cat > "$FIXTURE4/Board/$YESTERDAY.md" <<EOF
## Waiting on Kevin
- [sarabi] $LONG_TEXT <!-- session:max-1 -->
## In Progress
## Done
## Carried Over
EOF
KLMC_REPO="$FIXTURE4" "$SYNC" start
CARRIED_TEXT=$(sed -nE 's/^- \[mane\] (.*) <!-- session:carry:.*$/\1/p' "$FIXTURE4/Board/$TODAY.md")
if [ "${#CARRIED_TEXT}" -le 300 ] && printf '%s' "$CARRIED_TEXT" | grep -qF 'From sarabi:' && printf '%s' "$CARRIED_TEXT" | grep -qF '...'; then
  pass "maximum-length source is safely truncated under Board cap"
else
  fail "maximum-length source is safely truncated under Board cap"
fi

# A transient carry failure leaves a pending marker and retries on next start.
FIXTURE5="$TEST_TMP/retry"
new_fixture "$FIXTURE5"
cat > "$FIXTURE5/Board/$YESTERDAY.md" <<EOF
## Waiting on Kevin
- [sarabi] retry this carry <!-- session:retry-1 -->
## In Progress
## Done
## Carried Over
EOF
touch "$FIXTURE5/fail-carry-once"
if KLMC_REPO="$FIXTURE5" "$SYNC" start >/dev/null 2>&1; then
  fail "transient carry failure makes first start fail"
else
  pass "transient carry failure makes first start fail"
fi
assert_file_contains "$FIXTURE5/Board/$TODAY.md" "carry-forward pending" "failed carry leaves visible retry marker"
if printf '%s\n' "must not erase pending" | KLMC_REPO="$FIXTURE5" "$SYNC" complete --priorities-stdin >/dev/null 2>&1; then
  fail "complete refuses while carry-forward is pending"
else
  pass "complete refuses while carry-forward is pending"
fi
assert_file_contains "$FIXTURE5/Board/$TODAY.md" "carry-forward pending" "failed completion preserves pending retry state"
KLMC_REPO="$FIXTURE5" "$SYNC" start
assert_file_contains "$FIXTURE5/Board/$TODAY.md" "From sarabi: retry this carry" "next start retries carry on an existing board"
assert_count 0 "carry-forward pending" "$FIXTURE5/Board/$TODAY.md" "successful retry clears pending marker"

# An existing-but-unreadable yesterday board is an error, not a silent skip.
FIXTURE6="$TEST_TMP/show-failure"
new_fixture "$FIXTURE6"
printf '%s\n' '## Waiting on Kevin' > "$FIXTURE6/Board/$YESTERDAY.md"
touch "$FIXTURE6/fail-show"
if KLMC_REPO="$FIXTURE6" "$SYNC" start >/dev/null 2>&1; then
  fail "existing yesterday-board read failure propagates"
else
  pass "existing yesterday-board read failure propagates"
fi
assert_file_contains "$FIXTURE6/Board/$TODAY.md" "carry-forward pending" "read failure remains visible for retry"

assert_file_contains "$SCRIPT_DIR/../plugins/cos/skills/morning-sweep/SKILL.md" "references/morning-board.md" "morning skill invokes shared Board procedure"
assert_file_contains "$SCRIPT_DIR/../plugins/cos/skills/morning-sweep/SKILL.md" "Preserve every other existing page section" "morning skill preserves non-owned Notion sections"
assert_file_contains "$SCRIPT_DIR/../plugins/cos/skills/setup/SKILL.md" "daily_briefs_view_id:" "setup writes the pinned Daily Brief view ID"
assert_file_contains "$SCRIPT_DIR/../plugins/cos/skills/morning-sweep/SKILL.md" "disabled-module case" "Daily Briefs-disabled run still completes Board signal"
MORNING_BOARD="$SCRIPT_DIR/../plugins/cos/references/morning-board.md"
assert_file_contains "$MORNING_BOARD" "CLOUD BOARD PERSISTENCE MODE" "cloud run selects durable Board publication"
assert_count 0 "cos-board-cloud-persist" "$MORNING_BOARD" "cloud run no longer names the hand-rolled Board publisher"
assert_count 2 "/bin/memory-publish" "$MORNING_BOARD" "cloud run invokes the shared publisher once at each publication point"
assert_count 2 'KLMC_ROOT="$(git rev-parse --show-toplevel)"' "$MORNING_BOARD" "each cloud checkpoint resolves the checked-out klmc-agent-home root once"
assert_count 2 'TODAY="$(TZ=America/New_York date +%Y-%m-%d)"' "$MORNING_BOARD" "each cloud checkpoint resolves the ET date once"
assert_count 2 'config --local --get klmc.boardRole' "$MORNING_BOARD" "each cloud checkpoint verifies the canonical Board role"
assert_count 2 'KLMC_REPO="$KLMC_ROOT"' "$MORNING_BOARD" "cloud producer is pinned to the resolved klmc-agent-home root"
assert_count 2 '--branch "publish/cos-board-$TODAY"' "$MORNING_BOARD" "both cloud checkpoints update one deterministic publish branch"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
