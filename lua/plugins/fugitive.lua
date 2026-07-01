return {
  "tpope/vim-fugitive",
  cmd = { "Git", "G", "Gclog", "GBrowse", "Gread", "Gwrite", "Gdiffsplit" },
  keys = {
    { "<leader>gs", "<cmd>Git<cr>",         desc = "Git Status (Fugitive)" },
    { "<leader>gb", "<cmd>Git blame<cr>",    desc = "Git Blame" },
    { "<leader>gB", "<cmd>GBrowse<cr>",      desc = "Git Browse (open in browser)" },
    { "<leader>gw", "<cmd>Gwrite<cr>",       desc = "Git Stage Current File" },
  },
}
