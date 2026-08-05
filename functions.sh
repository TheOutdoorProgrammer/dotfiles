# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091

# Reload ~/.zshrc into the current shell
sourceHome(){
    source ~/.zshrc
}

# Run a command needing the OpenPGP applet (sops -d, gpg --card-status).
# scdaemon and the PIV ssh-agent cannot hold the card at once, so hand it over.
withgpgcard(){
  local rc
  ssh-add -e "$(readlink -f /opt/homebrew/lib/libykcs11.dylib)" >/dev/null 2>&1
  gpgconf --kill scdaemon >/dev/null 2>&1
  "$@"
  rc=$?
  "$HOME/projects/src/github.com/TheOutdoorProgrammer/home/scripts/piv-reacquire.sh"
  return $rc
}

# Take the YubiKey back for SSH after a bare gpg command stole it
pivfix(){
  "$HOME/projects/src/github.com/TheOutdoorProgrammer/home/scripts/piv-reacquire.sh" \
    && ssh-add -l
}

# Flush the macOS DNS cache
killDNS(){
  sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
}

# Exit the shell if it's a kubie/kubecm context shell
exitKubie(){
  if [[ ! -z "${KUBECONFIG}" ]]; then
    echo "Exiting Kubie Shell"
    exit
  fi
}

# Open IntelliJ IDEA with the given path (idea .)
idea(){
  open -na "IntelliJ IDEA.app" --args "$@"
}

# git routes through joey; escape a call with `git --escape …`
git(){ joey git "$@"; }

# joey CLI; the aws namespace emits shell exports so eval those, run the rest.
j(){
  case "$1" in
    aws) eval "$(command joey "$@")" ;;
    *) command joey "$@" ;;
  esac
}

# joey zsh completion (no-op until compinit has run)
if command -v joey >/dev/null 2>&1; then
  source <(joey completion zsh) 2>/dev/null
fi

source "$HOME/registry-list.sh"

# Defaults
export AWS_DEFAULT_REGION="us-east-2"
export AWS_PROFILE="default"
unset AWS_ENDPOINT_URL
