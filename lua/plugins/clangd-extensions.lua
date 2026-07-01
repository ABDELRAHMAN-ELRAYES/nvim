return {
  "p00f/clangd_extensions.nvim",
  ft = { "c", "cpp", "objc", "objcpp", "cuda" },
  dependencies = { "neovim/nvim-lspconfig" },
  opts = {
    inlay_hints = {
      inline = true,            -- show hints inline (Neovim 0.10+)
      only_current_line = false,
      show_parameter_hints = true,
      parameter_hints_prefix = "← ",
      other_hints_prefix = "» ",
      max_len_align = false,
      right_align = false,
    },
    ast = {
      -- Icons for the AST viewer (:ClangdAST)
      role_icons = {
        type        = "",
        declaration = "󰙠",
        expression  = "󰉺",
        specifier   = "󰦨",
        statement   = "󰜴",
        ["template argument"] = "󰛡",
      },
      kind_icons = {
        Compound   = "󰗲",
        Recovery   = "󱈸",
        TranslationUnit = "󰏢",
        PackExpansion   = "󰆦",
        TemplateTypeParm  = "󰆩",
        TemplateTemplateParm = "󱤬",
        TemplateParamObject  = "󰆩",
      },
    },
    memory_usage = { border = "rounded" },
    symbol_info  = { border = "rounded" },
  },
}
