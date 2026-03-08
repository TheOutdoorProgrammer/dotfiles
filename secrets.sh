#!/bin/zsh

# Fetch all secrets in parallel to avoid serial 1Password CLI latency
setopt LOCAL_OPTIONS NO_MONITOR
_secrets_tmp=$(mktemp -d)

vault get "GitHub Personal Access Token"  > "$_secrets_tmp/github_token" &
vault get "DockerHub"                     > "$_secrets_tmp/dockerhub" &
vault get "OpenAPI Key"                   > "$_secrets_tmp/openai" &
vault get "Cloudflare API Key"            > "$_secrets_tmp/cloudflare" &
vault get "Smithery API Key"              > "$_secrets_tmp/smithery" &
vault get "anthropic_api_key"             > "$_secrets_tmp/anthropic" &
vault get "perplexity_api_key"            > "$_secrets_tmp/perplexity" &
vault get "Obsidian API Key"              > "$_secrets_tmp/obsidian" &
vault get "SLACK_WORKSPACE_URL"           > "$_secrets_tmp/slack" &
spacectl profile export-token             > "$_secrets_tmp/spacelift" &

wait

export GITHUB_TOKEN=$(<"$_secrets_tmp/github_token")
export DOCKERHUB_USERNAME="apollorion"
export DOCKERHUB_PASSWORD=$(<"$_secrets_tmp/dockerhub")
export OPENAI_API_KEY=$(<"$_secrets_tmp/openai")
export CLOUDFLARE_API_TOKEN=$(<"$_secrets_tmp/cloudflare")
export SMITHERY_API_KEY=$(<"$_secrets_tmp/smithery")
export ANTHROPIC_API_KEY=$(<"$_secrets_tmp/anthropic")
export PERPLEXITY_API_KEY=$(<"$_secrets_tmp/perplexity")
export OBSIDIAN_API_KEY=$(<"$_secrets_tmp/obsidian")
export SPACELIFT_API_TOKEN=$(<"$_secrets_tmp/spacelift")
export SLACK_WORKSPACE_URL=$(<"$_secrets_tmp/slack")

rm -rf "$_secrets_tmp"
unset _secrets_tmp
