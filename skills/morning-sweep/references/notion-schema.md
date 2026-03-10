# COS Daily Briefs — Notion Schema

## Database Properties

| Property     | Type   | Values / Notes                 |
|--------------|--------|--------------------------------|
| Name         | title  | "Morning Sweep — YYYY-MM-DD"   |
| Date         | date   | Sweep date (ISO 8601)          |
| Status       | select | Draft, Complete, Reviewed      |
| Red Count    | number | Count of RED items             |
| Yellow Count | number | Count of YELLOW items          |

## Page Body Structure

Write the page body with these sections in order, using Notion heading blocks:

### 1. Morning Brief
The full classified brief (same format as Step 4 output in the sweep).
Use Notion paragraph blocks. Use bold for section headers within the brief
(CALENDAR TODAY, RED - YOURS, etc.)

### 2. Drafts: Gmail
Bulleted list of Gmail drafts created during this sweep.
Format each as: "**To:** [recipient] — **Subject:** [subject] — Draft created in Gmail"

### 3. Drafts: Adapture
For each Adapture draft, create a heading_3 block with the subject line,
then a code block containing:

```
To: recipient@adapture.com
Subject: The subject line

Body of the email here.
```

The user will copy this block and paste it into Outlook to send.

### 4. Outputs
Any structured outputs from the sweep:
- Expense data: use Notion code blocks with CSV content
- Checklists: use Notion to_do blocks
- Action items: use Notion bulleted_list blocks

## Writing to the Database

Use the Notion MCP `notion-create-pages` tool:
1. Set parent to the Daily Briefs database ID from config
2. Set the Name (title) property to "Morning Sweep — YYYY-MM-DD"
3. Set Date to today's date
4. Set Status to "Draft"
5. Set Red Count and Yellow Count from classification results
6. Add page body content as children blocks

After the sweep is complete and user has said "go" and all actions are done,
update the page Status to "Complete" using `notion-update-page`.
