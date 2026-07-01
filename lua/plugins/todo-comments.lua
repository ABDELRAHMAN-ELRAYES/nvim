return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    { "]t",          function() require("todo-comments").jump_next() end, desc = "Next TODO comment" },
    { "[t",          function() require("todo-comments").jump_prev() end, desc = "Prev TODO comment" },
    { "<leader>xt",  "<cmd>Trouble todo toggle<cr>",                      desc = "TODO list (Trouble)" },
    { "<leader>xT",  "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "TODO/FIX/FIXME" },
    { "<leader>st",  "<cmd>TodoTelescope<cr>",                            desc = "Search TODOs" },
  },
  opts = {
    signs = true,
    keywords = {
      FIX  = { icon = " ", color = "error",   alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
      TODO = { icon = " ", color = "info" },
      HACK = { icon = " ", color = "warning" },
      WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
      PERF = { icon = "󰅒 ",                   alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
      NOTE = { icon = "󰙏 ", color = "hint",   alt = { "INFO" } },
      TEST = { icon = "⏲ ", color = "test",   alt = { "TESTING", "PASSED", "FAILED" } },
    },
    highlight = {
      before  = "",
      keyword = "wide_bg",
      after   = "fg",
      pattern = [[.*<(KEYWORDS)\s*:]],
      comments_only = true,
    },
  },
}
