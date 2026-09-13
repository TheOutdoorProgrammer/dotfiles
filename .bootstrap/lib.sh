#!/bin/bash
# Shared by ~/.bootstrap/main.sh (the yadm bootstrap) and the home repo's
# scripts/boot-update.sh for host setup operations.

ensure_go_module_cache() {
  local target="$1" current source_device target_device
  case "$target" in
    /*.noindex) ;;
    *) echo "Go module cache must be an absolute .noindex path" >&2; return 1 ;;
  esac
  if [ -L "$target" ]; then
    echo "Go module cache destination must not be a symlink: $target" >&2
    return 1
  fi
  if [ -n "${GOMODCACHE:-}" ]; then
    echo "unset GOMODCACHE before configuring the persistent Go module cache" >&2
    return 1
  fi
  current=$(go env GOMODCACHE) || return 1
  if [ "$current" = "$target" ]; then
    mkdir -p "$target"
    return $?
  fi
  if [ -L "$current" ]; then
    if [ "$(readlink "$current")" != "$target" ] || [ ! -d "$target" ]; then
      echo "refusing to replace the existing cache symlink: $current" >&2
      return 1
    fi
  elif [ -e "$current" ]; then
    if [ ! -d "$current" ] || [ -e "$target" ]; then
      echo "refusing to merge or overwrite Go module caches: $current and $target" >&2
      return 1
    fi
    mkdir -p "$(dirname "$target")" || return 1
    source_device=$(stat -f %d "$current") || return 1
    target_device=$(stat -f %d "$(dirname "$target")") || return 1
    if [ "$source_device" != "$target_device" ]; then
      echo "Go cache migration requires a rename on the same filesystem" >&2
      return 1
    fi
    mv "$current" "$target" || return 1
    # Old build paths remain valid, including when persisting Go's setting fails.
    if ! ln -s "$target" "$current"; then
      mv "$target" "$current"
      return 1
    fi
  else
    mkdir -p "$target" || return 1
    mkdir -p "$(dirname "$current")" || return 1
    ln -s "$target" "$current" || return 1
  fi
  go env -w GOMODCACHE="$target"
}

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
        vault_get "Agent SSH key (public)" >"$ssh_dir/id_agent.pub"
        chmod 644 "$ssh_dir/id_agent.pub"
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
