return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  -- nvim-treesitter stores queries under runtime/queries/ not the plugin root.
  -- We must add that runtime/ subdirectory to rtp before any buffer loads
  -- so vim.treesitter.query.get('tsx', ...) can find the .scm files.
  init = function(plugin)
    vim.opt.rtp:prepend(plugin.dir .. "/runtime")
  end,
  config = function()
    -- Ensure parsers are installed for all languages in the stack
    local ok, install = pcall(require, "nvim-treesitter.install")
    if ok then
      install.prefer_git = true
    end

    -- Enable treesitter highlighting for all file buffers
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
        -- Only start if a parser + query are available
        if pcall(vim.treesitter.language.add, lang) then
          pcall(vim.treesitter.start, buf, lang)
        end
      end,
    })

    -- Treesitter-based indentation
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].buftype ~= "" then return end
        local ft = vim.bo[buf].filetype
        if ft == "" then return end
        local lang = vim.treesitter.language.get_lang(ft) or ft
        if pcall(vim.treesitter.language.add, lang) then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
