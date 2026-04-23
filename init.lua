-- require("config.lazy")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
vim.cmd([[autocmd BufEnter * silent! lcd %:p:h]])
-- local opts = {}
-- require("vim-options")
vim.opt.clipboard = "unnamedplus"

vim.api.nvim_create_autocmd({"InsertLeave", "TextChanged"}, {
  pattern = "*",
  command = "silent! write",
})

local lang__mappings = require("lang_shortcuts.mappings")
lang__mappings.cpp_mappings()

-- hover popup to view the error details
vim.o.updatetime = 250

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false })
  end
})

require("vim-options")
require("lazy").setup("plugins")

