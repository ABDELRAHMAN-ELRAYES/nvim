return {
  "jmbuhr/otter.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {},
  config = function(_, opts)
    local otter = require("otter")
    otter.setup(opts)

    -- Automatically activate otter on HTML files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "html",
      callback = function()
        -- Activate for javascript and css inside HTML
        otter.activate({ "javascript", "css" })
      end,
    })
  end,
}
