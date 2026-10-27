#!/bin/sh

payload=$(cat)
transcript=$(printf '%s' "$payload" | jq -r '.agent_transcript_path // empty')

case "$transcript" in
  "$HOME/.cursor/"*)
    state_root="$HOME/.cursor/rex-subagents"
    mkdir -p "$state_root"
    key=$(printf '%s' "$transcript" | shasum -a 256 | cut -d ' ' -f 1)
    tmp=$(mktemp "$state_root/status.XXXXXX")
    printf '%s' "$payload" |
      jq '{
        status,
        description,
        duration_ms,
        message_count,
        tool_call_count,
        modified_files
      }' >"$tmp" &&
      mv "$tmp" "$state_root/$key.status"
    ;;
esac

printf '{}\n'
