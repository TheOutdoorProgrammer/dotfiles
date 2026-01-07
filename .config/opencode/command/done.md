---
description: End meeting session and save notes to Obsidian
agent: meeting-assistant
---

End this meeting session and save the notes to Obsidian.

Follow the SYNTHESIZE mode workflow:
1. Search for related notes to determine if this should UPDATE an existing note or CREATE a new one
2. If same customer AND same topic as existing note → append to existing
3. If different topic → create new note with appropriate tags
4. Generate tags for people, technologies, topics, and meeting type
5. Show preview of what will be saved/appended and wait for confirmation
6. Save to Obsidian using the appropriate method (put_file for new, post_file for append)
7. After saving, commit the note to git:
   - cd ~/projects/src/github.com/theoutdoorprogrammer/obsidian
   - git add the specific note file
   - git commit with message format: "meeting notes: {topic} with {person}"
   - Do NOT push

If Obsidian MCP fails, prompt to open Obsidian - do not fall back to writing files directly.
