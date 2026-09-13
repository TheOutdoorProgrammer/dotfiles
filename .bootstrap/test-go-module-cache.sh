#!/bin/bash
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cache_test_root=$(mktemp -d)
trap 'rm -rf "$cache_test_root"' EXIT
unset GOMODCACHE
export GOENV="$cache_test_root/go-env" GOPATH="$cache_test_root/go"
cache_source="$GOPATH/pkg/mod"
cache_target="$cache_test_root/caches/go-mod.noindex"

mkdir -p "$cache_source/example.com/dependency@v1.0.0"
printf '%s\n' 'module example.com/dependency' > "$cache_source/example.com/dependency@v1.0.0/go.mod"
cache_inode=$(stat -f %i "$cache_source")
ensure_go_module_cache "$cache_target"
[ "$(go env GOMODCACHE)" = "$cache_target" ]
[ "$(readlink "$cache_source")" = "$cache_target" ]
[ "$(stat -f %i "$cache_target")" = "$cache_inode" ]
cmp "$cache_source/example.com/dependency@v1.0.0/go.mod" "$cache_target/example.com/dependency@v1.0.0/go.mod"
ensure_go_module_cache "$cache_target"
[ "$(stat -f %i "$cache_target")" = "$cache_inode" ]
printf '%s\n' 'PASS: migration preserves cache identity and legacy paths; rerun is idempotent'

go env -w GOMODCACHE="$cache_source"
ensure_go_module_cache "$cache_target"
[ "$(go env GOMODCACHE)" = "$cache_target" ]
printf '%s\n' 'PASS: retry completes persistence after an interrupted migration'

export GOENV="$cache_test_root/fresh-env" GOPATH="$cache_test_root/fresh-go"
ensure_go_module_cache "$cache_test_root/fresh.noindex"
[ -d "$cache_test_root/fresh.noindex" ]
[ "$(go env GOMODCACHE)" = "$cache_test_root/fresh.noindex" ]
[ "$(readlink "$GOPATH/pkg/mod")" = "$cache_test_root/fresh.noindex" ]
printf '%s\n' 'PASS: new installation creates and configures the cache'

mkdir "$cache_test_root/indexed-cache"
ln -s "$cache_test_root/indexed-cache" "$cache_test_root/symlink.noindex"
for cache_setting in "$cache_test_root/absent" "$cache_test_root/symlink.noindex" "$GOPATH/pkg/mod"; do
  go env -w GOMODCACHE="$cache_setting"
  if ensure_go_module_cache "$cache_test_root/symlink.noindex"; then
    echo 'FAIL: accepted a symlink destination' >&2
    exit 1
  fi
  [ "$(go env GOMODCACHE)" = "$cache_setting" ]
done
printf '%s\n' 'PASS: symlink destinations cannot bypass indexing exclusion'

export GOENV="$cache_test_root/conflict-env" GOPATH="$cache_test_root/conflict-go"
mkdir -p "$GOPATH/pkg/mod" "$cache_test_root/conflict.noindex"
printf '%s\n' 'source' > "$GOPATH/pkg/mod/keep"
printf '%s\n' 'target' > "$cache_test_root/conflict.noindex/keep"
if ensure_go_module_cache "$cache_test_root/conflict.noindex"; then
  echo 'FAIL: accepted conflicting caches' >&2
  exit 1
fi
[ "$(cat "$GOPATH/pkg/mod/keep")" = source ]
[ "$(cat "$cache_test_root/conflict.noindex/keep")" = target ]
[ "$(go env GOMODCACHE)" = "$GOPATH/pkg/mod" ]
printf '%s\n' 'PASS: conflicting caches remain untouched'

export GOMODCACHE="$cache_source"
if ensure_go_module_cache "$cache_target"; then
  echo 'FAIL: accepted an environment override' >&2
  exit 1
fi
unset GOMODCACHE
if ensure_go_module_cache "$cache_test_root/indexed"; then
  echo 'FAIL: accepted an indexed destination' >&2
  exit 1
fi
printf '%s\n' 'PASS: environment overrides and indexed destinations are refused'
