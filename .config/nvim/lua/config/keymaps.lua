-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Ctrl+click a symbol to jump to its definition (Cmd+click can't reach a terminal
-- app — the mouse protocol has no Cmd modifier). <LeftMouse> positions the cursor
-- first, then LSP jumps.
vim.keymap.set("n", "<C-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.definition()<cr>", { desc = "Go to definition (Ctrl+click)" })
