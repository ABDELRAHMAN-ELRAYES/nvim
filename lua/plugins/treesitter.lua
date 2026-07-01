return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    -- Neovim 0.12+: nvim-treesitter dropped the legacy "configs" module.
    -- Treesitter highlighting is now a built-in Neovim feature.
    -- nvim-treesitter is only needed for parser installation (:TSInstall/:TSUpdate).

    -- Ensure parsers are installed
    local ok, install = pcall(require, "nvim-treesitter.install")
    if ok then
      install.prefer_git = true
    end

    -- Enable treesitter highlighting for all buffers with a known parser
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        -- Skip special buffers (Telescope, neo-tree, quickfix, etc.)
        if vim.bo[buf].buftype ~= "" then
          return
        end
        local ft = vim.bo[buf].filetype
        if ft == "" then
          return
        end
        -- Map filetype to treesitter language name
        local lang = vim.treesitter.language.get_lang(ft) or ft
        -- Only start if a parser is available (pcall both calls)
        if pcall(vim.treesitter.language.add, lang) then
          pcall(vim.treesitter.start, buf, lang)
        end
      end,
    })

    -- Also enable treesitter-based indentation
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        local ft = vim.bo[buf].filetype
        local lang = vim.treesitter.language.get_lang(ft) or ft
        if pcall(vim.treesitter.language.add, lang) then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
