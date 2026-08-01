# Unstall Three — Quick-Win Personal Action Queue

Shared procedure for the "Unstall Three" surface (morning-sweep) and close-out
(evening-review). Both skills reference this file instead of duplicating the
mane-db query or the close-out logic.

## Why this exists

Kevin stalls on last-mile, ≤5-minute personal actions — the kind of thing
that's trivial to do but easy to let sit for weeks (cancel a subscription,
book an appointment, reply to one email). The queue for these lives in
mane-db as tasks: title prefixed `[unstall] `, `assigned_agent = kevin`, not
yet complete. Sarabi owns populating the queue; this doc only covers reading
it (morning) and closing it out (evening). See
`agents/sarabi-project-manager/memory/unstall-queue.md` in klmc-agent-home
for the queue-population convention if/when it exists — this procedure does
not depend on that doc existing.

v1 is deliberately minimal: no scoring, no streaks, no batting average, no
aging/carry-count machinery. An item that isn't done just stays in the
queue and can resurface on a later day by the same priority/oldest-first
rule.

## Contract

- **Title prefix:** `[unstall] ` (exact string, space included) — render the
  title verbatim after that prefix, no rewording.
- **Owner:** `assigned_agent = kevin`. (mane-db's `tasks` table has no
  separate `owner` column — see Deviations below.)
- **Open:** not yet `complete`.
- **Priority:** mane-db's `priority` field (`high` / `medium` / `low`).
- **Top 3:** priority high-first, then oldest `created_at` first within a
  priority tier.
- **Source project:** resolve `project_id` to the project's name via
  `mane-db projects get`/`projects list` and show it alongside the title.

## Gather step (run via Bash — keep this out of the LLM path)

```bash
TASKS=$(mane-db tasks list --agent kevin --format json 2>/dev/null)
PROJECTS=$(mane-db projects list --format json 2>/dev/null)
jq -n --argjson tasks "$TASKS" --argjson projects "$PROJECTS" '
  ($projects | map({(.id|tostring): .name}) | add) as $pmap
  | [ $tasks[]?
      | select(.title | startswith("[unstall] "))
      | select((.status // "") != "complete")
      | {id, title, priority: (.priority // "medium"), created_at,
         project: ($pmap[(.project_id|tostring)] // "Unknown project")} ]
  | sort_by([(if .priority == "high" then 0 elif .priority == "medium" then 1 else 2 end), .created_at])
  | .[0:3]
'
```

This is a single deterministic pipeline — do not re-derive it by hand-querying
mane-db and reasoning over the results yourself. Its output is a JSON array
of 0–3 objects: `{id, title, priority, created_at, project}`.

**If `mane-db` or `jq` is unavailable, or the command errors:** skip the
Unstall Three section for this run. Do not block the rest of the sweep and
do not attempt to hand-query the tasks table through a different path. Note
the skip once, quietly, in your output (e.g. "Unstall Three unavailable —
mane-db not reachable") — this is not a RED item.

**If the result is `[]`:** omit the section entirely. No "queue is empty!"
message, no placeholder line.

## Morning Sweep — Presentation

Insert into the brief between PIPELINE and CAPACITY CHECK, only when the
gather step above returned 1+ items:

```
UNSTALL THREE (your 10 minutes)
- [title] | [project]
- [title] | [project]
- [title] | [project]
```

Framing rule: this is a "clear these while your coffee's still hot" nudge,
not a guilt list. Never add deferral/aging language ("you've had this for N
days") — that's explicitly out of scope for v1. Titles render verbatim
(after the `[unstall] ` prefix), no added urgency wording.

If Daily Briefs (Notion) is enabled, this section is part of the brief text
already being written to the page — no separate Notion write is needed.

**Local artifact:** carry the exact `id`, title, and project for each
surfaced item into the daily-sweep artifact's `## Morning` section as a new
`### Unstall Three` subsection (see each skill's artifact template). This is
evening-review's only authoritative source for "which three were surfaced
today" — evening-review must not re-run the gather query and assume it
returns the same three (the queue can change during the day).

## Evening Review — Close-Out

1. Read today's local daily-sweep artifact's `## Morning` → `### Unstall
   Three` subsection for today's surfaced items' mane-db task ids. If that
   subsection doesn't exist or reads `_none_` (Unstall Three didn't run, or
   returned nothing, this morning), skip close-out entirely — nothing to
   close.
2. Check status first — don't just ask blind. If anything already gathered
   during this evening review's Step 4 (project/system update pass) plausibly
   closes one of these items, treat it as done. This is best-effort only; do
   not build new detection for it.
3. For anything not already resolved by step 2, ask once, batched (not one
   prompt per item):
   > "Quick close-out on this morning's Unstall Three: [title 1] / [title 2]
   > / [title 3] — any of these done?"
   Wait for the response.
4. For each item confirmed done: `mane-db tasks update <id> --status
   complete`.
5. For each item not done (explicit "no," or no response covering it): do
   nothing. It stays as-is in mane-db and can resurface in a future gather
   by the same priority/oldest-first rule. No streak counter, no batting
   average, no carry-count prefix.
6. Log the outcome in the evening review output and in the local artifact's
   `## Evening` section, e.g.: "Unstall Three close-out: 2 done (marked
   complete in mane-db), 1 carried."

## Deviations from the nominal contract (and why)

- **No `owner` column exists in mane-db.** `tasks list --help` / `tasks
  update --help` only expose `--agent` (column `assigned_agent`), not
  `--owner`. This procedure uses `--agent kevin` as the closest available
  filter. If Sarabi's queue-convention doc specifies something different when
  it lands, reconcile this doc to match.
- **"Open" is mapped to `status != complete`, not `status == pending`.**
  Verified live: `mane-db tasks create` has no `--status` flag at all, and
  the resulting row's `status` column is an empty string (`''`), not the
  schema's declared default (`'pending'`) — the CLI's INSERT explicitly
  passes an empty value rather than omitting the column, so the SQL
  `DEFAULT` never applies. A server-side `--status pending` filter therefore
  misses every freshly created queue item. Filtering client-side on
  "not complete" is robust to this regardless of whether a task's status is
  `''`, `pending`, `in_progress`, or `blocked`. Flagging this as a real
  mane-db gotcha worth fixing upstream (either default `status` to `pending`
  in the `tasks create` handler, or have Sarabi's queue-creation flow call
  `tasks update --status pending` immediately after `create`) — out of scope
  for this change, noted here for whoever picks it up.
