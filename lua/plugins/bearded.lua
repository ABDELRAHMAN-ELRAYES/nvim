return {
  "xStormyy/bearded-theme.nvim",
  lazy = false,
  priority = 1002,
  config = function()
    require("bearded").setup({
      theme = "arc",         -- Arc family
      variant = "blueberry", -- Arc Blueberry variant
      transparent = true,
    })
    vim.cmd.colorscheme("bearded-arc-blueberry")
  end,
}

