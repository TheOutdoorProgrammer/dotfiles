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
transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // empty')
if [ -z "$agent_id" ] || [ -z "$transcript" ]; then
  exit 0
fi

case "$transcript" in
  "$HOME/.codex/"*)
    state_root="$HOME/.codex/rex-subagents"
    mkdir -p "$state_root"
    key=$(printf '%s' "$agent_id" | shasum -a 256 | cut -d ' ' -f 1)
    marker="$state_root/$key.started"
    if (set -C; : >"$marker") 2>/dev/null; then
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
        "$agent_id" 2>/dev/null) &&
        printf '%s\n' "$created" >"$state_root/$key.window.json" ||
        rm -f "$marker"
    fi
    ;;
esac
