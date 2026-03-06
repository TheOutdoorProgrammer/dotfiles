---
description: Summarize my Obsidian kanban board (excluding Freezer/Low Prio and Done) and google calendar for the week.
agent: meeting-assistant
---

Summarize my work board from Obsidian and my google calendar for the week in a format I can share with my boss.
I use slack to share updates, so keep it consise and actionable.

Instructions:
1. Fetch the board file from `Work/Board.md` using obsidian_get_file
2. Parse the kanban board content, extracting items from each column
3. **IGNORE** these columns entirely:
   - "Freezer / Low Prio"
   - "Done"
   - "Archive"
4. For each remaining column (Medium Prio, To Do / High Prio, In Progress, Awaiting Customer, Awaiting Dev / Review), list:
   - Column name
   - Number of items
   - Brief summary of each item
5. **LINKED NOTES**: If a card contains an Obsidian link (e.g. `[[note-name]]`), fetch that note using obsidian_get_file and incorporate relevant context into the summary for that card. This adds important background info.
6. Use List-calendars mcp tool to list my available calendars (utilize the Joey Stout calendar ONLY for this. The non-work related, like family calendar, should be ignored)
7. Use List-events mcp tool to fetch events from the Joey Stout calendar for the week.
8. As needed you can get-event for more details on specific events.
6. Provide a quick overview at the top:
   - Total active items (excluding freezer/done)
   - Items currently in progress
   - Items blocked/awaiting others
   - Anything important to mention thats on my calendar (upcoming demos and workshops should be listed as well)
7. Keep the summary concise and actionable
8. Echo it with formatting into pbcopy so I can paste it to slack easily.

