# COS Plugin — Developer Notes

## Versioning Conventions

This repo follows semantic versioning (semver: MAJOR.MINOR.PATCH).

### When to increment each component

| Change type | Version component | Examples |
|------------|------------------|---------|
| Bug fix, behavior correction, documentation clarification | **PATCH** (0.3.x) | Fixing a timezone bug, tightening an ambiguous rule, adding a missing buffer duration |
| New feature, new config option, new skill step, new reference section | **MINOR** (0.x.0) | Adding a new skill, adding a new Notion module, introducing a new classification category |
| Breaking change — removes existing behavior, changes config schema, renames skills | **MAJOR** (x.0.0) | Renaming a skill, removing a me.md config field, changing the Daily Brief page structure |

### Patch criteria (do NOT bump minor for these)

All of the following qualify as patch-only changes:
- Fixing a rule that was ambiguous or underspecified
- Adding a missing default value (e.g., buffer duration in capacity calculation)
- Correcting behavior to match documented intent
- Adding a fallback/safety check that prevents silent failures
- Timezone, boundary, or date math corrections
- Tightening an aging rule or persistence rule

### Version bump locations

When releasing any version, update **both** of the following files:
1. `plugins/cos/.claude-plugin/plugin.json` — `version` field
2. `.claude-plugin/marketplace.json` — `version` field

These must always match. A mismatch is a release error.

### Commit and tag conventions

- Branch: `fix/<topic>` for patches, `feat/<topic>` for minor features
- Commit message: `fix(<scope>): description` or `feat(<scope>): description`
- After merging to main: tag as `vX.Y.Z` and push the tag

### Current version history

| Version | Date | Summary |
|---------|------|---------|
| 0.1.0 | — | Initial release |
| 0.2.0 | — | Added Pre-planned Path, carryover aging, evening review step 6 |
| 0.3.0 | — | MCP migration (gws → gcal/gmail MCPs), Immediate Execution Rule, Cold Start restructure, inline aging |
| 0.3.1 | 2026-03-26 | Sweep quality gates: brain dump gate, timezone rule, material change check, GRAY persistence, fallback evening detection, meeting buffer, email timezone boundary, Cold Start evening context |
| 0.4.0 | 2026-05-04 | Local daily-sweep artifact written by morning-sweep and evening-review |
| 0.5.0 | 2026-05-22 | Email Triage: GPS-label classifier (8 labels, multi-inbox klmc suffix), voice-matched drafting, Notion task creation. Split into email-classify / email-voice-draft / email-notion-sink sub-skills. Prompt-injection firewall, voice-profile cache, kevin-locked sentinel, supersede output, gmail_* tool names, Gmail Thread ID dedup. |
| 0.6.0 | 2026-07-30 | Unstall Three: morning-sweep surfaces up to 3 `[unstall]`-prefixed mane-db tasks (owner kevin, open, priority-then-oldest) as a low-pressure "your 10 minutes" section; evening-review closes them out (mark done in mane-db, not-done carries implicitly). Deterministic bash/jq gather + close-out, no LLM-side querying. New shared reference `unstall-three.md`. |
| 0.7.0 | 2026-08-05 | Daily Board morning integration: deterministic create/carry-forward, priorities upsert, visible start/completion signal, shared Notion-section preservation, and required pinned-view setup. |
| 0.7.1 | 2026-08-15 | Email voice: default sign-off is `–KM`. Fixes the no-historical-correspondence fallback template, which signed `Best,\nKevin`, and the sign-off style signal, which listed `Best,` as a valid inferred value and would have kept re-deriving it from sent mail even after the template fix. |
| 0.8.0 | 2026-08-15 | Voice becomes configuration. New `## Voice` section in `me.md`: `sign_off` (literal, verbatim), `voice_guide` (path to a written guide), `voice_profile_store`. When `voice_guide` is set, drafting reads it once per run and skips per-recipient sent-mail profiling entirely — removing up to 25 `FULL_CONTENT` thread fetches from a 5-draft run. Reverts 0.7.1's hardcoded `–KM`, which was a personal preference baked into a shared plugin. Also: a voice-profile store whose table is missing is now reported once as unavailable instead of silently missing on every lookup and refetching forever. Setup gained a Voice step. |
| 0.9.0 | 2026-08-15 | Reference and config files become wiki-linked clusters loaded on demand. New `references/config-resolution.md` defines the convention: a file is either monolithic or an index of `[[links]]` resolved to a sibling directory, read when needed rather than on sight, with `ALWAYS` entries for rules that must never be deferred. `email-triage.md` (330 lines, read whole by all four triage skills) and `agent-logic.md` (read by every skill) split into clusters; skills now name the sections they need. `me.md` may optionally be a cluster too — setup offers the choice and defaults to one file. Content moved verbatim; backward-compatible, so monolithic files keep working. |
| 0.9.1 | 2026-08-28 | Cloud Board checkpoints use the shared `memory-publish` publisher, reuse one deterministic date-keyed branch, and require an existing canonical Board role before producing. |
