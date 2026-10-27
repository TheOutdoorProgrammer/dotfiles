#!/bin/sh

payload=$(cat)
session_id=$(printf '%s' "$payload" | jq -r '.session_id // empty')
if [ -z "$session_id" ]; then
  exit 0
fi

state_root="$HOME/.codex/rex-subagents"
mkdir -p "$state_root"
parent_key=$(printf '%s' "$session_id" | shasum -a 256 | cut -d ' ' -f 1)
: >"$state_root/parent-$parent_key.closed"
