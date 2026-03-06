---
name: cos:setup
description: >
  First-run onboarding for the COS Morning Sweep. Collects timezone, role,
  email domains, and optional Notion databases through a conversational flow.
  Trigger with "setup cos", "configure morning sweep", or "cos setup".
version: 0.1.0
---

# COS Morning Sweep - Setup

Walk the user through first-time setup for their Chief of Staff morning sweep. Collect their configuration through a friendly, conversational flow — one question at a time.

## Before You Start

1. **Check for existing config.** Read `${CLAUDE_PLUGIN_ROOT}/skills/cos/references/config.md`.
   - If it exists, tell the user: "You already have a COS config. Want me to re-run setup from scratch, or would you rather edit the file directly?"
   - If the user wants to re-run, continue below. If they want to edit, open the file and help them.

2. **Check MCP connections.**
   - If Gmail MCP is not available: "I need Gmail and Google Calendar to run the morning sweep. Make sure they're connected in your Claude settings, then run setup again." **Stop here.**
   - If Google Calendar MCP is not available: Same message. **Stop here.**
   - If Notion MCP is not available: Note this internally. Skip Notion steps later.

## Collect Configuration (One Question at a Time)

Ask each question, wait for the user's response, then move to the next. Present defaults wherever possible so the user can just confirm.

### A. Timezone

Try to detect the user's timezone from the system (e.g., run `date +%Z` or check system settings).

> I detected your timezone as `[detected timezone]`. Is that right, or would you like to change it?

If detection fails, ask: "What timezone are you in? (e.g., America/New_York, Europe/London)"

Store the confirmed timezone.

### B. Role Context

> In one sentence, what do you do? This helps me figure out what needs YOUR brain vs what I can handle.
>
> Example: "Solo tech consultant running an agency and three side projects"

Store their response as `role`.

### C. Email Domains

> What email domains should I monitor for important messages? These are your clients, partners, key contacts.
>
> Format: `domain.com | optional label` — one per line or comma-separated.
>
> Example: `acme.com | main client, bigcorp.com | partner`

Store the list of domains with labels.

### D. Notion: Projects (Skip if Notion MCP unavailable)

> Do you track projects in a Notion database? (y/n)

If **no**, skip to the next section.

If **yes**:
> What's the database called? I'll search your workspace for it.

Use the Notion MCP to search for the database by name. Present matches and ask the user to confirm.

If search fails or returns no matches:
> No luck finding it. Can you open the database in Notion, copy the URL from your browser bar, and paste it here?

Extract the database ID from the URL.

Then ask:
> What status values mean a project is active? Default: `In Progress, Planning, Waiting, Blocked, Backlog`

And:
> What fields should I show in the brief? Default: `Project, Status, Deadline, Client, Owner`

Store: `database_id`, `active_statuses`, `fields`.

### E. Notion: Pipeline (Skip if Notion MCP unavailable)

> Do you have a database that tracks work through stages? (content calendar, deal pipeline, task board)

If **no**, skip to the next section.

If **yes**: Same search-then-URL flow as Projects.

Then ask:
> What's the status field called? Default: `Status`

> What statuses mean it's actively in the pipeline?

> Any date fields I should watch for deadlines? (comma-separated)

Store: `database_id`, `status_field`, `active_statuses`, `date_fields`.

### F. Notion: Clients (Skip if Notion MCP unavailable)

> Do you have a Notion database of clients or contacts? This lets me automatically discover email domains to monitor.

If **no**, skip to the next section.

If **yes**: Same search-then-URL flow.

Store: `data_source` (the database ID or collection URL).

### G. Hard Rules

Present the default safety rules:

> These are the default safety rules for your morning sweep:
>
> 1. NEVER send an email. Draft only. You review every outbound message.
> 2. NEVER delete or archive anything in Gmail, Notion, or any other system.
> 3. NEVER handle relationship-sensitive communications without flagging as RED.
> 4. When uncertain about classification: default to YELLOW (prep), not GREEN (dispatch).
>
> Want to add, remove, or change any?

If the user adds rules, store them in `## Custom Rules`. If they modify defaults, update the defaults list.

## Write the Config File

After collecting all answers, generate the config file at `${CLAUDE_PLUGIN_ROOT}/skills/cos/references/config.md` using this exact format:

```markdown
# COS Configuration

## Identity
timezone: [confirmed timezone]
role: [their role description]

## Email Monitoring
domains:
  - [domain1] | [label1]
  - [domain2] | [label2]

## Notion: Projects
enabled: [true/false]
database_id: [id if enabled]
active_statuses: [comma-separated statuses]
fields: [comma-separated field names]

## Notion: Pipeline
enabled: [true/false]
database_id: [id if enabled]
status_field: [field name]
active_statuses: [comma-separated statuses]
date_fields: [comma-separated field names]

## Notion: Clients
enabled: [true/false]
data_source: [database ID or collection URL if enabled]

## Hard Rules
- [rule 1]
- [rule 2]
- [rule 3]
- [rule 4]

## Custom Rules
- [any user-added rules, or "(none)"]
```

After writing the file, tell the user:

> Config saved. You can edit it anytime.
>
> You're all set. Start your morning sweep by saying "morning sweep".

## Behavioral Rules

- **ONE question at a time.** Never batch questions together.
- **Present sensible defaults** wherever possible.
- **Graceful degradation.** If Notion MCP is not connected, skip all Notion steps: "I don't see Notion connected. No worries — the morning sweep works great with just Calendar and Gmail. You can add Notion later by running setup again."
- **Target time:** Under 5 minutes for Gmail+Calendar only, under 10 minutes with all Notion modules.
- **Be conversational, not robotic.** This is onboarding, not a form.
