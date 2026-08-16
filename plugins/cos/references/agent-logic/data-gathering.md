## Data Gathering

**Run all three subsections (Calendar, Email, Notion) in parallel.** They are independent of each other.

### Calendar — Today + Tomorrow

Pull calendar events using the Google Calendar MCP tools:

- **Today's events:** Call `gcal_list_events` with `start` = start of today and `end` = end of today (in the timezone from me.md)
- **Tomorrow's events:** Call `gcal_list_events` with `start` = start of tomorrow and `end` = end of tomorrow

Both calls are independent — run them in parallel.

For each event:
- Note time, title, location, attendees
- Flag meetings that need prep (client calls, BD conversations)
- Flag back-to-back meetings with no buffer (less than 15 min gap)
- Flag events with physical locations (user may need drive time)

For meetings needing prep, call `gcal_get_event` with the event ID to retrieve attendees, description, and other event details. Run all `gcal_get_event` calls in parallel.

### Email Scan — Last 48 Hours

Scan email from monitored domains listed in the `## Email Monitoring` section of me.md:

- Call `gmail_search_messages` with query `from:domain1.com OR from:domain2.com newer_than:2d` (combining all monitored domains)

For each email found:
- Note the sender, subject, and date
- Determine if it looks like it needs a response or follow-up from the user
- Flag anything that appears unanswered

To read a specific message for more context, call `gmail_read_message` with the message ID.

If `## Notion: Clients` is enabled in me.md, also use the Notion MCP to pull client records from the configured `data_source` and extract any email domains. Search for those domains too.

### Notion — Active Projects + Pipeline

**If `## Notion: Projects` is enabled in me.md:**
- Query the database using the configured `database_id`
- Filter for items matching the configured `active_statuses`
- Display the configured `fields`

**If `## Notion: Pipeline` is enabled in me.md:**
- Query the database using the configured `database_id`
- Filter by the configured `active_statuses` on the configured `status_field`
- Note any configured `date_fields` for deadline tracking

**If neither Notion module is enabled, skip this section entirely.**
