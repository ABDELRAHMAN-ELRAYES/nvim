return  {
  "nvim-treesitter/nvim-treesitter", 
  build = ":TSUpdate",
  config = function()
    local ok, configs = pcall(require, "nvim-treesitter.configs")
    if not ok then
      return
    end

    configs.setup({
      auto_install = true,
      ensure_installed = {"lua" ,"javascript", "c", "cpp","typescript", "tsx", "rust", "go", "python"}, 
      highlight = { enable = true },
      indent = { enable = true },
    })
  end
}
