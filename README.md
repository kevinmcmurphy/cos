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

## Requirements

- Claude with Cowork (or Claude Code)
- Google Calendar connected via MCP
- Gmail connected via MCP
- (Optional) Notion connected via MCP

## Install

1. Download or clone this repo
2. Copy the `skills/cos/` folder to `~/.claude/skills/`
3. Start a conversation and ask for your morning sweep
4. First run walks you through setup (~5 min)

## How It Works

**First run:** Conversational onboarding asks for your timezone, email domains to monitor,
and optionally connects your Notion databases. Saves config to `~/.claude/skills/cos/config.md`.

**Every morning:** Run your sweep. Get a prioritized brief. Say "go" to execute.

## The Classification Framework

| Color | Meaning | Example |
|-------|---------|---------|
| RED | Needs your brain or presence today | Client call prep, strategic decisions, deadlines |
| YELLOW | Claude preps it 80%, you finalize | Email drafts, meeting research, content review |
| GREEN | Claude handles it | Routine replies, scheduling, status updates |
| GRAY | Not today | No deadline pressure, blocked by others |

## Configuration

After setup, your config lives at `~/.claude/skills/cos/config.md`.
It's human-readable markdown — edit it anytime to add email domains,
change Notion databases, or update your rules.

## Safety Rules (Defaults)

- Never sends email — drafts only, you review everything
- Never deletes or archives anything
- Flags relationship-sensitive items as RED
- When uncertain, preps (YELLOW) rather than dispatches (GREEN)

## License

MIT
