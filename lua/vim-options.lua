vim.api.nvim_set_option('expandtab', true)
vim.api.nvim_set_option('tabstop', 2)
vim.api.nvim_set_option('softtabstop', 2)
vim.api.nvim_set_option('shiftwidth', 2)
vim.g.mapleader = " "

local function set_transparent_background()
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_transparent_background,
})

set_transparent_background()
