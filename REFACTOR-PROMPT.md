# COS Plugin Refactor: Separate Agent Logic from Personalization

## Goal

Restructure the Chief of Staff plugin so it can be published to a marketplace with zero PII. All personal/business-specific content moves to a user-local file that never ships with the plugin.

## Architecture

Two files, two purposes:

- **`agent-logic.md`** (replaces `references/shared-core.md`) — how the agent operates. Ships with the plugin. Zero PII. Zero business names. Zero client references.
- **`me.md`** (replaces `${CLAUDE_PLUGIN_DATA}/config.md`) — who the user is, their business, their rules, their email routing setup. Lives in `${CLAUDE_PLUGIN_DATA}/me.md`. Never included in the `.plugin` file.

## What Needs to Change

### 1. Rename and refactor `references/shared-core.md` → `references/agent-logic.md`

The current file has PII hardcoded in it. Here's what needs to move out:

**Remove all Adapture references.** Replace the current "Gmail Drafts" vs "Adapture Drafts" split with a generic two-tier email routing system:

- **Connected email accounts** (user has MCP access, e.g. Gmail): Create drafts via the MCP tool. After creating, provide a link to the draft in that tool. Log in the Daily Brief.
- **Unconnected email accounts** (no MCP access): Write the draft as a copyable block in the Daily Brief page with To/Subject/Body. Tell the user which account to send from. Log in the Daily Brief.

The list of which accounts are connected vs unconnected should be driven by `me.md` config, not hardcoded.

**Remove "KLMC engagements" from hard rules.** Generalize to just "NEVER make pricing or scope decisions." Business-specific scoping belongs in `me.md`.

**Split hard rules into two tiers:**

Core hard rules (stay in `agent-logic.md` — these are safety/architectural and should NOT be user-modifiable):
- NEVER send an email — draft only, user reviews all outbound
- NEVER delete or archive anything
- NEVER handle relationship-sensitive communications without flagging as RED
- When uncertain: default to YELLOW (prep), not GREEN (dispatch)
- Execute everything possible up to the human-judgment boundary
- Completion target is 80%

User hard rules (move to `me.md` — these are personal preferences the user can modify):
- NEVER make pricing or scope decisions (user can scope this to their business)
- NEVER auto-schedule work tasks to Sunday / Sabbath protection (user can change the day or remove)
- Any custom rules the user adds during setup

Update all references from `config.md` to `me.md` throughout the file.

### 2. Refactor `references/notion-schema.md`

Remove the "Drafts: Adapture" section. Replace with a generic "Drafts: [Account Name]" pattern that supports any number of unconnected email accounts, driven by `me.md` config.

### 3. Refactor `skills/cos-setup/SKILL.md`

This creates the config file. Update it to:
- Create `${CLAUDE_PLUGIN_DATA}/me.md` instead of `config.md`
- Handle migration from legacy paths (`config.md` → `me.md`)
- Add a setup step for email accounts:
  - Ask which email tools they have connected (Gmail MCP, Outlook MCP, etc.)
  - Ask if there are other email accounts they use without MCP access
  - For each unconnected account, capture: account label, domain, and send instructions (e.g. "copy and paste into Outlook")
- Move Sabbath/rest day configuration into setup as a question rather than a hardcoded rule
- Write user-modifiable hard rules to the `## My Rules` section of `me.md`

The output `me.md` format should look something like:

```markdown
# me.md

## Identity
timezone: America/New_York
role: Solo consultant running a technical marketing agency

## Email Accounts
connected:
  - gmail | primary personal and business email
unconnected:
  - adapture | client Adapture work email | Send via Outlook

## Email Monitoring
domains:
  - acme.com | client - Acme Corp
  - partner.io | partner - PartnerCo

## Notion: Projects
enabled: true
database_id: abc123
active_statuses: In Progress, Planning, Waiting, Blocked, Backlog
fields: Project, Status, Deadline, Client, Owner

## Notion: Pipeline
enabled: false

## Notion: Clients
enabled: true
data_source: collection://xyz789

## Notion: Tasks
enabled: true
database_id: def456
default_personal_project: Personal Tasks

## Notion: Daily Briefs
enabled: true
database_id: ghi012

## My Rules
- NEVER make pricing or scope decisions for [my business name] engagements
- NEVER auto-schedule work tasks to Sunday (Sabbath protection)

## Custom Rules
- [user adds their own here]
```

### 4. Update `skills/morning-sweep/SKILL.md` and `skills/evening-review/SKILL.md`

- Update all references from `shared-core.md` to `agent-logic.md`
- Update all references from `config.md` to `me.md`
- Make sure neither file contains any PII or business-specific references

### 5. Update `commands/*.md`

- Update any references to old file names

### 6. Update `README.md`

- Replace Adapture/KLMC references with generic descriptions
- Document the `agent-logic.md` / `me.md` split
- Explain that `me.md` is created during setup and lives outside the plugin directory

### 7. Update `BUILD.md`

Add a PII verification step to the build process. After zipping, run:

```bash
# Scan for common PII patterns before publishing
unzip -p cos.plugin | grep -iE "(adapture|klmc|mcmurphy|kevin|@[a-z]+\.(com|io|org))" | grep -v "example\|acme\|partner\|recipient@"
```

If this returns anything, the build is not clean. Add this as a checklist item.

### 8. Delete the old `.plugin` file

Remove `cos.plugin` from the repo root — it was built before this refactor and contains PII.

## Files to Touch (summary)

| File | Action |
|------|--------|
| `references/shared-core.md` | Rename to `references/agent-logic.md`, remove all PII, generalize email routing and hard rules |
| `references/notion-schema.md` | Remove Adapture section, add generic unconnected email draft pattern |
| `skills/cos-setup/SKILL.md` | Rewrite to create `me.md`, add email account setup, add rest day setup |
| `skills/morning-sweep/SKILL.md` | Update file references |
| `skills/evening-review/SKILL.md` | Update file references |
| `commands/setup.md` | Update if needed |
| `commands/morning-sweep.md` | Update if needed |
| `commands/evening-review.md` | Update if needed |
| `README.md` | Remove PII, document the split |
| `BUILD.md` | Add PII scan step |
| `cos.plugin` | Delete (stale, contains PII) |

## Constraints

- Do NOT create any new skills or commands — this is a refactor, not a feature add
- Do NOT change the classification framework (`references/classification.md`) — it's already clean
- Do NOT change the plugin manifest (`plugin.json`) — name, version, description stay the same
- All `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` variable references must be preserved — these are resolved at runtime
- The morning sweep and evening review workflows should function identically after the refactor — just driven by config instead of hardcoded values
