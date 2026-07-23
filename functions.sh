# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091

# Reload ~/.zshrc into the current shell
sourceHome(){
    source ~/.zshrc
}

# Restart gpg-agent and re-detect the YubiKey (fixes stuck GPG/SSH auth)
gpgfix(){
  gpgconf --kill gpg-agent
  gpgconf --launch gpg-agent
  gpg-connect-agent updatestartuptty /bye
  gpg --card-status
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
