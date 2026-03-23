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
   - **Page found with any other status** → Reuse that page. Follow the **Cold Start Path** (the page exists but wasn't set up by an evening review).
   - **No page found** → Create a new page titled "YYYY-MM-DD" with Date = today, Status = "Draft". Follow the **Cold Start Path**.

3. Save the page ID — you'll update this page throughout the sweep.

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

Apply carryover aging rules from `${CLAUDE_PLUGIN_ROOT}/references/classification.md`.

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

### Step P5: Execute GREEN Items Immediately

No waiting for "go." Start working through GREEN items right away. This is safe because the user already reviewed and approved the plan during last night's evening review. The adjustment ask at the end serves as the safety valve.

Follow Email Draft Routing and Task Creation patterns from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md`.

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

**If `## Notion: Daily Briefs` is enabled in me.md:** Also query the Daily Briefs database for the most recent page where Status = "Complete" or "Reviewed" and Date < today. If one exists, fetch its content and cross-reference with the Tasks DB to identify items that were surfaced but never acted on.

If neither is enabled, skip this step.

Apply carryover aging rules from `${CLAUDE_PLUGIN_ROOT}/references/classification.md`.

### Step C1: Gather Context (parallel)

Use the Data Gathering steps from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md` to pull calendar, email, and Notion data.

### Step C2: Ask for Brain Dump

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

### Step C4: Present the Morning Brief

Output in the standard brief format (same as Step P4 above, but without the "updated from evening plan" header and changes-since-last-night line).

If Daily Briefs is enabled: set page status to "Active", write the brief to the page, set Red Count, Yellow Count, and Planned Items properties.

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
