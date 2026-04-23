return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && npm install",
  ft = { "markdown" },

  keys = {
    {
      "<leader>mp",
      "<cmd>MarkdownPreviewToggle<CR>",
      desc = "Markdown Preview Toggle",
    },
    {
      "<leader>ms",
      "<cmd>MarkdownPreviewStop<CR>",
      desc = "Stop Markdown Preview",
    },
  },
}
