-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Ctrl+click a symbol to jump to its definition (Cmd+click can't reach a terminal
-- app — the mouse protocol has no Cmd modifier). <LeftMouse> positions the cursor
-- first, then LSP jumps.
vim.keymap.set("n", "<C-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.definition()<cr>", { desc = "Go to definition (Ctrl+click)" })

-- <leader>cy: yank diagnostics to the system clipboard for pasting elsewhere
-- (bug reports, chats). Copies the current line's diagnostics, or the whole
-- buffer's if the cursor line is clean. Each line is "row:col message".
vim.keymap.set("n", "<leader>cy", function()
  local diags = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
  local scope = "line"
  if vim.tbl_isempty(diags) then
    diags = vim.diagnostic.get(0)
    scope = "buffer"
  end
  if vim.tbl_isempty(diags) then
    vim.notify("No diagnostics to copy", vim.log.levels.WARN)
    return
  end
  local lines = {}
  for _, d in ipairs(diags) do
    lines[#lines + 1] = string.format("%d:%d %s", d.lnum + 1, d.col + 1, d.message)
  end
  vim.fn.setreg("+", table.concat(lines, "\n"))
  vim.notify(string.format("Copied %d %s diagnostic(s) to clipboard", #diags, scope))
end, { desc = "Copy diagnostics to clipboard" })
