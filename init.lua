-- Silence deprecation warnings globally for Neovim 0.11+ compatibility
vim.deprecate = function() end

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

require("vim-options")  -- load options before plugins

vim.api.nvim_create_user_command("Manual", function(opts)
  require("manual").open(opts.args)
end, {
  nargs = "?",
  complete = function()
    local ids = {}
    for _, p in ipairs(require("manual").pages) do
      table.insert(ids, p.id)
    end
    return ids
  end,
  desc = "Open Neovim Keybinds & Motions Manual",
})
vim.keymap.set("n", "<leader>m", function()
  require("manual").open()
end, { desc = "Open Keybinds & Motions Manual" })

require("lazy").setup({
  spec = {
    { import = "plugins.lsp" },
    { import = "plugins.git" },
    { import = "plugins.ui" },
    { import = "plugins.editor" },
  }
})

