return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add          = { text = "▎" },
      change       = { text = "▎" },
      delete       = { text = "" },
      topdelete    = { text = "" },
      changedelete = { text = "▎" },
      untracked    = { text = "▎" },
    },
    signs_staged = {
      add          = { text = "▎" },
      change       = { text = "▎" },
      delete       = { text = "" },
      topdelete    = { text = "" },
      changedelete = { text = "▎" },
    },
    current_line_blame = false, -- toggle with <leader>gb
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol",
      delay = 500,
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      -- Navigation between hunks
      map("n", "]h", gs.next_hunk,  "Next git hunk")
      map("n", "[h", gs.prev_hunk,  "Prev git hunk")

      -- Hunk actions
      map("n", "<leader>hs", gs.stage_hunk,        "Stage hunk")
      map("n", "<leader>hr", gs.reset_hunk,        "Reset hunk")
      map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage hunk (visual)")
      map("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset hunk (visual)")
      map("n", "<leader>hS", gs.stage_buffer,      "Stage buffer")
      map("n", "<leader>hR", gs.reset_buffer,      "Reset buffer")
      map("n", "<leader>hu", gs.undo_stage_hunk,   "Undo stage hunk")
      map("n", "<leader>hp", gs.preview_hunk,      "Preview hunk")

      -- Blame
      map("n", "<leader>gb", gs.toggle_current_line_blame, "Toggle git blame")
      map("n", "<leader>gB", function() gs.blame_line({ full = true }) end, "Git blame full")

      -- Diff
      map("n", "<leader>gd", gs.diffthis,          "Diff this")
      map("n", "<leader>gD", function() gs.diffthis("~") end, "Diff this ~")

      -- Toggle
      map("n", "<leader>td", gs.toggle_deleted,    "Toggle deleted lines")
    end,
  },
}
