return  {
  "nvim-treesitter/nvim-treesitter", 
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      auto_install = true,
      ensure_installed = {"lua" ,"javascript", "c", "cpp","typescript", "tsx", "rust", "go", "python"}, 
      highlight = { enable = true },
      indent = { enable = true },
    })
  end
}
