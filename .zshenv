# Read by every zsh, including the non-interactive `ssh host <cmd>` that Moshi's
# probes, mosh-server lookups and `herdr --remote` use: they see no .zshrc, so
# Homebrew and ~/bin have to be on PATH here.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/bin:$HOME/.local/bin:$PATH"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
