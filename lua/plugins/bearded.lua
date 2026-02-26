return {
  "d-Dudas/bearded.nvim",
  lazy = false,
  priority = 1002,
  config = function()
    require("bearded").setup({
      style = {
        transparent = true,
        italic_comments = true,
        italic_keywords = false,
        bold_functions = true,
        dim_inactive = false,
        float_blend = 0,
      },
    })
    vim.cmd.colorscheme("bearded")
  end,
}


