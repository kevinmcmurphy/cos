## Output Format

Present the following block in conversation **and** write it to the Email Triage section of today's Daily Brief page when Daily Briefs is enabled.

**Supersede, don't append.** On each run, find the existing `Email Triage` section on the Daily Brief page and replace its body, updating the timestamp in the heading. If no Email Triage section exists yet, create it. The section heading is `Email Triage — HH:MM ET` (timestamp in user's timezone). The body is replaced entirely; prior run contents are not preserved in Notion. (The local artifact in `reports/daily-sweeps/` retains the full run-by-run history.)

```
EMAIL TRIAGE — [HH:MM ET, Date]
Scope: [N] threads (unread + last 48h)
Skipped (already labeled, no new activity): [M]

! ACTION NEEDED (KLMC) — [count]
- [sender] — [subject] — [draft created (id) / existing draft / no draft]

TO RESPOND (KLMC) — [count]
- [sender] — [subject] — [draft created (id) / existing draft]

WAITING ON (KLMC) — [count]
- [sender] — [subject] — last replied [date]

REVIEW (LOW PRIORITY) (KLMC) — [count]
- [sender] — [subject]

RECEIPTS/FINANCIALS (KLMC) — [count]
- [sender] — [subject]

NEWSLETTERS (KLMC) — [count]
- [sender] — [subject]

VENDORS (KLMC) — [count]
- [sender] — [subject]

RESPONDED (KLMC) — [count] (newly closed since last run)
- [sender] — [subject]

JUNK / NO LABEL — [count]
- [sender] — [subject snippet]

DRAFTS CREATED — [count]
- [recipient] — [subject] — Gmail draft id [id]

NOTION TASKS CREATED — [count]
- [task title] — linked to [project]
```

Empty buckets: write the heading with `— 0` and omit the bullet list. Do not drop empty headings entirely — Kevin uses the consistent shape to scan quickly.

---

## Source Linking

Every item in the output that references a Gmail thread must include a clickable link in the Notion-written version of the section. Format: `https://mail.google.com/mail/u/0/#inbox/<threadId>`. The conversation-only output may omit links for brevity, but the Daily Brief page version must always include them per the Source Linking Rule in `agent-logic.md`.

---
