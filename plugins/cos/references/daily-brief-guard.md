# Daily Brief Guard — Deterministic Get-or-Create

**Every skill that touches the Daily Brief page MUST call this procedure for
its "find or create today's page" step. Do not improvise a query, do not
invent your own filter, do not decide on your own whether a match is close
enough. This replaces all prior free-text "query the database for a page
with Date = today" instructions.**

## Why this exists

Prior to this procedure, each skill's Step 0 was described only in prose
("query the Daily Briefs database for a page with Date = today"). Prose has
no fixed tool call and no fixed decision rule, so different runs made
different non-deterministic choices about which tool to call and how to
judge a match — producing duplicate same-date pages in Notion. This
procedure fixes that by making every step of the decision explicit and by
delegating the actual decision logic to a tested, deterministic script.

## Config

Read `daily_briefs_view_id` from `## Notion: Daily Briefs` in me.md — the
ID of a dedicated Notion view on the Daily Briefs database. This view is
**unfiltered** (all rows) and **sorted by Date descending**. It exists
specifically so this procedure has a stable, known view to query — do not
use any other view, and do not construct an ad-hoc filter, because
`notion-query-database-view` executes the view's own stored query and does
not accept a runtime filter parameter.

**This procedure is target-date-parameterized, not "today"-only.** Most
callers use it for today's date (morning-sweep, evening-review Step 0,
email-classify), but evening-review's Step 6 also uses it for the *next
workday's* date when creating tomorrow's page. Everywhere below, "target
date" means whichever date the calling step needs — substitute "next
workday" for "today" in Step A when the caller is Step 6.

## Procedure (run this exact sequence)

### Step A — Determine the target date (ET)

Compute the target date in `YYYY-MM-DD` format, in the user's timezone from
me.md (America/New_York) — "today" for most callers, "next workday" for
evening-review's Step 6. If a Bash tool call is available in this session,
prefer shelling out to the guard script for this too (see Step C) so every
routine — local, cloud, plugin-skill — derives its date from the exact same
logic. Do not compute it ad hoc from a different source per skill.

### Step B — Query the pinned view

Call the Notion MCP `notion-query-database-view` tool with the
`daily_briefs_view_id` from config. This returns the view's page 1 (rows for
the target date, if any, will be near the top — sorted Date descending).
Capture the raw list of page objects returned.

**Log the raw row count from this query before calling the guard script**
(e.g. `[COS-GUARD] raw_rows=<N> from view query`). This is separate from the
guard's own `matches=` count in its `log_line` (Step D) — the raw count
catches a different silent failure: if the view query itself returned zero
or unexpectedly few rows (e.g. pagination cut off before reaching today's
row, or the view id is stale/wrong), that would look identical to a
legitimate 0-candidate result to anyone reading only the guard's decision.
Logging both counts makes each failure mode distinguishable in the run
output instead of collapsing into one invisible "matches=0" line.

### Step C — Ask the deterministic guard script for the decision

**Do not evaluate the query result yourself.** Shell out via Bash to the
guard script and feed it the raw rows from Step B as JSON on stdin:

```bash
echo '<JSON: {"target_date": "<target date from Step A>", "rows": <raw page objects from Step B>}>' \
  | python3 "${COS_DAILY_BRIEF_GUARD_SCRIPT:-$HOME/Projects/klmc-agent-home/tools/cos-daily-brief/guard_cli.py}"
```

(Script discovery follows the repo's existing convention: an env var
override, falling back to a fixed default path under
`klmc-agent-home/tools/cos-daily-brief/`. If the script cannot be found or
invoked — e.g. running in an environment without that repo checked out —
fall back to the literal Date-property + exact-title-match logic described
in "Fallback logic" below, and note in your output that the guard script was
unavailable.)

The script returns JSON:
```json
{
  "action": "reuse" | "create" | "stop_ambiguous",
  "page_id": "<id or null>",
  "title": "YYYY-MM-DD - Daily",
  "target_date": "YYYY-MM-DD",
  "match_count": <int>,
  "candidate_ids": ["<id>", ...],
  "log_line": "[COS-GUARD] date=... matches=... action=..."
}
```

### Step D — Print the log line, then branch

**Always print the returned `log_line` to your output before taking any
further action.** This is the visible find-count guard — it makes a future
silent miss observable in the run's output/log instead of an invisible
duplicate-creating event.

Then branch on `action`:

- **`"reuse"`** — use `page_id` as the Daily Brief page for the target date.
  Do not create anything. Continue with the rest of your skill's steps using
  this page id.
- **`"create"`** — call `notion-create-pages` exactly once:
  - Parent: the Daily Briefs database ID from me.md (`daily_briefs_database_id`)
  - Title (Name property): the returned `title` (`"YYYY-MM-DD - Daily"`)
  - Date property: the returned `target_date`
  - Status: `"Draft"`
  - Save the returned page ID and continue with the rest of your skill's steps.
- **`"stop_ambiguous"`** — **do not create a new page. Do not guess which
  `candidate_ids` entry to use.** This means 2+ rows in the database are
  already titled exactly `"YYYY-MM-DD - Daily"` for the target date — a
  genuine duplicate that needs human reconciliation (this is exactly the
  state Kevin/Sarabi found and partially cleaned up on 2026-07-01; residual
  duplicate dates may still exist until fully reconciled). Report the
  `candidate_ids` in your output and stop this step — do not proceed to
  write the brief/plan/section content until a human resolves which page is
  canonical. Continue with the rest of the skill's non-Notion-dependent work
  if possible (e.g., still present the brief in conversation), but skip all
  Notion write-back for this run.

## Fallback logic (only if the guard script is unavailable)

If Bash/the guard script genuinely cannot be invoked in your environment:
query the pinned view, then match rows client-side yourself using this
exact rule:

- A row whose **Name (title) property is exactly `"YYYY-MM-DD - Daily"`**
  for the target date is always a candidate.
- A row with a DIFFERENT title is ALSO a candidate if BOTH its Date property
  equals the target date AND the target date string appears somewhere in
  its title. This catches legacy-titled pages (bare `"YYYY-MM-DD"`,
  `"Morning Sweep — YYYY-MM-DD"`) that are real Daily Brief pages for that
  date — do not silently ignore these just because the title isn't exactly
  canonical, or you will return "create" for a date that already has a page.
- A row titled with Sarabi's `"[DUPLICATE - MERGED/EXACT COPY - SAFE TO
  TRASH]"` prefix is NEVER a candidate, regardless of Date or title match.
- **Date property match alone is NOT sufficient** for anything else (the
  database can contain unrelated pages someone filed in this DB by mistake,
  which may coincidentally carry a Date value).

If exactly one row is a candidate, reuse it. If zero, create exactly one.
If two or more, stop and report — do not create, do not guess.

## What every writer path must do

- **morning-sweep, evening-review**: this procedure IS their Step 0 (and
  evening-review's Step 6, targeting the next workday's date instead of
  today's). See each skill's relevant section, which now points here.
- **email-classify** (standalone path, when no `daily_brief_page_id` is
  passed in by a parent skill): this procedure is also its Step 2. Its
  fallback title bug (previously creating `"YYYY-MM-DD"` without the
  `" - Daily"` suffix) is fixed — it must always use the same
  `canonical_title()` format as every other writer.
- **email-notion-sink**: never runs this procedure itself. It only ever
  consumes the `daily_brief_page_id` handed to it by its caller (morning-
  sweep, evening-review, or the email-triage orchestrator, which itself got
  it from email-classify's Step 2). It must never free-create a page.
- **Cloud/external routines** (comms-sweep cloud prompt, Jasiri's weekly BD
  sweep): not plugin skills, so they don't reference `${CLAUDE_PLUGIN_ROOT}`.
  They implement the equivalent of this same procedure directly against
  `klmc-agent-home/tools/cos-daily-brief/guard_cli.py` — see those routines'
  own instructions for the exact wording, which mirrors this doc.
