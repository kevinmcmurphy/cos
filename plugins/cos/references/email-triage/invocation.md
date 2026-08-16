## Invocation from Parent Skills

When the email triage workflow is invoked as a sub-step of `morning-sweep` or `evening-review`:

- The calling skill already has the Daily Brief page ID. Pass it into the `email-classify` skill as `daily_brief_page_id` — skip Step 2 of the orchestrator.
- The `email-notion-sink` skill still appends an `Email Triage — HH:MM ET` section to the same Daily Brief page. The parent skill's `Drafts: Gmail` and `Outputs` sections receive the draft and task entries as usual.
- The `email-notion-sink` skill still emits conversation output, but the parent may fold it into its final summary rather than presenting it as a standalone block.

Each parent skill step invokes the `email-triage` orchestrator with one line:

> Run the email triage skill at `${CLAUDE_PLUGIN_ROOT}/skills/email-triage/SKILL.md`, passing today's Daily Brief page ID and skipping its Step 2.

---
