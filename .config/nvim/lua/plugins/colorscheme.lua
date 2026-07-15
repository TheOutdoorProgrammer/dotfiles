return {
  -- Dracula palette (my preferred theme everywhere)
  { "Mofiqul/dracula.nvim", lazy = false, priority = 1000 },

  -- Point LazyVim at it
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula",
    },
  },
}
