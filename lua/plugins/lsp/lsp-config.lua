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
        snyk_ls              = { enabled = false },
        tsgo                 = { enabled = false }, -- dev-preview only, use ts_ls instead
        cmake_language_server = { enabled = false }, -- requires Python <3.14, incompatible with 3.14.x
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

        -- Node/TS/React/HTML
        "html-lsp",
        "vtsls",
        "prettier",
        "eslint_d",
        "json-lsp",
        "css-lsp",
        "tailwindcss-language-server",
        "emmet-language-server",

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
      automatic_enable = false,
      ensure_installed = { "lua_ls", "html", "vtsls", "jdtls", "clangd", "gopls", "pyright", "dockerls", "jsonls", "cssls", "tailwindcss", "emmet_ls" },
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

      -- Setup servers using Neovim 0.11+ native LSP configuration API
        vim.lsp.config('lua_ls', { capabilities = capabilities })
        vim.lsp.config('html', { capabilities = capabilities })
        -- vtsls: modern TS/JS server that also handles embedded <script> in HTML
        vim.lsp.config('vtsls', {
          capabilities = capabilities,
          filetypes = {
            "javascript", "javascriptreact",
            "typescript", "typescriptreact",
            "html",   -- enables JS completions inside <script> tags
          },
          -- Use on_dir callback style required by Neovim 0.11+ vim.lsp.config API
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(bufnr, {
              "tsconfig.json", "tsconfig.base.json",
              "jsconfig.json", "package.json",
              "package-lock.json", "yarn.lock", "pnpm-lock.yaml",
              ".git",
            }) or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
            on_dir(root)
          end,
          settings = {
            typescript = {
              inlayHints = {
                parameterNames = { enabled = "all" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
              },
              preferences = {
                importModuleSpecifier = "relative",
                includeCompletionsForModuleExports = true,
                includeCompletionsWithSnippetText = true,
              },
            },
            javascript = {
              inlayHints = {
                parameterNames = { enabled = "all" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
              },
              preferences = {
                importModuleSpecifier = "relative",
                includeCompletionsForModuleExports = true,
                includeCompletionsWithSnippetText = true,
              },
            },
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
            },
          },
          -- Disable built-in formatter; use prettier (none-ls) instead
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
            "--fallback-style=google",
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

        -- Emmet LSP for fast HTML/JSX expansions
        vim.lsp.config('emmet_ls', { capabilities = capabilities })

        -- CMake for C++ build files
        vim.lsp.config('cmake', { capabilities = capabilities })

        vim.lsp.enable({ 'lua_ls', 'html', 'vtsls', 'clangd', 'gopls', 'pyright', 'dockerls', 'jsonls', 'cssls', 'tailwindcss', 'emmet_ls' })

      vim.keymap.set('n','k',vim.lsp.buf.hover,{})
      vim.keymap.set('n','gd',vim.lsp.buf.definition,{})
      vim.keymap.set({'n','v'},'<leader>ca',vim.lsp.buf.code_action,{})

      -- Ctrl + Click to go to definition (VSCode style)
      vim.keymap.set("n", "<C-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition (Ctrl+Click)" })
      vim.keymap.set("i", "<C-LeftMouse>", "<Esc><LeftMouse><cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition (Ctrl+Click)" })

      -- Highlight & underline symbol and all its references on hover
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            local group = vim.api.nvim_create_augroup("lsp_document_highlight_" .. args.buf, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = args.buf,
              group = group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = args.buf,
              group = group,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      local function set_lsp_highlights()
        vim.api.nvim_set_hl(0, "LspReferenceText", { underline = true, bold = true, bg = "#313244", sp = "#89b4fa" })
        vim.api.nvim_set_hl(0, "LspReferenceRead", { underline = true, bold = true, bg = "#313244", sp = "#a6e3a1" })
        vim.api.nvim_set_hl(0, "LspReferenceWrite", { underline = true, bold = true, bg = "#313244", sp = "#f38ba8" })
      end

      set_lsp_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_lsp_highlights })

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
