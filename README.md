# Chief of Staff

AI Chief of Staff for solo operators.

One plugin gives you a daily operating rhythm — morning sweep to prioritize and execute, evening review to close the day and plan tomorrow. Everything classified by what needs your brain and what doesn't.

## What It Does

Chief of Staff runs a two-part daily cycle:

**Morning Sweep** scans your world and gets you moving:
- Google Calendar (today + tomorrow)
- Gmail (last 48 hours from key contacts)
- Notion (active projects + pipeline)
- Classifies everything RED / YELLOW / GREEN / GRAY
- Executes on your command — drafts emails, preps materials, updates docs
- Saves the full daily brief to Notion

**Evening Review** closes the day and sets up tomorrow:
- Brain dump capture — get everything out of your head
- Accountability scorecard against an 80% completion target
- Project and system updates
- Plans the next workday
- Creates tomorrow's Daily Brief page so morning sweep can execute immediately

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- [Google Workspace CLI](https://github.com/googleworkspace/cli) (`npm install -g @googleworkspace/cli`)
- Notion MCP

## Install

In Claude Code, run these commands:

```
/plugin marketplace add kevinmcmurphy/cos
/plugin install cos@chief-of-staff
/reload-plugins
```

This adds the marketplace, installs the plugin, and loads it. Commands will be available as `/cos:morning-sweep`, `/cos:evening-review`, and `/cos:setup`.

**For development/testing:**
```bash
git clone https://github.com/kevinmcmurphy/cos.git
claude --plugin-dir ./cos
```
This loads the plugin for a single session without installing it permanently.

## First Run

Setup walks you through connecting everything:
- Your timezone
- Email accounts and domains to monitor
- Google Workspace CLI authentication (`gws auth setup`)
- Notion database connections (projects, clients, tasks)

Takes about 5 minutes.

## The Daily Cycle

The system is designed around an evening-to-morning flow:

1. **Evening review** closes your day. You dump what's in your head, score how the day went, and Claude plans tomorrow — creating a Daily Brief page with priorities already set.
2. **Morning sweep** refreshes live data (new emails, calendar changes) and executes against that plan immediately. No waiting around for analysis.

If you skip the evening review, morning sweep falls back to full planning mode — it still works, just takes a beat longer to build context from scratch.

## Classification Framework

| Color | Label | What It Means | Example |
|-------|-------|---------------|---------|
| RED | Yours | Needs your brain or presence today | Client call prep, strategic decisions, deadlines |
| YELLOW | Prep | Claude gets it 80% ready, you finalize | Email drafts, meeting research, content review |
| GREEN | Handle | Claude does it | Routine replies, scheduling, status updates |
| GRAY | Not today | Deferred with a reason | No deadline pressure, blocked by others, low priority |

When uncertain, Chief of Staff biases toward YELLOW. Better to over-prepare than to let something slip.

## Config

The plugin ships with `agent-logic.md` (how the agent works) and creates `me.md` during setup (who you are, your accounts, your rules). `me.md` lives in the plugin's data directory and survives updates.

`me.md` is human-readable markdown. Edit it anytime — add email domains, change Notion databases, adjust your rules.

## Safety Rules

Core rules (always enforced):
- Never sends email — drafts only, you review everything
- Never deletes or archives anything
- Flags relationship-sensitive items as RED
- When uncertain, preps (YELLOW) not dispatches (GREEN)

You can add your own rules during setup (e.g., blocked days, pricing boundaries, escalation preferences). These are stored in `me.md`.

## Inspiration

Built on the idea from [Jim Prosser's thread](https://x.com/jimprosser/status/2029699731539255640) — a solo operator doesn't need to hire a chief of staff when an AI can fill the role. Gather context, classify priorities, handle the routine, so you can focus on the work that actually needs your brain.

## License

MIT
