# cmux-goto — Ctrl+G: fuzzy-pick a ghq repo, open it as a new cmux workspace
# named after the repo, org-grouped in the sidebar, running claude-teams.
# Requires ghq/fzf/cmux, and the cmux socket (so: only from inside cmux).

zmodload zsh/datetime 2>/dev/null  # EPOCHREALTIME, used to seed color RANDOM

# Single full-width pane: j claude teams. cwd comes from `new-workspace --cwd`,
# so nothing needs interpolating here.
_CMUX_GOTO_LAYOUT='{"pane":{"surfaces":[{"type":"terminal","command":"j claude teams --dangerously-skip-permissions"}]}}'

# Session accents; the claude-teams shim reads them back to match the agents
# folder. Preferred = Dracula Classic; fallback used only when all are taken.
_CMUX_GOTO_DRACULA=(
  '#FF5555' '#FFB86C' '#F1FA8C' '#50FA7B' '#8BE9FD' '#BD93F9' '#FF79C6' '#6272A4'
  '#FF6E6E' '#69FF94' '#FFFFA5' '#D6ACFF' '#FF92DF' '#A4FFFF'
)
_CMUX_GOTO_FALLBACK=('#FF8C42' '#C3F73A' '#43D9C4' '#62A0FF' '#FF5FD2')

# Prefer an unused Dracula accent, then unused fallback, then any Dracula.
_cmux_goto_pick_color() {
  local -a used avail
  used=("${(@f)$(CMUX_QUIET=1 cmux workspace list --json 2>/dev/null \
    | jq -r '.workspaces[]?.custom_color // empty')}")
  avail=(${_CMUX_GOTO_DRACULA:|used})
  (( $#avail )) || avail=(${_CMUX_GOTO_FALLBACK:|used})
  (( $#avail )) || avail=($_CMUX_GOTO_DRACULA)
  # Sub-second seed so back-to-back $()-forked calls don't repeat a pick.
  RANDOM=${EPOCHREALTIME#*.}
  print -r -- ${avail[RANDOM % $#avail + 1]}
}

# Open a repo dir as a named, org-grouped, pre-laid-out workspace.
_cmux_goto_open() {
  local dir=$1 org name group
  org=${dir:h:t}    # …/github.com/ORG/REPO -> ORG
  name=${dir:t}     # -> REPO (workspace name)

  # Re-use an existing sidebar group for this org if there is one.
  group=$(CMUX_QUIET=1 cmux workspace-group list --json 2>/dev/null \
    | jq -r --arg o "$org" '.groups[]? | select(.name==$o) | .ref' 2>/dev/null | head -1)

  # `--folder` (cmux fork) = header is chrome, not a terminal. Older cmux has no
  # such thing, so fall back to a throwaway anchor — never `--from "$ws"`, which
  # renames the first repo session to the org and swallows its sidebar row.
  if [[ -z "$group" ]]; then
    local -a create_args=(--name "$org" --json)
    if cmux workspace-group --help 2>/dev/null | grep -q -- '--folder'; then
      create_args+=(--folder)
    else
      create_args+=(--cwd "${dir:h}")
    fi
    group=$(CMUX_QUIET=1 cmux workspace-group create "${create_args[@]}" 2>/dev/null \
      | jq -r '.group.ref // empty' 2>/dev/null)
  fi

  local args=(--name "$name" --cwd "$dir" --focus true --layout "$_CMUX_GOTO_LAYOUT")
  [[ -n "$group" ]] && args+=(--group "$group")

  local ws
  ws=$(CMUX_QUIET=1 cmux new-workspace "${args[@]}" 2>/dev/null | awk '/workspace:/{print $2}')
  [[ -z "$ws" ]] && { print -u2 "cmux-goto: failed to create workspace for $dir"; return 1 }

  # Tag the session with an accent so its agents can be matched to it.
  local color=$(_cmux_goto_pick_color)
  CMUX_QUIET=1 cmux workspace-action --action set-color --workspace "$ws" --color "$color" >/dev/null 2>&1
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
