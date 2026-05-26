# COS Local Daily-Sweep Artifact

Shared write procedure for the local daily-sweep artifact. Referenced by `morning-sweep/SKILL.md` and `evening-review/SKILL.md`. Both skills include only their own section template and a one-line reference to this file for the shared procedure.

The local artifact is **non-fatal** — if any file operation fails, report the error in the final summary to Kevin but do not retry and do not unwind any prior Notion or Telegram writes.

## Repo Root Resolution

Resolve `REPO_ROOT` using this priority order:
1. Check environment variable `$KLMC_REPO`. If set and the path contains `agents/registry.yaml`, use it.
2. Check `/Users/kevin/Projects/klmc-agent-home`. If it exists and contains `agents/registry.yaml`, use it.
3. Fall back to `./` (current working directory). Note in final summary: "Local artifact written to ./reports/daily-sweeps/ — repo root could not be auto-detected."

## Paths

```
YMD  = current date in America/New_York  (format: YYYY-MM-DD)
DIR  = $REPO_ROOT/reports/daily-sweeps
FILE = $DIR/$YMD.md
LINK = $DIR/latest.md
```

## mkdir / Rotate / Symlink Steps

1. Run: `/bin/mkdir -p "$DIR"`

2. **Morning sweep — rotate on same-day re-run:** If `$FILE` already exists, run:
   `/bin/mv "$FILE" "$DIR/$YMD.prev.md"`
   (This overwrites any older `.prev.md`. It is a crash-recovery safety net, not an archive.)

   **Evening review — handle missing file (morning sweep was skipped):** If `$FILE` does not exist, create it with frontmatter only before appending:
   ```
   ---
   date: YYYY-MM-DD
   timezone: America/New_York
   created_by: cos:evening-review
   created_at: YYYY-MM-DDTHH:MM:SS-HH:MM
   ---

   # Daily Sweeps — YYYY-MM-DD
   ```

3. Write or append the section per the calling skill's section template (see that skill's SKILL.md). Fill each bracketed field from context already available in the session. If a field value is unavailable, write `_unavailable_`. For empty list subsections, write `_none_` under the heading.

4. Update the symlink atomically. Run these two commands in sequence:
   ```
   cd "$DIR"
   /bin/ln -sfn "$YMD.md" latest.md
   ```
   Use exactly `/bin/ln -sfn` (not `rm` + `ln`). The target is a relative basename, not an absolute path.

## On Error

If step 1, 2, 3, or 4 fails:
- Do not retry.
- Do not unwind Notion or Telegram writes (they are already complete).
- Include this in the final summary to Kevin: "Local sweep artifact write failed: [error description]. Notion brief and Telegram summary were not affected."
