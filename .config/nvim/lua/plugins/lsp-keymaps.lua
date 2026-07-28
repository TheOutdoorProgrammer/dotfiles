-- Extra LSP navigation/fixes under <leader>c, alongside LazyVim's gd/gI/gD.

-- gopls and vtsls don't implement textDocument/declaration; fall back to
-- definition so the key is never dead.
local function goto_definition()
  if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = 0, method = "textDocument/declaration" })) then
    return vim.lsp.buf.definition()
  end
  vim.lsp.buf.declaration()
end

-- There's no code-action kind for this: vtsls emits a plain `quickfix` titled
-- "Add missing properties", so match the title and apply it without a menu.
local function add_missing_properties()
  vim.lsp.buf.code_action({
    apply = true,
    context = { only = { "quickfix" } },
    filter = function(action)
      return (action.title or ""):lower():find("missing propert", 1, true) ~= nil
    end,
  })
end

return {
  {
    "neovim/nvim-lspconfig",
    -- Appended, not assigned: lazy.nvim replaces list values instead of merging,
    -- so setting servers["*"].keys would wipe LazyVim's own LSP keymaps.
    opts = function(_, opts)
      vim.list_extend(opts.servers["*"].keys, {
        { "<leader>cd", goto_definition, desc = "Goto Definition" },
        { "<leader>ci", vim.lsp.buf.implementation, desc = "Goto Implementation" },
        { "<leader>ct", vim.lsp.buf.type_definition, desc = "Goto Type Definition" },
        -- "U"sages: cr/cR/cf/cu are all taken.
        { "<leader>cU", vim.lsp.buf.references, desc = "References" },
        { "<leader>cP", add_missing_properties, desc = "Add Missing Properties", has = "codeAction" },
      })
    end,
  },
}
