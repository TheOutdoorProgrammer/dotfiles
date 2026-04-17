---
description: Summarize my Obsidian kanban board (excluding Freezer/Low Prio and Done) and google calendar for the week.
agent: spacelift
---

Use all available sources to bring my Obsidian board and notes up to date, then generate a weekly summary for my boss based on the updated Obsidian content and calendar.
I use slack to share updates, so keep it concise and actionable.

# Sources

- Obsidian via the Obsidian MCP server
- Google Calendar via the Calendar MCP server (Joey Stout calendar only)
- Slack via the agent-slack skill (only messages with substantive work content)
- Notion via the Notion MCP server (internal Spacelift docs, runbooks, team knowledge)
- GitHub via `gh` CLI — issues and PRs across `spacelift-io`, `spacelift-io-examples`, and `spacelift-solutions` orgs (GitHub handle: `TheOutdoorProgrammer`)
- Granola via the Granola MCP server — meeting notes and transcripts from the previous week

# Workflow

This command runs in 3 phases. **Do NOT skip ahead** — complete each phase and wait for user input before proceeding to the next.

> **⚠️ CRITICAL RULE: READ-ONLY UNTIL APPROVED.**
> Do NOT write, edit, or create any files (notes, board cards, or anything else) until Phase 2 suggestions have been explicitly approved by the user. Phase 1 is strictly read-only. Phase 2 is presentation-only. Only after the user gives the thumbs up do you touch any files.

## Phase 1: Gather Data

Data gathering happens in two stages. **Stage 1** establishes what you know (board + meetings). **Stage 2** uses that combined context to search external sources with precision. Subtasks keep raw data out of the main context — each returns a **condensed digest only**.

### Step 1: Establish context — Board (do this yourself — no subtask)

1. Run date commands to get the current week boundaries and the previous week:
   ```bash
   date +%Y-%m-%d                # today's date
   date -v-monday +%Y-%m-%d     # Monday of current week
   date -v+friday +%Y-%m-%d     # Friday of current week
   date -v-monday -v-7d +%Y-%m-%d  # Monday of previous week
   date -v+friday -v-7d +%Y-%m-%d  # Friday of previous week
   ```
   Store these as `$TODAY`, `$WEEK_START`, `$WEEK_END`, `$PREV_WEEK_START`, `$PREV_WEEK_END`.

2. Fetch `Board.md` (at vault root) using obsidian_get_file and parse it yourself. **IGNORE** these columns: "Freezer / Low Prio", "Done", "Archive". For each remaining column (Medium Prio, To Do / High Prio, In Progress, Awaiting Customer, Awaiting Dev / Review), note the items. Build a structured list of board items with their column, title, and any linked resources (Slack URLs, Obsidian links, GitHub links).

### Step 2: Establish context — Granola (sequential, before other subtasks)

**This step runs BEFORE the other subtasks because its output shapes what they search for.**

Spawn a single subtask using `subagent_type='worker'`:

**Subtask: Granola Meeting Notes** (`subagent_type='worker'`):
- Use `granola_list_meetings` with `time_range='last_week'` to get all meetings from the previous week.
- Use `granola_get_meetings` on all returned meeting IDs (batch up to 10 at a time) to get summaries, attendees, and action items.
- Cross-reference meeting content against the board items (include the full board item list in the prompt). Look for:
  - Action items or commitments Joey made during meetings that aren't tracked on the board yet
  - Decisions made that affect board item status (e.g., scope changes, approvals, blockers identified)
  - New customer engagements, demos, or prospects discussed that should become board cards
  - Follow-ups or deliverables with deadlines that are overdue or coming up this week
  - Context that should be added to existing Obsidian notes (e.g., meeting outcomes for linked notes)
- **Do NOT use `granola_get_meeting_transcript`** unless a specific meeting summary is too vague to extract action items. Summaries are usually sufficient.
- Return a digest with two sections:
  1. **Board-relevant meetings:** meeting title, date, key takeaways that affect board items (2-3 sentences per meeting)
  2. **New items not on board:** any commitments, follow-ups, or new work that doesn't have a board card yet — include names, dates, and enough context that subsequent subtasks can search for related activity

**Wait for this subtask to complete before proceeding to Step 3.** Read its digest and merge the findings with your board item list. You now have a **combined search list**: board items + Granola-surfaced items. This is what drives the parallel subtasks.

### Step 3: Parallel subtasks — external sources

Now spawn these subtasks **in parallel**. **Include both the board items AND the Granola-surfaced items** in each subtask's prompt so they know the full scope of what to search for.

Use `subagent_type='worker'` for all subtasks. Accuracy matters more than speed — every subtask needs to cross-reference findings with the combined search list and produce a thoughtful digest, not just dump raw output.

**Subtask A — Linked Notes** (`subagent_type='worker'`):
- For each board card that contains an Obsidian link (`[[note-name]]`), fetch that note using `obsidian_obsidian_get_file`
- Also check if any Granola-surfaced items reference topics that might have existing notes in the vault
- Return a digest: card title → key context from the linked note (2-3 sentences max per note)

**Subtask B — Google Calendar** (`subagent_type='worker'`):
- Use `list-calendars` MCP tool to find the Joey Stout / primary work calendar (ignore family, holidays, etc.)
- Use `list-events` for `$WEEK_START` to `$WEEK_END`
- Use `get-event` for details on anything that looks relevant to board items or Granola-surfaced items
- Return a digest: list of work meetings/events with date, time, title, and relevance to the combined search list

**Subtask C — Slack** (`subagent_type='worker'`, `load_skills=['agent-slack']`):
- For each board item that has a Slack link, fetch the message/thread
- Search Slack for updates on In Progress and High Priority board items
- **Also search for Granola-surfaced items** — new customer names, meeting topics, commitments made. These may have related Slack threads that aren't linked on the board yet.
- **Only surface substantive work content** — status updates, decisions, blockers, action items. Skip casual conversation.
- **NEVER use `agent-slack message send`** — read only.
- Return a digest: item → latest status/updates from Slack (2-3 sentences max per item)

**Subtask D — Notion** (`subagent_type='worker'`):
- Use `notion_notion-search` with targeted queries for In Progress and High Priority board items
- **Also search for Granola-surfaced items** — customer names, product features, deal names that came up in meetings.
- Look for: engineering design docs, product announcements, team decisions, runbooks
- Return a digest: item → relevant Notion findings (2-3 sentences max per item)

**Subtask E — GitHub** (`subagent_type='worker'`):
- Run these `gh` CLI commands (substitute `$WEEK_START` with the actual date):
  ```bash
  # PRs authored (open + recently updated)
  gh search prs --author TheOutdoorProgrammer --owner spacelift-io --owner spacelift-io-examples --owner spacelift-solutions --updated ">=$WEEK_START" --json title,repository,state,url,updatedAt

  # PRs requesting review
  gh search prs --review-requested TheOutdoorProgrammer --owner spacelift-io --owner spacelift-io-examples --owner spacelift-solutions --state open --json title,repository,state,url,updatedAt

  # PRs reviewed this week
  gh search prs --reviewed-by TheOutdoorProgrammer --owner spacelift-io --owner spacelift-io-examples --owner spacelift-solutions --updated ">=$WEEK_START" --json title,repository,state,url,updatedAt

  # Issues involving you (authored, assigned, mentioned, commented)
  gh search issues --involves TheOutdoorProgrammer --owner spacelift-io --owner spacelift-io-examples --owner spacelift-solutions --updated ">=$WEEK_START" --json title,repository,state,url,updatedAt
  ```
- Deduplicate across queries
- Return a digest: grouped by repo — title, state, URL. Note which items relate to board cards or Granola-surfaced items.

### Step 4: Collect and synthesize

Wait for all parallel subtasks to complete, then read their digests. Cross-reference findings across all sources — if Slack, Notion, GitHub, and Granola all mention the same item, that's a strong signal for Phase 2. Pay special attention to Granola action items and commitments — these often surface overdue deliverables that other sources miss. You now have full context without the raw data bloating the conversation.

## Phase 2: Suggest Note Updates

Based on what you found in Slack, Notion, GitHub, Granola, and calendar, **present a numbered list of suggested updates** to Obsidian notes and board cards. Examples:
- Action items that have progressed since the card was last updated
- New information from threads (approvals, blockers, decisions)
- Cards that should be moved between columns based on current status
- Stale card descriptions missing context discovered in Slack, Notion, or GitHub
- PRs merged/closed that indicate a board item is done or progressed
- New issues or review requests that should become board cards
- Commitments made in meetings (from Granola) that are overdue or need tracking
- New customer engagements or demos from Granola that should become board cards

### ⚠️ Board Hygiene (ALWAYS ENFORCE)

**This applies to ALL cards on the board — not just items with new updates.** Scan the entire board for hygiene violations and suggest fixes even if a card has no status changes this week.

**Rule 1 — Keep cards concise.** A card should be a short title + at most a Slack link and/or an Obsidian `[[note-link]]`. If a card has more than ~2 lines of content, **suggest creating a dedicated note** in `Work/` (or `Work/Notes/`) and replacing the card's body with a `[[note-link]]`. Move the detail into the note. This keeps the board scannable. **Status updates and context belong in the linked note, never on the card itself.**

**Rule 2 — Hyperlink all URLs.** Raw URLs on cards should be converted to markdown hyperlinks (`[descriptive text](url)`). Slack links should use the format `[Slack thread](url)`, GitHub PRs should use `[PR #123: title](url)`, etc. If a card has bare URLs, suggest fixing them.

**Rule 3 — Absolute wikilinks.** All `[[note-links]]` on cards must use absolute vault paths (e.g. `[[Work/Notes/AFT]]`, not `[[AFT]]`). If you encounter a dead or ambiguous wikilink, ask Joey to locate the correct file before updating it.

**Rule 4 — GitHub PR closing requires permission.** Never close a PR on GitHub without first asking Joey for approval. When proposing to close a PR, include the comment you plan to leave so Joey can review it before you act.

**Rule 5 — Suggest freely.** If you see ANY card violating these rules — even cards with no new activity — include a hygiene suggestion. These are separate from status-update suggestions and should be clearly labeled as "Board hygiene" in the question tool options.

**Use the `question` tool to get user approval.** Present each suggestion as an option with `multiple: true` so the user can select which updates to apply. Include a clear description for each option explaining what will change. Only apply the updates the user selects.

## Phase 3: Generate Summary

After note updates are applied (or skipped), generate the weekly summary. **The summary is derived from Obsidian and calendar — not raw source data.** All the Slack/Notion/GitHub context should already be baked into the board and notes from Phase 2.

1. **Re-read** the updated `Board.md` (at vault root) and any linked notes using obsidian_get_file. This is your source of truth — do not summarize from Phase 1 data.
2. Pull the calendar events gathered in Phase 1 (or re-fetch if needed).
3. Format the summary for Slack (use `*bold*` mrkdwn, not markdown `**bold**`).
4. Include a quick overview at the top:
   - Total active items (excluding freezer/done)
   - Items currently in progress
   - Items blocked/awaiting others
5. For each active column, summarize items concisely with current status and next actions.
6. Include calendar highlights for the week — upcoming meetings, demos, workshops, deadlines. This helps my boss know what's on my plate beyond just task work (work meetings only, skip personal blocks).
7. Open a draft DM to Chris D (U07347FH18A) with the summary.
   **IMPORTANT**: Use `pty_spawn` so the draft UI stays alive after the agent finishes. The CLI exits on its own when the user is done.
   ```
   # First, get the DM channel ID (regular bash is fine for this)
   agent-slack user dm-open U07347FH18A

   # Then spawn the draft in a persistent PTY — do NOT use regular bash for this
   pty_spawn command="agent-slack" args=["message", "draft", "<dm-channel-id>", "<summary text>"] title="Weekly Summary Draft"
   ```
   This opens a browser-based rich-text editor so the user can review, tweak, and send manually. The PTY keeps the process alive until the user finishes.
   **NEVER use `agent-slack message send`** — draft only.
