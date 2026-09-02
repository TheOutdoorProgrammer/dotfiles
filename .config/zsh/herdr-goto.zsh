# herdr-goto: Ctrl+G fuzzy-picks a ghq repo, then an agent, and opens the repo
# as a Herdr workspace running it; ctrl-w in the repo picker uses a worktree.
# Thin on purpose: `joey claude goto` owns the workspace/tab/pane resolution.

herdr-goto() {
  command -v ghq   >/dev/null 2>&1 || { print -u2 "herdr-goto: ghq not installed";   return 1 }
  command -v fzf   >/dev/null 2>&1 || { print -u2 "herdr-goto: fzf not installed";   return 1 }
  command -v herdr >/dev/null 2>&1 || { print -u2 "herdr-goto: herdr not installed"; return 1 }
  [[ "${HERDR_ENV:-}" == 1 ]]     || { print -u2 "herdr-goto: run it inside a Herdr pane (start \`herdr\` first)"; return 1 }

  local root out key repo branch agent
  root=$(ghq root)
  out=$(ghq list | fzf \
    --prompt='go to > ' --height=70% --reverse --border \
    --header='enter: open   ctrl-w: open in a new worktree' \
    --expect=ctrl-w \
    --preview "f=\"$root/{}/README.md\"; if [ -f \"\$f\" ]; then command -v bat >/dev/null 2>&1 && bat --color=always --style=plain \"\$f\" || cat \"\$f\"; else ls -la \"$root/{}\"; fi") || return
  key=${out%%$'\n'*}
  repo=${out#*$'\n'}
  [[ -z "$repo" ]] && return
  if [[ "$key" == ctrl-w ]]; then
    branch=""
    vared -p "branch for the worktree: " branch
    [[ -z "$branch" ]] && return
  fi

  agent=$(printf '%s\n' \
    $'claude\tClaude Code, teammates as Herdr tabs' \
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

# Bind to Ctrl+G (overrides zsh's default ^G list-expand). Guarded so a
# non-interactive source never errors on zle/bindkey.
if [[ -o interactive ]]; then
  _herdr_goto_widget() { herdr-goto; zle reset-prompt }
  zle -N _herdr_goto_widget
  bindkey '^g' _herdr_goto_widget
fi
