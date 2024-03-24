vim.opt_local.shiftwidth = 2
vim.opt_local.concealcursor = 'nc'
vim.opt_local.conceallevel = 2
vim.opt_local.breakindent = true
vim.opt_local.linebreak = true

vim.opt_local.foldmethod = 'expr'
vim.opt_local.formatoptions = 'mBlrocq'

local vks = vim.keymap.set
vks('v', '<Leader>b', [[<ESC>`>a**<ESC>`<i**<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>i', [[<ESC>`>a*<ESC>`<i*<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>t', [[<ESC>`>a}<ESC>`<i{=<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>c', [[<ESC>`>a`<ESC>`<i`<ESC>`>ll]], { buffer = true })
