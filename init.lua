-- vim:fdm=marker:foldlevel=0
-- xell neovim nvim config
--      _/      _/  _/_/_/_/  _/        _/
--       _/  _/    _/        _/        _/
--        _/      _/_/_/    _/        _/
--     _/  _/    _/        _/        _/
--  _/      _/  _/_/_/_/  _/_/_/_/  _/_/_/_/
--  NEW

vim.cmd.colorscheme('onehalfdark')

-- Pre and helpers {{{
local tools = require'tools'
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
vim.o.wrapscan = false
vim.o.wildignore = '*.o,*.ojb,*.pyc,*.DS_Store,*.db,*.dll,*.exe,*.a'

vim.o.autochdir = true
vim.o.updatetime = 1000
vim.o.modelineexpr = true
-- clipboard-osc52
vim.o.clipboard = 'unnamedplus'

vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.opt.whichwrap:append('<,>,[,],l,h')
vim.opt.nrformats:append('alpha')
vim.opt.iskeyword:append('-') -- mainly for dictionary lookup

vim.o.shada = "'100,<1000,s500,h" -- ori viminfo
vim.o.sessionoptions = 'buffers,curdir,folds,globals,help,resize,slash,tabpages,winpos,winsize,localoptions,options'

if vim.fn.executable('rg') == 1 then
    vim.o.grepprg = 'rg --vimgrep --no-heading --smart-case'
end

-- Completion
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
    virtual_text = false,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "󰋼",
            [vim.diagnostic.severity.HINT] = "󰌵",
        },
    },
    float = {
        border = "rounded",
        format = function(d)
            return ("%s (%s) [%s]"):format(d.message, d.source, d.code or d.user_data.lsp.code)
        end,
    },
    underline = true,
    jump = {
        float = true,
    },
} -- }}}

-- reload current colorscheme
vim.api.nvim_create_user_command('ReloadColorscheme', function()
    vim.cmd.colorscheme(vim.api.nvim_exec2('colorscheme', { output = true })["output"])
end, {})

-- toggle relativenumber
vim.keymap.set('n', '<Leader>nn', function()
    vim.wo.relativenumber = not vim.wo.relativenumber:get()
end)

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
end)

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
        -- (function()
        --     local fs = vim.fn['fugitive#statusline']()
        --     if fs ~= '' then
        --         fs = string.sub(fs, 6, -3)
        --         return '  ' .. fs .. ' '
        --     else
        --         return ''
        --     end
        -- end)(),
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
end)
vim.keymap.set('n', '<Leader>ne', ':e ' .. xell_main_note .. '<CR>')
-- }}}

-- }}}

-- Windows and tab {{{

-- window size TODO
vim.keymap.set('n', '<M-->', '<C-w>-')
vim.keymap.set('n', '<M-=>', '<C-w>+')
vim.keymap.set('n', '<M-,>', '<C-w><')
vim.keymap.set('n', '<M-.>', '<C-w>>')

-- <M-n> goes to the n window
for i = 1, 10 do
    vim.keymap.set('n', '<M-' .. i .. '>', i .. '<c-w><c-w>')
end

-- <M-h/j/k/l>
for c in ('hjkl'):gmatch'.' do
    vim.keymap.set('n', '<M-' .. c .. '>', '<C-w>' .. c)
end

-- <Backspace> to jump between two recent windows
vim.keymap.set('n', '<Backspace>', function()
    local ori_win_nr = vim.api.nvim_win_get_number(0)
    vim.cmd.normal(k('<c-w><c-p>'))
    local cur_win_nr = vim.api.nvim_win_get_number(0)
    if ori_win_nr == cur_win_nr then
        vim.cmd.normal(k('<c-w><c-w>'))
    end
end, { silent = true })
-- \ to jump clockwise
vim.keymap.set('n', '\\', '<C-w>W')

-- split
vim.keymap.set('n', '<Leader>s', vim.cmd.split)
vim.keymap.set('n', '<Leader>v', vim.cmd.vsplit)
vim.keymap.set('n', '<Leader>S', vim.cmd.new)
vim.keymap.set('n', '<Leader>V', vim.cmd.vnew)

-- close
vim.keymap.set('n', '<Leader>c', '<C-w>c')
vim.keymap.set('n', '<Leader>o', '<C-w>o')

-- open window arrangment
vim.keymap.set('n', '<Leader>wh', function() vim.cmd [[topleft vertical split]] end)
vim.keymap.set('n', '<Leader>wj', function() vim.cmd [[botright split]] end)
vim.keymap.set('n', '<Leader>wk', function() vim.cmd [[topleft split]] end)
vim.keymap.set('n', '<Leader>wl', function() vim.cmd [[botright vertical split]] end)

-- tab, next and previous
vim.keymap.set('n', '<M-t>', ':tabnew<CR>')
vim.keymap.set('n', '<M-w>', ':tabclose')
vim.keymap.set('n', '<M-[>', 'gT')
vim.keymap.set('n', '<M-]>', 'gt')
for i = 1, 9, 1 do
    vim.keymap.set('n', '<Leader>' .. i, i .. 'gt')
end

-- window full screen plugin
vim.keymap.set('n', '<C-Enter>', vim.cmd.WinFullScreen)

--- }}}

-- Fold {{{
vim.o.foldcolumn = 'auto' -- nvim-spec
vim.o.foldlevel = 99
vim.o.foldlevelstart = -1

-- toggle fold
vim.cmd[[nnoremap <Space> @=((foldclosed(line('.')) < 0)?'zc':'zo')<CR>]]

vim.keymap.set('n', 'zkk', function()
    local current_foldlevel = vim.fn.foldlevel('.')
    local line = vim.fn.line('.')
    while line >= 1 do
        line = line - 1
        if vim.fn.foldlevel(line) < current_foldlevel then
            break
        end
    end
    vim.fn.cursor(line, '.')
end)

-- official markdown fold
vim.g.markdown_folding = 1

-- }}}

-- Editing (buffer) {{{
-- map j and k to their original in visual line mode
vim.cmd [[xnoremap <expr> j mode() ==# 'V' ? 'j' : 'gj']]
vim.cmd [[xnoremap <expr> k mode() ==# 'V' ? 'k' : 'gk']]

-- - to g_ last non-blank char
vim.keymap.set('', '-', 'g_')

-- move in insert mode
vim.keymap.set('i', '<M-h>', '<Left>')
vim.keymap.set('i', '<M-l>', '<Right>')
vim.keymap.set('i', '<M-->', '<PageDown>')
vim.keymap.set('i', '<M-=>', '<PageUp>')
vim.keymap.set('i', '<M-6>', '<Home>')
vim.keymap.set('i', '<M-4>', '<End>')

-- "reload" buffer
vim.keymap.set('n', '<M-e>', '<cmd>e %<CR>')
-- "reload" filetype, hack for highlight and folding
vim.keymap.set('n', '<M-C-l>', function()
    vim.t.lbr = vim.wo.linebreak
    vim.bo.filetype = vim.o.filetype
    if vim.fn.foldlevel('.') > 0 then
        vim.cmd.normal [[zv]]
    end
    -- WriteRoom
    if vim.t.showtabline_ori ~= nil then
        vim.bo.number = false
    end
    vim.wo.linebreak = vim.t.lbr
    vim.print('Refresh the filetype.')
end)

-- <M-s> update/write
vim.keymap.set({ 'n', 'i' }, '<M-s>', function()
    print(select(2, pcall(vim.cmd.update)))
end)

-- page up / down
vim.keymap.set('', '<C-k>', '<C-b>')
vim.keymap.set('', '<C-j>', '<C-f>')

-- search
vim.keymap.set('n', '<Leader>ns', function() vim.fn.setreg('/', '') end)
vim.keymap.set('n', '<Leader>nh', function() vim.o.hlsearch = false end)
vim.keymap.set('n', '<Leader>h', function() vim.o.hlsearch = not vim.o.hlsearch end)
vim.keymap.set('v', '<Leader>/', 'y/<C-r>=@"<CR><CR>')

-- highlight/blink yank area
vim.api.nvim_create_autocmd(
{ 'TextYankPost' },
{
    pattern = { '*' },
    callback = function()
        vim.highlight.on_yank({ timeout = 1000 })
    end,
})

-- while opening file, jump to last known cursor position
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

-- }}}

-- Commands {{{
vim.keymap.set('n', '<M-q>', [[q:]])

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
vim.keymap.set('n', 'gn', function() move_cursor_to_link('') end)
vim.keymap.set('n', 'gN', function() move_cursor_to_link('b') end)

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
vim.api.nvim_create_user_command('SpellGB', function()
    if vim.wo.spell then
        vim.wo.spell = false
    else
        vim.wo.spell = true
        vim.wo.spelllang = 'en_gb,cjk'
    end
end, {})
vim.api.nvim_create_user_command('SpellUS', function()
    if vim.wo.spell then
        vim.wo.spell = false
    else
        vim.wo.spell = true
        vim.wo.spelllang = 'en_us,cjk'
    end
end, {})


-- }}}

-- Abbreviations {{{
vim.keymap.set('ca', 'xfn', 'echo expand("%:p")')
vim.keymap.set('ia', 'xdate', '<C-r>=strftime("%Y-%m-%d %H:%M:%S")<CR>')
-- }}}

