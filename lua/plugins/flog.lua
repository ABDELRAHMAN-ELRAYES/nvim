return {
  "rbong/vim-flog",
  dependencies = { "tpope/vim-fugitive" },
  cmd = { "Flog", "Flogsplit", "Floggit" },
  keys = {
    { "<leader>gl",  "<cmd>Flog<cr>",       desc = "Git Log Graph (Flog)" },
    { "<leader>gls", "<cmd>Flogsplit<cr>",   desc = "Git Log Graph Split (Flog)" },
  },
}
