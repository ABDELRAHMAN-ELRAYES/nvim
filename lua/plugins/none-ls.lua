return {
  "nvimtools/none-ls.nvim",
  dependencies = { "nvimtools/none-ls-extras.nvim" },
  config = function()
    local null_ls = require("null-ls")
    local sources = {
      null_ls.builtins.formatting.clang_format,
      null_ls.builtins.formatting.stylua,
      null_ls.builtins.formatting.prettier,
      null_ls.builtins.formatting.black,
      null_ls.builtins.formatting.isort,
    }

    local function add_if_executable(cmd, get_builtin)
      if vim.fn.executable(cmd) == 1 then
        table.insert(sources, get_builtin())
      end
    end

    -- eslint_d and ruff were moved to none-ls-extras.nvim
    add_if_executable("eslint_d", function() return require("none-ls.diagnostics.eslint_d") end)
    add_if_executable("eslint_d", function() return require("none-ls.code_actions.eslint_d") end)
    add_if_executable("eslint_d", function() return require("none-ls.formatting.eslint_d") end)
    add_if_executable("erb_lint", function() return null_ls.builtins.diagnostics.erb_lint end)
    add_if_executable("rubocop", function() return null_ls.builtins.diagnostics.rubocop end)
    add_if_executable("rubocop", function() return null_ls.builtins.formatting.rubocop end)
    add_if_executable("golangci-lint", function() return null_ls.builtins.diagnostics.golangci_lint end)
    add_if_executable("ruff", function() return require("none-ls.diagnostics.ruff") end)
    add_if_executable("ruff", function() return require("none-ls.formatting.ruff") end)
    add_if_executable("mypy", function() return null_ls.builtins.diagnostics.mypy end)
    add_if_executable("hadolint", function() return null_ls.builtins.diagnostics.hadolint end)

    null_ls.setup({
      sources = sources,
    })

    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
  end,
}
