-- Use OpenTofu instead of Terraform for the lang.terraform extra.
-- Swaps the language server, formatter, and linter; keeps the extra's
-- treesitter parsers, tflint, and telescope docs.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        terraformls = false, -- disable HashiCorp Terraform LS
        tofu_ls = {}, -- OpenTofu Language Server (cmd: `tofu-ls serve`)
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs({ "terraform", "tf", "terraform-vars", "opentofu", "opentofu-vars" }) do
        opts.formatters_by_ft[ft] = { "tofu_fmt" } -- `tofu fmt`
      end
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      for _, ft in ipairs({ "terraform", "tf", "opentofu" }) do
        opts.linters_by_ft[ft] = { "tofu" } -- `tofu validate`
      end
    end,
  },
}
