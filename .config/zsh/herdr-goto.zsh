# herdr-goto: Ctrl+G fuzzy-picks a ghq repo and opens it as a Herdr workspace
# running an agent team. Repeating it adds a session, never reuses one. Thin on
# purpose: `joey claude goto` owns the workspace/tab/pane resolution.

herdr-goto() {
  command -v ghq   >/dev/null 2>&1 || { print -u2 "herdr-goto: ghq not installed";   return 1 }
  command -v fzf   >/dev/null 2>&1 || { print -u2 "herdr-goto: fzf not installed";   return 1 }
  command -v herdr >/dev/null 2>&1 || { print -u2 "herdr-goto: herdr not installed"; return 1 }
  [[ "${HERDR_ENV:-}" == 1 ]]     || { print -u2 "herdr-goto: run it inside a Herdr pane (start \`herdr\` first)"; return 1 }

  local root repo
  root=$(ghq root)
  repo=$(ghq list | fzf \
    --prompt='go to > ' --height=70% --reverse --border \
    --preview "f=\"$root/{}/README.md\"; if [ -f \"\$f\" ]; then command -v bat >/dev/null 2>&1 && bat --color=always --style=plain \"\$f\" || cat \"\$f\"; else ls -la \"$root/{}\"; fi") || return
  [[ -z "$repo" ]] && return
  joey claude goto "$root/$repo"
}

# Bind to Ctrl+G (overrides zsh's default ^G list-expand). Guarded so a
# non-interactive source never errors on zle/bindkey.
if [[ -o interactive ]]; then
  _herdr_goto_widget() { herdr-goto; zle reset-prompt }
  zle -N _herdr_goto_widget
  bindkey '^g' _herdr_goto_widget
fi
