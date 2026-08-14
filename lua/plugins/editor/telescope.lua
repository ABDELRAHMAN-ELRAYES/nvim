return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
  },
  config = function()
    -- Capture the launch directory ONCE before `lcd %:p:h` shifts cwd.
    -- This is the folder the user ran `nvim` from (i.e. the project root).
    local launch_dir = vim.fn.getcwd()
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

    -- Search from the directory nvim was launched from, not the current file's dir.
    vim.keymap.set("n", "<C-p>", function()
      builtin.find_files({ cwd = launch_dir })
    end, { desc = "Find files (launch dir)" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})

    require("telescope").load_extension("ui-select")
  end,
}





