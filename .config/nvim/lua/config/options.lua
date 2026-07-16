-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Absolute line numbers only (LazyVim defaults to hybrid relative numbers).
vim.opt.relativenumber = false

-- Put mise's shims dir on nvim's PATH so spawned LSPs/tools (tofu-ls -> `tofu`,
-- `tofu fmt`, etc.) resolve mise-managed binaries. The interactive shell uses
-- mise's shim-free PATH activation, but nvim can't run that hook — so shims are
-- mise's own recommended path for editors/IDEs, and this is the one place we use
-- them (dynamic: each shim resolves the version from the nearest .tool-versions).
-- NOTE: Go is deliberately NOT in mise — it's a brew formula, so there's no `go`
-- shim here and gopls falls through to brew's `go` (GOTOOLCHAIN=auto handles
-- per-project versions). Keep it that way; a managed `go` shim shadows brew and
-- breaks gopls.
vim.env.PATH = vim.fn.expand("~/.local/share/mise/shims") .. ":" .. vim.env.PATH

-- Silence "watch.watch: ENOENT" spam from gopls. On macOS Neovim hardwires the
-- libuv fs_event watcher (no fswatch/inotify path — see runtime _watchfiles.lua),
-- and gopls (esp. with a go.work workspace) registers didChangeWatchedFiles bases
-- that don't exist on disk. libuv can't fs_event_start a missing dir, so it errors.
-- Guard the watcher: skip bases that aren't there (they're unwatchable regardless),
-- otherwise defer to the real watchfunc so live file-watching is unchanged.
do
  local wf = require("vim.lsp._watchfiles")
  local uv = vim.uv or vim.loop
  local real = wf._watchfunc
  wf._watchfunc = function(path, opts, cb)
    if not uv.fs_stat(path) then
      return function() end
    end
    return real(path, opts, cb)
  end
end
