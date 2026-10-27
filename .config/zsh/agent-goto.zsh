# agent-goto: Ctrl+G fuzzy-picks a ghq repo, then an agent, and opens the repo
# in Rex; Cmd+W in the repo picker uses a worktree.
# Thin on purpose: `joey claude goto` owns Rex session creation.

agent-goto() {
  command -v ghq  >/dev/null 2>&1 || { print -u2 "agent-goto: ghq not installed";  return 1 }
  command -v fzf  >/dev/null 2>&1 || { print -u2 "agent-goto: fzf not installed";  return 1 }
  command -v joey >/dev/null 2>&1 || { print -u2 "agent-goto: joey not installed"; return 1 }
  command -v rex  >/dev/null 2>&1 || { print -u2 "agent-goto: rex not installed";  return 1 }
  [[ -n "${REX_SESSION:-}" ]] || { print -u2 "agent-goto: run it inside Rex"; return 1 }

  local root out key repo branch agent
  root=$(ghq root)
  out=$(ghq list | fzf \
    --prompt='go to > ' --height=70% --reverse --border \
    --header='enter: open   cmd-w: open in a new worktree' \
    --expect=ctrl-w,f12 \
    --preview "repo={}; f=\"$root/\$repo/README.md\"; if [ -f \"\$f\" ]; then command -v bat >/dev/null 2>&1 && bat --color=always --style=plain \"\$f\" || cat \"\$f\"; else ls -la \"$root/\$repo\"; fi") || return
  key=${out%%$'\n'*}
  repo=${out#*$'\n'}
  [[ -z "$repo" ]] && return
  if [[ "$key" == ctrl-w || "$key" == f12 ]]; then
    branch=$(printf '%s\n' 'Type a new branch name, then press Enter' | fzf \
      --phony --print-query --no-info \
      --prompt='branch > ' --height=~4 --reverse --border) || return
    branch=${branch%%$'\n'*}
    [[ -z "$branch" ]] && return
  fi

  agent=$(printf '%s\n' \
    $'codex\tOpenAI Codex' \
    $'cursor\tCursor agent' \
    $'claude\tClaude Code' \
    | fzf --prompt='agent > ' --height=~8 --reverse --border --delimiter=$'\t' --with-nth=1,2 | cut -f1) || return
  [[ -z "$agent" ]] && return

  if [[ -n "$branch" ]]; then
    joey claude goto --worktree "$branch" --agent "$agent" "$root/$repo"
  else
    joey claude goto --agent "$agent" "$root/$repo"
  fi
}

# Bind to Ctrl+G (Rex maps Cmd+G to it). Guarded so a non-interactive source
# never errors on zle/bindkey.
if [[ -o interactive ]]; then
  _agent_goto_widget() { agent-goto; zle reset-prompt }
  zle -N _agent_goto_widget
  bindkey '^g' _agent_goto_widget
fi
