changeProfile(){
    export AWS_PROFILE=$1
    aws sts get-caller-identity
}

changeRegion(){
    export AWS_DEFAULT_REGION=$1
    echo "Changed region to $1"
}

sourceHome(){
    source ~/.zshrc
}

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

killTmux(){
  # check if session is passed in as a variable
  if [[ "$1" != "" ]]; then
    tmux kill-session -t $1
  else
    tmux kill-session
  fi
}

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

gpgfix(){
  gpgconf --kill gpg-agent
  gpgconf --launch gpg-agent
  gpg-connect-agent updatestartuptty /bye
  gpg --card-status
}

count(){
  wc -l | xargs
}

yadmUpdateRemote(){
  cd ~
  yadm commit -a -m "$1"
  yadm push origin main
  cd -
}

yadmFetchRemote(){
  cd ~
  yadm fetch
  yadm pull
  cd -
}

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
      code --agent ask --prompt "Create a pull request for the current project using the git-pull-request skill." --model "anthropic/claude-sonnet-4-5"
    ;;

    "checkout")
       git checkout $(git branch -a | grep -ve "\*" -ve "->"  | sed 's/remotes\/origin\///' | awk '!seen[$0]++' | fzf)
    ;;

    *)
      hub "$@"
    ;;

  esac
}

ksecret(){
  kubectl get secret $1 -o json | jq '.data | map_values(@base64d)'
}

killDNS(){
  sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
}

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

exitKubie(){
  if [[ ! -z "${KUBECONFIG}" ]]; then
    echo "Exiting Kubie Shell"
    exit
  fi
}

help(){
  claude -p "$1"
}

fixGo(){
  golangci-lint run --fix
}

changeVideo(){
  curl http://digitalwindow.stout.zone:3000/change
}

setVideo(){
  curl -H "youtube-url:$1" http://digitalwindow.stout.zone:3000/set_video_id
}

idea(){
  open -na "IntelliJ IDEA.app" --args "$@"
}


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

kubie() {
    [[ "$1" == "ctx" ]] && kubecm switch "${@:2}" || kubecm "$@"
}

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

useAFTAccount(){
  export AWS_ACCESS_KEY_ID=$(vault get aft-account-access-key-id)
  export AWS_SECRET_ACCESS_KEY=$(vault get aft-account-access-key-secret)
  export AWS_DEFAULT_REGION="us-east-2"
  unset AWS_PROFILE
  aws sts get-caller-identity
}

useCTAccount(){
  export AWS_ACCESS_KEY_ID=$(vault get ct-account-access-key-id)
  export AWS_SECRET_ACCESS_KEY=$(vault get ct-account-access-key-secret)
  export AWS_DEFAULT_REGION="us-east-2"
  unset AWS_PROFILE
  aws sts get-caller-identity
}

useCloudflareAccount(){
  export AWS_ACCESS_KEY_ID=$(vault get cloudflare-account-access-key-id)
  export AWS_SECRET_ACCESS_KEY=$(vault get cloudflare-account-access-key-secret)
  export AWS_ENDPOINT_URL=$(vault get cloudflare-endpoint-url)
  export AWS_DEFAULT_REGION="auto"
  unset AWS_PROFILE
}

unsetEndpoint(){
  unset AWS_ENDPOINT_URL
}

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

code() {
  if [[ "$1" == "-r" ]]; then
    # List sessions, select with fzf (keep header, remove separator line), extract session ID, and resume
    local session_line=$(opencode session list | sed '2d' | fzf --header-lines=1)
    if [[ -n "$session_line" ]]; then
      # Parse session ID from the line (assuming format like "session-id: ...")
      local session_id=$(echo "$session_line" | awk '{print $1}')
      opencode -s "$session_id"
    fi
  elif [[ $# -eq 0 ]]; then
    opencode --agent ask
  else
    opencode "$@"
  fi
}

source $HOME/registry-list.sh

# Defaults
export AWS_DEFAULT_REGION="us-east-2"
export AWS_PROFILE="default"
unsetEndpoint
