return {
  "luckasRanarison/tailwind-tools.nvim",
  name = "tailwind-tools",
  ft = {
    "html",
    "css",
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "svelte",
    "vue",
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "neovim/nvim-lspconfig",
  },
  opts = {
    document_color = {
      enabled = true,
      kind = "inline", -- Inline color circles/squares next to tailwind classes
    },
    conceal = {
      enabled = false, -- Can be toggled on demand with :TailwindConcealToggle
    },
  },
}
