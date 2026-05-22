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
