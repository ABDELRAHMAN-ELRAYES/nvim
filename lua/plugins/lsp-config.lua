return {
  {
  "williamboman/mason.nvim",
    opts = {
      ensure_installed={
        "clangd",
        "clang-format",
        "codelldb",
      }
    },
  config = function()
    require("mason").setup()
  end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "jdtls" }
      })
    end
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    config = function()
      require("mason-nvim-dap").setup({
        ensure_installed = {"codelldb","java-debug-adapter","java-test"}
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Neovim 0.11+ uses the built-in vim.lsp.config/vim.lsp.enable API.
      -- Keep a fallback for older Neovim without triggering deprecation warnings.
      if vim.lsp.config and vim.lsp.enable then
        vim.lsp.config('lua_ls', { capabilities = capabilities })
        vim.lsp.config('html', { capabilities = capabilities })
        vim.lsp.config('ts_ls', { capabilities = capabilities })
        vim.lsp.config('clangd', { capabilities = capabilities })
        vim.lsp.enable({ 'lua_ls', 'html', 'ts_ls', 'clangd' })
      else
        local lspconfig = require("lspconfig")
        lspconfig.lua_ls.setup({ capabilities = capabilities })
        lspconfig.html.setup({ capabilities = capabilities })
        lspconfig.tsserver.setup({ capabilities = capabilities })
        lspconfig.clangd.setup({ capabilities = capabilities })
      end

      vim.keymap.set('n','k',vim.lsp.buf.hover,{})
      vim.keymap.set('n','gd',vim.lsp.buf.definition,{})
      vim.keymap.set({'n','v'},'<leader>ca',vim.lsp.buf.code_action,{})
    end
  },
  -- configure the java server
  {
    "mfussenegger/nvim-jdtls",
    dependencies = {
      "mfussenegger/nvim-dap",
    }
  }
}
