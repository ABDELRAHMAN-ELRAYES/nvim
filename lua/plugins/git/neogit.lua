return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = true,
  keys = {
    { "<leader>ng", "<cmd>Neogit<cr>", desc = "Neogit Status" },
  },
}
