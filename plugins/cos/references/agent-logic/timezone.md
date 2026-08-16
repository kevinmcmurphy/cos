## Timezone Rule — Non-Negotiable

All times presented to the user MUST be in the timezone from me.md. This applies to:
- Calendar event times (the `gcal_list_events` start/end params should use the user's timezone; verify returned times match)
- Email timestamps (`gmail_search_messages` and `gmail_read_message` return UTC — convert before displaying)
- Telegram message timestamps (arrive in UTC — convert before displaying)
- Capacity calculations (work hours 8am-6pm are in the user's local timezone)
- Carryover labels (e.g., "[overdue from March 14]" — use the user's local date, not UTC date)
- Any other time reference in the brief or conversation

Never display raw UTC to the user. If conversion is ambiguous, show both: "10:00 AM ET (14:00 UTC)."
