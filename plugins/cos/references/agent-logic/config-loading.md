## Config Loading

Read `${CLAUDE_PLUGIN_DATA}/me.md`. If it doesn't exist, tell the user: "No config found. Let me walk you through setup." Then run `/cos:setup` and stop.

### me.md may be monolithic or a cluster

Both layouts are valid; support both.

- **Monolithic** — every `## Section` inline in `me.md`. The default, and what setup writes unless the user chooses otherwise.
- **Cluster** — `me.md` is an index whose sections are `[[wiki-links]]` to files in `${CLAUDE_PLUGIN_DATA}/me/`. Resolve per `${CLAUDE_PLUGIN_ROOT}/references/config-resolution.md`: `[[voice]]` → `${CLAUDE_PLUGIN_DATA}/me/voice.md`.

In cluster form, **read only the linked files whose values this run needs** — the list below is what is *available*, not a checklist to load. A morning sweep needs `## Identity` and `## Email Monitoring` and has no use for `## Voice`; `email-voice-draft` is the reverse.

Two exceptions load every run regardless of task: `## Identity` (timezone gates every displayed time) and `## My Rules` / `## Custom Rules` (user-defined rules are not skippable — same reasoning as `[[core-rules]]`).

If a linked file is missing, log `config link [[name]] unresolved` once and continue with what resolved. Do not run `/cos:setup` for a missing *link* — only for a missing `me.md`.

### Available values

These live in `me.md` directly (monolithic) or in the linked file named by the section (cluster):
- `timezone` from `## Identity`
- `role` from `## Identity`
- `domains` from `## Email Monitoring`
- Notion module flags (`enabled: true/false`) from `## Notion: Projects`, `## Notion: Pipeline`, `## Notion: Clients`, `## Notion: Tasks`
- `daily_briefs_database_id` from `## Notion: Daily Briefs`
- `daily_briefs_view_id` from `## Notion: Daily Briefs` — the pinned, dedicated view used by the Daily Brief Guard procedure (`${CLAUDE_PLUGIN_ROOT}/references/daily-brief-guard.md`) for deterministic find-or-create. Required whenever Daily Briefs is enabled.
- All rules from `## My Rules` and `## Custom Rules`

If Daily Briefs is enabled but `daily_briefs_database_id`/`database_id` or `daily_briefs_view_id` is missing, stop before any Notion query or page creation and run `/cos:setup` to repair config. Never fall back to an arbitrary database view.
