return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  -- nvim-treesitter stores queries under runtime/queries/ not the plugin root.
  -- Prepend runtime/ so vim.treesitter.query.get('tsx', ...) finds the .scm files.
  init = function(plugin)
    vim.opt.rtp:prepend(plugin.dir .. "/runtime")
  end,
  config = function()
    -- Modern nvim-treesitter (v0.9+): use require("nvim-treesitter").setup()
    -- NOT require("nvim-treesitter.configs") which no longer exists.
    local ok, ts = pcall(require, "nvim-treesitter")
    if ok and ts.setup then
      ts.setup({
        ensure_installed = {
          -- Web (required for nvim-ts-autotag, tailwind-tools, etc.)
          "html", "css", "javascript", "typescript", "tsx", "json", "jsonc",
          -- Config / tooling
          "yaml", "toml", "graphql",
          -- Other languages in your stack
          "lua", "c", "cpp", "go", "python", "dockerfile", "bash",
        },
        auto_install = true, -- install missing parsers on first open
      })
    end

    local install_ok, install = pcall(require, "nvim-treesitter.install")
    if install_ok then
      install.prefer_git = true
    end

    -- Activate treesitter highlighting + indentation for every file buffer.
    -- This is what nvim-ts-autotag needs: an active parser in the buffer.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        -- Skip special buffers (Telescope, neo-tree, quickfix, etc.)
        if vim.bo[buf].buftype ~= "" then return end
        local ft = vim.bo[buf].filetype
        if ft == "" then return end
        local lang = vim.treesitter.language.get_lang(ft) or ft
        if pcall(vim.treesitter.language.add, lang) then
          pcall(vim.treesitter.start, buf, lang)
          -- Treesitter-based indentation
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
