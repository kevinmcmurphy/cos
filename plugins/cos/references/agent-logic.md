# COS Agent Logic

Index for shared behavior across all COS skills: config loading, timezone handling, data gathering, email routing, task creation, and the core safety rules.

**This is an index, not a document.** Load only what your task needs — see `config-resolution.md`. The two `Always` entries below are the exception and must be read every run.

## Always

- [[config-loading]] — reads `me.md` and establishes timezone, role, monitored domains, and which Notion modules are enabled. Nothing else can be resolved before this.
- [[core-rules]] — the non-negotiable safety rules (never send email without review, never auto-archive, relationship-sensitive comms go to the user), the Immediate Execution Rule, source linking, and voice/style. **Never defer this.** A skill cannot determine whether it needs a safety rule by inspecting its own task; that is exactly the reasoning these rules exist to override.

## On demand

- [[timezone]] — the non-negotiable timezone rule for anything shown to the user, and the timezone boundary for "today" in email queries. Load when rendering or comparing times.
- [[notion-writeback]] — rules for writing back to Notion without clobbering existing content. Load before any Notion write.
- [[data-gathering]] — calendar for today and tomorrow, the 48-hour email scan, and active Notion projects and pipeline. Load when gathering sweep inputs.
- [[email-routing]] — connected vs. unconnected account handling and per-account send instructions. Load when producing a draft the user must send.
- [[task-creation]] — creating Notion tasks with the right project and due date. Load when writing tasks.

## Note on `Always`

Marking only two entries `Always` is deliberate. A safety rule that is loaded conditionally is not a safety rule. If a future section carries a rule the system must never skip, it belongs in [[core-rules]] rather than in a new `Always` entry — one always-loaded rules file is easier to keep honest than several.
