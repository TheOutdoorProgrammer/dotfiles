# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091

# Reload ~/.zshrc into the current shell
sourceHome() {
  source ~/.zshrc
}

# Run a command needing the OpenPGP applet (sops -d, gpg --card-status).
# scdaemon and the PIV ssh-agent cannot hold the card at once, so hand it over.
withgpgcard() {
  local rc lock="${TMPDIR:-/tmp}/.piv-gpg-inflight"
  : >"$lock"
  trap 'rm -f "$lock"' INT TERM
  ssh-add -e "$(readlink -f /opt/homebrew/lib/libykcs11.dylib)" >/dev/null 2>&1
  gpgconf --kill scdaemon >/dev/null 2>&1
  "$@"
  rc=$?
  rm -f "$lock"
  "$HOME/projects/src/github.com/TheOutdoorProgrammer/home/scripts/piv-reacquire.sh"
  return $rc
}

# Take the YubiKey back for SSH after a bare gpg command stole it
pivfix() {
  "$HOME/projects/src/github.com/TheOutdoorProgrammer/home/scripts/piv-reacquire.sh" &&
    ssh-add -l
}

# Re-pin the ProFX stereo pair to 3/4 after macOS resets it to the dead 1/2
fixProFX() {
  set-stereo-pair ProFX 3 4 || return $?
  pgrep -x FineTune >/dev/null &&
    echo "re-route the app in FineTune so it rebuilds the tap on 3/4"
}

# Flush the macOS DNS cache
killDNS() {
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
}

# git routes through joey; escape a call with `git --escape …`
git() { joey git "$@"; }

# joey CLI; the aws namespace emits shell exports so eval those, run the rest.
j() {
  case "$1" in
  aws) eval "$(command joey "$@")" ;;
  *) command joey "$@" ;;
  esac
}

# claude, codex and cursor-agent run in their permissive modes by default
# (teams for Claude); subcommands like `codex login` pass through untouched,
# and `<tool> --escape …` reaches the real binary, same as `git --escape`.
claude() {
  [[ "$1" == --escape ]] && { shift; command claude "$@"; return; }
  j claude teams --dangerously-skip-permissions "$@"
}
codex() {
  [[ "$1" == --escape ]] && { shift; command codex "$@"; return; }
  j codex yolo "$@"
}
cursor-agent() {
  [[ "$1" == --escape ]] && { shift; command cursor-agent "$@"; return; }
  j cursor yolo "$@"
}

# Pick a coding agent (claude, cursor, codex) and launch it here in permissive
# mode, as `code` always did for Claude. `code <agent> [args]` skips the picker.
code() {
  local agent=$1
  if [[ -n "$agent" ]]; then
    shift
  elif command -v fzf >/dev/null 2>&1; then
    agent=$(printf '%s\n' \
      $'claude\tClaude Code, teammates as Herdr tabs' \
      $'cursor\tCursor agent' \
      $'codex\tOpenAI Codex' \
      | fzf --height=~8 --reverse --prompt='agent > ' --delimiter=$'\t' --with-nth=1,2 | cut -f1) || return
  else
    local choice
    select choice in claude cursor codex; do agent=$choice; break; done
  fi
  [[ -z "$agent" ]] && return
  case "$agent" in
  claude) j claude teams --dangerously-skip-permissions "$@" ;;
  cursor) j cursor yolo "$@" ;;
  codex) j codex yolo "$@" ;;
  *) print -u2 "code: unknown agent '$agent' (claude, cursor, codex)"; return 1 ;;
  esac
}

# joey zsh completion (no-op until compinit has run)
if command -v joey >/dev/null 2>&1; then
  source <(joey completion zsh) 2>/dev/null
fi

# Defaults
export AWS_DEFAULT_REGION="us-east-2"
export AWS_PROFILE="default"
unset AWS_ENDPOINT_URL
