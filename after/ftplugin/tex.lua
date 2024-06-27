-- local vol = vim.opt_local
-- vol.foldtext = 'v:lua.TexFoldText()'
-- _G.TexFoldText = function () return { { vim.fn['vimtex#fold#text'](), 'Title' } } end

-- use `{ { 'text1', 'highlight_group1' }, { 'text2', 'highlight_group2' }, }`, for example `{ { '+WE', 'WarningMsg' }, { foldtext:sub(4), 'ModeMsg' }, }`

-- Disable vimtex matchparen to deal with the slow problem
-- vim.keymap.set('n', 'j', 'gj')
-- vim.keymap.set('n', 'k', 'gk')
