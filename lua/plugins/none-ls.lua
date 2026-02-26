return {
  "nvimtools/none-ls.nvim",
  -- "nvim-telescope/telescope.nvim",
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

    add_if_executable("eslint_d", function() return null_ls.builtins.diagnostics.eslint_d end)
    add_if_executable("eslint_d", function() return null_ls.builtins.code_actions.eslint_d end)
    add_if_executable("eslint_d", function() return null_ls.builtins.formatting.eslint_d end)
    add_if_executable("erb_lint", function() return null_ls.builtins.diagnostics.erb_lint end)
    add_if_executable("rubocop", function() return null_ls.builtins.diagnostics.rubocop end)
    add_if_executable("rubocop", function() return null_ls.builtins.formatting.rubocop end)

    null_ls.setup({
      sources = sources,
    })

    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
  end,
}
