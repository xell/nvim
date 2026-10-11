-- vim:fdm=marker
-- init_vscode.lua

vim.g.xell_vsc = 3
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


-- turn off output message
-- https://stackoverflow.com/questions/78611905/turn-off-neovim-messages-in-vscode
vim.o.cmdheight = 4

-- }}}

-- Special settings {{{

-- I don't use yode in vscode
-- vim.g.seditor_table = {}

vim.g.fast_cursor_move_acceleration = false
vim.g.EasyMotion_verbose = 0

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


-- }}}

-- Editing {{{
vim.o.clipboard = 'unnamedplus'
vim.g.clipboard = vim.g.vscode_clipboard

-- spell
-- vim.keymap.set('n', '[s', function () c('cSpell.goToPreviousSpellingIssueAndSuggest') end)
-- vim.keymap.set('n', ']s', function () c('cSpell.goToNextSpellingIssueAndSuggest') end)
vim.keymap.set('n', '[s', function () c('editor.action.marker.prev') end)
vim.keymap.set('n', ']s', function () c('editor.action.marker.next') end)

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
vim.keymap.set('v', "<Leader>`", [[<ESC>`>a`<ESC>`<i`<ESC>`>ll]])
vim.keymap.set('v', "<Leader>i", [[<ESC>`>a*<ESC>`<i*<ESC>`>ll]])
vim.keymap.set('v', "<Leader>b", [[<ESC>`>a**<ESC>`<i**<ESC>`>ll]])

-- indent reindent
-- ori editor.action.formatSelection
-- https://github.com/vscode-neovim/vscode-neovim/discussions/2289
vim.keymap.set('n', '==', function () c('editor.action.reindentlines') end)
vim.keymap.set('v', '=', function () c('editor.action.reindentlines') end)

-- problem
-- M-n https://github.com/microsoft/vscode/issues/41024
vim.keymap.set('n', '<M-m>', function () c('editor.action.marker.nextInFiles') end)
vim.keymap.set('n', '<M-p>', function () c('editor.action.marker.prevInFiles') end)
vim.keymap.set('n', '<C-M-n>', function () c('editor.action.marker.next') end)
vim.keymap.set('n', '<C-M-p>', function () c('editor.action.marker.prev') end)

-- }}}

-- Commands {{{

-- google search selection
-- TODO or better https://github.com/lalitmee/browse.nvim
local function uri_encode(string)
    local vf = vim.fn
    return vf.substitute(vf.iconv(string, 'latin1', 'utf-8'),'[^A-Za-z0-9_.~-]','\\="%".printf("%02X",char2nr(submatch(0)))','g')
end
vim.keymap.set('v', '<M-g>', function()
    vim.cmd.normal [["zy]]
    vim.ui.open('https://www.google.com/search?q=' .. uri_encode(vim.fn.eval('@z')))
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

-- vim.keymap.set({'n','v'}, '<C-v>', '<C-v>')

-- vim.opt.selectmode = {}
-- vim.opt.keymodel = {}
-- vim.opt.mousemodel = "extend"
-- vim.cmd('behave xterm')

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
    spec = {
        -- import your plugins
        { import = "plugins" },
    },
    -- Configure any other settings here. See the documentation for more details.
    -- colorscheme that will be used when installing plugins.
    install = { colorscheme = { "habamax" } },
    -- automatically check for plugin updates
    checker = { enabled = false },
    dev = {
        path = "~/Developer/vim/scripts",
        fallback = true,
    },
    change_detection = {
        -- automatically check for config file changes and reload the ui
        enabled = true,
        notify = false, -- get a notification when changes are found
    },
})

-- vim script 中的 cursorMove 不支持 select 参数
-- 所以这里通过lua脚本，同样调用 cursorMove，但是可以传递 select 参数
-- !但仍然存在问题：
-- 1. cursorMove 会破坏 visual line 模式，所以 visual line 模式只会保留一次，然后就会变成 visual 模式
-- 2. 文档中存在有中文时，移动过程中，col 会出现偏移，导致选区不准确
-- local vim_api = vim.api
-- 行内移动
local function moveInLine(d)
    require('vscode-neovim').action('cursorMove', {
        args = {{
            to = d == 'end' and 'wrappedLineEnd' or 'wrappedLineStart',
            by = 'wrappedLine',
            -- by = 'line',
            -- value = vim.v.count1,
            -- value = vim.v.count,
            value = 0,
            select = true
        }}
    })
    return '<Ignore>'
end

-- 行间移动
local function moveLine(d)
    -- local current_mode = vim.api.nvim_get_mode().mode
    require('vscode-neovim').action('cursorMove', {
        args = {{
            to = d == 'j' and 'down' or 'up',
            by = 'wrappedLine',
            -- by = 'line',
            value = vim.v.count1,
            -- value = vim.v.count,
            select = true
        }}
        -- not work
        -- callback = function()
        --     -- cb()
        --     if current_mode == 'V' then
        --         vim.schedule(function()
        --             vim_api.nvim_input('V')
        --         end)
        --         -- vim_api.nvim_input('V')
        --         -- vim_api.nvim_feedkeys('V', 'x', false)
        --         -- vim_api.nvim_feedkeys('V', 'v', true)
        --         -- debug.debug()
        --         -- return 'V'
        --     end
        --     -- return '<Ignore>'
        -- end
    })
    return '<Ignore>'
end

local function move(d)
    return function()
        -- 获取当前编辑模式
        local current_mode = vim.api.nvim_get_mode().mode
        -- Only works in charwise visual and visual line mode
        -- if current_mode ~= 'v' and current_mode ~= 'V' then
        --     return 'g' .. d
        -- end

        -- 因为 moveCursor 会破坏 visual line 模式，所以 visual line 模式只会保留一次，然后就会变成 visual 模式
        -- 因此这段逻辑在一次选区的动作中只会执行一次
        if current_mode == 'V' then
            moveLine(d)
            if d == 'j' then
                moveInLine('end')
            else
                moveInLine('start')
            end
        else
            -- 获取当前选区的标记的位置（<）
            local start_pos = vim.api.nvim_buf_get_mark(0, "<")
            local end_pos = vim.api.nvim_buf_get_mark(0, ">")
            -- 提取列号 和 行号
            local start_line = start_pos[1]
            local start_col = start_pos[2]
            local end_line = end_pos[1]
            local end_col = end_pos[2]

            -- 获取光标当前列号
            local cursor_col = vim.fn.col('.')
            -- 获取当前行最大列号
            local line_end_col = vim.fn.col('$')
            -- 获取选区的结束行文本内容
            local selected_end_line_text = vim.fn.getline(end_line)
            -- 获取当前光标位置的行号和列号
            -- 参数 0 表示当前窗口
            local cursor = vim.api.nvim_win_get_cursor(0)
            -- 提取行号
            local current_line = cursor[1]

            -- 如果选区只有一行，而且整行内容都已被选中
            -- 那么在执行完行间移动后，就将新行的光标移动到行首或行尾
            -- 实现模拟 visual line 的效果
            -- 最后直接返回，不再执行下面的逻辑
            if start_col == 0 and end_col + 1 == #selected_end_line_text and start_line == end_line then
                moveLine(d)
                if d == 'j' then
                    moveInLine('end')
                else
                    moveInLine('start')
                end
                return '<Ignore>'
            end

            -- 其他情况
            moveLine(d)

            -- k方向，向上移动
            -- 如果选区的结束行行内容被全选中，那么在执行完行间移动后，就将新行的光标移动到行尾
            -- 实现模拟 visual line 的效果
            if end_col + 1 == #selected_end_line_text and current_line < end_line then
                moveInLine('start')
                -- return 'V'
            end
            -- j方向，向下移动
            -- 如果选区的开始行行内容被全选中，那么在执行完行间移动后，就将新行的光标移动到行首
            -- 实现模拟 visual line 的效果
            if start_col == 0 and current_line > start_line then
                moveInLine('end')
                -- return 'V'
            end
        end
        return '<Ignore>'
    end
end

vim.keymap.set('v', 'gj', move('j'), {
    expr = true,
    noremap = true,
    silent = true
})
vim.keymap.set('v', 'gk', move('k'), {
    expr = true,
    noremap = true,
    silent = true
})

local function moveCursor(d)
    return function()
        -- 当 v.count 为 0 时，表示没有使用数字修饰符，此时可以执行自定义的移动
        -- 否则，执行原生的移动，如 10j
        if (vim.v.count == 0 and vim.fn.reg_recording() == '' and vim.fn.reg_executing() == '') then
            return 'g' .. d
        else
            return d
        end
    end
end

-- 依赖于 gj 和 gk 的定义，所以要放在 gj 和 gk 的后面
vim.keymap.set('', 'k', moveCursor('k'), {
    expr = true,
    remap = true,
    silent = true
})
vim.keymap.set('', 'j', moveCursor('j'), {
    expr = true,
    remap = true,
    silent = true
})

vim.g.testfoldkey = 1
