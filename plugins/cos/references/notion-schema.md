# COS Daily Briefs — Notion Schema

## Database Properties

| Property        | Type    | Values / Notes                                              |
|-----------------|---------|-------------------------------------------------------------|
| Name            | title   | "YYYY-MM-DD" (date of the day this brief covers)           |
| Date            | date    | Brief date (ISO 8601)                                       |
| Status          | select  | Planned, Draft, Active, Complete, Reviewed                  |
| Red Count       | number  | Count of RED items                                          |
| Yellow Count    | number  | Count of YELLOW items                                       |
| Planned Items   | number  | Count of RED + YELLOW + GREEN items planned (excludes GRAY) |
| Completed Items | number  | Count of items resolved by end of day                       |
| Completion Rate | formula | `if(prop("Planned Items") > 0, prop("Completed Items") / prop("Planned Items") * 100, 0)` |

### Status Lifecycle

**Pre-planned path** (evening review done the night before):
`Planned` → `Active` → `Complete` → `Reviewed`

**Cold start path** (no evening review):
`Draft` → `Active` → `Complete` → `Reviewed`

| Status   | Set By         | Meaning                                          |
|----------|----------------|--------------------------------------------------|
| Planned  | Evening review | Tomorrow's plan written, tasks created           |
| Draft    | Morning sweep  | Page created without evening review (cold start) |
| Active   | Morning sweep  | Sweep running, executing items                   |
| Complete | Morning sweep  | All execution done, outputs logged               |
| Reviewed | Evening review | Accountability review done, day closed out       |

## Page Body Structure

Write the page body with these sections in order, using Notion heading blocks. Not all sections will be present on every page — each section is written by the skill that owns it.

### 1. Plan (written by evening review)

The pre-classified plan for the day. Written the evening before.
Use Notion paragraph blocks. Use bold for section headers within the plan.

Contents:
- Calendar preview for the planned day
- Classified items (RED/YELLOW/GREEN/GRAY) in standard brief format
- Capacity check
- Brain dump context from the evening

This section only exists on pages created by the evening review (status starts as `Planned`). Cold-start pages skip this section.

### 2. Morning Brief (written by morning sweep)

The full classified brief from the morning sweep.
Use Notion paragraph blocks. Use bold for section headers within the brief (CALENDAR TODAY, RED - YOURS, etc.)

If a Plan section exists, the morning brief notes changes since the evening plan:
`Changes since last night: [summary of new items/changes]`

### 3. Drafts: [Connected Account]

For each connected email account that had drafts created, add a section with the account label as the heading.
Bulleted list of drafts created during the sweep.
Format each as: "**To:** [recipient] — **Subject:** [subject] — Draft created in [tool name]"

Repeat this section for each connected account that had drafts (e.g., "Drafts: Gmail", "Drafts: Outlook").

### 4. Drafts: [Unconnected Account]

For each unconnected email account that needs drafts, add a section with the account label as the heading.
For each draft, create a heading_3 block with the subject line, then a code block containing:

```
To: recipient@example.com
Subject: The subject line

Body of the email here.
```

Include the send instructions from me.md so the user knows how to send (e.g., "Copy and paste into Outlook").

Repeat this section for each unconnected account that had drafts.

### 5. Outputs

Any structured outputs from the sweep:
- Expense data: use Notion code blocks with CSV content
- Checklists: use Notion to_do blocks
- Action items: use Notion bulleted_list blocks
- Notion updates: use Notion bulleted_list blocks describing what was changed
- Tasks created: use Notion bulleted_list blocks with task name and linked project

### 5.5. Email Triage (appended by email-triage skill)

Written by the `email-triage` skill — either standalone, or when invoked as a sub-step of morning-sweep or evening-review.

This section can appear multiple times per day. Each run appends a new subsection titled `Email Triage — HH:MM ET` (timestamp in user's timezone). Never overwrite a prior run's subsection.

Each subsection contains the GPS-classified inbox state, counts per label, drafts created, and Notion tasks created for `! Action Needed (Kevin)` items. Format is defined in the "Output Format" section of `${CLAUDE_PLUGIN_ROOT}/references/email-triage.md`.

Drafts created during triage also appear in the "Drafts: Gmail" section (per Email Draft Routing). Tasks created during triage also appear in the "Outputs" section (per Task Creation). The Email Triage section itself is a summary view — it duplicates those entries on purpose so Kevin can see the full triage state in one place.

### 6. Evening Review (appended by evening review)

Written at end of day by the evening review skill.

Contents:
- **Accountability Scorecard** — Planned vs. completed counts, completion rate, done/not-done item lists, unplanned wins
- **Pattern Check** — Multi-day completion trend (if sufficient data)
- **System Updates** — Log of all database updates made during evening review
- **Brain Dump** — User's evening brain dump (feeds into next day's plan)

## Writing to the Database

Use the Notion MCP `notion-create-pages` tool:
1. Set parent to the Daily Briefs database ID from me.md
2. Set the Name (title) property to "YYYY-MM-DD" format
3. Set Date to the appropriate date
4. Set Status to the appropriate starting status (Planned, Draft)
5. Set Red Count, Yellow Count, and Planned Items from classification results
6. Add page body content as children blocks

Use `notion-update-page` to transition statuses and update properties as the sweep progresses.

## Finding Existing Pages

**Always search by Date property**, not by title. This supports both old-format ("Morning Sweep — YYYY-MM-DD") and new-format ("YYYY-MM-DD") pages. Query the Daily Briefs database filtering by Date = target date.
