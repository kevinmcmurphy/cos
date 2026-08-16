## Email Draft Routing

Read the `## Email Accounts` section from `${CLAUDE_PLUGIN_DATA}/me.md` to determine which accounts are connected and which are unconnected.

### Connected Email Accounts

For emails that should be sent from a connected account (per `## Email Accounts` in me.md):

Call `gmail_create_draft` with the recipient, subject, and body. This creates a draft — it does NOT send.

**NEVER send emails directly.** Core rule: draft only, user reviews all outbound.

**Replying to threads:** Call `gmail_create_draft` with the appropriate `threadId` and `In-Reply-To` header to create a threaded reply draft.

After each draft, log in the Daily Brief "Drafts: [Account Label]" section:
`**To:** [recipient] — **Subject:** [subject] — Draft created in Gmail`

### Unconnected Email Accounts

For emails that should be sent from an unconnected account:
- Do NOT create .eml files or any local files
- Write each draft as a copyable code block in the "Drafts: [Account Label]" section of the Daily Brief page:
  ```
  To: recipient@example.com
  Subject: The subject line

  Body of the email here.
  ```
- Tell the user which account to send from and how (per the send instructions in me.md): "[Account label] draft for [recipient] saved to your Daily Brief in Notion. [Send instructions from me.md]"

### Timezone Boundary for Email Queries

When checking Gmail for emails sent "today" (e.g., accountability review verifying if a draft was sent), define "today" using the user's timezone from me.md:
- Start of today = midnight in user's timezone (e.g., 00:00 ET = 04:00 UTC during EDT, 05:00 UTC during EST)
- End of today = current time in user's timezone

When calling `gmail_search_messages`, the `newer_than:1d` filter uses a rolling 24-hour window from the call time, which is usually sufficient. But when the date boundary matters (e.g., accountability review at 11 PM ET — which is past midnight UTC), use explicit `after:` and `before:` epoch timestamps converted from the user's timezone boundaries.
