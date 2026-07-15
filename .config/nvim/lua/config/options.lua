-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Absolute line numbers only (LazyVim defaults to hybrid relative numbers).
vim.opt.relativenumber = false

-- Put asdf shims on nvim's PATH so spawned LSPs/tools (tofu-ls -> `tofu`,
-- `tofu fmt`, etc.) resolve asdf-managed binaries even when nvim was launched
-- from a context that didn't source the shell's asdf init (e.g. the cmux layout).
vim.env.PATH = vim.fn.expand("~/.asdf/shims") .. ":" .. vim.env.PATH
