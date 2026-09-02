#!/bin/bash
# Shared by ~/.bootstrap/main.sh (the yadm bootstrap) and the home repo's
# scripts/boot-update.sh, so both agree on how a host gets its git identity.

# vault_get reads one CLI-vault secret: through joey once it is built, through
# raw op before that (bootstrap runs first). Needs ~/OP.sh sourced.
vault_get() {
  if command -v joey >/dev/null 2>&1; then
    joey vault get "$1"
  else
    op item get "$1" --vault CLI --fields data --reveal --format json | jq -r .value
  fi
}

# ensure_agent_identity points ~/.ssh/id_signing at the key this host can use:
# the YubiKey's PIV key when its agent socket exists, otherwise the shared
# agent key, fetched from the vault the first time (home repo ADR 0005).
ensure_agent_identity() {
  local ssh_dir="$HOME/.ssh" target tmp
  mkdir -p "$ssh_dir" && chmod 700 "$ssh_dir"
  if [ -S "$ssh_dir/agent.sock" ]; then
    target="id_piv_auth.pub"
  else
    target="id_agent"
    if [ ! -s "$ssh_dir/id_agent" ]; then
      [ -f "$HOME/OP.sh" ] && . "$HOME/OP.sh"
      tmp=$(mktemp "$ssh_dir/.id_agent.XXXXXX") || return 1
      if vault_get "Agent SSH key" >"$tmp" && [ -s "$tmp" ]; then
        chmod 600 "$tmp" && mv -f "$tmp" "$ssh_dir/id_agent"
        vault_get "Agent SSH key (public)" >"$ssh_dir/id_agent.pub" && chmod 644 "$ssh_dir/id_agent.pub"
        echo "installed ~/.ssh/id_agent from the vault"
      else
        rm -f "$tmp"
        echo "could not fetch the agent SSH key from the vault" >&2
        return 1
      fi
    fi
  fi
  if [ "$(readlink "$ssh_dir/id_signing" 2>/dev/null)" != "$target" ]; then
    ln -sfn "$target" "$ssh_dir/id_signing" && echo "$ssh_dir/id_signing -> $target"
  fi
}
