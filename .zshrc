#!/bin/zsh

# Always do this first
source ~/OP.sh

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

autoload -U compinit; compinit

# Homebrew Path Mac M1
export PATH="/opt/homebrew/bin:$PATH"
# Homebrew Path Intel
export PATH="/usr/local/sbin:$PATH"
# Custom Path
export PATH="$HOME/bin:$PATH"
# GO Path
export PATH="$HOME/projects/bin:$PATH"
# BUN path
export PATH="$HOME/.bun/bin:$PATH"

export BREW_PATH=$(brew --prefix)

# GPG and SSH config
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

# OHMYZSH and POWERLEVEL10K Config
ZSH_DISABLE_COMPFIX=true
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
autoload -U compinit && compinit
export TERM="xterm-256color"
export ZSH="/Users/$(whoami)/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh
eval "$(oh-my-posh init zsh --config /Users/$(whoami)/oh_my_posh.json)"

# Built in config
DEFAULT_USER=whoami

# Application Configuration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(mise activate zsh)"
export FZF_DEFAULT_OPTS='--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4'
export BAT_THEME="Dracula"

# Extend TMUX History File
HISTFILE=~/.histfile
HISTSIZE=1000000
SAVEHIST=1000000

# Aliases
alias ll="ls -lah"
alias cat="bat --style=plain"
alias grep="rg"
alias kunhealthy="kubectl get -o wide pods -A | grep -v \"Completed|1/1|2/2|3/3|4/4|5/5|6/6|7/7\""
alias sublime="subl"
alias k="kubectl"
alias vim="nvim"

# OrbStack's own init line (PATH for its CLI and machines); it exits quietly on
# the Macs that do not run OrbStack.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Personal Stuff
source ~/functions.sh
source ~/secrets.sh
source ~/.config/zsh/herdr-goto.zsh
export AWS_PAGER=""
export GOPATH=~/projects
# Go manages its own toolchain (brew installs one real `go`; each project's
# go.mod/go.work version directive is auto-downloaded). Not asdf — the shim
# indirection broke LSPs. See docs/dev-environment.md in the home repo.
export GOTOOLCHAIN=auto
export CDPATH=".:$HOME/projects"
export BUILDKIT_PROGRESS=plain
export AGENT_SLACK_SAFE_MODE=1  # agent-slack: send→draft redirect, edit/delete blocked (human in the loop, enforced)
export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"
export POETRY_VIRTUALENVS_PREFER_ACTIVE_PYTHON=true

# Update gpg-agent TTY without killing the agent (safe for multi-tab)
gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1

source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
source <(kubectl completion zsh)

# bun completions
[ -s "/Users/joeystout/.bun/_bun" ] && source "/Users/joeystout/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/joeystout/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
export PATH="$HOME/.local/bin:$PATH"

# Dev overrides shadow everything: temporarily drop a build into ~/dev to test
# it, delete it to fall back to the installed one. Keep this the FIRST entry.
export PATH="$HOME/dev:$PATH"

# Capture the fully-built interactive PATH for team agents, read by the
# ollie-hooks teammate-env rule when a teammate launches without it. Inert under
# Herdr, whose panes are login shells. Must be the LAST PATH line here.
print -r -- "$PATH" > "$HOME/.claude/teammate-path"
