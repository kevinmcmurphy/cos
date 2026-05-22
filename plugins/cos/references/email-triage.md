# COS Email Triage — GPS Reference

Authoritative source for Email GPS label semantics, re-triage rules, voice drafting, and task creation behavior. Referenced by the `email-triage` skill and by invocation hooks in `morning-sweep` and `evening-review`.

## GPS Label Taxonomy

Apply exactly one of these labels to each in-scope Gmail thread. Display names must be preserved exactly — leading `! ` and parenthetical suffixes included — so they sort and read correctly in Gmail.

| # | Display name in Gmail | When to apply | Action |
|---|----------------------|---------------|--------|
| 1 | `! Action Needed (Kevin)` | Requires Kevin's direct input — strategic decisions, relationship-sensitive replies, anything outside the human-judgment boundary. | Apply label. Draft voice-matched reply. Create Notion task if Tasks enabled. |
| 2 | `To Respond` | Routine reply Claude can handle on Kevin's behalf — scheduling, acknowledgments, simple Q&A. | Apply label. Draft voice-matched reply. |
| 3 | `Review (Low Priority)` | Informational, FYI — Kevin reads at his discretion. No response expected. | Apply label. No draft. |
| 4 | `Responded` | Thread has been addressed and no follow-up is expected. | Apply label only when the loop is closed. |
| 5 | `Waiting On` | Thread is awaiting an external reply that Kevin or Claude already requested. | Apply label. Snooze logic: re-surface if no reply in 24-48h. |
| 6 | `Receipts/Financials` | Expense reports, invoices, payment confirmations, statements. | Apply label. No draft. |
| 7 | `Newsletters` | Subscribed informational content. | Apply label. No draft. |
| 8 | `Vendors` | Inbound vendor pitches, sales outreach, cold requests. | Apply label. Draft a polite decline only if obviously cold. |

**Implicit ninth bucket — Junk / No Label.** Blatant promotional spam or irrelevant noise. Core Rule #2 forbids auto-archiving, so leave these unlabeled and surface them in the Email Triage output under "Junk / no label applied" with subject snippets. Kevin decides.

## Tiebreakers

- `To Respond` vs. `! Action Needed (Kevin)` → choose `! Action Needed (Kevin)`. Per Core Rule #3, relationship-sensitive comms go to Kevin.
- `Review` vs. `Newsletters` → `Newsletters` only if it's a recurring subscription. One-off informational emails go to `Review`.
- `Vendors` vs. `! Action Needed (Kevin)` → if there is prior Kevin→sender correspondence in the last 90 days, treat as `! Action Needed (Kevin)`. Cold outreach goes to `Vendors`.
- `Waiting On` vs. `Responded` → if Kevin's last reply asked a question or requested action, `Waiting On`. If his last reply closed the loop, `Responded`.

## Re-triage Rules

Skip a thread if **all** of the following are true:
- The thread already has at least one GPS label.
- The thread has no unread messages.
- The newest message in the thread is older than 24 hours.

Otherwise, re-classify. Re-classification may keep or change labels. When changing a label, remove the old GPS label (`unlabel_thread`) and add the new one (`label_thread`) — do not leave both attached.

Common transitions:
- `! Action Needed (Kevin)` → `Responded` after Kevin replies.
- `To Respond` → `Responded` after the draft is sent.
- `Waiting On` → `! Action Needed (Kevin)` when a reply arrives requiring decision.
- `Waiting On` → `To Respond` when a reply arrives requiring routine response.

## Voice Drafting

Voice-matched drafts are required only for `! Action Needed (Kevin)` and `To Respond`. Other labels get no draft.

### Gather voice context

For each thread that requires a draft:

1. Identify the reply recipient — the email address of the most recent non-Kevin sender in the thread.
2. Call `search_threads` with query `from:me to:<recipient_email>` and `pageSize=5`. Results return newest-first.
3. For each returned thread, call `get_thread` with `messageFormat=FULL_CONTENT` and extract Kevin's most recent sent message body from that thread.
4. Cache the recipient → sent-messages list for the duration of this triage run. Reuse if drafting multiple replies to the same recipient — never refetch.

### Extract voice profile

From the up-to-5 sent messages, infer:

- **Greeting style**: `Hi [Name],` / `[Name],` / `Hey,` / no greeting.
- **Sign-off**: `Thanks,` / `Best,` / `—Kevin` / `K` / none.
- **Formality register**: formal (full sentences, no contractions), casual (contractions, fragments), terse (one-line replies).
- **Sentence length**: short and punchy vs. multi-sentence elaboration.
- **Signature block**: present or absent; if present, copy verbatim.
- **Emoji / exclamation frequency**: rare, occasional, frequent.

If the 5 messages split between registers, default to the register of the **most recent** message.

### Compose

Draft the reply addressing the actual content of the inbound message — acknowledge what's being asked, propose an answer if obvious, ask a clarifying question if ambiguous. Apply the inferred voice profile.

### Fallback — no historical correspondence

If the recipient search returns zero results, draft a neutral acknowledgment with a specific clarifying question:

```
Hi [Name],

Thanks for reaching out. Before I respond — [one specific question
targeting the actual ambiguity in their request].

Best,
Kevin
```

The clarifying question must target the specific ambiguity (timing, scope, deliverable format, decision criteria) — not a generic "let me know what you need."

### Draft collision

Before drafting, inspect the thread for an existing draft. Call `get_thread` with `messageFormat=FULL_CONTENT` and check each message's `labelIds` for `DRAFT`. If present, skip drafting and log `existing draft on thread — not overwritten` in the output.

### Create the draft

Call `create_draft` with:
- `to`: recipient email
- `subject`: original subject, prefixed with `Re: ` if not already
- `body`: the drafted reply text
- `replyToMessageId`: the ID of the most recent inbound message in the thread

Per Core Rule #1, the skill **never sends** — drafts only.

## Notion Task Creation

For each thread labeled `! Action Needed (Kevin)`:

**If `## Notion: Tasks` is enabled in me.md:**

1. Before creating, query the Tasks DB for an open task whose description contains this thread's Gmail URL (`https://mail.google.com/mail/u/0/#inbox/<threadId>`). If one exists, skip creation and log `task already exists for this thread`.
2. Otherwise, create a task per the Task Creation pattern in `agent-logic.md`:
   - **Title**: the email subject with `Re:` / `Fwd:` prefixes stripped.
   - **Deadline**: today's date in the user's timezone. Action Needed is by definition immediate.
   - **Status**: `Not Started`.
   - **Project**: if the sender's domain matches a project in the Projects DB (via Clients DB lookup when enabled), link there. Otherwise link to `default_personal_project` from me.md.
   - **Description / context block**: include the Gmail thread URL and a one-line snippet of the inbound message.

**If Tasks is not enabled:** no task. The item still surfaces in the Email Triage section of the brief.

## Output Format

Present this block in conversation **and** write it to the Email Triage section of today's Daily Brief page when Daily Briefs is enabled. Each run gets its own timestamped subsection — never overwrite a prior run's output.

```
EMAIL TRIAGE — [HH:MM ET, Date]
Scope: [N] threads (unread + last 48h)
Skipped (already labeled, no new activity): [M]

! ACTION NEEDED (KEVIN) — [count]
- [sender] — [subject] — [draft created (id) / existing draft / no draft]

TO RESPOND — [count]
- [sender] — [subject] — [draft created (id) / existing draft]

WAITING ON — [count]
- [sender] — [subject] — last replied [date]

REVIEW (LOW PRIORITY) — [count]
- [sender] — [subject]

RECEIPTS/FINANCIALS — [count]
- [sender] — [subject]

NEWSLETTERS — [count]
- [sender] — [subject]

VENDORS — [count]
- [sender] — [subject]

RESPONDED — [count] (newly closed since last run)
- [sender] — [subject]

JUNK / NO LABEL — [count]
- [sender] — [subject snippet]

DRAFTS CREATED — [count]
- [recipient] — [subject] — Gmail draft id [id]

NOTION TASKS CREATED — [count]
- [task title] — linked to [project]
```

Empty buckets: write the heading with `— 0` and omit the bullet list. Do not drop empty headings entirely — Kevin uses the consistent shape to scan quickly.

## Source Linking

Every item in the output that references a Gmail thread must include a clickable link in the Notion-written version of the section. Format: `https://mail.google.com/mail/u/0/#inbox/<threadId>`. The conversation-only output may omit links for brevity, but the Daily Brief page version must always include them per the Source Linking Rule in `agent-logic.md`.
