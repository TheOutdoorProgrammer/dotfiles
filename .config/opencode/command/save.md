---
description: Alias for /done - End meeting session and save notes to Obsidian
agent: meeting-assistant
---

End this meeting session and save the notes to Obsidian.

Follow the SYNTHESIZE mode workflow:
1. Search for related notes to determine if this should UPDATE an existing note or CREATE a new one
2. If same customer AND same topic as existing note → append to existing
3. If different topic → create new note with appropriate tags
4. Generate tags for people, technologies, topics, and meeting type
5. Save to the Obsidian vault by writing directly to the filesystem at ~/projects/src/github.com/theoutdoorprogrammer/obsidian using the Write tool (for new files) or Edit tool (for appending to existing). Do NOT use Obsidian MCP write tools — they are disabled.
6. After saving, commit the note to git:
   - cd ~/projects/src/github.com/theoutdoorprogrammer/obsidian
   - git add the specific note file
   - git commit with message format: "meeting notes: {topic} with {person}"
   - Do NOT push
7. If there are action items assigned to me, add them to Work/Board.md under the appropriate priority column with a link to the note

Always write notes using the filesystem Write/Edit tools. Do NOT use Obsidian MCP write tools (put_file, post_file, etc.) — they are globally disabled.
