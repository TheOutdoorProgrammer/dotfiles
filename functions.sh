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
      # Get the base branch (main or master)
      base_branch=$(hub rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||' || echo "main")

      # Get the merge base
      merge_base=$(hub merge-base HEAD origin/$base_branch 2>/dev/null || hub merge-base HEAD $base_branch)

      # Get the last commit message for PR title
      pr_title=$(hub log -1 --pretty=%s)

      # Get commit log
      commit_log=$(hub log --oneline $merge_base..HEAD)

      # Get the diff
      diff_output=$(hub diff $merge_base...HEAD)

      # Create a temporary file with the context
      context_file=$(mktemp)
      cat > "$context_file" << EOF
Generate a pull request description based on these changes.

## Commit History:
$commit_log

## Changes:
$diff_output

IMPORTANT: Your output will be streamed to the terminal in real-time so the user can see your thinking process.
You MUST wrap the final PR description body between <PR_DESCRIPTION_BODY> and </PR_DESCRIPTION_BODY> tags.
Everything outside these tags will be visible to the user but NOT included in the PR.

Please provide a well-structured PR description with the following sections:

1. A short 1-2 sentence description of the change
2. **Motivation** - Why this change is needed
3. **Changes** - Bullet points of what changed
4. **Features** (if new feature) or **Fixes** (if bug fixes) - What functionality is added/fixed
5. **Usage** - How to use the new feature/changes (if applicable)
6. **Documentation** - Links to relevant docs (if any, omit section if none)

Use markdown formatting to make it readable. Keep it concise but informative.
EOF

      # Get PR description from Claude with progress spinner
      echo -n "Generating PR description... "

      # Disable job control messages
      set +m

      # Start spinner in background
      (
        spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        i=0
        while true; do
          printf "\b${spinner:$i:1}"
          i=$(( (i + 1) % 10 ))
          sleep 0.1
        done
      ) &
      spinner_pid=$!

      # Get PR description from Claude
      full_output=$(claude -p "$(cat $context_file)")

      # Kill spinner
      kill $spinner_pid 2>/dev/null
      wait $spinner_pid 2>/dev/null
      printf "\b✓\n\n"

      # Re-enable job control
      set -m

      # Show the full output
      echo "$full_output"
      echo ""

      rm "$context_file"

      # Extract content between tags
      pr_body=$(echo "$full_output" | sed -n '/<PR_DESCRIPTION_BODY>/,/<\/PR_DESCRIPTION_BODY>/p' | sed '1d;$d')

      # Extract any additional flags passed after -o
      shift 2  # Remove "pull-request" and "-o"
      additional_flags="$@"

      # Create PR with hub - separate title and body
      hub pull-request -o -m "$pr_title" -m "$pr_body" $additional_flags
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

source $HOME/registry-list.sh

# Defaults
export AWS_DEFAULT_REGION="us-east-2"
export AWS_PROFILE="default"
