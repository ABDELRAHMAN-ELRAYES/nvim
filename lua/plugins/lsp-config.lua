return {
  {
  "williamboman/mason.nvim",
    opts = {
      ensure_installed={
        "clangd",
        "clang-format",
        "codelldb",
        "gopls",
        "goimports",
        "gofumpt",
        "golangci-lint",
        "delve",
        "typescript-language-server",
        "prettier",
        "eslint_d",
        "pyright",
        "ruff",
        "black",
        "isort",
        "dockerfile-language-server",
        "hadolint",
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
        ensure_installed = { "lua_ls", "ts_ls", "jdtls", "clangd", "gopls", "pyright", "dockerls" }
      })
    end
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    config = function()
      require("mason-nvim-dap").setup({
        ensure_installed = { "codelldb", "delve", "java-debug-adapter", "java-test" }
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
        vim.lsp.config('clangd', {
          capabilities = capabilities,
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--completion-style=detailed",
            "--header-insertion=iwyu",
          },
        })
        vim.lsp.config('gopls', {
          capabilities = capabilities,
          settings = {
            gopls = {
              gofumpt = true,
              staticcheck = true,
              analyses = {
                unusedparams = true,
                nilness = true,
                unusedwrite = true,
                useany = true,
              },
            },
          },
        })

        vim.lsp.config('pyright', {
          capabilities = capabilities,
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        })

        vim.lsp.config('dockerls', { capabilities = capabilities })

        vim.lsp.enable({ 'lua_ls', 'html', 'ts_ls', 'clangd', 'gopls', 'pyright', 'dockerls' })
      else
        local lspconfig = require("lspconfig")
        lspconfig.lua_ls.setup({ capabilities = capabilities })
        lspconfig.html.setup({ capabilities = capabilities })
        lspconfig.tsserver.setup({ capabilities = capabilities })
        lspconfig.clangd.setup({
          capabilities = capabilities,
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--completion-style=detailed",
            "--header-insertion=iwyu",
          },
        })
        lspconfig.gopls.setup({
          capabilities = capabilities,
          settings = {
            gopls = {
              gofumpt = true,
              staticcheck = true,
              analyses = {
                unusedparams = true,
                nilness = true,
                unusedwrite = true,
                useany = true,
              },
            },
          },
        })
        lspconfig.pyright.setup({
          capabilities = capabilities,
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        })
        lspconfig.dockerls.setup({ capabilities = capabilities })
      end

      vim.keymap.set('n','k',vim.lsp.buf.hover,{})
      vim.keymap.set('n','gd',vim.lsp.buf.definition,{})
      vim.keymap.set({'n','v'},'<leader>ca',vim.lsp.buf.code_action,{})

      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
          local params = vim.lsp.util.make_range_params()
          params.context = { only = { "source.organizeImports" } }
          local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1500)
          for _, res in pairs(result or {}) do
            for _, action in pairs(res.result or {}) do
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
              elseif action.command then
                vim.lsp.buf.execute_command(action.command)
              end
            end
          end
          vim.lsp.buf.format({ async = false })
        end,
      })
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
