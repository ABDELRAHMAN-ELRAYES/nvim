return {
  {
  "williamboman/mason.nvim",
  config = function(_, opts)
    require("mason").setup(opts)
  end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      servers = {
        snyk_ls = { enabled = false },
      },
      ensure_installed = {
        -- C/C++
        "clangd",
        "clang-format",
        "codelldb",

        -- Go
        "gopls",
        "goimports",
        "gofumpt",
        "golangci-lint",
        "delve",

        -- Node/TS/React
        "typescript-language-server",
        "prettier",
        "eslint_d",
        "json-lsp",
        "css-lsp",
        "tailwindcss-language-server",

        -- Python
        "pyright",
        "ruff",
        "black",
        "isort",

        -- Docker
        "dockerfile-language-server",
        "hadolint",

        -- C++ build system
        "cmake-language-server",
      },
      auto_update = false,
      run_on_start = true,
    },
    config = function(_, opts)
      require("mason-tool-installer").setup(opts)
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function(_, opts)
      require("mason-lspconfig").setup(opts)
    end,
    opts = {
      ensure_installed = { "lua_ls", "ts_ls", "jdtls", "clangd", "gopls", "pyright", "dockerls", "jsonls", "cssls", "tailwindcss", "cmake" },
    },
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    config = function(_, opts)
      require("mason-nvim-dap").setup(opts)
    end,
    opts = {
      ensure_installed = { "codelldb", "delve", "java-debug-adapter", "java-test" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local function exepath_or(name)
        local p = vim.fn.exepath(name)
        if p == nil or p == "" then
          return name
        end
        return p
      end

      -- Neovim 0.11+ uses the built-in vim.lsp.config/vim.lsp.enable API.
      -- Keep a fallback for older Neovim without triggering deprecation warnings.
      if vim.lsp.config and vim.lsp.enable then
        vim.lsp.config('lua_ls', { capabilities = capabilities })
        vim.lsp.config('html', { capabilities = capabilities })
        vim.lsp.config('ts_ls', {
          capabilities = capabilities,
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
              },
              preferences = {
                importModuleSpecifier = "relative",   -- prefer relative imports
                includeCompletionsForModuleExports = true,
                includeCompletionsWithSnippetText = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
              },
              preferences = {
                importModuleSpecifier = "relative",
                includeCompletionsForModuleExports = true,
              },
            },
          },
          -- Disable tsserver's built-in formatter; use prettier (none-ls) instead
          on_attach = function(client)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end,
        })
        vim.lsp.config('clangd', {
          capabilities = capabilities,
          cmd = {
            exepath_or("clangd"),
            "--background-index",
            "--clang-tidy",
            "--completion-style=detailed",
            "--header-insertion=iwyu",
          },
        })
        vim.lsp.config('gopls', {
          capabilities = capabilities,
          cmd = { exepath_or("gopls") },
          root_dir = function(bufnr, _)
            return vim.fs.root(bufnr, { "go.work", "go.mod", ".git" })
          end,
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

        -- JSON with schema validation
        vim.lsp.config('jsonls', {
          capabilities = capabilities,
          settings = {
            json = {
              schemas = {},         -- populated by on_new_config once schemastore loads
              validate = { enable = true },
            },
          },
          on_new_config = function(config)
            local ok, ss = pcall(require, 'schemastore')
            if ok then
              config.settings.json.schemas = ss.json.schemas()
            end
          end,
        })

        -- CSS / SCSS / Less
        vim.lsp.config('cssls', { capabilities = capabilities })

        -- Tailwind CSS (activates only in projects that use it)
        vim.lsp.config('tailwindcss', { capabilities = capabilities })

        -- CMake for C++ build files
        vim.lsp.config('cmake', { capabilities = capabilities })

        vim.lsp.enable({ 'lua_ls', 'html', 'ts_ls', 'clangd', 'gopls', 'pyright', 'dockerls', 'jsonls', 'cssls', 'tailwindcss', 'cmake' })
      else
        local lspconfig = require("lspconfig")
        lspconfig.lua_ls.setup({ capabilities = capabilities })
        lspconfig.html.setup({ capabilities = capabilities })
        lspconfig.ts_ls.setup({
          capabilities = capabilities,
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
              },
              preferences = {
                importModuleSpecifier = "relative",
                includeCompletionsForModuleExports = true,
                includeCompletionsWithSnippetText = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
              },
              preferences = {
                importModuleSpecifier = "relative",
                includeCompletionsForModuleExports = true,
              },
            },
          },
          on_attach = function(client)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end,
        })
        lspconfig.clangd.setup({
          capabilities = capabilities,
          cmd = {
            exepath_or("clangd"),
            "--background-index",
            "--clang-tidy",
            "--completion-style=detailed",
            "--header-insertion=iwyu",
          },
        })
        lspconfig.gopls.setup({
          capabilities = capabilities,
          cmd = { exepath_or("gopls") },
          root_dir = function(bufnr, _)
            return vim.fs.root(bufnr, { "go.work", "go.mod", ".git" })
          end,
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

        -- JSON with schema validation
        lspconfig.jsonls.setup({
          capabilities = capabilities,
          on_new_config = function(config)
            local ok, ss = pcall(require, 'schemastore')
            if ok then
              config.settings.json.schemas = ss.json.schemas()
            end
          end,
          settings = { json = { validate = { enable = true } } },
        })

        -- CSS / SCSS / Less
        lspconfig.cssls.setup({ capabilities = capabilities })

        -- Tailwind CSS
        lspconfig.tailwindcss.setup({ capabilities = capabilities })

        -- CMake
        lspconfig.cmake.setup({ capabilities = capabilities })
      end

      vim.keymap.set('n','k',vim.lsp.buf.hover,{})
      vim.keymap.set('n','gd',vim.lsp.buf.definition,{})
      vim.keymap.set({'n','v'},'<leader>ca',vim.lsp.buf.code_action,{})

      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
          local has_gopls = false
          for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
            if c.name == "gopls" then
              has_gopls = true
              break
            end
          end
          if not has_gopls then
            return
          end

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
