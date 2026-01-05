#!/bin/zsh

# github token
export GITHUB_TOKEN=$(vault get "GitHub Personal Access Token")

# dockerhub
export DOCKERHUB_USERNAME="apollorion"
export DOCKERHUB_PASSWORD=$(vault get "DockerHub")

export OPENAI_API_KEY=$(vault get "OpenAPI Key")

export CLOUDFLARE_API_TOKEN=$(vault get "Cloudflare API Key")

export SMITHERY_API_KEY=$(vault get "Smithery API Key")

export ANTHROPIC_API_KEY=$(vault get "anthropic_api_key")

export PERPLEXITY_API_KEY=$(vault get "perplexity_api_key")

export OBSIDIAN_API_KEY=$(vault get "Obsidian API Key")

export SPACELIFT_API_TOKEN=$(spacectl profile export-token)
