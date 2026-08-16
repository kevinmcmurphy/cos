## Re-triage Rules

Skip a thread if **all** of the following are true:
- The thread already has at least one GPS label.
- The thread has no unread messages.
- The newest message in the thread is older than 24 hours.
- The thread does **not** have the `kevin-locked` label.

Otherwise, re-classify. Re-classification may keep or change labels. When changing a label, remove the old GPS label (`gmail_unlabel_thread`) and add the new one (`gmail_label_thread`) — do not leave both attached.

### `kevin-locked` Override Sentinel

If a thread has the `kevin-locked` Gmail label, skip it in all re-triage passes regardless of unread status or age. Kevin applies `kevin-locked` manually to opt a thread out of re-triage permanently (e.g., a thread he is personally managing or monitoring). The classify skill must check for `kevin-locked` in the skip rule before all other conditions.

Common re-triage transitions:
- `! Action Needed (klmc)` → `Responded (klmc)` after Kevin replies.
- `To Respond (klmc)` → `Responded (klmc)` after the draft is sent.
- `Waiting On (klmc)` → `! Action Needed (klmc)` when a reply arrives requiring decision.
- `Waiting On (klmc)` → `To Respond (klmc)` when a reply arrives requiring routine response.

---
