return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
        },
      },
    },
  },
  init = function()
    local function apply()
      local ok, dracula = pcall(require, "dracula")
      if not ok then
        return
      end
      local c = dracula.colors()
      vim.api.nvim_set_hl(0, "SnacksPickerPathHidden", { fg = c.purple })
      vim.api.nvim_set_hl(0, "SnacksPickerPathIgnored", { fg = c.comment })
    end
    vim.api.nvim_create_autocmd("ColorScheme", { pattern = "dracula", callback = apply })
    apply()
  end,
}
