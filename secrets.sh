#!/bin/zsh

# Fetch all secrets in parallel to avoid serial 1Password CLI latency
setopt LOCAL_OPTIONS NO_MONITOR
_secrets_tmp=$(mktemp -d)
_secrets_pids=()

# Usage: _fetch <outfile> <command> [args...]
_fetch() {
  local outfile=$1; shift
  "$@" > "$_secrets_tmp/$outfile" 2>/dev/null &
  _secrets_pids+=($!)
}

_fetch github_token  vault get "GitHub Personal Access Token"
_fetch dockerhub     vault get "DockerHub"
_fetch openai        vault get "OpenAPI Key"
_fetch cloudflare    vault get "Cloudflare API Key"
_fetch smithery      vault get "Smithery API Key"
_fetch perplexity    vault get "perplexity_api_key"
_fetch obsidian      vault get "Obsidian API Key"
_fetch slack         vault get "SLACK_WORKSPACE_URL"
_fetch gemini        vault get "GEMINI_API_KEY"
_fetch airtrail      vault get "AirTrail API Key"
#_fetch litellm       vault get "LiteLLM API Key"
#_fetch litellm_work  vault get "LiteLLM Work API Key"
_fetch spacelift     spacectl profile export-token

# Watchdog: kill any stragglers after 60s
( sleep 60; kill $_secrets_pids 2>/dev/null ) &
_secrets_watchdog=$!

# Wait for all secret fetches, track if any failed
_secrets_ok=true
for _pid in $_secrets_pids; do
  wait $_pid 2>/dev/null || _secrets_ok=false
done

# Clean up the watchdog
kill $_secrets_watchdog 2>/dev/null
wait $_secrets_watchdog 2>/dev/null

if [[ $_secrets_ok == false ]]; then
  print -P "%F{yellow}⚠ Issue setting secrets (timed out or failed)%f" >&2
fi

export GITHUB_TOKEN=$(<"$_secrets_tmp/github_token")
export DOCKERHUB_USERNAME="apollorion"
export DOCKERHUB_PASSWORD=$(<"$_secrets_tmp/dockerhub")
export OPENAI_API_KEY=$(<"$_secrets_tmp/openai")
export CLOUDFLARE_API_TOKEN=$(<"$_secrets_tmp/cloudflare")
export SMITHERY_API_KEY=$(<"$_secrets_tmp/smithery")
export PERPLEXITY_API_KEY=$(<"$_secrets_tmp/perplexity")
export OBSIDIAN_API_KEY=$(<"$_secrets_tmp/obsidian")
export SPACELIFT_API_TOKEN=$(<"$_secrets_tmp/spacelift")
export SLACK_WORKSPACE_URL=$(<"$_secrets_tmp/slack")
export GEMINI_API_KEY=$(<"$_secrets_tmp/gemini")
export AIRTRAIL_API_KEY=$(<"$_secrets_tmp/airtrail")
#export LITELLM_API_KEY=$(<"$_secrets_tmp/litellm")
#export LITELLM_WORK_API_KEY=$(<"$_secrets_tmp/litellm_work")

#export ANTHROPIC_BASE_URL=https://ai.stout.zone
#export ANTHROPIC_CUSTOM_HEADERS="x-litellm-api-key: Bearer $LITELLM_WORK_API_KEY"

rm -rf "$_secrets_tmp"
unset _secrets_tmp
