#!/bin/sh

payload=$(cat)

if [ -z "${REX_SESSION:-}" ]; then
  exit 0
fi
rex_bin=$(command -v rex 2>/dev/null || true)
if [ -z "$rex_bin" ]; then
  rex_bin="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
fi
if [ ! -x "$rex_bin" ] || ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

agent_id=$(printf '%s' "$payload" | jq -r '.agent_id // empty')
agent_type=$(printf '%s' "$payload" | jq -r '.agent_type // "agent"')
session_id=$(printf '%s' "$payload" | jq -r '.session_id // empty')
transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // empty')
if [ -z "$agent_id" ] || [ -z "$session_id" ] || [ -z "$transcript" ]; then
  exit 0
fi

case "$transcript" in
  "$HOME/.codex/"*)
    state_root="$HOME/.codex/rex-subagents"
    mkdir -p "$state_root"
    key=$(printf '%s' "$agent_id" | shasum -a 256 | cut -d ' ' -f 1)
    marker="$state_root/$key.started"
    if (set -C; : >"$marker") 2>/dev/null; then
      parent_key=$(printf '%s' "$session_id" | shasum -a 256 | cut -d ' ' -f 1)
      parent_closed="$state_root/parent-$parent_key.closed"
      rm -f "$state_root/$key.status" "$state_root/$key.closed" "$parent_closed"
      printf '%s\n' "$session_id" >"$state_root/$key.parent"

      metadata=
      IFS= read -r metadata <"$transcript" || true
      agent_path=$(printf '%s' "$metadata" | jq -r '
        .payload.agent_path
        // .payload.source.subagent.thread_spawn.agent_path
        // empty
      ' 2>/dev/null)
      agent_nickname=$(printf '%s' "$metadata" |
        jq -r '.payload.agent_nickname // empty' 2>/dev/null)
      for alias in "$agent_path" "${agent_path##*/}" "$agent_nickname"; do
        if [ -n "$alias" ]; then
          alias_key=$(printf '%s' "$alias" | shasum -a 256 | cut -d ' ' -f 1)
          printf '%s\n' "$key" >"$state_root/alias-$alias_key"
        fi
      done

      short=$(printf '%.8s' "$agent_id")
      created=$("$rex_bin" window new \
        --session "$REX_SESSION" \
        "Codex $agent_type $short" \
        --focus=false \
        --keep-open \
        --shell=none \
        --json \
        -- "$HOME/.codex/rex-subagent-view.py" \
        "$transcript" \
        "$state_root/$key.status" \
        "$state_root/$key.closed" \
        "$parent_closed" \
        "$agent_id" \
        "$REX_SESSION" \
        "${REX_BLOCK:-}" 2>/dev/null) &&
        printf '%s\n' "$created" >"$state_root/$key.window.json" ||
        rm -f "$marker"
    fi
    ;;
esac
