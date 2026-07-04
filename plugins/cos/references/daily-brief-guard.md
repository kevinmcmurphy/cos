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

**2026-07-04 rewrite:** the guard script itself (`guard_cli.py` /
`daily_brief_guard.py` in klmc-agent-home) was rebuilt against a REAL
captured `notion-query-database-view` payload after discovering the prior
version parsed a Notion REST envelope
(`row["properties"]["Name"]["title"][...]["plain_text"]`) that this MCP tool
never actually returns — every row's title silently read as `None` in
production, so the guard always fell through to `"create"`. This doc is
updated to match that rewrite's actual I/O contract. **There is no
`stop_ambiguous` action and no `candidate_ids` field anymore** — see "Two or
more matches" below for the current behavior.

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
Capture the raw list of page objects returned — pass these **rows exactly as
the tool returned them**, without reshaping. The real row shape is a flat
dict with a `Name` string (the title, already rendered — not a REST
`properties`/`title` envelope) and a `url` string (the row's only
identifier; there is no bare `id` field). The guard script's own `title_of()`
is the single choke point that reads `row["Name"]` — do not pre-parse the
title yourself.

You do not need to log the raw row count yourself before calling the guard
script — the guard's own output includes `raw_rows` (see Step C), which is
this exact same count, always present regardless of match outcome. Logging
it a second time here would be redundant with the guard's own `log_line`.

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
fall back to the literal exact-title-match logic described in "Fallback
logic" below, and note in your output that the guard script was
unavailable.)

The script returns JSON:
```json
{
  "action": "reuse" | "create",
  "page_id": "<id or null>",
  "title": "YYYY-MM-DD - Daily",
  "target_date": "YYYY-MM-DD",
  "match_count": <int>,
  "raw_rows": <int>,
  "duplicate_ids": ["<id>", ...],
  "log_line": "[COS-GUARD] date=... matches=... raw_rows=... action=..."
}
```

- `action` is only ever `"reuse"` or `"create"` — there is no third value.
- `page_id` is the matching row's `url` (the row's only identifier) when
  `action == "reuse"`; `null` when `action == "create"`.
- `raw_rows` is the total number of rows the query returned (any date) —
  cheap, always-present observability. If this is unexpectedly 0 or far
  lower than expected, that's a sign the view query itself misfired
  (pagination cut off, wrong/stale view id) — a different failure mode than
  a legitimate `match_count: 0`.
- `duplicate_ids` is populated ONLY when `match_count >= 2` — every matching
  row's `url`, in the same positional order as `page_id` (which is always
  `duplicate_ids[0]` in that case).

### Step D — Print the log line, then branch

**Always print the returned `log_line` to your output before taking any
further action.** This is the visible find-count guard — it makes a future
silent miss (or a genuine duplicate) observable in the run's output/log
instead of an invisible event. When `match_count >= 2`, the `log_line` is a
loud `WARN` naming every duplicate id; otherwise it's a plain observability
line.

Then branch on `action`:

- **`"reuse"`** — use `page_id` as the Daily Brief page for the target date.
  Do not create anything. Continue with the rest of your skill's steps using
  this page id.
  - **If `match_count >= 2`** (two or more rows already titled exactly
    `"YYYY-MM-DD - Daily"` for this date — a genuine duplicate): the guard
    has already picked `page_id` for you — it is the FIRST matching row **by
    positional order in the query response array, not by creation time**
    (this MCP surface exposes no `created_time`/sortable id — see "Two or
    more matches" below). Proceed using that `page_id` as normal. Report
    `duplicate_ids` in your output so a human can do manual cleanup of the
    extra row(s) later — do **not** try to merge or delete them yourself as
    part of this step.
- **`"create"`** — call `notion-create-pages` exactly once:
  - Parent: the Daily Briefs database ID from me.md (`daily_briefs_database_id`)
  - Title (Name property): the returned `title` (`"YYYY-MM-DD - Daily"`)
  - Date property: the returned `target_date`
  - Status: `"Draft"`
  - Save the returned page ID and continue with the rest of your skill's steps.

### Two or more matches (no `stop_ambiguous` — never aborts)

The guard never stops the run and never asks you to guess. When 2+ rows
match, it deterministically reuses the first one by **positional order in
the query response array** — explicitly NOT chronological order, because
this MCP surface has no `created_time` field, no `sorts` query parameter,
and page ids/urls are empirically NOT time-sortable (a later-created row has
been observed sorting lexically before an earlier one on the same real
payload). Positional order is the only deterministic, reproducible tiebreak
available, so that's what the guard uses — it is a real tradeoff (the
"first" row picked is not guaranteed to be the true first-created one), not
a bug.

Your job as the calling skill: print the WARN `log_line`, proceed with the
chosen `page_id` exactly as you would for a clean single match, and surface
`duplicate_ids` in your output as a flag for manual reconciliation. Never
silently drop the brief, never block write-back, never try to reconcile the
duplicates yourself in this step.

## Fallback logic (only if the guard script is unavailable)

If Bash/the guard script genuinely cannot be invoked in your environment:
query the pinned view, then match rows client-side yourself using this
exact rule:

- A row is a candidate if and only if its **`Name` (title) property is
  exactly `"YYYY-MM-DD - Daily"`** for the target date — exact string match
  only. Do not fuzzy-match, do not treat a Date-property match alone as
  sufficient (the database can contain unrelated pages someone filed in
  this DB by mistake, which may coincidentally carry a matching Date
  value), and do not special-case any other title pattern or prefix.
- If zero rows are candidates, create exactly one new page.
- If one or more rows are candidates, reuse the FIRST one **by positional
  order in the rows you received** (not by any inferred creation time —
  this surface doesn't expose one). If two or more are candidates, still
  reuse that first one (do not stop, do not ask a human first) and note
  every candidate's `url` in your output as a duplicate-cleanup flag.

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
