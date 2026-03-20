---
name: cos-setup
description: >
  Use when the user wants to configure the Chief of Staff plugin, set up COS,
  or when config is missing at ${CLAUDE_PLUGIN_DATA}/config.md. Walks through timezone, email
  domains, Notion databases, and creates config.
---

# Chief of Staff — Setup

Walk the user through configuring the Chief of Staff plugin. This creates the config file at `${CLAUDE_PLUGIN_DATA}/config.md`.

## Step 0: Detect Config State

Before starting setup, check for existing configuration:

1. **If `${CLAUDE_PLUGIN_DATA}/config.md` exists** → Scenario C (existing config)
   - Ask: "Config found at ${CLAUDE_PLUGIN_DATA}/config.md. Use existing config or re-run setup?"
   - If use existing: validate all required sections are present (Identity, Email Monitoring, Notion modules, Hard Rules). Report any missing sections and offer to fill gaps.
   - If re-run: copy existing to `${CLAUDE_PLUGIN_DATA}/config.md.bak` as backup, then proceed to Step 1.

2. **If `${CLAUDE_PLUGIN_DATA}/config.md` does NOT exist but `~/.claude/skills/cos/config.md` exists** → Scenario B (migration from legacy install)
   - Ask: "Found existing COS config at ~/.claude/skills/cos/config.md. Migrate to the plugin's data directory?"
   - If yes: copy file to `${CLAUDE_PLUGIN_DATA}/config.md`, verify copy, say "Config migrated successfully."
   - Check if config has `## Notion: Tasks` section. If missing, run just the Tasks setup step (Step F below).
   - If no: proceed to Step 1 (full setup).

3. **If neither exists** → Scenario A (fresh install)
   - Proceed to Step 1.

## Step 1: Full Setup Flow

The plugin data directory at `${CLAUDE_PLUGIN_DATA}` is created automatically when first referenced. Ensure it exists:
```bash
mkdir -p "${CLAUDE_PLUGIN_DATA}"
```

### Step A: Timezone

Detect the user's timezone from the system if possible. Confirm with them:
> "Your system timezone appears to be [detected]. Is that correct, or would you prefer a different timezone?"

### Step B: Role Context

Ask:
> "In one or two sentences, what do you do? This helps me understand what 'needs your brain' means for you."

### Step C: Email Domains

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

> "I need a Daily Briefs database to save your sweep outputs. I can create one for you under your Operations Home (or wherever you'd like). Should I create it now?"

If yes:
- Create the database with properties: Name (title), Date (date), Status (select: Planned, Draft, Active, Complete, Reviewed), Red Count (number), Yellow Count (number), Planned Items (number), Completed Items (number)
- Note: Completion Rate formula property may need to be added manually by the user
- Save the database ID

If no: ask where they'd like it, or skip (sweep outputs will only appear in conversation).

### Step I: Hard Rules

Present the default hard rules:
1. NEVER send an email — draft only, user reviews all outbound
2. NEVER make pricing or scope decisions
3. NEVER delete or archive anything in Gmail, Notion, or any other system
4. NEVER handle relationship-sensitive communications without flagging as RED
5. When uncertain: default to YELLOW (prep), not GREEN (dispatch)
6. NEVER auto-schedule work tasks to Sunday (Sabbath protection)

Ask: "Want to modify any of these, or add your own rules?"

### Step J: Write Config

Write the config to `${CLAUDE_PLUGIN_DATA}/config.md` in this format:

```
# COS Configuration

## Identity
timezone: [timezone]
role: [role description]

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

## Hard Rules
- [rule 1]
- [rule 2]
...

## Custom Rules
- [any user-added rules]
```

Tell the user: "Config saved to ${CLAUDE_PLUGIN_DATA}/config.md. You can edit it anytime — it's human-readable markdown. This file survives plugin updates."

### Graceful Degradation

- If Notion MCP is not available: skip all Notion steps, note which features will be limited
- If Gmail MCP is not available: skip email domain setup, note email scanning won't work
- If Google Calendar MCP is not available: warn that calendar features won't work
