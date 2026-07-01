return {
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  keys = {
    { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undo Tree" },
  },
  config = function()
    vim.g.undotree_WindowLayout       = 2    -- tree on left, diff on right
    vim.g.undotree_SplitWidth         = 35
    vim.g.undotree_SetFocusWhenToggle = 1    -- focus tree panel on open
    vim.g.undotree_ShortIndicators    = 1
    vim.g.undotree_RelativeTimestamp  = 1

    -- Persist undo history across Neovim restarts
    if vim.fn.has("persistent_undo") == 1 then
      local undo_dir = vim.fn.stdpath("data") .. "/undo"
      vim.fn.mkdir(undo_dir, "p")
      vim.opt.undodir  = undo_dir
      vim.opt.undofile = true
    end
  end,
}
