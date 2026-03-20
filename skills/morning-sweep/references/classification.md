# COS Classification Framework

Shared classification logic referenced by both morning-sweep.md and evening-review.md.

## Categories

### RED — Yours (needs the user's brain or presence today)
- Client calls or meetings requiring prep
- Strategic decisions only the user can make
- Relationship-sensitive communications
- Anything the user flagged as urgent in their brain dump
- Deadlines that are today or overdue

### YELLOW — Prep (Claude gets it 80% ready)
- Email replies that need the user's voice but Claude can draft
- Content pieces that need the user's review/editing
- Research or prep work for upcoming meetings
- Project updates that need the user's input

### GREEN — Handle (Claude can do this)
- Routine email responses (draft only, never send)
- Status updates to project docs
- Straightforward follow-ups (draft only)
- Notion updates (mark items done, update dates, etc.)

### GRAY — Not Today (defer with reason)
- Items with no deadline pressure
- Nice-to-haves that would overload today
- Items blocked by someone else

## Classification Rules

- Use the `role` from config to inform what "needs your brain" means — a solo consultant's RED items differ from a startup founder's.
- When in doubt between GREEN and YELLOW, choose YELLOW (prep, don't dispatch)
- If the user mentioned something in their brain dump, weight it higher
- Deadlines within 48 hours automatically bump up one level
- Back-to-back meetings mean fewer action items can fit — be realistic about capacity
- If the day's calendar is packed, be aggressive about pushing things to GRAY

## Capacity Calculation

Based on the calendar:
1. Calculate total hours between work start (~8am) and work end (~6pm) in user's timezone
2. Subtract all meeting durations (include buffer for back-to-back)
3. Subtract 30min for lunch if no lunch block exists
4. The remainder is available capacity
5. Estimate each RED item at 30-60min, YELLOW at 20-40min, GREEN at 10-20min
6. Compare total estimated time to available capacity
7. Assessment: "fits comfortably" (< 70% capacity), "tight but doable" (70-90%), "you'll need to push some YELLOWs to tomorrow" (> 90%)

## Carryover Aging Rules

When items carry over from a previous day:
- Carryover items start one level higher than they ended
- A GRAY item deferred 3+ consecutive days with no change in the underlying project/email status → bump to YELLOW and flag it
- A YELLOW item with prep done but no user action → re-surface as YELLOW; don't silently drop it
- A RED item that wasn't resolved → surfaces again as RED, unless email or Notion shows it's since been handled
- Label carryover items clearly — e.g. `[carried over from March 14]` — so the user knows they're not new

The goal: no item should ever disappear just because it got pushed to GRAY or left unactioned for a day.
