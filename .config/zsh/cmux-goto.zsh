# cmux-goto — "go to project" launcher (James-style), bound to Ctrl+G.
#
#   Ctrl+G  ->  fuzzy-pick a repo (ghq) -> open a NEW cmux workspace named after
#               the repo, grouped in the sidebar by org, with this layout:
#
#     ┌───────────────┬──────────────┐
#     │               │              │
#     │ claude-teams  │   nvim .     │
#     │  (left panel) │ (file tree)  │
#     └───────────────┴──────────────┘
#
# Open a terminal yourself if you need one. Requires: ghq, fzf, cmux.
# Only works from inside cmux (needs the socket).

# Static pane layout: left = cmux claude-teams, right = nvim at the project.
# cwd for every pane comes from `new-workspace --cwd`, so nothing needs interpolating here.
_CMUX_GOTO_LAYOUT='{"direction":"horizontal","split":0.45,"children":[{"pane":{"surfaces":[{"type":"terminal","command":"cmux claude-teams"}]}},{"pane":{"surfaces":[{"type":"terminal","command":"nvim ."}]}}]}'

# Open a repo dir as a named, org-grouped, pre-laid-out workspace.
_cmux_goto_open() {
  local dir=$1 org name group
  org=${dir:h:t}    # …/github.com/ORG/REPO -> ORG
  name=${dir:t}     # -> REPO (workspace name)

  # Re-use an existing sidebar group for this org if there is one.
  group=$(CMUX_QUIET=1 cmux workspace-group list --json 2>/dev/null \
    | jq -r --arg o "$org" '.groups[]? | select(.name==$o) | .ref' 2>/dev/null | head -1)

  local args=(--name "$name" --cwd "$dir" --focus true --layout "$_CMUX_GOTO_LAYOUT")
  [[ -n "$group" ]] && args+=(--group "$group")

  local ws
  ws=$(CMUX_QUIET=1 cmux new-workspace "${args[@]}" 2>/dev/null | awk '/workspace:/{print $2}')
  [[ -z "$ws" ]] && { print -u2 "cmux-goto: failed to create workspace for $dir"; return 1 }

  # First repo for this org -> create the group, anchored on this workspace.
  [[ -z "$group" ]] && CMUX_QUIET=1 cmux workspace-group create --name "$org" --from "$ws" >/dev/null 2>&1
  return 0
}

cmux-goto() {
  command -v ghq  >/dev/null 2>&1 || { print -u2 "cmux-goto: ghq not installed";  return 1 }
  command -v fzf  >/dev/null 2>&1 || { print -u2 "cmux-goto: fzf not installed";  return 1 }
  command -v cmux >/dev/null 2>&1 || { print -u2 "cmux-goto: cmux not installed"; return 1 }
  [[ -n "$CMUX_WORKSPACE_ID" ]]   || { print -u2 "cmux-goto: run this from inside cmux"; return 1 }

  local root repo
  root=$(ghq root)
  repo=$(ghq list | fzf \
    --prompt='go to > ' --height=70% --reverse --border \
    --preview "f=\"$root/{}/README.md\"; if [ -f \"\$f\" ]; then command -v bat >/dev/null 2>&1 && bat --color=always --style=plain \"\$f\" || cat \"\$f\"; else ls -la \"$root/{}\"; fi") || return
  [[ -z "$repo" ]] && return
  _cmux_goto_open "$root/$repo"
}

# Bind to Ctrl+G (overrides zsh's default ^G list-expand). Guarded so a
# non-interactive source never errors on zle/bindkey.
if [[ -o interactive ]]; then
  _cmux_goto_widget() { cmux-goto; zle reset-prompt }
  zle -N _cmux_goto_widget
  bindkey '^g' _cmux_goto_widget
fi
