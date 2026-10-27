#!/bin/sh

payload=$(cat)
agent_id=$(printf '%s' "$payload" | jq -r '.agent_id // empty')

if [ -n "$agent_id" ]; then
  state_root="$HOME/.codex/rex-subagents"
  mkdir -p "$state_root"
  key=$(printf '%s' "$agent_id" | shasum -a 256 | cut -d ' ' -f 1)
  tmp=$(mktemp "$state_root/status.XXXXXX")
  printf '%s' "$payload" |
    jq '{
      status: "finished",
      agent_id,
      agent_type,
      last_assistant_message
    }' >"$tmp" &&
    mv "$tmp" "$state_root/$key.status"
fi
