# Switch AWS_PROFILE and verify with an STS caller-identity check
changeProfile(){
    export AWS_PROFILE=$1
    aws sts get-caller-identity
}

# Set AWS_DEFAULT_REGION
changeRegion(){
    export AWS_DEFAULT_REGION=$1
    echo "Changed region to $1"
}

# Reload ~/.zshrc into the current shell
sourceHome(){
    source ~/.zshrc
}

# Attach to a tmux session by name, or list sessions and pick/create one interactively
newTmux(){
    if [[ "$1" != "" ]]; then
        tmux attach -t $1 || tmux new -s $1
        return
    fi

    tmux_sessions=$(tmux ls 2>/dev/null)
    echo "Current TMUX sessions:"
    echo
    echo $tmux_sessions
    echo
    answer=$(bash -c 'read -e -p "Session select (or new/exit): " tmp; echo $tmp')
    if [[ "$answer" == "exit" ]]; then
        return
    fi
    tmux attach -t $answer || tmux new -s $answer
}

# Launch a throwaway doks-debug pod for cluster debugging, optionally under a service account
kdebug(){
    name=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-25 | awk '{print tolower($0)}')
    name="joeystout-$name"
    serviceAccount=$1
    shift

    echo "Command"
    echo "kubectl run $name --rm -i --tty --overrides=\"{ \\\"spec\\\": { \\\"serviceAccount\\\": \\\"$serviceAccount\\\" }  }\" --image digitalocean/doks-debug:latest -- $@"

    if [[ "$1" != "" ]]; then
        kubectl run $name --rm -i --tty --overrides="{ \"spec\": { \"serviceAccount\": \"$serviceAccount\" }  }" --image digitalocean/doks-debug:latest -- $@
    else
        kubectl run $name --rm -i --tty --image digitalocean/doks-debug:latest
    fi
}

# Kill a tmux session by name, or the current one
killTmux(){
  # check if session is passed in as a variable
  if [[ "$1" != "" ]]; then
    tmux kill-session -t $1
  else
    tmux kill-session
  fi
}

# Toggle terminal line wrapping on/off
wrap(){
  FILE=~/.wrapped
  if test -f "$FILE"; then
    tput rmam
    rm $FILE
    echo "Wrapping Disabled"
  else
    tput smam
    touch $FILE
    echo "Wrapping Enabled"
  fi
}

# Restart gpg-agent and re-detect the YubiKey (fixes stuck GPG/SSH auth)
gpgfix(){
  gpgconf --kill gpg-agent
  gpgconf --launch gpg-agent
  gpg-connect-agent updatestartuptty /bye
  gpg --card-status
}

# Count lines from stdin (wc -l, whitespace-trimmed)
count(){
  wc -l | xargs
}

# Commit all dotfile changes with a message and push to the yadm remote
yadmUpdateRemote(){
  cd ~
  yadm commit -a -m "$1"
  yadm push origin main
  cd -
}

# Fetch + pull the latest dotfiles from the yadm remote
yadmFetchRemote(){
  cd ~
  yadm fetch
  yadm pull
  cd -
}

# git wrapper adding custom subcommands (commit -c, clean, checkout via fzf, pull-request, delete --olderthan); everything else falls through to hub
git(){
  case "$@" in

    "commit -c")
      ASDF_NODEJS_VERSION="16.13.2" git cz
    ;;

    "freak")
      echo "linking main to master"
      git symbolic-ref refs/heads/main refs/heads/master
    ;;

    "clean")
      git branch --merged | grep --color=auto -v "(^\*|main|master)" | xargs git branch -d
    ;;

    # git delete --olderthan 2022-01-26
    "delete --olderthan"*)
        date=$3
        for item in $(git ls-files); do
          result=$(git --no-pager log --since "$date" -- $item)
          if [[ "$result" == "" ]]; then
            echo $item
            rm $item
          fi
        done
    ;;

    "pull-request -v")
      gh pr view --web
    ;;

    "pull-request -o"*)
      claude --print "Create a pull request for the current project using the git-pull-request skill." --model "claude-opus-4-6"
    ;;

    "checkout")
       git checkout $(git branch -a | grep -ve "\*" -ve "->"  | sed 's/remotes\/origin\///' | awk '!seen[$0]++' | fzf)
    ;;

    *)
      hub "$@"
    ;;

  esac
}

# Print a k8s secret's data with values base64-decoded
ksecret(){
  kubectl get secret $1 -o json | jq '.data | map_values(@base64d)'
}

# Flush the macOS DNS cache
killDNS(){
  sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
}

# Get/set key-value secrets in the 1Password "CLI" vault (wraps op)
vault(){
  query="$1"
  title="$2"
  value="$3"

  if [[ "$query" == "get" ]]; then
    op item get "$title" --vault CLI --fields data --reveal
  fi

  if [[ "$query" == "set" ]]; then
  	op item get "$title" --vault CLI --fields data --reveal > /dev/null 2>&1
  	if [ $? -ne 0 ]; then
  	  op item create --category="API Credential" --title="$title" --vault=CLI data="$value"
  	else
  	  op item edit "$title" --vault=CLI data="$value"
        fi
  fi
}

# Exit the shell if it's a kubie/kubecm context shell
exitKubie(){
  if [[ ! -z "${KUBECONFIG}" ]]; then
    echo "Exiting Kubie Shell"
    exit
  fi
}

# Ask Claude a one-off question from the terminal (claude -p)
help(){
  claude -p "$1"
}

# Run golangci-lint with auto-fix
fixGo(){
  golangci-lint run --fix
}

# Cycle the digital window to the next video
changeVideo(){
  curl http://digitalwindow.stout.zone:3000/change
}

# Set the digital window to a specific YouTube URL
setVideo(){
  curl -H "youtube-url:$1" http://digitalwindow.stout.zone:3000/set_video_id
}

# Open IntelliJ IDEA with the given path (idea .)
idea(){
  open -na "IntelliJ IDEA.app" --args "$@"
}


# Run specific Go tests by name: goTestFunc [-p package] <test1> [test2] ...
goTestFunc() {
    # Check if at least 1 argument is provided
    if [ $# -lt 1 ]; then
        echo "Usage: goTestFunc [-p package] <test1> [test2] [test3] ..."
        echo "Example: goTestFunc test1 test2                           # uses ./..."
        echo "Example: goTestFunc -p spacelift test1 test2              # uses ./spacelift"
        return 1
    fi

    local package="./..."
    local tests=()

    # Check if first argument is -p
    if [[ $1 == "-p" ]]; then
        # -p flag present, second argument is package, rest are tests
        if [ $# -lt 3 ]; then
            echo "Error: When using -p, you must specify package and at least one test"
            echo "Usage: goTestFunc -p <package> <test1> [test2] ..."
            return 1
        fi
        package="./$2"
        tests=("${@:3}")  # All arguments starting from the third one
    else
        # No -p flag, all arguments are test names
        tests=("$@")
    fi

    # Build the -run parameter by joining test names with |
    local run_pattern=""
    if [ ${#tests[@]} -eq 1 ]; then
        run_pattern="${tests[1]}"
    else
        # Join test names with | for regex OR pattern
        run_pattern=$(printf "%s|" "${tests[@]}")
        run_pattern="${run_pattern%|}"  # Remove trailing |
    fi

    # Construct and execute the command
    local cmd="go test -v $package -run \"$run_pattern\""

    echo "Running: $cmd"
    eval "$cmd"
}

# kubecm wrapper: `kubie ctx` maps to kubecm switch, everything else passes through
kubie() {
    [[ "$1" == "ctx" ]] && kubecm switch "${@:2}" || kubecm "$@"
}

# Strip finalizers from a stuck k8s resource so it can delete
removeFinalizers() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: removeFinalizers <resource-type> <resource-name>"
        echo "Examples:"
        echo "  removeFinalizers pod my-pod"
        echo "  removeFinalizers ns stuck-namespace"
        echo "  removeFinalizers pvc my-pvc"
        return 1
    fi

    local resource_type="$1"
    local resource_name="$2"

    echo "Removing finalizers from $resource_type/$resource_name..."
    kubectl patch "$resource_type" "$resource_name" -p '{"metadata":{"finalizers":null}}' --type=merge
}

# Wait for a pod to become ready, then tail its logs
waitAndTail() {
    local pod_name=$1
    local container=${2:-""}
    local container_flag=""

    if [ -n "$container" ]; then
        container_flag="-c $container"
    fi

    echo "Waiting for pod $pod_name to be ready..."
    if kubectl wait --for=condition=ready pod/$pod_name --timeout=300s; then
        echo "Pod ready! Tailing logs..."
        kubectl logs -f $pod_name $container_flag
    else
        echo "Pod failed to become ready within timeout"
        return 1
    fi
}

# Export the AFT account's AWS creds from the vault and verify with STS
useAFTAccount(){
  export AWS_ACCESS_KEY_ID=$(vault get aft-account-access-key-id)
  export AWS_SECRET_ACCESS_KEY=$(vault get aft-account-access-key-secret)
  export AWS_DEFAULT_REGION="us-east-2"
  unset AWS_PROFILE
  aws sts get-caller-identity
}

# Export the Control Tower account's AWS creds from the vault and verify with STS
useCTAccount(){
  export AWS_ACCESS_KEY_ID=$(vault get ct-account-access-key-id)
  export AWS_SECRET_ACCESS_KEY=$(vault get ct-account-access-key-secret)
  export AWS_DEFAULT_REGION="us-east-2"
  unset AWS_PROFILE
  aws sts get-caller-identity
}

# Export Cloudflare R2 (S3-compatible) creds + endpoint from the vault
useCloudflareAccount(){
  export AWS_ACCESS_KEY_ID=$(vault get cloudflare-account-access-key-id)
  export AWS_SECRET_ACCESS_KEY=$(vault get cloudflare-account-access-key-secret)
  export AWS_ENDPOINT_URL=$(vault get cloudflare-endpoint-url)
  export AWS_DEFAULT_REGION="auto"
  unset AWS_PROFILE
}

# Unset AWS_ENDPOINT_URL (undo useCloudflareAccount)
unsetEndpoint(){
  unset AWS_ENDPOINT_URL
}

# Report whether each deployment's pods are spread across nodes (true = properly distributed)
deploymentCheck(){
  kubectl get pods -A -o json | jq -r '
  .items
  | group_by(.metadata.namespace + "/" + ((.metadata.ownerReferences[]? | select(.kind == "ReplicaSet") | .name | split("-")[:-1] | join("-")) // "no-deployment"))
  | map({
      deployment: (.[0].metadata.ownerReferences[]? | select(.kind == "ReplicaSet") | .name | split("-")[:-1] | join("-")),
      namespace: .[0].metadata.namespace,
      properly_distributed: ((group_by(.spec.nodeName) | map(length) | max) == 1)
    })
  | map(select(.deployment != null))
  | .[]
  | "Deployment: \(.namespace)/\(.deployment), \(.properly_distributed)"
'
}

# Switch ANTHROPIC_API_KEY between personal and work accounts (from the vault)
switchAnthropicAccount() {
  if [[ "$1" == "personal" ]]; then
    export ANTHROPIC_API_KEY=$(vault get "personal_anthropic_api_key")
    echo "Using personal Claude account"
    return
  fi

  if [[ "$1" == "work" ]]; then
    export ANTHROPIC_API_KEY=$(vault get "anthropic_api_key")
    echo "Using work Claude account"
    return
  fi
}

# Rebase the current branch onto the fork's upstream default branch (adds the upstream remote if missing)
syncFork(){
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not a git repository"
    return 1
  fi

  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "Working tree is dirty. Commit or stash changes first."
    return 1
  fi

  if ! git remote | grep -q '^upstream$'; then
    local parent=$(gh repo view --json parent -q '.parent.owner.login + "/" + .parent.name' 2>/dev/null)
    if [[ -z "$parent" || "$parent" == "null" ]]; then
      echo "No upstream remote and couldn't detect parent repo. Add manually:"
      echo "  git remote add upstream <url>"
      return 1
    fi
    echo "Adding upstream: $parent"
    git remote add upstream "https://github.com/$parent.git"
  fi

  git fetch upstream

  local default=$(git symbolic-ref refs/remotes/upstream/HEAD 2>/dev/null | sed 's|refs/remotes/upstream/||')
  if [[ -z "$default" ]]; then
    default=$(git remote show upstream 2>/dev/null | awk '/HEAD branch/ {print $NF}')
  fi
  : "${default:=main}"

  local branch=$(git rev-parse --abbrev-ref HEAD)
  echo "Rebasing $branch onto upstream/$default..."
  git rebase "upstream/$default"
}

source $HOME/registry-list.sh

# Defaults
export AWS_DEFAULT_REGION="us-east-2"
export AWS_PROFILE="default"
unsetEndpoint
