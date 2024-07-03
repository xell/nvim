-- Some settings.
vim.wo.scrolloff = 0
vim.bo.buflisted = false

-- Add the cfilter plugin.
vim.cmd.packadd'cfilter'

vim.keymap.set('n', 'j', 'j', { buffer = true })
vim.keymap.set('n', 'k', 'k', { buffer = true })
