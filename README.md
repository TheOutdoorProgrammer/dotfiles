# Joeys Dotfiles

## Installation

1. Install Homebrew - brew.sh
2. Install Yadm `brew install yadm`
3. Using yadm, clone this repo `yadm clone https://github.com/Apollorion/dotfiles.git`
4. Install GPG keys off your yubikey `gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xFAFA8E62C123F240`
5. Add your public key off your yubikey for SSH (make sure yubikey is plugged in) `ssh-add -L > ~/.ssh/id_rsa_yubikey.pub`
6. If not asked, run bootstrap `yadm bootstrap`

## Go module cache

Bootstrap moves the Go module cache into `$HOME/Library/Caches/go-mod.noindex` and persists `GOMODCACHE` with `go env -w`.
The `.noindex` directory keeps Spotlight from indexing downloaded dependencies.
The old cache path becomes a symlink so existing build paths remain valid.

Stop Go builds and language servers before the first migration, and run only one bootstrap at a time.
Unset any exported `GOMODCACHE` first.
Migration refuses to merge existing caches or copy between filesystems, preserving the original cache on those conflicts.
Repeated runs reuse the configured cache.

To apply just this step after updating the dotfiles:

```sh
bash -c 'source "$HOME/.bootstrap/lib.sh"; ensure_go_module_cache "$HOME/Library/Caches/go-mod.noindex"'
```

Run the isolated migration checks with `bash .bootstrap/test-go-module-cache.sh`.
They use a temporary `GOENV` and leave the host's Go configuration unchanged.

## Updating GPG Keys after expiration

See [updating_keys.md](keys/updating_keys.md) in the keys directory.

## Notes

If you have trouble with SSH/GPG, try the following:

- run `gpgfix` this will run a command that will force your yubikey to, basically, restart
- run `gpg --card-status` not sure why but this fixes problems sometimes
