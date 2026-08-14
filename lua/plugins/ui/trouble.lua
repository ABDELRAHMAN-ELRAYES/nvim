return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Trouble",
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",                        desc = "Diagnostics (project)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",           desc = "Diagnostics (buffer)" },
    { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>",                desc = "Symbols (Trouble)" },
    { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP definitions / refs" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>",                            desc = "Location list" },
    { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>",                             desc = "Quickfix list" },
  },
  opts = {
    modes = {
      diagnostics = {
        auto_open   = false,
        auto_close  = true,   -- close when no items remain
        auto_preview = true,
        use_diagnostic_signs = true,
      },
    },
  },
}
