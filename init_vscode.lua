-- vim:fdm=marker
-- init_vscode.lua

vim.g.xell_vsc = 3
local tools = require 'tools'
local vscode = require('vscode')
local c = vscode.call

-- ---

-- General settings {{{
vim.g.mapleader = ','
vim.g.maplocalleader = [[\]]

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true
vim.o.inccommand = 'split'
vim.o.wrapscan = false

vim.o.updatetime = 500
vim.o.modelineexpr = true

-- no support yet
-- https://github.com/microsoft/vscode/issues/164267
-- https://github.com/microsoft/vscode/issues/167314
vim.o.breakindent = true
vim.o.breakindentopt = 'list:-2'

-- }}}

-- Special settings {{{

vim.g.seditor_table = {}

-- xell Notes -- {{{
vim.g.xell_notes_root = vim.fn.fnameescape(vim.fn.glob('~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes'))
local xell_main_note = string.gsub(vim.g.xell_notes_root .. '/Notes/notes.md', '\\', '')
vim.keymap.set('n', '<Leader>ne', ':e ' .. xell_main_note .. '<CR>', { desc = 'Note in current tab' })
-- }}}

-- https://github.com/vscode-neovim/vscode-neovim/issues/169
vim.keymap.set('n', [[<leader>\]], function()
    local msg = 'Get digraph of: '
    print(msg)
    local a = vim.fn.getcharstr()
    print(msg .. a)
    local b = vim.fn.getcharstr()
    print(' ')
    local digraph = vim.fn.digraph_get(a .. b)
    vim.api.nvim_put({ digraph }, '', false, true)
end)
-- }}}

-- Windows Tabs aka Editor Groups {{{
vim.keymap.set('n', '<Leader>v', function () c('workbench.action.splitEditor') end)
vim.keymap.set('n', '<Leader>s', function () c('workbench.action.splitEditorDown') end)
vim.keymap.set('n', '<Leader>c', function () c('workbench.action.closeActiveEditor') end)

vim.cmd[[
let s:switch_recently_used_editor = 1
function SwitchRecentlyUsedEditor() abort
    if (s:switch_recently_used_editor)
        call VSCodeNotify('workbench.action.openPreviousRecentlyUsedEditor')
        let s:switch_recently_used_editor = !s:switch_recently_used_editor
    else
        call VSCodeNotify('workbench.action.openNextRecentlyUsedEditor')
        let s:switch_recently_used_editor = !s:switch_recently_used_editor
    endif
endfunction
nnoremap <Tab> <Cmd>call SwitchRecentlyUsedEditor()<CR>
]]

vim.keymap.set('n', '<Backspace>', function () c('workbench.action.focusNextGroup') end)

-- <M-Tab> workbench.action.navigateEditorGroups
-- <D-k> s toggle size
-- <D-k> m toggle maximize

-- [Allow to open two distinct editors side by side in one group · Issue #36700 · microsoft/vscode](https://github.com/microsoft/vscode/issues/36700)
-- [Tabs that group editor grid layouts (Vim-style tabs) · Issue #143024 · microsoft/vscode](https://github.com/microsoft/vscode/issues/143024)
-- [Workviews - Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=agquick.workviews)
-- <D-k> <D-S-\>
-- <D-k> <Tab> workbench.action.focusOtherSideEditor
-- }}}

-- Fold {{{
-- " https://github.com/vscode-neovim/vscode-neovim/issues/58
vim.keymap.set('n', 'zM', function () c('editor.foldAll') end)
vim.keymap.set('n', 'zR', function () c('editor.unfoldAll') end)
vim.keymap.set('n', 'zc', function () c('editor.fold') end)
vim.keymap.set('n', 'zC', function () c('editor.foldRecursively') end)
vim.keymap.set('n', 'zo', function () c('editor.unfold') end)
vim.keymap.set('n', 'zO', function () c('editor.unfoldRecursively') end)
vim.keymap.set('n', 'za', function () c('editor.toggleFold') end)
vim.keymap.set('n', '<Space>', function () c('editor.toggleFold') end)
vim.keymap.set('n', 'zA', function () c('editor.toggleFoldRecursively') end)
vim.keymap.set('n', 'zj', function () c('editor.gotoNextFold') end)
vim.keymap.set('n', 'zk', function () c('editor.gotoPreviousFold') end)
vim.keymap.set('n', 'zK', function () c('editor.gotoParentFold') end)
vim.keymap.set('n', 'zv', function () c('editor.foldAllExcept') end)
vim.keymap.set('n', 'z1', function () c('editor.foldLevel1') end)
vim.keymap.set('n', 'z2', function () c('editor.foldLevel2') end)
vim.keymap.set('n', 'z3', function () c('editor.foldLevel3') end)
vim.keymap.set('n', 'z4', function () c('editor.foldLevel4') end)
vim.keymap.set('n', 'z5', function () c('editor.foldLevel5') end)
vim.keymap.set('n', 'z6', function () c('editor.foldLevel6') end)
vim.keymap.set('n', 'z7', function () c('editor.foldLevel7') end)

require('hackKeymap')

-- }}}

-- Editing {{{
vim.o.clipboard = 'unnamedplus'

-- spell
vim.keymap.set('n', '[s', function () c('cSpell.goToPreviousSpellingIssueAndSuggest') end)
vim.keymap.set('n', ']s', function () c('cSpell.goToNextSpellingIssueAndSuggest') end)

-- Make U opposite to u.
vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })

-- leave cursor in the end of visual block
vim.keymap.set('v', 'y', 'ygv<Esc>')
vim.keymap.set('n', 'P', 'gP')

-- select pasted content
vim.cmd[[nnoremap <expr> g<C-v> '`[' . getregtype()[0] . '`]']]

-- indent the just pasted content
vim.keymap.set('n', '<Leader>=', '`[V`]==', { desc = 'Indent just pasted' })
vim.keymap.set('n', '<Leader>P', 'p`[V`]==', { desc = 'Paste and indent' })

-- - to g_ last non-blank char
vim.keymap.set('', '-', 'g_')
-- swap ^ and 0 for convenience
vim.keymap.set('', '0', '^')
vim.keymap.set('', '^', '0')

-- page up / down
vim.keymap.set('', '<C-k>', '<C-b>')
vim.keymap.set('', '<C-j>', '<C-f>')

-- search
vim.keymap.set('n', '*', '*``') -- or :keepjumps
vim.keymap.set('n', '#', '#``')
vim.keymap.set('n', '<Leader>ns', function() vim.fn.setreg('/', '') end, { desc = 'Clear search' })
vim.keymap.set('n', '<Leader>nh', function() vim.o.hlsearch = false end, { desc = 'Hide search' })
vim.keymap.set('n', '<Leader>h', function() vim.o.hlsearch = not vim.o.hlsearch end, { desc = 'Hide/show search' })
vim.keymap.set('v', '<Leader>/', 'y/<C-r>=@"<CR><CR>', { desc = 'Search selected' })
vim.api.nvim_create_user_command('Search2LocList', function ()
    vim.cmd('lvimgrep "' .. vim.fn.getreg('/') .. '" %')
    vim.cmd.lwindow()
end, {})
-- Keeping the cursor centered.
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll downwards' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll upwards' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next result' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous result' })

-- Indent while remaining in visual mode.
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- highlight/blink yank area
vim.api.nvim_create_autocmd(
    { 'TextYankPost' },
    {
        pattern = { '*' },
        callback = function()
            vim.highlight.on_yank({ timeout = 1000 })
        end,
    })

-- yank
vim.keymap.set('n', 'Y', '^yg_')

-- Capitalization of the current line
-- Capitalize all words in titles of publications and documents, except a, an, the, at, by, for, in, of, on, to, up, and, as, but, or, and nor.
-- https://taptoe.wordpress.com/2013/02/06/vim-capitalize-every-first-character-of-every-word-in-a-sentence/
vim.api.nvim_create_user_command('Capitalize', function()
    vim.cmd[[s/\v^\a|\:\s\a|<%(a>|an>|and>|as>|at>|but>|by>|for>|in>|nor>|of>|on>|or>|the>|to>|up>)@!\a/\U&/g]]
end, {})

-- poorman's surrounding
-- http://www.teifel.net/projects/vim/mappings.html
vim.keymap.set('v', '<Leader>(', [[<ESC>`>a)<ESC>`<i(<ESC>`>ll]])
vim.keymap.set('v', '<Leader><', [[<ESC>`>a><ESC>`<i<<ESC>`>ll]])
vim.keymap.set('v', '<Leader>[', [[<ESC>`>a]<ESC>`<i[<ESC>`>ll]])
vim.keymap.set('v', '<Leader>{', [[<ESC>`>a}<ESC>`<i{<ESC>`>ll]])
vim.keymap.set('v', '<Leader>$', [[<ESC>`>a$<ESC>`<i$<ESC>`>ll]])
vim.keymap.set('v', '<Leader>"', [[<ESC>`>a"<ESC>`<i"<ESC>`>ll]])
vim.keymap.set('v', "<Leader>'", [[<ESC>`>a'<ESC>`<i'<ESC>`>ll]])

-- indent
vim.keymap.set('n', '==', function () c('editor.action.reindentlines') end)

-- }}}

-- Commands {{{

-- google search selection
-- TODO or better https://github.com/lalitmee/browse.nvim
vim.keymap.set('v', '<M-g>', function()
    vim.cmd.normal[["zy]]
    vim.ui.open('https://www.google.com/search?q=' .. tools.uri_encode(vim.fn.eval('@z')))
end)

-- look up word in dictionary
vim.keymap.set('n', '<M-d>', function()
    vim.ui.open('dict://' .. vim.fn.expand('<cword>'))
end)

-- goto for next or previous link
vim.g.url_pattern = [[[[:alpha:]-]\+:\/\/[^ "'>\])]\+]]
vim.g.markdown_link_pattern = [[\(\[[^\^]\{-}\]\([:\[]\)\@!\(([^ ]\{-}\%(\s"[^"]\{-}"\)\?)\)\?\)]]
vim.g.link_pattern = vim.g.url_pattern .. [[\|]] .. vim.g.markdown_link_pattern
local function move_cursor_to_link(backward)
    local link_pattern = vim.b.link_pattern or vim.g.link_pattern
    vim.fn.search(link_pattern, 's' .. backward)
end
vim.keymap.set('n', ']n', function() move_cursor_to_link('') end, { desc = 'Goto next link' })
vim.keymap.set('n', '[n', function() move_cursor_to_link('b') end, { desc = 'Goto previous link' })

-- }}}

-- workbench.action.openRecent
vim.keymap.set('n', '<Leader>ff', function () c('workbench.action.openRecent') end)
-- workbench.action.showAllEditors
vim.keymap.set('n', '<Leader>fb', function () c('workbench.action.showAllEditors') end)
-- <D-S-f> workbench.action.findInFiles
-- File: Open File <D-o> - workbench.action.files.openFile
-- File: Open Folder - workbench.action.files.openFolderViaWorkspace
-- File: Open - workbench.action.files.openFileFolder
-- File: Open Recent <D-M-o> - workbench.action.openRecent
-- Go: Go to File <D-p> - workbench.action.quickOpen
-- workbench.action.files.openLocalFileFolder

vim.keymap.set('n', 'gX', function () c('editor.action.openLink') end)

require 'config.lazy'
