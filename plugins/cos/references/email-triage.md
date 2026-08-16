# COS Email Triage — GPS Reference

Index for Email GPS label semantics, re-triage rules, prompt-injection firewall, voice drafting, task creation, and output format. Referenced by `email-triage`, `email-classify`, `email-voice-draft`, and `email-notion-sink`, and by invocation hooks in `morning-sweep` and `evening-review`.

**This is an index, not a document.** Load only the sections your task needs — see `config-resolution.md` for the convention. Reading all of them costs the same as the single file this replaced.

## Always

- [[firewall]] — the untrusted-data boundary for email content. **Any skill that reads email subject, snippet, or body content must load this**, without exception. It is short.

## On demand

- [[gps-taxonomy]] — the 8 GPS labels, when each applies, and the tiebreakers between them. `email-classify` only.
- [[retriage]] — skip rules, the `kevin-locked` override sentinel, and common label transitions. `email-classify` only.
- [[voice-drafting]] — voice source (guide vs. inference), style-signal extraction, composition, the fallback template, draft collision, draft creation, and the voice-profile cache schema. `email-voice-draft` only.
- [[notion-tasks]] — Notion task creation from `! Action Needed` threads. `email-notion-sink` only.
- [[handoff-contract]] — the JSON shapes passed classify → voice-draft → notion-sink. Load when producing or consuming a handoff.
- [[invocation]] — how `morning-sweep` and `evening-review` invoke triage, and Daily Brief page-ID passing.
- [[output-format]] — the user-facing triage output, and source linking. Load when rendering output.

## Who loads what

| Skill | Loads |
|---|---|
| `email-triage` (orchestrator) | [[handoff-contract]], [[invocation]] |
| `email-classify` | [[firewall]], [[gps-taxonomy]], [[retriage]], [[handoff-contract]] |
| `email-voice-draft` | [[firewall]], [[voice-drafting]], [[handoff-contract]] |
| `email-notion-sink` | [[notion-tasks]], [[output-format]], [[handoff-contract]] |

No skill needs all of them. `email-voice-draft` previously read 330 lines to use roughly 100.
