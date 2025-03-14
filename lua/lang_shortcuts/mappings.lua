local mappings = {}

mappings.cpp_mappings = function ()
  
   vim.api.nvim_set_keymap("n", "<F5>", ":w<CR>:!g++ % -o %< && ./%<<CR>", { noremap = true, silent = true })
   vim.api.nvim_set_keymap("n", "<F6>", ":w<CR>:split | terminal g++ % -o %< && ./%<<CR>", { noremap = true, silent = true })

end



return mappings
