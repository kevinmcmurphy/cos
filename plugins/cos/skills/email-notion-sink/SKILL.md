---
name: email-notion-sink
description: >
  Notion task creation and Daily Brief section write for email triage.
  Takes classified threads and draft results from email-voice-draft and
  writes to Notion Tasks DB and the Daily Brief page.
---

# Email Notion Sink

Handles Steps 7–8 of the email triage workflow: Notion task creation and Daily Brief section append/supersede. Takes the full handoff shape from `email-voice-draft` as input.

## Before You Start

Load the `Always` entries from `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md` — [[agent-logic/config-loading]] and [[agent-logic/core-rules]]. Both are required every run; never defer them.

Load on demand from the same index as this skill reaches them: [[agent-logic/notion-writeback]], [[agent-logic/task-creation]], [[agent-logic/email-routing]].

From `${CLAUDE_PLUGIN_ROOT}/references/email-triage.md`, load [[email-triage/notion-tasks]], [[email-triage/output-format]], and [[email-triage/handoff-contract]].

## Input Shape

Receives from `email-voice-draft`:
```json
{
  "daily_brief_page_id": "<notion-page-id or null>",
  "classified_threads": [
    {
      "threadId": "<gmail-thread-id>",
      "label": "<GPS display name or null>",
      "sender": "<sender-email>",
      "subject": "<subject-line>"
    }
  ],
  "skip_count": N,
  "scope_count": N,
  "draft_results": [
    {
      "threadId": "<gmail-thread-id>",
      "draftId": "<gmail-draft-id or null>",
      "status": "created | skipped_existing | skipped_collision_check_failed | skipped_cap | no_draft_needed"
    }
  ]
}
```

## Step 1: Notion Task Creation (Action Needed only)

For each thread in `classified_threads` where `label == "! Action Needed (klmc)"`:

If `## Notion: Tasks` is enabled in me.md, follow the Notion Task Creation logic in `email-triage.md`:

1. **Dedup:** Query the Tasks DB for any task (regardless of status — open or closed) with `Gmail Thread ID` property = this thread's `threadId`. If found, log `task already exists for this thread (Gmail Thread ID: [threadId])` and skip creation. This handles closed and reopened tasks idempotently.

2. **Create task** per the Task Creation pattern in `agent-logic.md`:
   - **Title**: email subject with `Re:` / `Fwd:` prefixes stripped
   - **Gmail Thread ID**: `threadId` (for future dedup)
   - **Gmail Thread URL**: `https://mail.google.com/mail/u/0/#inbox/<threadId>`
   - **Deadline**: today's date in user's timezone
   - **Status**: `Not Started`
   - **Project**: matched from sender domain → Projects DB → Clients DB if enabled; else `default_personal_project` from me.md
   - **Description**: email subject only — no inbound message body snippet
   - Log each task in the "Outputs" section of the Daily Brief per Task Creation in `agent-logic.md`.

If Tasks is not enabled: no task creation. Items still surface in the Email Triage output.

## Step 2: Write to Daily Brief Page

**This skill never runs the Daily Brief Guard procedure and never calls `notion-create-pages` for the Daily Brief page.** It only ever consumes the `daily_brief_page_id` it was handed in its input shape (originating from morning-sweep, evening-review, or email-classify's Step 2). If that id is null, skip this entire step — do not attempt to find or create a page yourself.

If `daily_brief_page_id` is not null and Daily Briefs is enabled:

**Supersede behavior.** Find the existing `Email Triage` section on the Daily Brief page. If found, replace its entire body content with the new output (update the timestamp in the heading). If not found, create the section. The section heading is `Email Triage — HH:MM ET`. Do not append a new section on each run — replace the existing one.

Write the output block formatted per the Output Format section of `email-triage.md`.

For each Gmail draft created (status `created` in `draft_results`), also add a row to the "Drafts: Gmail" section of the Daily Brief per Email Draft Routing in `agent-logic.md`.

For each task created in Step 1, log in the "Outputs" section per Task Creation in `agent-logic.md`.

The Notion Write-Back Rule applies: write incrementally as actions complete.

## Step 3: Present in Conversation

Output the Email Triage block in conversation, formatted per the Output Format section of `email-triage.md`. Voice and Style per `agent-logic.md` — direct, scannable, no filler.

End with one closing line:
- If any `! Action Needed (klmc)` items: `[N] item(s) need your eyes. Drafts are in Gmail — review and send when you're ready.`
- If only routine triage happened: `Triage complete. [N] drafts ready for review.`
- If nothing actionable: `Inbox is clean — no new action items.`
