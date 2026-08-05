---
name: setup
description: >
  Use when the user wants to configure the Chief of Staff plugin, set up COS,
  or when config is missing at ${CLAUDE_PLUGIN_DATA}/me.md. Walks through timezone,
  email accounts, email domains, Notion databases, and creates config.
---

# Chief of Staff — Setup

Walk the user through configuring the Chief of Staff plugin. This creates the personal config file at `${CLAUDE_PLUGIN_DATA}/me.md`.

## Step 1: Check Prerequisites

Verify required tools are available before proceeding.

### 1a: Google Workspace CLI

Test with:
```bash
gws calendar +agenda --today
```

- If "command not found": guide the user to install (`npm install -g @googleworkspace/cli`) and authenticate (`gws auth setup`). Wait for completion before continuing.
- If auth error: guide the user to run `gws auth login`. Wait for completion before continuing.
- If successful: proceed.

### 1b: Notion MCP

Check if Notion MCP tools are available (e.g., `notion-fetch`). If not available, note that Notion features will be skipped. Setup can still proceed — Notion is optional.

## Step 2: Detect Existing Config

Check for existing configuration to determine the setup path:

1. **`${CLAUDE_PLUGIN_DATA}/me.md` exists** → ask: "Config found. Use existing config or re-run setup?"
   - If use existing: validate all required sections are present (Identity, Email Accounts, Email Monitoring, Notion modules, My Rules). Report any missing sections and offer to fill gaps. Skip to the first missing section.
   - If re-run: copy existing to `${CLAUDE_PLUGIN_DATA}/me.md.bak` as backup, then proceed to Step 3.

2. **`${CLAUDE_PLUGIN_DATA}/me.md` does NOT exist but `${CLAUDE_PLUGIN_DATA}/config.md` exists** → migration from previous plugin version.
   - Ask: "Found existing COS config. Migrate to the new format?"
   - If yes: read config.md, convert to me.md format (add Email Accounts section, rename Hard Rules to My Rules), write as me.md. Say "Config migrated successfully." Then check for missing sections — if `## Notion: Tasks` or `## Email Accounts` are absent, jump to Steps 4b and 5c to fill the gaps.
   - If no: proceed to Step 3.

3. **`${CLAUDE_PLUGIN_DATA}/me.md` does NOT exist but `~/.claude/skills/cos/config.md` exists** → migration from legacy standalone install.
   - Ask: "Found legacy COS config. Migrate to the plugin?"
   - If yes: same migration as scenario 2 but reading from the legacy path.
   - If no: proceed to Step 3.

4. **None of the above exist** → fresh install. Proceed to Step 3.

## Step 3: Identity

### 3a: Timezone

Detect the user's timezone from the system if possible. Confirm:
> "Your system timezone appears to be [detected]. Is that correct, or would you prefer a different timezone?"

### 3b: Role

Ask:
> "In one or two sentences, what do you do? This helps me understand what 'needs your brain' means for you."

## Step 4: Email Monitoring

### 4a: Domains

Ask:
> "What email domains should I monitor? These are the domains of people whose emails matter most — clients, partners, key contacts. Format: `domain.com | label`"
>
> Example:
> ```
> acme.com | client - Acme Corp
> partner.io | partner - PartnerCo
> ```

### 4b: Additional Accounts

Ask:
> "Do you send email from any account besides your primary Google account? For example, a work email you access through Outlook or another client."

For each additional account:
- Ask for account label (e.g., "work-outlook", "client-email")
- Ask for the domain
- Ask for send instructions (e.g., "Copy and paste into Outlook")

These become "unconnected" accounts in the config. The primary Google account (authenticated via `gws`) is automatically a "connected" account.

## Step 5: Notion Databases

Skip this entire step if Notion MCP is not available (noted in Step 1b).

### 5a: Projects

> "Do you have a Projects database in Notion? I can pull active projects into your daily brief."

If yes:
- Help them find the database (search Notion)
- Confirm the database ID
- Ask which statuses mean "active" (e.g., "In Progress, Planning, Waiting, Blocked, Backlog")
- Ask which fields to display (e.g., "Project, Status, Deadline, Client, Owner")

If no: set `enabled: false`.

### 5b: Pipeline / Content

> "Do you have a content pipeline or editorial calendar in Notion?"

If yes:
- Help find the database
- Confirm database ID
- Ask for the status field name and active statuses
- Ask for date fields to track (e.g., "Due Date, Go Live")

If no: set `enabled: false`.

### 5c: Tasks

> "Do you have a Tasks database in Notion? This is where the evening review will create tomorrow's tasks."

If yes:
- Help find the database
- Confirm database ID
- Ask: "What should I call the default project for personal tasks (health, errands, etc.)?" Default: "Personal Tasks"

If no: set `enabled: false`.

### 5d: Clients

> "Do you have a Clients or CRM database in Notion? I can pull email domains from client records to expand monitoring."

If yes:
- Help find the database
- Confirm data source URL

If no: set `enabled: false`.

### 5e: Daily Briefs

> "I need a Daily Briefs database to save your sweep outputs. I can create one for you, or connect to an existing one. What would you prefer?"

If creating new:
- Create the database with properties: Name (title), Date (date), Status (select: Planned, Draft, Active, Complete, Reviewed), Red Count (number), Yellow Count (number), Planned Items (number), Completed Items (number)
- Note: Completion Rate formula property may need to be added manually by the user
- Save the database ID
- Create or select a dedicated, unfiltered database view sorted by Date descending. Save its view ID as `daily_briefs_view_id`; the deterministic Daily Brief Guard requires it.

If connecting existing: confirm the database ID, then select a dedicated, unfiltered view sorted by Date descending and save its view ID as `daily_briefs_view_id`.

If skip: sweep outputs will only appear in conversation.

## Step 6: Rules

### 6a: Personal Rules

> "I have some core safety rules built in (like never sending email without your review). But you can add your own rules too. Common ones people add:"
> - NEVER make pricing or scope decisions for [your business]
> - NEVER auto-schedule work on [rest day] (e.g., Sunday)
> - [Anything else specific to how you work]
>
> "What rules would you like to add? You can always edit these later."

### 6b: Custom Rules

> "Any other standing instructions? Things like 'ignore alerts from system X' or 'always check Y before Z'?"

## Step 7: Write Config

Write the config to `${CLAUDE_PLUGIN_DATA}/me.md` in this format:

```
# me.md

## Identity
timezone: [timezone]
role: [role description]

## Email Accounts
connected:
  - gmail | primary Google account (via gws CLI)
unconnected:
  - [label] | [description] | [send instructions]

## Email Monitoring
domains:
  - [domain1] | [label1]
  - [domain2] | [label2]

## Notion: Projects
enabled: [true/false]
database_id: [id]
active_statuses: [statuses]
fields: [fields]

## Notion: Pipeline
enabled: [true/false]
database_id: [id]
status_field: [field]
active_statuses: [statuses]
date_fields: [fields]

## Notion: Clients
enabled: [true/false]
data_source: [collection://id]

## Notion: Tasks
enabled: [true/false]
database_id: [id]
default_personal_project: [name]

## Notion: Daily Briefs
enabled: [true/false]
database_id: [id]
daily_briefs_view_id: [id of dedicated unfiltered Date-descending view]

## My Rules
- [user's personal rules]

## Custom Rules
- [user's custom rules]
```

Tell the user: "Config saved. You can edit it anytime — it's human-readable markdown. This file lives in the plugin's data directory and survives plugin updates."
