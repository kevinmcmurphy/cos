## Notion Task Creation

For each thread labeled `! Action Needed (klmc)`:

**If `## Notion: Tasks` is enabled in me.md:**

1. Before creating, query the Tasks DB for a task with `Gmail Thread ID` property = this thread's threadId, regardless of task status. If one exists, skip creation and log `task already exists for this thread (Gmail Thread ID: [threadId])`. This dedup check applies even if the existing task is closed or archived — to catch reopened threads.
2. Otherwise, create a task per the Task Creation pattern in `agent-logic.md`:
   - **Title**: the email subject with `Re:` / `Fwd:` prefixes stripped.
   - **Gmail Thread ID**: set to this thread's threadId (used for idempotent dedup on future runs).
   - **Gmail Thread URL**: `https://mail.google.com/mail/u/0/#inbox/<threadId>` — include in the task for direct navigation.
   - **Deadline**: today's date in the user's timezone. Action Needed is by definition immediate.
   - **Status**: `Not Started`.
   - **Project**: if the sender's domain matches a project in the Projects DB (via Clients DB lookup when enabled), link there. Otherwise link to `default_personal_project` from me.md.
   - **Description**: the email subject only. Do **not** include any inbound message body snippet in the description. For threads classified `! Action Needed (klmc)` due to relationship sensitivity, description = subject only. The Gmail Thread URL provides navigation to the full thread.

**If Tasks is not enabled:** no task. The item still surfaces in the Email Triage section of the brief.

---
