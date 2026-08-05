# muxy-goto — Ctrl+G: fuzzy-pick a ghq repo, open it as a muxy project running
# an agent team in its own tab. Repeating it adds a session, never reuses one.
# Thin on purpose: `j claude goto` owns the tab/pane resolution.

muxy-goto() {
  command -v ghq  >/dev/null 2>&1 || { print -u2 "muxy-goto: ghq not installed";  return 1 }
  command -v fzf  >/dev/null 2>&1 || { print -u2 "muxy-goto: fzf not installed";  return 1 }
  command -v muxy >/dev/null 2>&1 || { print -u2 "muxy-goto: muxy not installed"; return 1 }

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
  _muxy_goto_widget() { muxy-goto; zle reset-prompt }
  zle -N _muxy_goto_widget
  bindkey '^g' _muxy_goto_widget
fi
