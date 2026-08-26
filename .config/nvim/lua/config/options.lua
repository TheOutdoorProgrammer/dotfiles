-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Absolute line numbers only (LazyVim defaults to hybrid relative numbers).
vim.opt.relativenumber = false

-- nvim can't run mise's shell activation hook, so spawned LSPs/tools find
-- mise-managed binaries through the shims instead (mise's editor-recommended path).
-- A shim with no version resolvable from cwd exits 1: for `go` that kills gopls
-- ("no views"), so keep a global default (`mise use -g go@<ver>`) for unpinned repos.
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
