---
name: cos-setup
description: >
  Use when the user wants to configure the Chief of Staff plugin, set up COS,
  or when config is missing at ${CLAUDE_PLUGIN_DATA}/me.md. Walks through timezone,
  email accounts, email domains, Notion databases, and creates config.
---

# Chief of Staff — Setup

Walk the user through configuring the Chief of Staff plugin. This creates the personal config file at `${CLAUDE_PLUGIN_DATA}/me.md`.

## Step 0: Detect Config State

Before starting setup, check for existing configuration:

1. **If `${CLAUDE_PLUGIN_DATA}/me.md` exists** → Scenario C (existing config)
   - Ask: "Config found. Use existing config or re-run setup?"
   - If use existing: validate all required sections are present (Identity, Email Accounts, Email Monitoring, Notion modules, My Rules). Report any missing sections and offer to fill gaps.
   - If re-run: copy existing to `${CLAUDE_PLUGIN_DATA}/me.md.bak` as backup, then proceed to Step 1.

2. **If `${CLAUDE_PLUGIN_DATA}/me.md` does NOT exist but `${CLAUDE_PLUGIN_DATA}/config.md` exists** → Scenario B1 (migration from previous plugin version)
   - Ask: "Found existing COS config. Migrate to the new format?"
   - If yes: read config.md, convert to me.md format (add Email Accounts section, rename Hard Rules to My Rules), write as me.md. Verify. Say "Config migrated successfully."
   - Check if config has `## Notion: Tasks` section. If missing, run just the Tasks setup step (Step F below).
   - Check if config has `## Email Accounts` section. If missing, run just the Email Accounts setup step (Step C1 below).
   - If no: proceed to Step 1 (full setup).

3. **If `${CLAUDE_PLUGIN_DATA}/me.md` does NOT exist but `~/.claude/skills/cos/config.md` exists** → Scenario B2 (migration from legacy standalone install)
   - Ask: "Found legacy COS config at ~/.claude/skills/cos/config.md. Migrate to the plugin?"
   - If yes: same migration as Scenario B1 but reading from the legacy path.
   - If no: proceed to Step 1 (full setup).

4. **If none of the above exist** → Scenario A (fresh install)
   - Proceed to Step 1.

## Step 1: Full Setup Flow

The plugin data directory at `${CLAUDE_PLUGIN_DATA}` is created automatically when first referenced.

### Step A: Timezone

Detect the user's timezone from the system if possible. Confirm with them:
> "Your system timezone appears to be [detected]. Is that correct, or would you prefer a different timezone?"

### Step B: Role Context

Ask:
> "In one or two sentences, what do you do? This helps me understand what 'needs your brain' means for you."

### Step C1: Email Accounts

Ask:
> "Let's set up your email accounts. For each account, I need to know if you have an MCP tool connected for it (like Gmail MCP or Outlook MCP) — that determines whether I can create drafts directly or need to write them as copyable blocks."

For each account:
- Ask for account label (e.g., "gmail", "work-outlook")
- Ask if there's an MCP tool connected for it (connected vs unconnected)
- If connected: note which MCP tool
- If unconnected: ask for the domain and send instructions (e.g., "Copy and paste into Outlook")

### Step C2: Email Monitoring Domains

Ask:
> "What email domains should I monitor? These are the domains of people whose emails matter most — clients, partners, key contacts. Format: `domain.com | label`"
>
> Example:
> ```
> acme.com | client - Acme Corp
> partner.io | partner - PartnerCo
> ```

### Step D: Notion — Projects Database

If the Notion MCP is available:
> "Do you have a Projects database in Notion? I can pull active projects into your daily brief."

If yes:
- Help them find the database (search Notion)
- Confirm the database ID
- Ask which statuses mean "active" (e.g., "In Progress, Planning, Waiting, Blocked, Backlog")
- Ask which fields to display (e.g., "Project, Status, Deadline, Client, Owner")

If no: skip, set `enabled: false`.

### Step E: Notion — Pipeline/Content Database

> "Do you have a content pipeline or editorial calendar in Notion?"

If yes:
- Help find the database
- Confirm database ID
- Ask for the status field name and active statuses
- Ask for date fields to track (e.g., "Due Date, Go Live")

If no: skip, set `enabled: false`.

### Step F: Notion — Tasks Database

> "Do you have a Tasks database in Notion? This is where the evening review will create tomorrow's tasks."

If yes:
- Help find the database
- Confirm database ID
- Ask: "What should I call the default project for personal tasks (health, errands, etc.)?" Default: "Personal Tasks"

If no: skip, set `enabled: false`.

### Step G: Notion — Clients Database

> "Do you have a Clients or CRM database in Notion? I can pull email domains from client records to expand monitoring."

If yes:
- Help find the database
- Confirm data source URL

If no: skip, set `enabled: false`.

### Step H: Notion — Daily Briefs Database

> "I need a Daily Briefs database to save your sweep outputs. I can create one for you, or connect to an existing one. What would you prefer?"

If creating new:
- Create the database with properties: Name (title), Date (date), Status (select: Planned, Draft, Active, Complete, Reviewed), Red Count (number), Yellow Count (number), Planned Items (number), Completed Items (number)
- Note: Completion Rate formula property may need to be added manually by the user
- Save the database ID

If connecting existing: confirm the database ID.

If skip: sweep outputs will only appear in conversation.

### Step I: Personal Rules

> "I have some core safety rules built in (like never sending email without your review). But you can add your own rules too. Common ones people add:"
> - NEVER make pricing or scope decisions for [your business]
> - NEVER auto-schedule work on [rest day] (e.g., Sunday)
> - [Anything else specific to how you work]
>
> "What rules would you like to add? You can always edit these later."

### Step J: Custom Rules

> "Any other standing instructions? Things like 'ignore alerts from system X' or 'always check Y before Z'?"

### Step K: Write Config

Write the config to `${CLAUDE_PLUGIN_DATA}/me.md` in this format:

```
# me.md

## Identity
timezone: [timezone]
role: [role description]

## Email Accounts
connected:
  - [label] | [description]
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

## My Rules
- [user's personal rules]

## Custom Rules
- [user's custom rules]
```

Tell the user: "Config saved. You can edit it anytime — it's human-readable markdown. This file lives in the plugin's data directory and survives plugin updates."

### Graceful Degradation

- If Notion MCP is not available: skip all Notion steps, note which features will be limited
- If no email MCP is available: still set up email monitoring domains (for scanning), note that all drafts will be written as copyable blocks
- If Google Calendar MCP is not available: warn that calendar features won't work
