---
name: morning-sweep
description: >
  Use when the user wants to start their day, run a morning sweep, get a daily brief,
  or asks "what's on my plate today". Scans calendar, email, and Notion, classifies
  items by priority, and executes on command.
---

# Morning Sweep - Chief of Staff

You are the user's Chief of Staff. Your job is to pull together everything they need to see this morning, classify it, surface loose ends, and give them a prioritized plan for the day.

## Before You Start

Load config and apply all rules per `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md`.

## Step 0: Find or Create Daily Brief Page — Detect Path

If `## Notion: Daily Briefs` is enabled in me.md:

1. **Search by Date property** (not title). Query the Daily Briefs database for a page with Date = today. This finds both old-format ("Morning Sweep — YYYY-MM-DD") and new-format ("YYYY-MM-DD") pages.

2. **Branch based on what you find:**
   - **Page found with Status = "Planned"** → This day was pre-planned by an evening review. Follow the **Pre-planned Path** below.
   - **Page found with any other status** → Reuse that page. Check the **fallback** below, then follow the **Cold Start Path**.
   - **No page found** → Check the **fallback** below. Create a new page titled "YYYY-MM-DD" with Date = today, Status = "Draft". Follow the **Cold Start Path**.

3. **Fallback — detect partial evening review:** If no "Planned" page exists for today, query for the most recent Daily Brief page with Status = "Reviewed" and Date within the last 48 hours. If found, set an internal flag `evening_review_detected = true`. This flag signals Steps C0.5, C2, and C4.5 that an evening review ran even though the Pre-planned Path wasn't triggered. The Cold Start Path will use this flag to pull evening review context, skip/shorten the brain dump, and present material changes before executing.

4. Save the page ID — you'll update this page throughout the sweep.

See `${CLAUDE_PLUGIN_ROOT}/references/notion-schema.md` for page structure and writing instructions.

The Notion Write-Back Rule from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md` applies to all subsequent steps.

If the Daily Briefs module is not enabled, skip all page management, write-backs, and page status updates. Outputs will only appear in the conversation. Follow the Cold Start Path but skip any steps that reference the Daily Brief page.

---

## Pre-planned Path

Use this path when the evening review already planned today. The plan exists on the Daily Brief page and tasks are already in the Tasks DB. Goal: refresh data, update classifications, and execute immediately.

### Step P1: Gather Fresh Data (parallel)

Use the Data Gathering steps from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md` to pull:
- Calendar today + tomorrow
- Email scan (last 48 hours)
- Notion projects + pipeline

**Additionally:** Query the Tasks DB for tasks with Deadline = today and Status != Done/Archive. These are the pre-planned tasks from last night's evening review.

### Step P2: Review Carryover

Query the Tasks DB for tasks with Deadline < today and Status not in (Done, Archive, Dropped). These are overdue tasks that need attention.

**Contract note:** The evening review (Step 4 and Step 5) is responsible for ensuring all carryover-worthy items become tasks in the Tasks DB. This means the pre-planned path can safely rely on Tasks DB alone for carryover — no need to parse previous Daily Brief pages.

Apply carryover aging rules from `${CLAUDE_PLUGIN_ROOT}/references/classification.md`:
- Tasks overdue by 3+ days → escalate classification
- Label as `[overdue from YYYY-MM-DD]`

**GRAY item aging:** Additionally, query the Tasks DB for tasks with titles starting with `[GRAY]` and Deadline <= today. For each:
- Count consecutive days deferred: check how many previous Daily Brief pages (up to 5 most recent) listed this item as GRAY.
- If 3+ consecutive days as GRAY with no status change on the underlying project/email: bump to YELLOW. Remove `[GRAY]` prefix from the task title. Flag prominently in the brief: "[GRAY->YELLOW] [item] — deferred [N] consecutive days, needs attention."
- If < 3 days: keep as GRAY, carry forward.
- If consecutive-day count cannot be determined, default to keeping the item as GRAY and flag: "Unable to determine GRAY aging for [item] — review manually."

### Step P3: Refresh Classifications

Start from last night's plan as baseline. Layer in fresh data:
- New emails received overnight
- Calendar changes (added/cancelled meetings)
- Notion project/pipeline updates
- Overdue tasks from Step P2

Reclassify items using the framework in `${CLAUDE_PLUGIN_ROOT}/references/classification.md` if the new data warrants it. Note what changed.

### Step P4: Present Brief

Update the page status from "Planned" to "Active".

Output in this format:

```
MORNING SWEEP — [Date, Day of Week] (updated from evening plan)
Changes since last night: [summary — e.g., "2 new emails, 1 meeting cancelled"]

CALENDAR TODAY:
- [time] [event] [location if any] [PREP NEEDED if applicable]
(If heavy meeting day, note: "Heavy meeting day - limited action capacity")

CALENDAR TOMORROW (preview):
- [time] [event] [anything to prep today for tomorrow]

---

RED - YOURS ([count] items - need your brain)
- [item] | [why it's red] | [context]

YELLOW - PREP ([count] items - I'll get them 80% done)
- [item] | [what I'd do]

GREEN - HANDLE ([count] items - I can take care of these)
- [item] | [action I'd take]

GRAY - NOT TODAY ([count] items)
- [item] | [reason] | [suggested day/timeframe]

---

LOOSE ENDS SURFACED:
- [emails from key contacts with no apparent reply]
- [projects with Status=Waiting or Blocked — only if Projects module enabled]

PIPELINE:
- [items approaching due dates — only if Pipeline module enabled]

---

CAPACITY CHECK: Based on your calendar, you have roughly [X hours] of
unscheduled time today. The RED + YELLOW items above would take
approximately [Y hours]. [Assessment]
```

Only include PIPELINE if the Pipeline module is enabled. Only include project-related LOOSE ENDS if the Projects module is enabled.

**Immediately write the brief to the Daily Brief page.** Update Red Count and Yellow Count properties.

**Also write a local daily-sweep artifact** (after the Notion write is complete). See the "Local Daily-Sweep Artifact" section at the end of this skill for the exact write procedure. Write the `## Morning` section.

### Step P4.5: Email Triage Pass

Run the Email Triage workflow defined in `${CLAUDE_PLUGIN_ROOT}/skills/email-triage/SKILL.md` against today's Daily Brief page (skip its Step 2 — reuse the page ID from Step 0 here). This labels the broader inbox per the GPS taxonomy in `${CLAUDE_PLUGIN_ROOT}/references/email-triage.md`, drafts voice-matched replies for Action Needed and To Respond items, and creates Notion tasks for Action Needed (when Tasks is enabled).

The triage output appends an `Email Triage — HH:MM ET` section to today's Daily Brief page and any Action Needed items that surface here that were not already in the morning brief should be flagged in the Step P7 summary. Drafts created by triage land in the same `Drafts: Gmail` section used by the rest of the sweep.

This step is distinct from the email scan in Step P1 — that scan is monitored-domains-only and feeds RED/YELLOW/GREEN classification. The triage pass operates over the full inbox and uses the GPS taxonomy.

### Step P5: Execute GREEN Items Immediately

No waiting for "go." Start working through GREEN items right away. This is safe because the user already reviewed and approved the plan during last night's evening review. The adjustment ask at the end serves as the safety valve.

Follow Email Draft Routing and Task Creation patterns from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md`.

For each action:
- Email drafts: follow routing rules from agent-logic.md
- Notion updates: update databases, log in "Outputs" section
- Task updates: mark tasks in progress or done as appropriate

**All outputs follow the Notion Write-Back Rule** — update after each action, not at the end.

### Step P6: Prep YELLOW Items

For each YELLOW item, do the prep work:
- Draft emails (never send)
- Research and summarize findings
- Prepare meeting notes or agendas
- Write up options for the user to decide on

Write all prep work to the Daily Brief page as you go.

### Step P7: Finalize and Ask for Adjustments

After all GREEN and YELLOW items are processed:
1. Verify the Daily Brief page has all content from incremental writes
2. Set `Completed Items` property
3. Present a summary of what was done

> "Morning sweep complete. Here's what I did: [summary of actions taken]. Anything to adjust?"

If the user adjusts: make the changes, update the Notion page.

Once adjustments are done (or the user confirms no changes): set Status to "Complete".

---

## Cold Start Path

Use this path when no evening review was done. This is the fallback — full planning from scratch.

### Step C0.5: Review Carryover

**If `## Notion: Tasks` is enabled in me.md:** Query the Tasks DB for tasks with Deadline < today and Status not in (Done, Archive, Dropped). These are overdue tasks that need attention.

**If `## Notion: Daily Briefs` is enabled in me.md:** Also query the Daily Briefs database for the most recent page where Status = "Complete" or "Reviewed" and Date < today (within the last 48 hours). If one exists:
1. Fetch its full content — scorecard, brain dump, NOT DONE items, evening review section, and plan.
2. Cross-reference with the Tasks DB to identify items that were surfaced but never acted on.
3. If the page has Status = "Reviewed" (meaning an evening review ran), or if `evening_review_detected` was set in Step 0:
   - Extract the brain dump — this feeds into the Step C2 gate (brain dump skip).
   - Extract NOT DONE items — these should already be tasks (per evening review Step 5), but verify. If any NOT DONE item has no corresponding task, create one.
   - Extract the evening review's classification — use as baseline context for Step C3 classification. Items the user was worried about last night should be weighted higher today.
4. Store this data as `evening_review_context` for use in Steps C2, C3, and C4.5.

If neither is enabled, skip this step.

Apply carryover aging rules from `${CLAUDE_PLUGIN_ROOT}/references/classification.md`:
- Tasks overdue by 3+ days → escalate classification
- Label as `[overdue from YYYY-MM-DD]`

**GRAY item aging:** Additionally, query the Tasks DB for tasks with titles starting with `[GRAY]` and Deadline <= today. For each:
- Count consecutive days deferred: check how many previous Daily Brief pages (up to 5 most recent) listed this item as GRAY.
- If 3+ consecutive days as GRAY with no status change on the underlying project/email: bump to YELLOW. Remove `[GRAY]` prefix from the task title. Flag prominently in the brief: "[GRAY->YELLOW] [item] — deferred [N] consecutive days, needs attention."
- If < 3 days: keep as GRAY, carry forward.
- If consecutive-day count cannot be determined, default to keeping the item as GRAY and flag: "Unable to determine GRAY aging for [item] — review manually."

### Step C1: Gather Context (parallel)

Use the Data Gathering steps from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md` to pull calendar, email, and Notion data.

### Step C2: Ask for Brain Dump (or Reuse Evening Review)

**Before prompting, check for a recent evening review brain dump:**

If `## Notion: Daily Briefs` is enabled and `evening_review_detected` is true (set in Step 0 / C0.5) and `evening_review_context` was populated in Step C0.5:
1. Check if the evening review context contains a brain dump.
2. If a brain dump exists:
   - Surface it: "I found your brain dump from last night's evening review: [summary]. Anything to add or change for this morning?"
   - If the user adds items, merge them with the evening brain dump.
   - If the user says nothing or confirms, proceed with the evening brain dump as context.
   - **Skip the full brain dump prompt below.**

**If no recent brain dump is found** (no evening review context, or Daily Briefs is not enabled):

Present a brief summary of what you found:
- "Found X calendar events today, Y tomorrow"
- "Found X emails from key contacts that may need attention"
- If Notion modules are enabled: "X active projects, Y pipeline items"
- If carryover items exist: "X overdue tasks carried over" (name them briefly)

Then ask:

> **What's on your mind this morning?** Anything weighing on you — deadlines, worries, things you might be forgetting, priorities for today? Just dump it here. I'll factor it into the plan.

Wait for the user's response before proceeding.

### Step C3: Classify Everything

Use the Classification Framework from `${CLAUDE_PLUGIN_ROOT}/references/classification.md`.

Take ALL inputs — calendar, email, projects, pipeline, carryover, and the user's brain dump — and classify each item.

If `evening_review_context` was populated in Step C0.5, use the evening review's classification as baseline context: items the user flagged as important last night should be weighted higher today.

### Step C4: Present the Morning Brief

Output in the standard brief format (same as Step P4 above, but without the "updated from evening plan" header and changes-since-last-night line).

If Daily Briefs is enabled: set page status to "Active", write the brief to the page, set Red Count, Yellow Count, and Planned Items properties.

**Also write a local daily-sweep artifact** (after the Notion write is complete). See the "Local Daily-Sweep Artifact" section at the end of this skill for the exact write procedure. Write the `## Morning` section.

### Step C4.5: Material Change Check (if evening review context exists)

**If `evening_review_context` was populated in Step C0.5** (meaning an evening review ran recently):
1. Compare the fresh classification from Step C3 against the evening review's plan.
2. Determine if there are **material changes** (defined in `${CLAUDE_PLUGIN_ROOT}/references/classification.md`).
3. **If no material changes:** Add to the brief output: "Plan matches last night's review — no material changes." Proceed to Step C5 (Execute GREEN).
4. **If material changes exist:** Present them explicitly before executing: "Since last night: [list changes — e.g., '1 new RED item: [describe]', '1 meeting cancelled: [describe]', 'GRAY item [X] promoted to YELLOW (3-day aging)']." Then proceed to Step C5.

**If no evening review context:** Proceed to Step C5 immediately per the Immediate Execution Rule.

**Note:** This step does NOT reintroduce a "go" gate. Execution proceeds regardless. The purpose is transparency — Kevin should know whether the plan changed overnight, even though the system will execute either way.

### Step C4.6: Email Triage Pass

Run the Email Triage workflow defined in `${CLAUDE_PLUGIN_ROOT}/skills/email-triage/SKILL.md` against today's Daily Brief page (skip its Step 2 — reuse the page ID from Step 0 here). This labels the broader inbox per the GPS taxonomy in `${CLAUDE_PLUGIN_ROOT}/references/email-triage.md`, drafts voice-matched replies for Action Needed and To Respond items, and creates Notion tasks for Action Needed (when Tasks is enabled).

The triage output appends an `Email Triage — HH:MM ET` section to today's Daily Brief page. Any Action Needed items that surface here but were not in the morning brief should be flagged in the Step C7 summary so Kevin sees what came in beyond the monitored-domains scan from Step C1.

### Step C5: Execute GREEN Items

Follow Email Draft Routing and Task Creation patterns from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md`.

Work through all GREEN items.

### Step C6: Prep YELLOW Items

Same as Step P6.

### Step C7: Finalize and Ask for Adjustments

After all GREEN and YELLOW items are processed:
1. If Daily Briefs is enabled: verify the page has all content, set `Completed Items` property
2. Present a summary of what was done
3. Ask: "Morning sweep complete. Here's what I did: [summary]. Anything to adjust?" (Add "Daily brief saved in Notion." if Daily Briefs is enabled.)

If the user adjusts: make the changes, update the Notion page.

Once adjustments are done (or the user confirms no changes): if Daily Briefs is enabled, set Status to "Complete".

---

## Local Daily-Sweep Artifact

This section defines the local artifact write procedure. It is invoked at the points marked in Steps P4 and C4 above. Execute it after all Notion and Telegram writes for the morning sweep are complete. The local artifact is **non-fatal** — if any file operation fails, report the error in your final summary to Kevin but do not retry and do not unwind any prior writes.

### Repo Root Resolution

Resolve `REPO_ROOT` using this priority order:
1. Check environment variable `$KLMC_REPO`. If set and the path contains `agents/registry.yaml`, use it.
2. Check `/Users/kevin/Projects/klmc-agent-home`. If it exists and contains `agents/registry.yaml`, use it.
3. Fall back to `./` (current working directory). Note in final summary: "Local artifact written to ./reports/daily-sweeps/ — repo root could not be auto-detected."

### Paths

```
YMD  = current date in America/New_York  (format: YYYY-MM-DD)
DIR  = $REPO_ROOT/reports/daily-sweeps
FILE = $DIR/$YMD.md
LINK = $DIR/latest.md
```

### Write Steps

1. Run: `/bin/mkdir -p "$DIR"`

2. **Rotate on same-day re-run:** If `$FILE` already exists, run:
   `/bin/mv "$FILE" "$DIR/$YMD.prev.md"`
   (This overwrites any older `.prev.md`. It is a crash-recovery safety net, not an archive.)

3. Write `$FILE` with the following content. Fill each bracketed field from context you already have in this session. If a field value is unavailable, write `_unavailable_`. For empty list subsections, write `_none_` under the heading rather than omitting the heading.

```
---
date: YYYY-MM-DD
timezone: America/New_York
created_by: cos:morning-sweep
created_at: YYYY-MM-DDTHH:MM:SS-HH:MM
---

# Daily Sweeps — YYYY-MM-DD

## Morning

- **Run at:** YYYY-MM-DD HH:MM ET
- **Skill:** cos:morning-sweep
- **Notion brief:** https://www.notion.so/PAGE-ID-WITHOUT-DASHES
- **Telegram message id:** MESSAGE_ID

### Classified Items

#### RED — Yours
- ITEM — WHY

#### YELLOW — Prep
- ITEM — WHAT WAS PREPPED

#### GREEN — Handle
- ITEM — WHAT WAS HANDLED

#### GRAY — Not today
- ITEM — REASON

### Drafts Created

- **Gmail (kevin@klmc.co):** SUBJECT — draft id `DRAFT-ID`
- **Adapture (Notion code block):** SUBJECT — see Notion brief "Drafts: Adapture" section

### Telegram Summary Sent

```
VERBATIM TEXT OF THE SUMMARY MESSAGE SENT TO KEVIN
```

### Actions Taken

- ACTION — OUTCOME
```

   Notes on specific fields:
   - `created_at`: ISO 8601 timestamp with ET offset (e.g., `2026-05-04T07:42:00-04:00`)
   - `Notion brief` URL: derive from the Notion page ID returned by the Notion MCP — format as `https://www.notion.so/{id-without-dashes}`. If the page ID is unavailable, write `_unavailable_`.
   - `Telegram message id`: the `message_id` returned by `mcp__plugin_telegram_telegram__reply`. If unavailable (e.g., no Telegram message was sent this run), write `_unavailable_`.
   - `Classified Items`: mirror the same RED/YELLOW/GREEN/GRAY content sent to Notion. Keep one bullet per item. For empty subsections, write `_none_`.
   - `Drafts Created`: list each Gmail draft with its draft id; list each Adapture draft by subject. If no drafts were created, write `_none_` under the heading.
   - `Telegram Summary Sent`: the verbatim text string passed to the `text` parameter of `mcp__plugin_telegram_telegram__reply`. If no Telegram message was sent this run, write `_none_`.
   - `Actions Taken`: one bullet per executed action with outcome. If none, write `_none_`.

4. Update the symlink atomically. Run these two commands in sequence:
   ```
   cd "$DIR"
   /bin/ln -sfn "$YMD.md" latest.md
   ```
   Use exactly `/bin/ln -sfn` (not `rm` + `ln`). The target is a relative basename, not an absolute path.

### On Error

If step 1, 2, 3, or 4 fails:
- Do not retry.
- Do not unwind Notion or Telegram writes (they are already complete).
- Include this in your final summary to Kevin: "Local sweep artifact write failed: [error description]. Notion brief and Telegram summary were not affected."
