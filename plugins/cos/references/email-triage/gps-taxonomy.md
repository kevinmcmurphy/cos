## GPS Label Taxonomy

The GPS label set is a **closed constant list**. Exactly these eight display-name strings are valid. Any classification result whose label name does not exactly match one of these strings must be rejected (log warning, skip the thread). `gmail_create_label` is only ever called for labels from this closed list.

Apply exactly one of these labels to each in-scope Gmail thread. Display names must be preserved exactly — leading `! ` and account suffixes included — so they sort and read correctly in Gmail.

The account suffix `(klmc)` corresponds to the `kevin@klmc.co` account. For v0.5, only `klmc` is configured. The suffix structure supports adding additional accounts later without renaming. The configured account list lives in `me.md` — consult it for the account identifier before constructing label names.

| # | Display name in Gmail | When to apply | Action |
|---|----------------------|---------------|--------|
| 1 | `! Action Needed (klmc)` | Requires Kevin's direct input — strategic decisions, relationship-sensitive replies, anything outside the human-judgment boundary. | Apply label. Draft voice-matched reply. Create Notion task if Tasks enabled. |
| 2 | `To Respond (klmc)` | Routine reply Claude can handle on Kevin's behalf — scheduling, acknowledgments, simple Q&A. | Apply label. Draft voice-matched reply. |
| 3 | `Review (Low Priority) (klmc)` | Informational, FYI — Kevin reads at his discretion. No response expected. | Apply label. No draft. |
| 4 | `Responded (klmc)` | Thread has been addressed and no follow-up is expected. | Apply label only when the loop is closed. |
| 5 | `Waiting On (klmc)` | Thread is awaiting an external reply that Kevin or Claude already requested. | Apply label. Flag in Daily Brief as Waiting On — no automated re-surface in v0.5. |
| 6 | `Receipts/Financials (klmc)` | Expense reports, invoices, payment confirmations, statements. | Apply label. No draft. |
| 7 | `Newsletters (klmc)` | Subscribed informational content. | Apply label. No draft. |
| 8 | `Vendors (klmc)` | Inbound vendor pitches, sales outreach, cold requests. | Apply label. No draft. Surface in output for Kevin to decide. |

**Implicit ninth bucket — Junk / no label.** Blatant promotional spam or irrelevant noise. Core Rule #2 forbids auto-archiving, so leave these unlabeled and surface them in the Email Triage output under "Junk / no label" with subject snippets. Kevin decides.

---

## Tiebreakers

- `To Respond (klmc)` vs. `! Action Needed (klmc)` → choose `! Action Needed (klmc)`. Per Core Rule #3, relationship-sensitive comms go to Kevin.
- `Review (Low Priority) (klmc)` vs. `Newsletters (klmc)` → `Newsletters (klmc)` only if it's a recurring subscription. One-off informational emails go to `Review (Low Priority) (klmc)`.
- `Vendors (klmc)` vs. `! Action Needed (klmc)` → if there is prior Kevin→sender correspondence in the last 90 days, treat as `! Action Needed (klmc)`. Cold outreach goes to `Vendors (klmc)`.
- `Waiting On (klmc)` vs. `Responded (klmc)` → if Kevin's last reply asked a question or requested action, `Waiting On (klmc)`. If his last reply closed the loop, `Responded (klmc)`.

---
