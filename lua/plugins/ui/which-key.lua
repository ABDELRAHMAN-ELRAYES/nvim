return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 400, -- ms before popup appears
    icons = {
      mappings = true,
      keys = {},
    },
    spec = {
      -- Group labels so the popup is organized
      { "<leader>g",  group = "Git" },
      { "<leader>h",  group = "Git hunks" },
      { "<leader>x",  group = "Diagnostics / Trouble" },
      { "<leader>t",  group = "Toggle" },
      { "<leader>c",  group = "Code actions" },
    },
  },
}
