---
name: email-triage
description: >
  Triage email using the Email GPS taxonomy. Use when asked to "triage
  email", "check inbox", "what needs my reply", "any new emails",
  "clear the inbox", "GPS my email", or "what's in my inbox". Orchestrates
  classify → voice-draft → notion-sink in sequence.
---

# Email Triage — Chief of Staff

You are the user's Chief of Staff. This skill is the thin orchestrator for the email triage workflow. It invokes three sub-skills in sequence and passes the handoff shape between them. Decision logic, GPS taxonomy, firewall rules, and output format are all in `${CLAUDE_PLUGIN_ROOT}/references/email-triage.md`.

Safe to run multiple times per day — re-triage logic in `email-classify` skips already-handled threads without new activity.

## Before You Start

Load config and apply all rules per `${CLAUDE_PLUGIN_ROOT}/references/agent-logic.md`.

Read `${CLAUDE_PLUGIN_ROOT}/references/email-triage.md` for the full reference: GPS taxonomy, skill handoff contract, output format, and all decision rules.

## Step 1: Classify

Run `${CLAUDE_PLUGIN_ROOT}/skills/email-classify/SKILL.md`.

If a `daily_brief_page_id` is available from a calling parent skill (morning-sweep or evening-review), pass it in and instruct email-classify to skip its Step 2. Otherwise let email-classify manage page discovery.

Receive the classified thread list handoff shape.

## Step 2: Voice Draft

Run `${CLAUDE_PLUGIN_ROOT}/skills/email-voice-draft/SKILL.md`, passing the classified thread list handoff shape from Step 1.

Receive the draft results handoff shape.

## Step 3: Notion Sink

Run `${CLAUDE_PLUGIN_ROOT}/skills/email-notion-sink/SKILL.md`, passing the full handoff shape (classified threads + draft results) from Steps 1–2.

## Invocation from morning-sweep and evening-review

Each parent skill invokes this orchestrator with one line:

> Run the email triage skill at `${CLAUDE_PLUGIN_ROOT}/skills/email-triage/SKILL.md`, passing today's Daily Brief page ID and skipping email-classify's Step 2.

The orchestrator passes the page ID through to email-classify and email-notion-sink via the handoff shape.
