#!/bin/sh

payload=$(cat)
tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // empty')
case "$tool_name" in
  close_agent|*/close_agent|*.close_agent) ;;
  *) exit 0 ;;
esac

target=$(printf '%s' "$payload" | jq -r '.tool_input.target // empty')
if [ -z "$target" ]; then
  exit 0
fi

state_root="$HOME/.codex/rex-subagents"
direct_key=$(printf '%s' "$target" | shasum -a 256 | cut -d ' ' -f 1)
key=$direct_key
if [ ! -f "$state_root/$key.started" ]; then
  alias_file="$state_root/alias-$direct_key"
  if [ ! -f "$alias_file" ]; then
    exit 0
  fi
  key=$(cat "$alias_file")
fi

case "$key" in
  *[!0-9a-f]*|'') exit 0 ;;
esac
if [ "${#key}" -ne 64 ] || [ ! -f "$state_root/$key.started" ]; then
  exit 0
fi

: >"$state_root/$key.closed"
