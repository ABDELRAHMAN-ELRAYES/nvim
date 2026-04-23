return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
  },
  config = function()
    require("telescope").setup({
      defaults = {
        preview = {
          treesitter = false, -- prevents ft_to_lang crash
        },
      },
      extensions = {
        ["ui-select"] = require("telescope.themes").get_dropdown(),
      },
    })

    local builtin = require("telescope.builtin")

    vim.keymap.set("n", "<C-p>", builtin.find_files, {})
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})

    require("telescope").load_extension("ui-select")
  end,
}





