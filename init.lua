-- vim:fdm=marker:foldlevel=0
-- xell neovim nvim config
--      _/      _/  _/_/_/_/  _/        _/
--       _/  _/    _/        _/        _/
--        _/      _/_/_/    _/        _/
--     _/  _/    _/        _/        _/
--  _/      _/  _/_/_/_/  _/_/_/_/  _/_/_/_/
--  NEW

-- Pre and helpers {{{
-- https://www.reddit.com/r/neovim/comments/12bmzjk/reduce_neovim_startup_time_with_plugins/
vim.loader.enable()
package.path = package.path .. ';' .. vim.fn.expand('$HOME') .. '/.luarocks/share/lua/5.1/?/init.lua;'
package.path = package.path .. ';' .. vim.fn.expand('$HOME') .. '/.luarocks/share/lua/5.1/?.lua;'
local tools = require 'tools'
local function k(keys)
    return vim.api.nvim_replace_termcodes(keys, true, true, true)
end
-- }}}

-- General settings {{{
vim.g.mapleader = ','
vim.g.maplocalleader = '\\'

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true
vim.o.inccommand = 'split'
vim.o.wrapscan = false
vim.o.wildignore = '*.o,*.obj,*.dll,*.exe,*.so,*.a,*.lib,*.pyc,*.pyo,*.pyd,*.swp,*.swo,*.class,*.DS_Store,*.orig,*.db,*.javac,*.pyc,*.aux,*.out,*.toc'
vim.o.suffixesadd = '.java,.rs,.lua'

vim.o.autochdir = true
vim.o.updatetime = 500
vim.o.modelineexpr = true

vim.o.shada = "'100,<1000,s500,h" -- ori viminfo
vim.o.sessionoptions = 'buffers,curdir,folds,globals,help,resize,slash,tabpages,winpos,winsize,localoptions,options'

if vim.fn.executable('rg') == 1 then
    vim.o.grepprg = 'rg --vimgrep --no-heading --smart-case'
end

-- Completion
vim.o.pumheight = 20
vim.o.wildmenu = true
vim.o.omnifunc = 'syntaxcomplete#Complete'
vim.o.dictionary = '/usr/share/dict/words'
vim.opt.complete:append('k')
vim.o.infercase = true
vim.keymap.set('i', '<M-d>', '<C-x><C-k>')
-- }}}

-- UI GUI {{{
vim.o.number = true
vim.o.breakindent = true
vim.o.breakindentopt = 'list:-2'
vim.o.concealcursor = 'nc'

vim.o.smoothscroll = true

vim.o.laststatus = 2 -- nvim-spec
vim.o.shortmess = 'atI'
vim.o.visualbell = true
vim.o.report = 0

vim.o.equalalways = false
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.scrolloff = 10

-- if 'listchars' or 'fillchars' contains double width characters
vim.o.ambiwidth = 'single'
vim.o.listchars = 'tab:▸\\ ,eol:¬'
vim.opt.fillchars = { --- nvim-spec
    fold = ' ',
    foldopen = ({ '', '' })[1],
    foldclose = ({ '', '' })[1],
    foldsep = '│',
    diff = '╱',
    eob = ' ',
    vert = '│',
}

-- set lsp diagnostic signs {{{
-- https://www.reddit.com/r/neovim/comments/1d8tq14/setting_up_signs_with_vimdiagnostic/
vim.diagnostic.config {
    virtual_text = true,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] =    '',
            [vim.diagnostic.severity.WARN]  =    '',
            [vim.diagnostic.severity.INFO]  =    '󰋼',
            [vim.diagnostic.severity.HINT]  = ({ '', '', '󰌵' })[1]
        },
    },
    float = {
        border = 'rounded',
        format = function(d)
            return ('%s (%s) [%s]'):format(d.message, d.source, d.code or d.user_data.lsp.code)
        end,
    },
    underline = true,
    jump = {
        float = true,
    },
} -- }}}

-- reload current colorscheme
vim.api.nvim_create_user_command('ReloadColorscheme', function()
    vim.cmd.colorscheme(vim.api.nvim_exec2('colorscheme', { output = true })['output'])
end, {})

-- toggle relativenumber
vim.keymap.set('n', '<Leader>nn', function()
    vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = 'Toggle relative number' })

-- set colorcolumn cc
vim.keymap.set('n', '<Leader>hc', function()
    local col = vim.fn.virtcol('.')
    local colorcolumn_list = vim.opt.colorcolumn:get()
    for _, v in pairs(colorcolumn_list) do
        if v == '' .. col then
            vim.opt.colorcolumn:remove('' .. v)
            return
        end
    end
    vim.opt.colorcolumn:append('' .. col)
end, { desc = 'Add or remove colorcolumn' })

-- statusline {{{
-- let g:mystatusline1 = '\ %{winnr()}\ %<%f\ %h%y%m%r\ [%{&ff}]\ [%{&fenc}]'
-- let g:mystatusline2 = '%=%-14.(%l,%c%V%)\ %L\ %P\ '
-- vim.o.statusline = ' %{winnr()} %<%f %h%y%m%r [%{&ff}] [%{&fenc}]' .. ' %{fugitive#statusline()}' .. '%=%-14.(%l,%c%V%) %L %P '
-- https://nuxsh.is-a.dev/blog/custom-nvim-statusline.html
-- vim.g.WinID = {'󰲠', '󰲢', '󰲤', '󰲦', '󰲨', '󰲪', '󰲬',}
vim.g.WinID = { '󰎦', '󰎩', '󰲤', '󰲦', '󰲨', '󰲪', '󰲬', }
-- 󰎦 󰎩
-- 󰲡 󰲣
StatuslineActive = function()
    -- '󰎤', '󰎧', '󰎪', '󰎭', '󰎱', '󰎳', '󰎶',
    -- '󰲠', '󰲢', '󰲤', '󰲦', '󰲨', '󰲪', '󰲬',
    -- '󰼏', '󰼐', '󰼑', '󰼒', '󰼓', '󰼔', '󰼕',
    return table.concat {
        '   %#WinBar#%{winnr()}%#StatusLine# %<%f %h%y%m%r ',
        -- '  %{winnr() <= 7 ? g:WinID[winnr() - 1] : winnr()} %<%f %h%y%m%r ',
        -- (function ()
        --     local digits = {'󰲠', '󰲢', '󰲤', '󰲦', '󰲨', '󰲪', '󰲬',}
        --     -- local winnr = vim.fn.winnr()
        --     if vim.fn.winnr() <= 7 then
        --         return ' ' .. digits[vim.fn.winnr()] .. ' '
        --     else
        --         return ' ' .. vim.fn.winnr() .. ' '
        --     end
        -- end)(),
        -- ' %<%f %h%y%m%r ',
        vim.opt.fileformat:get() == 'unix' and '' or '[' .. vim.opt.fileformat:get() .. '] ',
        vim.opt.fileencoding:get() == 'utf-8' and '' or '[' .. vim.opt.fileencoding:get() .. '] ',
        (function()
            local fs = vim.fn['fugitive#statusline']()
            if fs ~= '' then
                fs = string.sub(fs, 6, -3)
                return '  ' .. fs .. ' '
            else
                return ''
            end
        end)(),
        '%=%-14.(%l,%c%V%) %L %P ',
    }
end
StatuslineInactive = function()
    return table.concat {
        '   %#WinBar#%{winnr()}%#StatusLineNC# %<%f %h%y%m%r ',
        -- ' %{winnr() <= 7 ? g:WinID[winnr() - 1] : winnr()} %<%f %h%y%m%r ',
        -- (function ()
        --     local digits = {'󰲠', '󰲢', '󰲤', '󰲦', '󰲨', '󰲪', '󰲬',}
        --     -- local winnr = vim.fn.winnr()
        --     if vim.fn.winnr() <= 7 then
        --         return ' ' .. digits[vim.fn.winnr()] .. ' '
        --     else
        --         return ' ' .. vim.fn.winnr() .. ' '
        --     end
        -- end)(),
        -- ' %<%f %h%y%m%r ',
    }
end
vim.cmd [[
  augroup Statusline
  au!
  au WinEnter,BufEnter * setlocal statusline=%!v:lua.StatuslineActive()
  au WinLeave,BufLeave * setlocal statusline=%!v:lua.StatuslineInactive()
  augroup END
]]
-- vim.cmd[[set statusline=%!v:lua.Statusline()]]
--- }}}
-- }}}

-- Special settings {{{
vim.g.netrw_liststyle = 3

vim.g.seditor_table = {}

vim.opt.diffopt:append('linematch:60')

-- Disable health checks for these providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- xell Notes -- {{{
vim.g.xell_notes_root = vim.fn.fnameescape(vim.fn.glob('~/Documents/Notes'))
local xell_main_note = string.gsub(vim.g.xell_notes_root .. '/Notes/notes.md', '\\', '')
vim.keymap.set('n', '<Leader>N', function()
    -- Iterate through all buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        -- Check if the buffer is valid and loaded
        if vim.api.nvim_buf_is_loaded(buf) then
            -- Compare the name with the given filepath
            if vim.api.nvim_buf_get_name(buf) == xell_main_note then
                -- Iterate over all tab pages
                for tabnr = 1, vim.fn.tabpagenr('$') do
                    -- Iterate over all buffers in this tab page
                    for _, bufid in ipairs(vim.fn.tabpagebuflist(tabnr)) do
                        if bufid == buf then
                            -- Switch to the correct tab page
                            vim.cmd('tabnext ' .. tabnr)
                            return
                        end
                    end
                end
            end
        end
    end
    if vim.bo.modified == false and
        vim.fn.getline('1') == '' and
        vim.fn.line('$') == 1 then
        -- current buffer is new, open here
        vim.cmd('e ' .. xell_main_note)
    else
        vim.cmd('tabe ' .. xell_main_note)
    end
end, { desc = 'Note in new tab' })
vim.keymap.set('n', '<Leader>ne', ':e ' .. xell_main_note .. '<CR>', { desc = 'Note in current tab' })
-- }}}

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('xell/close_with_q', { clear = true }),
    desc = 'Close with <q>',
    pattern = {
        'git',
        'help',
        'man',
        'qf',
        'query',
        'scratch',
        'spectre_panel',
    },
    callback = function(args)
        vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = args.buf })
    end,
})



-- }}}

-- Windows and tab {{{

-- window size TODO
vim.keymap.set('n', '<M-->', '<C-w>-')
vim.keymap.set('n', '<M-=>', '<C-w>+')
vim.keymap.set('n', '<M-,>', '<C-w><')
vim.keymap.set('n', '<M-.>', '<C-w>>')
vim.keymap.set("n", "<down>", ":resize +2<cr>")
vim.keymap.set("n", "<up>", ":resize -2<cr>")
vim.keymap.set("n", "<right>", ":vertical resize +2<cr>")
vim.keymap.set("n", "<left>", ":vertical resize -2<cr>")

-- <M-n> goes to the n window
for i = 1, 10 do
    vim.keymap.set('n', '<M-' .. i .. '>', i .. '<c-w><c-w>')
end

-- <M-h/j/k/l>
for c in ('hjkl'):gmatch'.' do
    vim.keymap.set('n', '<M-' .. c .. '>', '<C-w>' .. c)
end

-- <Tab> to jump between two recent windows
vim.keymap.set('n', '<Tab>', function()
    local ori_win_nr = vim.api.nvim_win_get_number(0)
    vim.cmd.normal(k('<c-w><c-p>'))
    local cur_win_nr = vim.api.nvim_win_get_number(0)
    if ori_win_nr == cur_win_nr then
        vim.cmd.normal(k('<c-w><c-w>'))
    end
end, { silent = true })
-- <Backspace> to jump clockwise
vim.keymap.set('n', '<Backspace>', '<C-w>W')

-- split
vim.keymap.set('n', '<Leader>s', vim.cmd.split, { desc = 'Split U/D' })
vim.keymap.set('n', '<Leader>v', vim.cmd.vsplit, { desc = 'Split L/R' })
vim.keymap.set('n', '<Leader>S', vim.cmd.new, { desc = 'Split U/D new' })
vim.keymap.set('n', '<Leader>V', vim.cmd.vnew, { desc = 'split L/R new' })

-- close
vim.keymap.set('n', '<Leader>c', '<C-w>c', { desc = 'Close current window' })
vim.keymap.set('n', '<Leader>o', '<C-w>o', { desc = 'Close other windows' })

-- open window arrangment
vim.keymap.set('n', '<Leader>wh', function() vim.cmd [[topleft vertical split]] end, { desc = 'Split far left' })
vim.keymap.set('n', '<Leader>wj', function() vim.cmd [[botright split]] end, { desc = 'Split far bottom' })
vim.keymap.set('n', '<Leader>wk', function() vim.cmd [[topleft split]] end, { desc = 'Split far top' })
vim.keymap.set('n', '<Leader>wl', function() vim.cmd [[botright vertical split]] end, { desc = 'Split far right' })

-- tab, next and previous
vim.keymap.set('n', '<M-t>', ':tabnew<CR>')
vim.keymap.set('n', '<M-w>', ':tabclose')
vim.keymap.set('n', '<M-[>', 'gT')
vim.keymap.set('n', '<M-]>', 'gt')
for i = 1, 9, 1 do
    vim.keymap.set('n', '<Leader>' .. i, i .. 'gt', { desc = 'Goto ' .. i .. ' tab' })
end

-- window full screen plugin
vim.keymap.set('n', '<C-Enter>', vim.cmd.WinFullScreen)

--- }}}

-- Fold {{{
vim.o.foldmethod = 'marker'
vim.o.foldcolumn = 'auto' -- nvim-spec
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
-- vim.o.foldopen = 'all'
vim.o.foldopen = 'block,hor,mark,percent,quickfix,search,tag,undo,insert'

-- toggle fold
vim.cmd[[nnoremap <silent> <Space> @=((foldclosed(line('.')) < 0)?'zc':'zo')<CR>]]

vim.keymap.set('n', 'z[', function()
    local current_foldlevel = vim.call('foldlevel', '.')
    local line = vim.fn.line('.')
    while line >= 1 do
        line = line - 1
        if vim.fn.foldlevel(line) < current_foldlevel then
            break
        end
    end
    vim.call('cursor', { line, '.' })
end, { desc = 'Goto parent fold' })

-- official markdown fold
vim.g.markdown_folding = 1

-- }}}

-- Editing (buffer) {{{
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.opt.whichwrap:append('<,>,[,],l,h')
vim.opt.nrformats:append('alpha')
vim.opt.iskeyword:append('-') -- mainly for dictionary lookup

-- clipboard-osc52
vim.o.clipboard = 'unnamedplus'

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

-- move in insert mode
vim.keymap.set({ 'i', 'c' }, '<M-h>', '<Left>')
vim.keymap.set({ 'i', 'c' }, '<M-l>', '<Right>')
vim.keymap.set({ 'i', 'c' }, '<M-6>', '<Home>')
vim.keymap.set({ 'i', 'c' }, '<M-4>', '<End>')
vim.keymap.set('i', '<M-->', '<PageDown>')
vim.keymap.set('i', '<M-=>', '<PageUp>')

-- "reload" buffer
vim.keymap.set('n', '<M-e>', '<cmd>e %<CR>')
-- "reload" filetype, hack for highlight and folding
vim.keymap.set('n', '<M-C-l>', function()
    vim.t.lbr = vim.wo.linebreak
    vim.bo.filetype = vim.o.filetype
    if vim.call('foldlevel', '.') > 0 then
        vim.cmd.normal [[zv]]
    end
    -- WriteRoom
    if vim.t.showtabline_ori ~= nil then
        vim.bo.number = false
    end
    vim.wo.linebreak = vim.t.lbr
    vim.wo.foldmethod = vim.o.foldmethod
    vim.print('Refresh the filetype.')
end)

-- <M-s> update/write
vim.keymap.set({ 's', 'i', 'n', 'v' }, '<M-s>', function()
    print(select(2, pcall(vim.cmd.update)))
end)

-- page up / down
vim.keymap.set('', '<C-k>', '<C-b>')
vim.keymap.set('', '<C-j>', '<C-f>')

-- search
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

-- toggle conceallevel
vim.keymap.set('n', '<Leader>L', function ()
    if vim.wo.conceallevel == 2 then
        vim.wo.conceallevel = 0
    elseif vim.wo.conceallevel == 0 then
        vim.wo.conceallevel = 2
    end
end, { desc = 'Toggle conceallevel 0/2' })

-- while opening file, jump to last known cursor position (last location)
-- :h lua-guide-autocommands-group
local vim_startup_aug = vim.api.nvim_create_augroup('vimStartup', { clear = true })
vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
    pattern = '*',
    group = vim_startup_aug,
    callback = function()
        local reg_doublequote_position = vim.fn.line([['"]])
        if reg_doublequote_position >= 1 and
            reg_doublequote_position <= vim.fn.line('$') and
            vim.bo.filetype ~= 'commit' then
            vim.cmd.normal(k([[g`"]]))
        end
    end,
})

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

-- https://vi.stackexchange.com/questions/25130/close-buffer-in-the-other-instance
-- https://github.com/vim/vim/blob/master/runtime/pack/dist/opt/editexisting/plugin/editexisting.vim
-- vim.cmd.runtime('macros/editexisting.vim')
vim.api.nvim_create_autocmd({ 'SwapExists' }, {
    callback = function()
        vim.v.swapchoice = 'o'
        vim.bo.modifiable = false
    end,
})

-- Return to normal mode while losing focus
vim.api.nvim_create_autocmd({ 'FocusLost' }, {
    pattern = '*',
    group = vim_startup_aug,
    callback = function()
        vim.cmd[[stopinsert]]
        -- https://stackoverflow.com/a/2969052/138219
        -- vim.api.nvim_feedkeys(k([[<c-\><c-n>]]), 'n', false)
    end,
})

-- curly quote
vim.keymap.set('i', "<M-'>", '’')

-- }}}

-- Commands {{{
vim.keymap.set('n', '<M-q>', [[q:]])
vim.keymap.set('n', 'qq', [[q:]])

-- command mode to search
vim.keymap.set('c', '<C-k>', '<Up>')
vim.keymap.set('c', '<C-j>', '<Down>')

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

-- TODO get word count -- {{{
vim.cmd[[
command! -range=% Num :call NumberOfChars()
function! NumberOfChars() range
	"count double-byte characters
	redir => numChs
	"silent! execute a:firstline.",".a:lastline."s/[^\\x00-\\xff]/&/gn"
	silent! execute "'<,'>s/[^\\x00-\\xff]/&/gn"
	redir END
	if match(numChs,'E486') > 0
		let numC = 0
	else
		let numC = strpart(numChs, 0, stridx(numChs,' '))
	endif

	"count english words
	redir => numEng
	silent! execute "'<,'>s/\\<\\(\\w\\|-\\|'\\)\\+\\>/&/gn"
	redir END
	if match(numEng,'E486') > 0
		let numE = 0
    else
		let numE = strpart(numEng, 0, stridx(numEng,' '))
	endif

	"echo to vim
	echo ''
	echo numC . ' 个中文字符'
	echo numE . ' 个英文词语'
endfunction
]] -- }}}

-- diffthis
vim.api.nvim_create_user_command('Diffthis', function()
    vim.cmd.diffthis()
    vim.wo.wrap = true
    vim.cmd.normal(k('<C-w>w'))
    vim.wo.wrap = true
    vim.cmd.diffthis()
end, {})

-- spell including cjk
-- https://stackoverflow.com/questions/18196399/exclude-capitalized-words-from-vim-spell-check
-- vim.cmd[[syn match myCapitalWords +\<\w*[A-Z]\K*\>\|'s+ contains=@NoSpell]]
local function toggle_spell(eng_dialect)
    if vim.o.spell then
        vim.o.spell = false
    else
        vim.o.spell = true
        vim.o.spelllang = 'en_' .. eng_dialect .. ',cjk'
    end
end
vim.api.nvim_create_user_command('SpellGB', function()
    toggle_spell('gb')
end, {})
vim.api.nvim_create_user_command('SpellUS', function()
    toggle_spell('us')
end, {})

-- Toggle the quickfix/loclist window -- {{{
-- When toggling these, ignore error messages and restore the cursor to the original window when opening the list
local silent_mods = { mods = { silent = true, emsg_silent = true } }
vim.keymap.set('n', '<Leader>xq', function()
    if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
        vim.cmd.cclose(silent_mods)
    elseif #vim.fn.getqflist() > 0 then
        local win = vim.api.nvim_get_current_win()
        vim.cmd.copen(silent_mods)
        if win ~= vim.api.nvim_get_current_win() then
            vim.cmd.wincmd 'p'
        end
    end
end, { desc = 'Toggle quickfix list' })
vim.keymap.set('n', '<Leader>xl', function()
    if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
        vim.cmd.lclose(silent_mods)
    elseif #vim.fn.getloclist(0) > 0 then
        local win = vim.api.nvim_get_current_win()
        vim.cmd.lopen(silent_mods)
        if win ~= vim.api.nvim_get_current_win() then
            vim.cmd.wincmd 'p'
        end
    end
end, { desc = 'Toggle location list' })
-- and navigating through the items.
vim.keymap.set('n', '[q', '<cmd>cprev<cr>zvzz', { desc = 'Previous quickfix item' })
vim.keymap.set('n', ']q', '<cmd>cnext<cr>zvzz', { desc = 'Next quickfix item' })
vim.keymap.set('n', '[l', '<cmd>lprev<cr>zvzz', { desc = 'Previous loclist item' })
vim.keymap.set('n', ']l', '<cmd>lnext<cr>zvzz', { desc = 'Next loclist item' })
-- }}}

-- }}}

-- Abbreviations {{{
vim.keymap.set('ca', 'xfn', 'echo expand("%:p")')
vim.keymap.set('ia', 'xdate', '<C-r>=strftime("%Y-%m-%d %H:%M:%S")<CR>')
-- }}}

require('config.lazy')

