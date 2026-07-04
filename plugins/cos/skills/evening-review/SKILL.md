---
name: evening-review
description: >
  Use when the user wants to close out their day, run an evening review, plan tomorrow,
  or do a brain dump for the next workday. Reviews accountability, updates project
  systems, and creates tomorrow's plan.
---

# Evening Review - Chief of Staff

You are the user's Chief of Staff. Your job is to close out the day — review what happened, update systems, capture what's on the user's mind, and plan the next workday so the morning sweep can execute immediately.

## Before You Start

Load config and apply all rules per `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md`.

## Step 0: Find or Create Today's Daily Brief Page

**If `## Notion: Daily Briefs` is enabled in me.md:**

**Run the Daily Brief Guard procedure** from `${CLAUDE_PLUGIN_ROOT}/references/daily-brief-guard.md` in full. Do not query or decide on your own. Print the guard's `log_line` before proceeding, exactly as that procedure requires.

- **If the guard's `action` was `"reuse"` and `match_count >= 2`** (a genuine duplicate): proceed with the guard's chosen `page_id` as normal — do not skip Notion write-back. Report the returned `duplicate_ids` in your output so a human can reconcile the extra row(s) later; do not try to merge/delete them yourself.
- **Either way (`reuse` or `create`), fetch/note the resulting page's Status:**
  - **Status "Reviewed":** An evening review was already done tonight. Ask: "I see an evening review was already done tonight. Update it or start fresh?" If "update," continue with the existing page. If "start fresh," proceed as normal but overwrite the evening review sections.
  - **Any other status** (including a freshly created page, which starts at "Draft"): Use that page ID. An existing page found this way should typically have status `Complete` (morning sweep finished) or possibly `Draft`/`Active` (morning sweep started but didn't finish); a newly created page means no morning sweep ran today.

The Notion Write-Back Rule from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md` applies to all subsequent steps.

**If Daily Briefs is not enabled:** Skip page management. All outputs appear in the conversation only. Skip write-back steps throughout.

## Step 1: Brain Dump

The brain dump comes before data gathering. The user's subjective experience of the day should inform how the system interprets the data, not the other way around.

Ask:

> **How was today? What's on your mind for tomorrow?** Wins, frustrations, things you're forgetting, ideas, worries — dump it all here. I'll sort it out.

Wait for the user's response before proceeding.

## Step 2: Accountability Review

Gather data automatically (in parallel where possible):

- If Daily Briefs enabled: read today's Daily Brief page for what was planned (morning brief content)
- If Tasks enabled: query Tasks DB (from me.md) for tasks with Deadline = today → which are Done vs. still open
- Check Gmail for drafts created during morning sweep:
  - If a draft is no longer in the drafts folder, check Sent folder for matching subject/recipient today
  - If found in Sent → mark as sent
  - If not found anywhere → note as "draft removed (status unknown)"
  - This is best-effort
- Check calendar — which events were on today's schedule?
- Check Notion for project/content changes made today (compare current state to morning brief state)
- Detect unplanned completions — things done that weren't in the morning plan (new tasks marked Done, emails sent that weren't drafted by the sweep, project status changes)

Calculate completion rate:
- Count planned items: RED + YELLOW + GREEN from the morning brief (or from `Planned Items` property if set)
- Count completed items: tasks marked Done, drafts sent, outputs logged
- Rate = Completed / Planned * 100

Present:

```
TODAY'S SCORECARD
Planned: X items | Completed: Y | Rate: Z% (target: 80%)

DONE
- [task/item] — completed [evidence: task marked Done / email sent / etc.]

NOT DONE
- [task/item] — [what happened or why not, if detectable]

UNPLANNED WINS (things you did that weren't in the plan)
- [detected from Notion changes, sent emails, new tasks completed, etc.]
```

After presenting, immediately write the scorecard to the "Evening Review" section of today's Daily Brief page. Update the `Completed Items` property.

## Step 3: Pattern Check

Query the 5 most recent Daily Brief pages by Date property where Status = Reviewed or Complete. Read their Completion Rate property.

- Pages without a Completion Rate (pre-dating this feature) are excluded from the calculation.
- If completion rate < 80% for 3+ of the qualifying days:
  > "Third time below 80% in the last five workdays — you may be overloading your mornings. Consider planning fewer RED/YELLOW items for tomorrow."
- If fewer than 3 qualifying days exist, skip with:
  > "Not enough data for pattern tracking yet."

Append pattern check results to the Evening Review section of the Daily Brief page.

## Step 4: Project and System Updates

Review all items from today and make database updates:

**Auto-execute (clear evidence — do these without asking):**
- Mark tasks Done in Tasks DB if evidence is clear (email was sent, meeting happened, deliverable completed)
- Update project statuses in Projects DB based on day's activity (e.g., a project with all tasks done today → update status)
- Update content pipeline dates in Content DB based on progress
- Log each update in the "Outputs" section of the Daily Brief

**Flag for confirmation (ambiguous — ask before updating):**
- Status changes that require judgment ("This project has had no activity in 2 weeks — move to Waiting?")
- Any change that involves client-facing fields, deadlines, or scope

Pricing/scope decisions, relationship-sensitive communications, and archiving/deleting are governed by the Core Rules in `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md`. Do not touch these without explicit user instruction.

Follow Email Draft Routing from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md` for any drafts created during this step.

Follow Task Creation patterns from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md` for any tasks created during this step.

## Step 4.5: Email Triage Pass

Run the email triage skill at `${CLAUDE_PLUGIN_ROOT}/skills/email-triage/SKILL.md`, passing today's Daily Brief page ID and skipping email-classify's Step 2.

## Step 5: Plan Next Workday

### Determine the Target Day

- **Monday-Thursday evening:** Plan for tomorrow.
- **Friday evening:** Plan for Monday.
- **Saturday evening:** Plan for Monday.
- **Sunday:** Protected — do not auto-schedule work tasks. If the user runs an evening review on Sunday, plan for Monday.

### Gather Data for Next Workday

Use the Data Gathering steps from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md`, but pull calendar for the **next workday** (not today/tomorrow as in the morning sweep).

### Triage Incomplete Items

For each NOT DONE item from today's scorecard:
> "Move to [next workday] or drop? [item name]"

Wait for user response on all items before classifying.

### Classify

Use the Classification Framework from `${CLAUDE_PLUGIN_ROOT}/references/classification.md`.

Inputs for classification:
- Carried-over items from today (user-approved moves from triage above)
- Brain dump priorities from Step 1
- Next workday's calendar events
- Active email threads needing response
- Project/pipeline items with approaching deadlines
- Any new items the user mentioned

Apply carryover aging rules from the classification reference.

### Present Tomorrow's Plan

```
[NEXT WORKDAY]'S PLAN — [Date, Day of Week]

CALENDAR:
- [time] [event] [prep needed?]

CAPACITY: ~X hours unscheduled

RED - YOURS ([count])
- [item] | [why]

YELLOW - PREP ([count])
- [item] | [what I'll do]

GREEN - HANDLE ([count])
- [item] | [action]

GRAY - NOT TODAY ([count])
- [item] | [reason]
```

### Create Tasks

**If `## Notion: Tasks` is enabled in me.md:** Create tasks in the Tasks DB for each RED, YELLOW, GREEN, and GRAY item that doesn't already have a task. If Tasks is not enabled, skip this substep.
- RED/YELLOW/GREEN tasks:
  - `Deadline` = next workday date
  - `Status` = Not Started
  - `Project` = linked to appropriate project
  - Personal tasks → default personal project from me.md
- GRAY tasks:
  - `Deadline` = next workday date
  - `Status` = Not Started
  - Prefix the task title with `[GRAY]` (e.g., `[GRAY] Review vendor contract`)
  - `Project` = linked to appropriate project

When GRAY tasks are created, note in the evening review output: "Created [N] GRAY tasks in Notion. These have [GRAY] prefixes that track deferral aging — please don't remove the prefix."

Follow Task Creation patterns from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md`.

## Step 6: Create Next Workday's Daily Brief Page

**If `## Notion: Daily Briefs` is enabled in me.md:**

- **Run the Daily Brief Guard procedure** from `${CLAUDE_PLUGIN_ROOT}/references/daily-brief-guard.md`, using the **next workday's date** (not today's) as the target date throughout. This is the same deterministic procedure Step 0 uses — it is not "today"-specific, it works for any target date. Print the guard's `log_line`. The guard's `action` is always `"reuse"` or `"create"` — if `"reuse"` with `match_count >= 2` (a genuine duplicate), proceed with the guard's chosen `page_id` as normal and report the returned `duplicate_ids` for later human reconciliation; do not skip this page's write-back.
- Write the plan from Step 5 to the "Plan" section (see page body structure in `${CLAUDE_PLUGIN_ROOT}/references/notion-schema.md`)
- Set page status to "Planned"
- Set `Planned Items` property to total RED + YELLOW + GREEN count
- When creating OR updating the next workday's Daily Brief page, ALWAYS set these properties from the Step 5 classification:
  - **Red Count** (number): Count of items classified RED in the plan
  - **Yellow Count** (number): Count of items classified YELLOW in the plan
  - These properties MUST be set on every write to the next-workday page — whether creating a new page or updating an existing one. The morning sweep's Pre-planned Path reads these values to build the priority summary. Stale or missing counts cause incorrect priority totals.
- Set Date to next workday's date

**If Daily Briefs is not enabled:** Skip this step. The plan was already presented in conversation.

## Step 7: Update Today's Page

**If Daily Briefs is enabled:**
- Append all evening review content to today's page (if not already written via incremental write-backs): accountability scorecard, brain dump, pattern notes, list of system updates made
- Set today's page status to "Reviewed"

If not enabled, skip.

**Also write a local daily-sweep artifact** (after today's Notion page is updated). See `${CLAUDE_PLUGIN_ROOT}/references/daily-sweep-artifact.md` for the shared procedure. Write the `## Evening` section using the template below.

## Step 8: Finalize

If Daily Briefs is enabled:
> "[Next workday]'s plan is in Notion — you can preview it anytime. Morning sweep will refresh and execute. Good night."

If not enabled:
> "Tomorrow's plan is ready. Morning sweep will gather fresh data and execute. Good night."

---

## Local Daily-Sweep Artifact

See `${CLAUDE_PLUGIN_ROOT}/references/daily-sweep-artifact.md` for the shared repo root resolution, paths, mkdir/rotate/symlink steps, and On Error handling.

Invoke the shared procedure at the point marked in Step 7. Execute it after all Notion and Telegram writes for the evening review are complete.

Write the `## Evening` section using this template:

```
## Evening

- **Run at:** YYYY-MM-DD HH:MM ET
- **Skill:** cos:evening-review
- **Notion brief:** https://www.notion.so/PAGE-ID-WITHOUT-DASHES
- **Telegram message id:** MESSAGE_ID

### Brain Dump

VERBATIM OR SUMMARIZED BRAIN DUMP FROM STEP 1

### Scorecard

- **Planned:** X items
- **Completed:** Y items
- **Rate:** Z% (target: 80%)
- **Pattern note:** PATTERN CHECK RESULT FROM STEP 3

### Tomorrow's Plan

SUMMARY OF THE NEXT WORKDAY PLAN FROM STEP 5 (RED/YELLOW/GREEN/GRAY counts and key items)

### Telegram Summary Sent

```
VERBATIM TEXT OF THE SUMMARY MESSAGE SENT TO KEVIN
```

### Actions Taken

- ACTION — OUTCOME
```

Field notes:
- `Notion brief` URL: derive from today's Daily Brief page ID — format as `https://www.notion.so/{id-without-dashes}`.
- `Telegram message id`: the `message_id` returned by `mcp__plugin_telegram_telegram__reply` for the evening summary. If no Telegram message was sent, write `_unavailable_`.
- `Brain Dump`: verbatim or lightly condensed version of what the user shared in Step 1.
- `Scorecard`: pull from the Step 2 accountability review output.
- `Pattern note`: the one-sentence result from Step 3.
- `Tomorrow's Plan`: condensed summary — RED count, YELLOW count, GREEN count, GRAY count, and top 2–3 RED items by name.
- `Telegram Summary Sent`: verbatim text passed to `text` parameter of the reply tool. If none, write `_none_`.
- `Actions Taken`: one bullet per system update or task creation from Steps 4–6. If none, write `_none_`.
