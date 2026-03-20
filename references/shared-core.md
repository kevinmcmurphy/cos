# COS Shared Core

Shared logic referenced by both morning-sweep.md and evening-review.md. Do NOT duplicate this content — reference this file instead.

## Config Loading

Read `${CLAUDE_PLUGIN_DATA}/config.md`. If it doesn't exist, tell the user: "No config found. Let me walk you through setup." Then invoke the `/cos:setup` skill and stop.

Load these values from the config:
- `timezone` from `## Identity`
- `role` from `## Identity`
- `domains` from `## Email Monitoring`
- Notion module flags (`enabled: true/false`) from `## Notion: Projects`, `## Notion: Pipeline`, `## Notion: Clients`, `## Notion: Tasks`
- `daily_briefs_database_id` from `## Notion: Daily Briefs`
- All rules from `## Hard Rules` and `## Custom Rules`

## Notion Write-Back Rule

**Update the Daily Brief page in Notion after every meaningful interaction.** This is non-negotiable. The user should be able to open the Daily Brief from any device at any point and see the current state.

What triggers a write-back:
- Brief is presented → write the full brief to the page
- User provides adjustments → update the brief on the page
- A Gmail draft is created → add it to the "Drafts: Gmail" section
- An Adapture draft is composed → add it to the "Drafts: Adapture" section
- A Notion page is updated → log it in the "Outputs" section
- A task is created → log it in the "Outputs" section
- Any other action is completed → log it in the "Outputs" section

Do NOT batch writes. Do NOT wait until the end. Write after each action.

## Data Gathering

### Calendar — Today + Tomorrow

Use the Google Calendar MCP to pull events for today and tomorrow.
- Use the timezone from config
- Note meetings that need prep (client calls, BD conversations)
- Flag back-to-back meetings with no buffer
- Flag events with physical locations (user may need drive time)

### Email Scan — Last 48 Hours

Use the Gmail MCP to search for recent emails from the domains listed in the `## Email Monitoring` section of config. For each domain, run a search with `newer_than:2d`:
- `from:[domain]` for each configured domain
- Combine domains from the same organization into one search where it makes sense (e.g., `from:domain1.com OR from:domain2.com`)

For each email found:
- Note the sender, subject, and date
- Determine if it looks like it needs a response or follow-up from the user
- Flag anything that appears unanswered (no reply from the user in the thread)

If `## Notion: Clients` is enabled in config, also use the Notion MCP to pull client records from the configured `data_source` and extract any email domains. Search Gmail for those domains too.

### Notion — Active Projects + Pipeline

**If `## Notion: Projects` is enabled in config:**
- Query the database using the configured `database_id`
- Filter for items matching the configured `active_statuses`
- Display the configured `fields`

**If `## Notion: Pipeline` is enabled in config:**
- Query the database using the configured `database_id`
- Filter by the configured `active_statuses` on the configured `status_field`
- Note any configured `date_fields` for deadline tracking

**If neither Notion module is enabled, skip this section entirely.**

## Email Draft Routing

### Gmail Drafts

For emails to/from the user's primary address (per config):
- Create drafts via Gmail MCP — **never send**
- After each draft, log in the Daily Brief "Drafts: Gmail" section:
  `**To:** [recipient] — **Subject:** [subject] — Draft created in Gmail`

### Adapture Drafts

For emails to/from Adapture addresses:
- Do NOT create .eml files or any local files
- Write each draft as a copyable code block in the "Drafts: Adapture" section of the Daily Brief page:
  ```
  To: recipient@adapture.com
  Subject: The subject line

  Body of the email here.
  ```
- Tell the user: "Adapture draft for [recipient] saved to your Daily Brief in Notion. Copy and paste into Outlook to send."

## Task Creation

**If `## Notion: Tasks` is enabled in config:**
- Create tasks in the configured Tasks database
- **Every task must be linked to a project.** If the task is personal (health, family, admin, errands, personal finances, etc.) and doesn't belong to a specific client or work project, assign it to the project configured as `default_personal_project`. If that project doesn't exist yet in Notion, create it as an ongoing project with no end date before creating the task.
- Never create a floating task with no project — tasks without a home get lost.
- Set `Deadline` to the appropriate date
- Set `Status` to "Not Started"
- Log each task in the "Outputs" section of the Daily Brief

## Hard Rules — Non-Negotiable

Read the `## Hard Rules` and `## Custom Rules` sections from config. Apply all of them.

Standing hard rules:
1. NEVER send an email — draft only, user reviews all outbound
2. NEVER make pricing or scope decisions for KLMC engagements
3. NEVER delete or archive anything in Gmail, Notion, or any system
4. NEVER handle relationship-sensitive communications without flagging as RED
5. When uncertain about classification: default to YELLOW (prep), not GREEN (dispatch)
6. NEVER auto-schedule work tasks to Sunday (Sabbath protection)
7. Execute everything possible up to the human-judgment boundary — stop only where outside judgment or action is required
8. Completion target is 80% — surface shortfalls gently, track patterns across days

## Voice and Style

- Direct and scannable. No filler.
- Use the user's time efficiently
- Be honest about capacity. If the day is overloaded, say so.
- Never be sycophantic. The user is a peer, not a boss to impress.
- If something looks like it's falling through the cracks, flag it clearly.
