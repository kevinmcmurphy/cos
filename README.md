# COS Morning Sweep

A Chief of Staff for solo operators. One command gives you a prioritized morning brief
across your calendar, email, and projects — classified by what needs your brain,
what can be prepped, and what can wait.

## What It Does

- Scans your Google Calendar (today + tomorrow)
- Checks Gmail for messages from your key contacts (last 48 hours)
- Optionally pulls active projects and pipeline items from Notion
- Asks what's on your mind
- Classifies everything: RED (yours) / YELLOW (prep) / GREEN (handle) / GRAY (not today)
- Presents a scannable morning brief with capacity check
- Executes on your command — drafts emails, preps materials, updates docs
- Saves the full daily brief to a Notion database for access from any device

## Requirements

- Claude Code or claude.ai
- Google Calendar connected via MCP
- Gmail connected via MCP
- Notion connected via MCP (for daily briefs and optional project tracking)

## Install

**Claude Code:**
1. Clone this repo
2. Copy the `skills/morning-sweep/` folder to `~/.claude/skills/cos/`
3. Start a conversation and ask for your morning sweep
4. First run walks you through setup (~5 min)

## How It Works

**First run:** Conversational onboarding asks for your timezone, email domains to monitor,
connects your Notion databases, and creates a "COS Daily Briefs" database for sweep outputs.
Saves config to `~/.claude/skills/cos/config.md`.

**Every morning:** Run your sweep. Get a prioritized brief. Say "go" to execute.

**Outputs go to Notion:** The full brief, Gmail draft references, Adapture email drafts
(as copyable code blocks), expense CSVs, and checklists are all saved to your Daily Briefs
database. Access them from any device — phone, tablet, or desktop.

**Adapture drafts:** Since there's no M365 MCP, Adapture email drafts are written as
copyable text blocks in Notion. Copy and paste into Outlook to send.

## The Classification Framework

| Color | Meaning | Example |
|-------|---------|---------|
| RED | Needs your brain or presence today | Client call prep, strategic decisions, deadlines |
| YELLOW | Claude preps it 80%, you finalize | Email drafts, meeting research, content review |
| GREEN | Claude handles it | Routine replies, scheduling, status updates |
| GRAY | Not today | No deadline pressure, blocked by others |

## Configuration

After setup, your config lives at `~/.claude/skills/cos/config.md` — human-readable markdown.
Edit it anytime to add email domains, change Notion databases, or update your rules.

## Safety Rules (Defaults)

- Never sends email — drafts only, you review everything
- Never deletes or archives anything
- Flags relationship-sensitive items as RED
- When uncertain, preps (YELLOW) rather than dispatches (GREEN)

## Inspiration

The idea of an AI Chief of Staff came from [Jim Prosser's thread](https://x.com/jimprosser/status/2029699731539255640)
on building a personal COS — the concept that a solo operator doesn't need to hire a
chief of staff when an AI can fill the role: gathering context, classifying priorities,
and handling the routine so you can focus on the work that actually needs your brain.

## License

MIT
