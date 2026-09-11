vim.wo.foldmethod = 'expr'
-- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- vim.wo.foldtext = ''
vim.wo.signcolumn = 'yes'
-- source / run
vim.keymap.set('n', '<M-r>', [[:so %<CR>]], { buffer = true })
