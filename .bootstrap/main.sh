#!/bin/bash

# Install brew stuff
cd ~
brew bundle install
cd -

# Install OHMYZSH
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Easy K8s Secrets
cd ~
git clone https://github.com/Apollorion/easy-k8s-secrets.git
cd -

# Set default applications for file types
duti -s com.sublimetext.4 .md all
duti -s com.sublimetext.4 .txt all
duti -s com.sublimetext.4 .yaml all
duti -s com.sublimetext.4 .yml all
duti -s com.sublimetext.4 .sh all
duti -s com.sublimetext.4 .js all
duti -s com.sublimetext.4 .config all
duti -s com.sublimetext.4 .json all
duti -s com.sublimetext.4 .html all
duti -s com.sublimetext.4 .css all
duti -s com.sublimetext.4 .ts all
duti -s com.sublimetext.4 .tsx all
duti -s com.sublimetext.4 .jsx all
duti -s com.sublimetext.4 .rb all
duti -s com.sublimetext.4 .py all
duti -s com.sublimetext.4 .go all

# Install / configure asdf plugins
asdf plugin add awscli
asdf plugin add golang
asdf plugin add kubectl
asdf plugin add terraform
asdf plugin add opentofu
asdf plugin add nodejs
asdf plugin add yarn
asdf plugin add python
asdf plugin add ruby
asdf plugin add golangci-lint https://github.com/hypnoglow/asdf-golangci-lint.git

asdf install awscli latest
asdf install golang 1.17.6
asdf install kubectl latest
asdf install terraform latest
asdf install opentofu latest
asdf install nodejs lts
asdf install yarn 1.22.17
asdf install python 3.10.5
asdf install ruby 3.1.2
asdf install golangci-lint 1.64.8

asdf set --home awscli latest
asdf set --home golang 1.17.6
asdf set --home kubectl latest
asdf set --home terraform latest
asdf set --home opentofu latest
asdf set --home nodejs lts
asdf set --home yarn 1.22.17
asdf set --home python 3.10.5
asdf set --home ruby 3.1.2
asdf set --home golangci-lint 1.64.8

npm install --global expo-cli commitizen cz-customizable

# OSX defaults
defaults -currentHost write com.apple.dock tilesize -float 36 # Sets dock size
defaults -currentHost write com.apple.dock show-recents -bool false # Disable recents in the dock
defaults -currentHost write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2 # Right click with bottom right corner of trackpad
defaults -currentHost write -g com.apple.swipescrolldirection -bool false # Disable natural scroll direction
defaults -currentHost write -g com.apple.mouse.scaling -float "3.0" # Speed up the mouse

# GPG Things
#launchctl load gnupg.gpg-agent.plist
#launchctl load gnupg.gpg-agent-symlink.plist

# Install help command
gh extension install github/gh-copilot

# Install Slack CLI
curl -fsSL https://raw.githubusercontent.com/stablyai/agent-slack/main/install.sh | sh

# Claude Code MCP servers
MCP_CONFIG="$HOME/.claude/mcp-servers.json"
if [ -f "$MCP_CONFIG" ] && command -v claude &>/dev/null; then
  echo "Installing Claude Code MCP servers..."
  for server in $(jq -r 'keys[]' "$MCP_CONFIG"); do
    config=$(jq -c ".\"$server\"" "$MCP_CONFIG")
    claude mcp add-json "$server" "$config" -s user
  done
  echo "Claude Code MCP servers installed."
elif [ -f "$MCP_CONFIG" ]; then
  echo "SKIP: claude CLI not found — install Claude Code, then re-run bootstrap for MCP servers."
fi

# Wire agent skills into Claude Code (~/.claude/skills)
# Source of truth: ~/.agents/skills (tracked in dotfiles) and the home repo (if cloned).
# Idempotent — only creates links that are missing, never clobbers existing files.
link_claude_skills() {
  local src="$1"
  [ -d "$src" ] || return 0
  mkdir -p "$HOME/.claude/skills"
  local dir name target
  for dir in "$src"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    target="$HOME/.claude/skills/$name"
    if [ -e "$target" ] || [ -L "$target" ]; then
      continue
    fi
    ln -s "${dir%/}" "$target" && echo "linked claude skill: $name"
  done
}
link_claude_skills "$HOME/.agents/skills"
link_claude_skills "$HOME/projects/src/github.com/TheOutdoorProgrammer/home/skills"

# OnePassword Check
if [ ! -f ~/OP.sh ]; then
  echo "export OP_SERVICE_ACCOUNT_TOKEN=\"\"" > ~/OP.sh
  chmod +x ~/OP.sh
  echo "JOEY put your onepassword service account token into ~/OP.sh"
fi
