# COS Morning Sweep Board Integration — Implementation Plan

**Goal:** Implement the approved Daily Board Phase 3 morning-sweep integration without adding an LLM call or risking existing Notion page sections.

**Architecture:** Add a deterministic shell helper that uses the existing `klmc-agent-home/bin/board` CLI. The morning skill invokes it once at start to ensure/carry forward the Board and write an in-progress run marker, then once after the configured brief delivery succeeds to upsert the existing sweep's one-line priorities and move the run marker to Done. A missing marker indicates a missed run; a marker left In Progress indicates an interrupted/failed run.

**Tech stack:** Bash, the existing `bin/board` CLI, Markdown skill instructions.

### Task 1: Add deterministic Board helper with tests

- Add `scripts/board-morning-sync.test.sh` first, covering fresh creation/carry-forward, existing-board idempotency, start/failure signal, and completion/priorities.
- Run it and confirm it fails because the helper is absent.
- Add distributable `plugins/cos/scripts/board-morning-sync.sh` with `start` and `complete` commands.
- Run the tests to green.

### Task 2: Wire morning-sweep and preserve shared Notion content

- Invoke `start` before data gathering.
- Invoke `complete --priorities <summary>` only after the existing Notion brief write succeeds.
- Make the Morning Brief writer update only its owned section and preserve Communications, Email Triage, drafts, outputs, and other skill-owned sections.
- Add the required pinned `daily_briefs_view_id` to setup collection and the generated config template.
- Preserve original carry-forward attribution in text while writing as Mane, because the live Board CLI's identity binding deliberately rejects cross-agent `--agent` values.

### Task 3: Release metadata and verification

- Bump both manifests to `0.7.0` (new integration/config option).
- Run shell tests, JSON validation, and targeted static assertions.
- Review the diff, commit on `feat/daily-board-integration`, push, and open a draft PR.
