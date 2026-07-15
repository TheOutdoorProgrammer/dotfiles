#!/bin/bash
input=$(cat)

# Debug: dump raw JSON to file (remove after debugging)
echo "$input" > /tmp/claude-statusline-debug.json

# --- Parse fields ---
MODEL=$(echo "$input" | jq -r '.model.display_name // "—"')
CWD=$(echo "$input" | jq -r '.workspace.current_dir // "—"')
CWD_SHORT="${CWD/#$HOME/~}"

# Context usage
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
BAR_WIDTH=20
FILLED=$(( PCT * BAR_WIDTH / 100 ))
EMPTY=$(( BAR_WIDTH - FILLED ))
if [ "$PCT" -lt 50 ]; then
  COLOR="\033[32m"
elif [ "$PCT" -lt 75 ]; then
  COLOR="\033[33m"
else
  COLOR="\033[31m"
fi
RST="\033[0m"
DIM="\033[90m"
BAR="${COLOR}$(printf '█%.0s' $(seq 1 $FILLED 2>/dev/null))$(printf '░%.0s' $(seq 1 $EMPTY 2>/dev/null))${RST}"

# Cost & lines
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
COST_FMT=$(printf '$%.2f' "$COST")
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Effort & thinking
EFFORT=$(echo "$input" | jq -r '.effort.level // "—"')
THINKING=$(echo "$input" | jq -r '.thinking.enabled // false')
if [ "$THINKING" = "true" ]; then
  THINK_ICON="\033[36mon${RST}"
else
  THINK_ICON="\033[33moff${RST}"
fi

# Worktree
WT_NAME=$(echo "$input" | jq -r '.worktree.name // empty')
WT_BRANCH=$(echo "$input" | jq -r '.worktree.branch // empty')
if [ -n "$WT_NAME" ]; then
  WT_INFO="\033[35m${WT_NAME}${RST}${DIM}(${WT_BRANCH})${RST}"
fi

# Rate limits — also snapshot them for `joey usage claude` (Claude Code only
# exposes rate_limits via this stdin payload, so the statusline is the tap).
# Atomic mv so a concurrent reader never sees a partial file.
if echo "$input" | jq -e '.rate_limits.five_hour' >/dev/null 2>&1; then
  SNAP="$HOME/.claude/usage-snapshot.json"
  echo "$input" | jq -c '{rate_limits, model: .model.display_name, captured_at: now}' > "${SNAP}.tmp.$$" 2>/dev/null \
    && mv "${SNAP}.tmp.$$" "$SNAP"
fi
RL_5H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
RL_7D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
RL_5H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
RL_7D_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')

# Plannotator review gate — flag file per session means the gate is on
if [ -n "$SESSION_ID" ] && [ -f "$HOME/.claude/plannotator-review-gate.sessions/$SESSION_ID" ]; then
  GATE_ICON="\033[36mon${RST}"
else
  GATE_ICON="\033[33moff${RST}"
fi

# MCP servers (configured) — bold if used this session
SETTINGS="$HOME/.claude.json"
MCP_LOGFILE="/tmp/claude-mcp-${SESSION_ID}.log"

# Build list of used server names (just the server part from "server:tool")
USED_SERVERS=""
if [ -n "$SESSION_ID" ] && [ -f "$MCP_LOGFILE" ]; then
  USED_SERVERS=$(cut -d: -f1 "$MCP_LOGFILE" | sort -u | tr '\n' '|' | sed 's/|$//')
fi

BOLD="\033[1;37m"
MCP_LINE=""
if [ -f "$SETTINGS" ]; then
  while IFS= read -r server; do
    if [ -n "$USED_SERVERS" ] && echo "$server" | grep -qE "^(${USED_SERVERS})$"; then
      # Bold white for used servers
      MCP_LINE="${MCP_LINE}${BOLD}${server}${RST}${DIM}, "
    else
      MCP_LINE="${MCP_LINE}${server}, "
    fi
  done < <(jq -r '.mcpServers // {} | keys[]' "$SETTINGS" 2>/dev/null)
  # Trim trailing ", "
  MCP_LINE=$(echo "$MCP_LINE" | sed 's/, $//')
fi

# --- Line 1: model, context, cost, lines ---
printf "%s  %b %s%%  %s  \033[32m+%s${RST} \033[31m-%s${RST}\n" \
  "$MODEL" "$BAR" "$PCT" "$COST_FMT" "$ADDED" "$REMOVED"

# --- Line 2: directory, effort, thinking, worktree ---
# Dim keys, colored values, reset after every value so nothing bleeds
L2="${DIM}${CWD_SHORT}${RST}  ${DIM}effort:${RST}\033[35m${EFFORT}${RST}  ${DIM}thinking:${RST}${THINK_ICON}  ${DIM}gate:${RST}${GATE_ICON}"
if [ -n "$WT_NAME" ]; then
  L2="${L2}  ${DIM}wt:${RST}${WT_INFO}"
fi
L2="${L2}  ${DIM}sid:${RST}${SESSION_ID:-—}"
printf "%b\n" "$L2"

# --- Line 3: rate limits (if available) + MCP ---
L3=""
if [ -n "$RL_5H" ]; then
  RL_5H_INT=$(printf '%.0f' "$RL_5H")
  if [ "$RL_5H_INT" -lt 50 ]; then RL_5H_CLR="\033[32m"
  elif [ "$RL_5H_INT" -lt 80 ]; then RL_5H_CLR="\033[33m"
  else RL_5H_CLR="\033[31m"; fi
  L3="5h:${RL_5H_CLR}${RL_5H_INT}%${RST}"
fi
if [ -n "$RL_7D" ]; then
  RL_7D_INT=$(printf '%.0f' "$RL_7D")
  if [ "$RL_7D_INT" -lt 50 ]; then RL_7D_CLR="\033[32m"
  elif [ "$RL_7D_INT" -lt 80 ]; then RL_7D_CLR="\033[33m"
  else RL_7D_CLR="\033[31m"; fi
  L3="${L3}  7d:${RL_7D_CLR}${RL_7D_INT}%${RST}"
fi
if [ -n "$L3" ]; then
  printf "%b  ${DIM}MCP: %b${RST}\n" "$L3" "$MCP_LINE"
else
  printf "${DIM}MCP: %b${RST}\n" "$MCP_LINE"
fi
