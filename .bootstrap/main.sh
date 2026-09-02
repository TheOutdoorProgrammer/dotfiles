#!/bin/bash
# yadm bootstrap: converge this Mac to what the dotfiles expect. Idempotent, so
# `yadm bootstrap` reruns safely and `yadm clone --bootstrap` builds a new Mac.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib.sh"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/bin:$HOME/.local/bin:$PATH"
HOME_REPO="$HOME/projects/src/github.com/TheOutdoorProgrammer/home"

step() { printf '\n== %s\n' "$*"; }

step "Homebrew, jq and the 1Password CLI (everything else waits for the git identity)"
command -v brew >/dev/null 2>&1 ||
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
command -v jq >/dev/null 2>&1 || brew install jq
command -v op >/dev/null 2>&1 || brew install --cask 1password/tap/1password-cli

step "1Password service account"
if [ ! -s "$HOME/OP.sh" ]; then
  echo 'export OP_SERVICE_ACCOUNT_TOKEN=""' >"$HOME/OP.sh"
  chmod 600 "$HOME/OP.sh"
  echo "JOEY: put the 1Password service-account token into ~/OP.sh, then rerun yadm bootstrap"
  exit 1
fi
. "$HOME/OP.sh"
echo "ok: ~/OP.sh present"

step "git identity: YubiKey when present, the vault's agent key otherwise"
# Before the bundle: the tracked ssh config routes every git@github.com clone
# (taps included) through this identity.
ensure_agent_identity

step "Homebrew bundle (~/Brewfile is the tool list for every host)"
# One untrusted tap, even one the Brewfile never names, makes `brew bundle`
# refuse the whole batch with reasonless "has failed!" lines; trust the
# Brewfile's taps (tap lines and owner/tap/name entries) and every local tap.
{
  sed -n 's/^tap "\([^"]*\)".*/\1/p' "$HOME/Brewfile"
  sed -n 's/^\(brew\|cask\) "\([^"/]*\/[^"/]*\)\/[^"]*".*/\2/p' "$HOME/Brewfile"
  brew tap
} | sort -u | while read -r tap; do
  brew trust "$tap" >/dev/null 2>&1 || true
done
brew bundle install --file="$HOME/Brewfile" --no-upgrade ||
  echo "some Brewfile entries did not install; casks with installers and Mac App Store apps need a console session, rerun \`brew bundle\` there"

step "GitHub CLI"
if gh auth status >/dev/null 2>&1; then
  echo "ok: gh already authenticated"
else
  vault_get "GitHub Personal Access Token" | gh auth login --with-token
fi

step "oh-my-zsh and zsh-completions"
[ -d "$HOME/.oh-my-zsh" ] ||
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ZC="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions"
[ -d "$ZC" ] || git clone -q ssh://git@github.com/zsh-users/zsh-completions.git "$ZC"

step "mise runtimes from ~/.tool-versions (Go stays a brew formula, see the home repo)"
mise settings set auto_install true
mise install
mise reshim

step "npm globals"
npm install --global expo-cli commitizen cz-customizable >/dev/null

step "default apps and macOS defaults"
for ext in md txt yaml yml sh js config json html css ts tsx jsx rb py go; do
  duti -s com.sublimetext.4 ".$ext" all 2>/dev/null
done
defaults -currentHost write com.apple.dock tilesize -float 36
defaults -currentHost write com.apple.dock show-recents -bool false
defaults -currentHost write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2
defaults -currentHost write -g com.apple.swipescrolldirection -bool false
defaults -currentHost write -g com.apple.mouse.scaling -float "3.0"

step "gh copilot extension"
gh extension list 2>/dev/null | grep -q gh-copilot || gh extension install github/gh-copilot

step "agent-slack"
command -v agent-slack >/dev/null 2>&1 ||
  curl -fsSL https://raw.githubusercontent.com/stablyai/agent-slack/main/install.sh | sh

step "home repo"
if [ -d "$HOME_REPO" ]; then
  git -C "$HOME_REPO" pull -q --ff-only || echo "home repo is not fast-forwardable here; boot-update reconciles it"
else
  ghq get TheOutdoorProgrammer/home
fi

step "repo Go CLIs (joey, hoot, boards, custom-ollie-rules)"
# Homebrew's go defaults GOTOOLCHAIN=local, so a go.work toolchain bump fails
# `go vet` from any non-login shell (this one, hooks, gopls). Persist auto.
go env -w GOTOOLCHAIN=auto
export GOTOOLCHAIN=auto
for dir in "$HOME_REPO"/*/; do
  if [ -f "$dir/Makefile" ] && [ -f "$dir/go.mod" ]; then
    make -C "$dir" install || echo "install failed for $dir"
  fi
done

step "Claude Code MCP servers from ~/.claude/mcp-servers.json"
MCP_CONFIG="$HOME/.claude/mcp-servers.json"
# An unauthenticated `claude mcp …` blocks forever instead of failing, and
# sign-in is interactive, so a fresh Mac defers this until `claude` has run.
if [ ! -f "$HOME/.claude/.credentials.json" ]; then
  echo "skip: Claude Code is not signed in here; run \`claude\` at the console once, then rerun yadm bootstrap for the MCP servers"
elif [ -f "$MCP_CONFIG" ] && command -v claude >/dev/null 2>&1; then
  for server in $(jq -r 'keys[]' "$MCP_CONFIG"); do
    claude mcp get "$server" >/dev/null 2>&1 && continue
    claude mcp add-json "$server" "$(jq -c ".\"$server\"" "$MCP_CONFIG")" -s user && echo "mcp: $server"
  done
fi

step "Claude skills (~/.agents/skills and the home repo's skills/)"
link_claude_skills() {
  local src="$1" dir name target
  [ -d "$src" ] || return 0
  mkdir -p "$HOME/.claude/skills"
  for dir in "$src"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    target="$HOME/.claude/skills/$name"
    [ -e "$target" ] || [ -L "$target" ] || { ln -s "${dir%/}" "$target" && echo "skill: $name"; }
  done
}
link_claude_skills "$HOME/.agents/skills"
link_claude_skills "$HOME_REPO/skills"

step "agent integrations: Herdr, skills, Moshi"
if command -v herdr >/dev/null 2>&1; then
  for agent in claude codex cursor; do
    herdr integration install "$agent" >/dev/null 2>&1 && echo "herdr integration: $agent"
  done
fi
# Always --skill: rjyo/moshi-skill also ships the author's Google Play skill.
npx -y skills add herdrdev/herdr --skill herdr -g -y >/dev/null 2>&1 && echo "skill: herdr"
npx -y skills add rjyo/moshi-skill --skill moshi-best-practices -g -y >/dev/null 2>&1 && echo "skill: moshi-best-practices"
if command -v moshi-hook >/dev/null 2>&1; then
  for agent in claude codex cursor; do
    moshi-hook install --target "$agent" >/dev/null 2>&1 && echo "moshi-hook: $agent"
  done
fi

step "boot-update LaunchAgent"
PLIST="$HOME/Library/LaunchAgents/zone.stout.boot-update.plist"
if [ ! -f "$PLIST" ]; then
  cp "$HOME_REPO/scripts/zone.stout.boot-update.plist" "$PLIST" &&
    launchctl bootstrap "gui/$(id -u)" "$PLIST" && echo "boot-update agent loaded"
fi

step "yadm secrets gate (betterleaks pre-commit; these dotfiles are public)"
yadm gitconfig core.hooksPath "$HOME/.config/yadm/git-hooks"

printf '\nbootstrap done\n'
