#!/bin/bash
# Tracks MCP tool usage per session. Called by PostToolUse hook.
# Writes unique "server:tool" entries to /tmp/claude-mcp-<session_id>.log
input=$(cat)

SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')
TOOL_NAME=$(echo "$input" | jq -r '.tool_name // empty')

[ -z "$SESSION_ID" ] || [ -z "$TOOL_NAME" ] && exit 0

# Extract server and tool from mcp__<server>__<tool>
SERVER=$(echo "$TOOL_NAME" | sed -n 's/^mcp__\([^_]*\)__.*$/\1/p')
TOOL=$(echo "$TOOL_NAME" | sed -n 's/^mcp__[^_]*__\(.*\)$/\1/p')

[ -z "$SERVER" ] && exit 0

LOGFILE="/tmp/claude-mcp-${SESSION_ID}.log"
ENTRY="${SERVER}:${TOOL}"

# Only append if not already tracked
if ! grep -qxF "$ENTRY" "$LOGFILE" 2>/dev/null; then
  echo "$ENTRY" >> "$LOGFILE"
fi
