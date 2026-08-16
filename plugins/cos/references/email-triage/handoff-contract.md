## Skill Handoff Contract

When the email triage workflow is split across `email-classify`, `email-voice-draft`, and `email-notion-sink`, the following data shapes are passed between skills:

### classify → voice-draft

```
{
  "daily_brief_page_id": "<notion-page-id>",
  "classified_threads": [
    {
      "threadId": "<gmail-thread-id>",
      "label": "<exact GPS display name>",
      "sender": "<sender-email>",
      "subject": "<subject-line>"
    }
  ]
}
```

### voice-draft → notion-sink

```
{
  "daily_brief_page_id": "<notion-page-id>",
  "classified_threads": [ /* same shape as above */ ],
  "draft_results": [
    {
      "threadId": "<gmail-thread-id>",
      "draftId": "<gmail-draft-id-or-null>",
      "status": "created | skipped_existing | skipped_collision_check_failed | skipped_cap | no_draft_needed"
    }
  ]
}
```

The `email-triage` orchestrator passes the appropriate slice of this data to each sub-skill in sequence.

---
