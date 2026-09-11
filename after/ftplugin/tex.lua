-- Disable vimtex matchparen to deal with the slow problem
vim.wo.linebreak = true

local vks = vim.keymap.set
vks('v', '<Leader>b', [[<ESC>`>a}<ESC>`<i\textbf{<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>i', [[<ESC>`>a}<ESC>`<i\textit{<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>c', [[<ESC>`>a}<ESC>`<i\texttt{<ESC>`>ll]], { buffer = true })
