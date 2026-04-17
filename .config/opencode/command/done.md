---
description: End meeting session and save notes to Obsidian
---

End this meeting session and save the notes to Obsidian. Follow the full SYNTHESIZE workflow below.

# Step 1: Search for Related Notes

Use `obsidian_obsidian_simple_search` to find:
- Notes with the same customer/person (search by name)
- Notes with the same topic/technology (search by topic keywords)
- Notes with matching tags (search for `tags: [tagname]` in frontmatter)

# Step 2: Determine Create vs Update

| Same Customer? | Same Topic? | Action |
|----------------|-------------|--------|
| Yes | Yes | **UPDATE** existing note (append new session) |
| Yes | No | **CREATE** new note (different topic = different note) |
| No | Yes | **CREATE** new note (shared tags will connect them) |
| No | No | **CREATE** new note |

**"Same Topic"** = core subject matter is the same, continuation of previous conversation, or follow-up on previous decisions.

**When uncertain**, ask:
```
I found an existing note: Work/Meetings/2026-01-07-azure-autoscaling-integration.md
This meeting seems related (same person, similar topic).

Should I:
1. **Update** the existing note with this new session?
2. **Create** a new note? (shared tags will still connect them)
```

# Step 3: Generate Tags

**Use TAGS for categorization (frontmatter):**
- People → `jubran`, `billy`, `person/john-smith`
- Technologies → `github-actions`, `terraform`, `kubernetes`, `azure`
- Topics → `autoscaling`, `ci-cd`, `infrastructure`
- Meeting types → `architecture`, `incident`, `planning`, `demo`
- Customers → `spacelift`, `customer/acme`

Use lowercase, hyphenated format. Tags go in frontmatter.

**Use WIKILINKS only for specific references** to prior decisions or design docs — not for categorization.

# Step 4: Consider Note Merging

If you find highly related notes (same topic, different people), suggest keeping separate or merging. Only suggest merging when the notes are complementary and consolidation reduces fragmentation.

# Step 5: Save Path Logic

```
IF updating existing note:
  path = existing note's path
  action = append new session with date header
ELSE IF customer/company identified:
  path = Work/Customers/{customer}/{date}-{topic}.md
ELSE:
  path = Work/Meetings/{date}-{topic}.md
```

# Step 6: Save the Note

**CRITICAL: Updates must be ADDITIVE ONLY. Never lose existing content.**

The Obsidian vault is at: `~/projects/src/github.com/theoutdoorprogrammer/obsidian/`

- **NEW notes**: Use the native `Write` tool
- **UPDATING existing notes**: Use native `Read` tool to get current content, then `Edit` tool to append

**DO NOT preview the content before saving.** The Edit/Write tools will prompt for permission — the user sees the content there.

Do NOT use Obsidian MCP write tools (put_file, post_file, etc.) — they are globally disabled.

## Note Template — New Notes:
```markdown
---
date: {YYYY-MM-DD}
tags: [meeting, {person-tags}, {topic-tags}, {tech-tags}]
---

# {Meeting Title}

**Meeting Type**: {inferred or specified}
**Attendees**: {names captured during meeting}

## TL;DR
{2-3 sentence summary of the meeting}

## Key Decisions
- {Decision 1}
- {Decision 2}

## Action Items
- [ ] {Action} - {Owner if known}
- [ ] {Action} - {Owner if known}

## Discussion Notes
{Structured breakdown of topics discussed, organized by theme}

## Open Questions
{Questions that weren't answered or need follow-up}

## Risks & Concerns
{Potential issues or risks identified during discussion}

## Raw Notes
{Original input preserved verbatim for reference}
```

## Note Template — Appending to Existing Notes:
```markdown

---

## Session: {YYYY-MM-DD}

**Attendees**: {names for this session}

### Updates
{What changed or was decided in this session}

### New Action Items
- [ ] {Action} - {Owner}

### Discussion
{Notes from this session}

### Raw Notes
{Original input from this session}
```

# Step 7: Git Commit the Note

After saving:
```bash
# Stage and commit (use workdir parameter, don't cd)
git add "{path-to-note}.md"
git commit -m "meeting notes: {topic} with {person}"
```

Working directory: `~/projects/src/github.com/theoutdoorprogrammer/obsidian`

Commit message format:
- New note: `meeting notes: {topic} with {person/customer}`
- Updated note: `meeting notes: update {topic} - {brief change summary}`

Do NOT push. If git fails, report the error but don't block — the note is already saved.

# Step 8: Update Board with Personal Todos

If there are action items assigned to Joey from this meeting, add them to `Board.md` (vault root).

**When to update the board:**
- Action item is explicitly assigned to Joey/you/me
- Action item has no owner but is clearly Joey's responsibility
- Do NOT add items assigned to other people

**Priority Inference:**
- **High**: Explicit deadline, customer-facing, blocking others, urgent language
- **Medium**: Important but no hard deadline, internal improvements, follow-ups
- **Low**: Nice-to-have, backlog items
- **If uncertain**: Ask the user which priority

Joey works from the bottom of the column to the top. High priority items go at the bottom of the High Prio column.

**Card Format:**
```markdown
- [ ] {Brief description}
	[[{absolute-path-to-note}]]
```

Add ALL cards in a single Edit operation. Use the native `Read` tool to get Board.md, then `Edit` to insert cards under the appropriate heading.
