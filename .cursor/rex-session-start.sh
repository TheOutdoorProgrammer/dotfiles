#!/bin/sh

payload=$(cat)

if [ -z "${REX_SESSION:-}" ] || [ -z "${REX_BLOCK:-}" ]; then
  printf '{}\n'
  exit 0
fi
rex_bin=$(command -v rex 2>/dev/null || true)
if [ -z "$rex_bin" ]; then
  rex_bin="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
fi
if [ ! -x "$rex_bin" ] || ! command -v jq >/dev/null 2>&1; then
  printf '{}\n'
  exit 0
fi

is_background=$(printf '%s' "$payload" | jq -r '.is_background_agent // false')
transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // empty')
if [ "$is_background" = true ] && [ -n "$transcript" ]; then
  case "$transcript" in
    "$HOME/.cursor/"*)
      state_root="$HOME/.cursor/rex-subagents"
      mkdir -p "$state_root"
      key=$(printf '%s' "$transcript" | shasum -a 256 | cut -d ' ' -f 1)
      marker="$state_root/$key.started"
      if (set -C; : >"$marker") 2>/dev/null; then
        name=${transcript##*/}
        name=${name%.jsonl}
        short=$(printf '%.8s' "$name")
        created=$("$rex_bin" window new \
          --session "$REX_SESSION" \
          "Cursor $short" \
          --focus=false \
          --keep-open \
          --shell=none \
          --json \
          -- "$HOME/.cursor/rex-subagent-view.sh" \
          "$transcript" \
          "$state_root/$key.status" 2>/dev/null) &&
          printf '%s\n' "$created" >"$state_root/$key.window.json" ||
          rm -f "$marker"
      fi
      ;;
  esac
fi

context=$("$rex_bin" __internal session-start \
  --agent cursor \
  --feature-session-naming=false 2>/dev/null) || {
  printf '{}\n'
  exit 0
}
if [ -z "$context" ]; then
  printf '{}\n'
  exit 0
fi

printf '%s' "$context" | jq -Rs '{additional_context: .}'
