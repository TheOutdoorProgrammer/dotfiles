# agent-goto: Ctrl+G fuzzy-picks a ghq repo, then an agent, and opens the repo
# in Rex or Herdr; ctrl-w in the repo picker uses a worktree.
# Thin on purpose: `joey claude goto` owns the multiplexer-specific opening.

agent-goto() {
  command -v ghq  >/dev/null 2>&1 || { print -u2 "agent-goto: ghq not installed";  return 1 }
  command -v fzf  >/dev/null 2>&1 || { print -u2 "agent-goto: fzf not installed";  return 1 }
  command -v joey >/dev/null 2>&1 || { print -u2 "agent-goto: joey not installed"; return 1 }
  if [[ -n "${REX_SESSION:-}" ]]; then
    command -v rex >/dev/null 2>&1 || { print -u2 "agent-goto: rex not installed"; return 1 }
  elif [[ "${HERDR_ENV:-}" == 1 ]]; then
    command -v herdr >/dev/null 2>&1 || { print -u2 "agent-goto: herdr not installed"; return 1 }
  else
    print -u2 "agent-goto: run it inside Rex or Herdr"
    return 1
  fi

  local root out key repo branch agent claude_description worktree_key
  worktree_key="ctrl-w"
  [[ -n "${REX_SESSION:-}" ]] && worktree_key="cmd-w"
  root=$(ghq root)
  out=$(ghq list | fzf \
    --prompt='go to > ' --height=70% --reverse --border \
    --header="enter: open   ${worktree_key}: open in a new worktree" \
    --expect=ctrl-w,f12 \
    --preview "f=\"$root/{}/README.md\"; if [ -f \"\$f\" ]; then command -v bat >/dev/null 2>&1 && bat --color=always --style=plain \"\$f\" || cat \"\$f\"; else ls -la \"$root/{}\"; fi") || return
  key=${out%%$'\n'*}
  repo=${out#*$'\n'}
  [[ -z "$repo" ]] && return
  if [[ "$key" == ctrl-w || "$key" == f12 ]]; then
    branch=""
    vared -p "branch for the worktree: " branch
    [[ -z "$branch" ]] && return
  fi

  claude_description="Claude Code"
  [[ "${HERDR_ENV:-}" == 1 ]] && claude_description+=", teammates as Herdr tabs"
  agent=$(printf '%s\n' \
    "claude"$'\t'"${claude_description}" \
    $'cursor\tCursor agent' \
    $'codex\tOpenAI Codex' \
    | fzf --prompt='agent > ' --height=~8 --reverse --border --delimiter=$'\t' --with-nth=1,2 | cut -f1) || return
  [[ -z "$agent" ]] && return

  if [[ -n "$branch" ]]; then
    joey claude goto --worktree "$branch" --agent "$agent" "$root/$repo"
  else
    joey claude goto --agent "$agent" "$root/$repo"
  fi
}

herdr-goto() { agent-goto "$@" }

# Bind to Ctrl+G (overrides zsh's default ^G list-expand). Guarded so a
# non-interactive source never errors on zle/bindkey.
if [[ -o interactive ]]; then
  _agent_goto_widget() { agent-goto; zle reset-prompt }
  zle -N _agent_goto_widget
  bindkey '^g' _agent_goto_widget
fi
