---
description: Start a new meeting session with context lookup
agent: meeting-assistant
---

Starting a meeting with $ARGUMENTS.

Initialize the meeting session:
1. Search Obsidian for existing notes related to this person/customer/topic
2. If highly relevant notes are found, fetch the full content (limit 2-3 notes)
3. Store this context for use during /probe
4. Summarize any existing context found
5. Display available commands (/probe, /done)
6. Enter INTAKE mode - ready to capture notes with minimal friction
