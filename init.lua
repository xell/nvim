-- vim:fdm=marker
-- xell neovim nvim config
--      _/      _/  _/_/_/_/  _/        _/
--       _/  _/    _/        _/        _/
--        _/      _/_/_/    _/        _/
--     _/  _/    _/        _/        _/
--  _/      _/  _/_/_/_/  _/_/_/_/  _/_/_/_/

-- Pre and helpers {{{
local function k(keys)
    return vim.api.nvim_replace_termcodes(keys, true, true, true)
end

-- Start listening on a PID-addressable socket so other instances of this
-- config can find and RPC into this one (see lua/swap_takeover.lua).
require('swap_takeover').setup_server()
-- }}}

-- General settings {{{
vim.g.mapleader = ','
vim.g.maplocalleader = [[\]]

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true
vim.o.inccommand = 'split'
vim.o.wrapscan = false
vim.o.wildignore =
'*.o,*.obj,*.dll,*.exe,*.so,*.a,*.lib,*.pyc,*.pyo,*.pyd,*.swp,*.swo,*.class,*.DS_Store,*.orig,*.db,*.javac,*.pyc,*.aux,*.out,*.toc'
vim.o.suffixesadd = '.java,.rs,.lua'

vim.o.updatetime = 500
vim.o.modelineexpr = true

vim.o.shada = "'100,<1000,s500,h" -- ori viminfo
vim.o.sessionoptions = 'buffers,curdir,folds,globals,help,resize,slash,tabpages,winpos,winsize,localoptions,options,terminal'

vim.o.grepprg = 'rg --vimgrep --smart-case'

-- Completion
vim.o.pumheight = 20
vim.o.wildmenu = true
vim.o.omnifunc = 'syntaxcomplete#Complete'
vim.o.dictionary = '/usr/share/dict/words'
vim.opt.complete:append('k') -- also scan file(s) in the 'dictionary'
vim.o.infercase = true
vim.keymap.set('i', '<M-space>', '<C-x><C-k>')
-- }}}

-- UI GUI {{{
vim.o.title = true
vim.o.guifont = "Sarasa Term SC Nerd:h14"
vim.o.guifontwide = "Sarasa Term SC Nerd:h14"
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
    foldopen =  ({ '▾', '', '' })[1],
    foldclose = ({ '▸', '', '' })[1],
    foldsep = '│',
    diff = '╱',
    eob = ' ',
    vert = '│',
}

-- colorscheme auto dark
local function apply_colorscheme()
    vim.cmd.colorscheme(vim.o.background == 'dark' and 'ayu-mirage' or 'onehalflight')
    -- onehalflight.vim runs `set background=light`; re-set it from Lua so Neovim
    -- keeps following the terminal's theme reports
    vim.o.background = vim.o.background
end
-- wait for lazy.nvim, which provides ayu
vim.api.nvim_create_autocmd('VimEnter', { once = true, nested = true, callback = apply_colorscheme })
vim.api.nvim_create_autocmd('OptionSet', {
    pattern = 'background',
    nested = true,
    callback = apply_colorscheme,
})
-- Nvim only asks the terminal for its background colour at startup; ask again
-- on focus so a system appearance change (Ghostty follows it) updates 'background'
vim.api.nvim_create_autocmd('FocusGained', {
    callback = function()
        vim.api.nvim_ui_send('\027]11;?\007')
    end,
})

-- reload current colorscheme
vim.api.nvim_create_user_command('ReloadColorscheme', function()
    vim.cmd.colorscheme(vim.api.nvim_exec2('colorscheme', { output = true })['output'])
end, {})

-- toggle relativenumber
vim.keymap.set('n', '<Leader>nn', function()
    vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = 'Toggle relative number' })

-- show/hide number
vim.keymap.set('n', '<Leader>nN', function()
    vim.wo.number = not vim.wo.number
end, { desc = 'Show/hide number' })

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

-- keep bar cursor {{{
local saved_guicursor

local function set_cursor_bar()
    -- Clearing guicursor stops nvim's teardown from emitting terminfo Se
    -- (ESC[2 q, steady block), which would otherwise override the write below.
    -- Plain DECSCUSR, never a \ePtmux; passthrough: tmux's allow-passthrough is
    -- off by default, so passthrough is silently swallowed. Writing it plainly
    -- also keeps tmux's own per-pane cursor state in sync. Inside tmux the
    -- decisive fix is the Se override in ~/.tmux.conf, not this hook.
    saved_guicursor = vim.o.guicursor
    vim.o.guicursor = ""
    io.write("\27[5 q")
end

vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, { callback = set_cursor_bar })
vim.api.nvim_create_autocmd("VimResume", {
    callback = function()
        if saved_guicursor then
            vim.o.guicursor = saved_guicursor
        end
    end,
})

-- Cursor: normal-ish => block, insert-ish => bar. Single source of truth for
-- both the main editor and the Ctrl-G temp editor (CLI agents use $EDITOR).
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver30,o:block,r-cr-o:ver30"

vim.api.nvim_create_autocmd({ "ModeChanged", "WinEnter", "BufEnter" }, {
  callback = function()
    if vim.bo.buftype ~= "terminal" then
      vim.cmd("redraw!")              -- re-emits current shape from guicursor
    end
  end,
})
--- }}}

require('gitstatus')  -- registers its BufReadPost/BufWritePost refresh

require('wordcount').setup({
    format = function(c)
        return string.format(' zh:%d en:%dw/%dc ', c.cjk, c.words, c.chars)
    end,
})

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
        -- `+` staged changes
        -- `*` unstaged changes
        -- `%` untracked
        -- `!` merge conflict
        (function()
            local fs = require('gitstatus').get()
            if fs ~= '' then
                return '  ' .. fs .. ' '
            else
                return ''
            end
        end)(),
        require('wordcount').statusline(),
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
vim.g.netrw_keepdir = 0

vim.opt.termguicolors = true

vim.g.seditor_table = {}

vim.opt.diffopt:append('linematch:60')

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
        'fugitive',
    },
    callback = function(args)
        vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = args.buf })
    end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = function()
    -- Move the newly opened help window into a local split of the active window
    vim.cmd("wincmd K")
  end,
})

-- }}}

-- Windows and tab {{{

-- window size TODO
vim.keymap.set('n', '<M-->', '<C-w>-')
vim.keymap.set('n', '<M-=>', '<C-w>+')
vim.keymap.set('n', '<M-,>', '<C-w><')
vim.keymap.set('n', '<M-.>', '<C-w>>')
vim.keymap.set('t', '<M-->', '<C-\\><C-n><C-w>-')
vim.keymap.set('t', '<M-=>', '<C-\\><C-n><C-w>+')
vim.keymap.set('t', '<M-,>', '<C-\\><C-n><C-w><')
vim.keymap.set('t', '<M-.>', '<C-\\><C-n><C-w>>')
vim.keymap.set("n", "<down>", ":resize +1<cr>")
vim.keymap.set("n", "<up>", ":resize -1<cr>")
vim.keymap.set("n", "<right>", ":vertical resize +1<cr>")
vim.keymap.set("n", "<left>", ":vertical resize -1<cr>")

-- <M-n> goes to the n window
for i = 1, 9 do
    vim.keymap.set('n', '<M-' .. i .. '>', i .. '<c-w><c-w>')
    vim.keymap.set('t', '<M-' .. i .. '>', '<C-\\><C-N>' .. i .. '<c-w><c-w>')
end

-- <M-h/j/k/l>
for c in ('hjkl'):gmatch '.' do
    vim.keymap.set('t', '<M-' .. c .. '>', '<C-\\><C-N><C-w>' .. c)
    vim.keymap.set('n', '<M-' .. c .. '>', '<C-w>' .. c)
end

-- <Tab> to jump between two recent windows
vim.keymap.set('n', '<Tab>', function()
    local ori_win_nr = vim.fn.winnr() -- vim.api.nvim_win_get_number(0)

    -- Asynchronous execution
    -- vim.api.nvim_feedkeys(k('<C-w><C-p>'), 'n', true)
    vim.cmd('wincmd p')
    local cur_win_nr = vim.fn.winnr()

    if ori_win_nr == cur_win_nr then
        vim.api.nvim_feedkeys(k('<C-w><C-w>'), 'n', true)
    end
    local win_id = vim.api.nvim_get_current_win()
    local config = vim.api.nvim_win_get_config(win_id)
    if config.relative ~= '' and config.focusable == false then
        vim.api.nvim_feedkeys(k('<C-w><C-w>'), 'n', true)
    end
end)
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
vim.keymap.set('t', '<M-t>', '<C-\\><C-o>:tabnew<CR>')
vim.keymap.set('n', '<M-w>', ':tabclose')
vim.keymap.set('n', '<M-[>', 'gT')
vim.keymap.set('n', '<M-]>', 'gt')
vim.keymap.set('t', '<M-[>', [[<C-\><C-n>gT]])
vim.keymap.set('t', '<M-]>', [[<C-\><C-n>gt]])
for i = 1, 9, 1 do
    vim.keymap.set('n', '<C-' .. i .. '>', i .. 'gt', { desc = 'Goto ' .. i .. ' tab' })
    vim.keymap.set('t', '<C-' .. i .. '>', '<C-\\><C-n>' .. i .. 'gt', { desc = 'Goto ' .. i .. ' tab' })
end
-- edit current buf in a new tab
vim.api.nvim_create_user_command('TabnewEditBuf', function()
    vim.cmd [[exec 'tabe +buf\ ' . bufnr()]]
end, {})

-- window full screen plugin
vim.keymap.set('n', '<C-Enter>', vim.cmd.WinFullScreen)

-- previous and next buffer
vim.keymap.set('n', 'H', '<CMD>bprevious<CR>')
vim.keymap.set('n', 'L', '<CMD>bnext<CR>')

-- Merge other windows' buffers into the current
-- WinBuffers
-- OnlyKeep {{{
local function get(win)
    return vim.w[win].win_buffers or {}
end

local function record(win, buf)
    if not vim.api.nvim_buf_is_valid(buf)
        or not vim.bo[buf].buflisted
        or vim.bo[buf].buftype ~= "" then
        return
    end
    -- most-recent first, deduped, dead buffers pruned
    local list = vim.tbl_filter(function(b)
        return b ~= buf and vim.api.nvim_buf_is_valid(b)
    end, get(win))
    table.insert(list, 1, buf)
    vim.w[win].win_buffers = list  -- must reassign; vim.w returns a copy
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter" }, {
    group = vim.api.nvim_create_augroup("WinBufferHistory", { clear = true }),
    callback = function()
        record(vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf())
    end,
})

-- Picker limited to buffers this window has shown
vim.api.nvim_create_user_command("WinBuffers", function()
    local bufs = vim.tbl_filter(vim.api.nvim_buf_is_valid, get(0))
    if #bufs == 0 then
        return vim.notify("This window has no buffer history", vim.log.levels.INFO)
    end
    vim.ui.select(bufs, {
        prompt = "Window buffers",
        format_item = function(b)
            local name = vim.api.nvim_buf_get_name(b)
            return b .. ": " .. (name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]")
        end,
    }, function(choice)
            if choice then vim.api.nvim_set_current_buf(choice) end
        end)
end, { desc = "Pick from buffers this window has displayed" })

-- Your original request: merge other windows' lists into the current one, then close them
vim.api.nvim_create_user_command("OnlyKeep", function()
    local cur = vim.api.nvim_get_current_win()
    local merged, seen = {}, {}

    local function add(b)
        if not seen[b] and vim.api.nvim_buf_is_valid(b) then
            seen[b] = true
            table.insert(merged, b)
        end
    end

    for _, b in ipairs(get(cur)) do add(b) end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if win ~= cur then
            for _, b in ipairs(get(win)) do add(b) end
        end
    end

    vim.w[cur].win_buffers = merged
    vim.cmd("only!")
end, { desc = "Close other windows in this tab, merging their buffer histories into this one" })
-- }}}

--- }}}

-- Fold {{{
-- vim.o.foldmethod = 'marker'
-- vim.o.foldcolumn = 'auto' -- nvim-spec

local fcs = vim.opt.fillchars:get()

-- Stolen from Akinsho
local function get_fold(lnum)
    if vim.fn.foldlevel(lnum) <= vim.fn.foldlevel(lnum - 1) then return ' ' end
    return vim.fn.foldclosed(lnum) == -1 and fcs.foldopen or fcs.foldclose
end

_G.get_statuscol = function()
    return "%s%l " .. get_fold(vim.v.lnum) .. " "
end

vim.opt_local.statuscolumn = "%!v:lua.get_statuscol()"

vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
-- vim.o.foldopen = 'all'
vim.o.foldopen = 'block,hor,mark,percent,quickfix,search,tag,undo,insert'

-- toggle fold
--
-- foldexpr (e.g. treesitter's markdown query) deliberately flattens the
-- blank separator line before the next heading/list/etc. to an outer
-- level, purely so closed siblings stack without a gap. Structurally that
-- line belongs to the parent; psychologically a human reading top-to-bottom
-- still considers it part of whatever deeper content just ended, no matter
-- what foldlevel() says. Toggling by strict foldlevel containment therefore
-- closes/opens the wrong (much bigger) fold whenever the cursor sits on one
-- of these flattened lines.
--
-- The same query also folds lists, blockquotes etc., not just ATX headings
-- -- e.g. a list right under a heading gets its own deeper fold. <Space>
-- should never toggle one of those; it should always resolve to the
-- nearest heading, treating list/blockquote/etc. folds as transparent.
--
-- Fix, in two stateless phases (recomputed fresh every press, so toggling
-- stays symmetric even when the cursor never moves):
--   1. Walk backward over the run of lines flattened to the cursor's own
--      level; if that run is preceded by something deeper, step into it.
--   2. From there, climb to that fold's true start, and if it isn't an ATX
--      heading, keep climbing to the parent fold's start until one is.

local function is_heading(text)
    return text:match('^#+%s') ~= nil
end

-- First line of the fold containing `lnum`, given `lnum` is already known
-- to be at foldlevel `level` (walks back while the level stays >= that,
-- i.e. while still inside the same fold or a nested one).
local function fold_start_at(lnum, level)
    local s = lnum
    while s > 1 and vim.fn.foldlevel(s - 1) >= level do
        s = s - 1
    end
    return s
end

local function toggle_fold()
    local lnum = vim.fn.line('.')

    -- Phase 1: attribute a flattened separator line to the deeper content
    -- that precedes it, if any.
    local level = vim.fn.foldlevel(lnum)
    local probe = lnum
    while probe > 1 and vim.fn.foldlevel(probe - 1) == level do
        probe = probe - 1
    end
    if probe > 1 and vim.fn.foldlevel(probe - 1) > level then
        probe = probe - 1
    end

    -- Phase 2: climb past non-heading folds (list, blockquote, ...) to the
    -- nearest ancestor whose fold actually starts on an ATX heading.
    local target
    local p, plevel = probe, vim.fn.foldlevel(probe)
    while plevel > 0 do
        local start = fold_start_at(p, plevel)
        if is_heading(vim.fn.getline(start)) then
            target = start
            break
        end
        p = start - 1
        if p < 1 then break end
        plevel = vim.fn.foldlevel(p)
    end
    target = target or probe

    local closed = vim.fn.foldclosed(target)
    if closed > 0 then
        vim.cmd(closed .. 'foldopen')
    else
        vim.cmd(target .. 'foldclose')
    end
end

vim.keymap.set('n', '<Space>', toggle_fold, { silent = true, desc = 'Toggle the nearest heading fold, transparent to gaps/lists/blockquotes' })

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


vim.keymap.set('n', 'j', 'gj', { desc = 'gj' })
vim.keymap.set('n', 'k', 'gk', { desc = 'gk' })
vim.cmd[[xnoremap <expr> j mode() =~ 'V\\|' ? 'j' : 'gj']]
vim.cmd[[xnoremap <expr> k mode() =~ 'V\\|' ? 'k' : 'gk']]

-- Make U opposite to u.
vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })

-- leave cursor in the end of visual block
vim.keymap.set('v', 'y', 'ygv<Esc>')
vim.keymap.set('n', 'P', 'gP')

-- select pasted content
vim.cmd [[nnoremap <expr> gp '`[' . getregtype()[0] . '`]']]
-- vim.keymap.set("n", "gp", "`[v`]", { desc = "Select last pasted text" })


-- indent the just pasted content
vim.keymap.set('n', '<Leader>P=', '`[V`]==', { desc = 'Indent just pasted' })
vim.keymap.set('n', '<Leader>PP', 'p`[V`]==', { desc = 'Paste and indent' })

-- - to g_ last non-blank char
vim.keymap.set('', '-', 'g_')
-- swap ^ and 0 for convenience
vim.keymap.set('', '0', '^')
vim.keymap.set('', '^', '0')

-- move in insert mode
vim.keymap.set({ 'i', 'c' }, '<M-h>', '<Left>')
vim.keymap.set({ 'i', 'c' }, '<M-l>', '<Right>')
vim.keymap.set({ 'i', 'c' }, '<M-j>', '<Down>')
vim.keymap.set({ 'i', 'c' }, '<M-k>', '<Up>')
vim.keymap.set({ 'i', 'c' }, '<M-6>', '<Home>')
vim.keymap.set({ 'i', 'c' }, '<M-4>', '<End>')
vim.keymap.set('i', '<M-->', '<PageDown>')
vim.keymap.set('i', '<M-=>', '<PageUp>')

-- "reload" buffer
vim.api.nvim_create_user_command("ReloadBuffer", function()
    local win = vim.api.nvim_get_current_win()
    local lnum = vim.fn.line(".")

    vim.cmd("mkview 9")
    vim.cmd("edit")

    local tries = 0
    local function restore()
        if not vim.api.nvim_win_is_valid(win) then return end
        vim.api.nvim_win_call(win, function()
            tries = tries + 1
            if vim.fn.foldlevel(lnum) > 0 or tries >= 40 then
                vim.cmd("silent! loadview 9")
            else
                vim.defer_fn(restore, 25)
            end
        end)
    end
    restore()
end, {})
vim.keymap.set('n', '<M-e>', '<cmd>ReloadBuffer<CR>')
-- "reload" filetype, hack for highlight and folding
vim.keymap.set('n', '<M-C-l>', function()
    vim.t.lbr = vim.wo.linebreak
    vim.bo.filetype = vim.o.filetype
    -- WriteRoom
    if vim.t.showtabline_ori ~= nil then
        vim.wo.number = false
    end
    vim.wo.linebreak = vim.t.lbr
    vim.wo.foldmethod = vim.o.foldmethod
    vim.print('Refresh the filetype.')
    if vim.call('foldlevel', '.') > 0 then
        vim.cmd.normal [[zv]]
    end
end)

-- <M-s> update/write
vim.keymap.set({ 's', 'i', 'n', 'v' }, '<M-s>', function()
    print(select(2, pcall(vim.cmd.update)))
end)

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
vim.api.nvim_create_user_command('Search2LocList', function()
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
            vim.hl.on_yank({ timeout = 500 })
        end,
    })

-- yank
vim.keymap.set('n', 'Y', '^yg_')

-- toggle conceallevel
vim.keymap.set('n', '<Leader>L', function()
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
    vim.cmd [[s/\v^\a|\:\s\a|<%(a>|an>|and>|as>|at>|but>|by>|for>|in>|nor>|of>|on>|or>|the>|to>|up>)@!\a/\U&/g]]
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
-- Neovim 0.10+ ships its own SwapExists handler that picks (E)dit and prints
-- "W325: Ignoring swapfile ..." for a live Nvim owner. swap_takeover handles
-- every case itself, and that extra line causes a hit-enter prompt.
pcall(vim.api.nvim_del_augroup_by_name, 'nvim.swapfile')
vim.api.nvim_create_autocmd({ 'SwapExists' }, {
    callback = require('swap_takeover').handle_swap_exists,
})

-- Return to normal mode while losing focus
local focuslost_stopinsert = true

vim.api.nvim_create_autocmd('FocusLost', {
    pattern = '*',
    group = vim_startup_aug,
    desc = 'Return to normal mode while losing focus',
    callback = function()
        if not focuslost_stopinsert then return end
        vim.cmd.stopinsert()
    end,
})
vim.api.nvim_create_user_command('ToggleFocusLost', function()
    focuslost_stopinsert = not focuslost_stopinsert
    vim.notify('FocusLost stopinsert: ' .. (focuslost_stopinsert and 'on' or 'off'))
end, { desc = 'Toggle stopinsert on FocusLost' })

-- curly quote
vim.keymap.set('i', "<M-'>", '’')

-- i_CTRL-u stopps at column 1
vim.keymap.set('i', '<C-u>', function()
  if vim.fn.col('.') == 1 then
    return ''
  end
  return vim.api.nvim_replace_termcodes('<C-u>', true, true, true)
end, { expr = true, noremap = true, silent = true, desc = 'Delete to line start, but no line-eating at col 1' })

-- 
-- " Prefer Neovim terminal insert mode to normal mode.
-- autocmd BufEnter term://* startinsert
-- auto enter zsh vi-mode insert mode
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    pattern = "term://*",
    callback = function()
        vim.cmd("startinsert")
    end,
})
vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "term://*",
    callback = function()
        -- Deliberately delayed: startinsert here makes Nvim start reflecting the
        -- terminal's live cursor shape immediately, before the shell has even
        -- exec'd and sourced its rc file. That means it captures the terminal's
        -- default block cursor (see :help terminal-cursor-style) before zsh's
        -- vi-mode plugin has had a chance to send its own DECSCUSR shape escape,
        -- and the display never catches up. Waiting lets the shell finish
        -- starting first, so the initial shape is already correct.
        vim.defer_fn(function()
            vim.cmd("startinsert")
        end, 1000)
    end,
})

-- Copy a gneovim:// link to the current file to the system clipboard.
vim.api.nvim_create_user_command('GneovimCopyLink', function()
    local path = vim.api.nvim_buf_get_name(0)
    if path == '' then
        vim.notify('GneovimCopyLink: buffer has no file name', vim.log.levels.WARN)
        return
    end
    path = vim.fn.fnamemodify(path, ':p')
    -- Percent-encode every byte except unreserved characters and '/'.
    local url = 'gneovim://file' .. (path:gsub('[^A-Za-z0-9._~/-]', function(c)
        return string.format('%%%02X', c:byte())
    end))
    vim.fn.setreg('+', url)
    vim.notify('Copied ' .. url)
end, { desc = 'Copy a gneovim:// link to the current file' })

-- Auto read/load buffer after modified externally
--
-- A reload throws away which folds were open and recomputes them all from
-- 'foldlevel' alone -- and zM leaves that at 0, so the whole file comes back
-- folded, with the cursor pulled up to the start of the fold it is now
-- hidden in. So right before checking, snapshot the closed folds and the
-- cursor of every window whose file has changed on disk, and put them back
-- once the reloaded folds exist. Lines are found again by their text, since
-- the external edit may have moved them; a fold whose first line was edited
-- or deleted just stays open.

local fold_snapshots = {} -- [winid] = state taken right before a reload

local function disk_mtime(buf)
    local st = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
    return st and st.mtime.sec .. '.' .. st.mtime.nsec
end

-- text -> every lnum holding exactly that text, in order
local function line_index(lines)
    local index = {}
    for lnum, text in ipairs(lines) do
        index[text] = index[text] or {}
        table.insert(index[text], lnum)
    end
    return index
end

-- A line, remembered as the nth of the `total` lines with its text.
local function line_anchor(lines, index, lnum)
    local same = index[lines[lnum]]
    for nth, l in ipairs(same) do
        if l == lnum then
            return { text = lines[lnum], nth = nth, total = #same, lnum = lnum }
        end
    end
end

-- Same occurrence if the text occurs as often as before, otherwise the
-- occurrence nearest to where the line used to be.
local function find_anchor(index, anchor)
    local same = index[anchor.text]
    if not same then return nil end
    if #same == anchor.total then return same[anchor.nth] end
    local best = same[1]
    for _, l in ipairs(same) do
        if math.abs(l - anchor.lnum) < math.abs(best - anchor.lnum) then best = l end
    end
    return best
end

local function snapshot_folds(win, buf)
    return vim.api.nvim_win_call(win, function()
        local view = vim.fn.winsaveview()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local index = line_index(lines)
        -- foldclosed() can't see closed folds nested in a closed fold, so
        -- open each one found (outermost first) to look inside it, then
        -- close them all again innermost first.
        local closed = {}
        local lnum = 1
        while lnum <= #lines do
            if vim.fn.foldclosed(lnum) == lnum then
                table.insert(closed, lnum)
                vim.cmd(lnum .. 'foldopen')
            else
                lnum = lnum + 1
            end
        end
        for i = #closed, 1, -1 do vim.cmd(closed[i] .. 'foldclose') end
        vim.fn.winrestview(view)

        for i, l in ipairs(closed) do closed[i] = line_anchor(lines, index, l) end
        return {
            buf = buf,
            tick = vim.b[buf].changedtick,
            closed = closed,
            cursor = line_anchor(lines, index, view.lnum),
            cursor_level = vim.fn.foldlevel(view.lnum),
            col = view.col,
            curswant = view.curswant,
            row = vim.fn.winline() - 1,
        }
    end)
end

local function restore_folds(win, snap)
    vim.api.nvim_win_call(win, function()
        local lines = vim.api.nvim_buf_get_lines(snap.buf, 0, -1, false)
        local index = line_index(lines)
        vim.cmd('silent! %foldopen!')
        for i = #snap.closed, 1, -1 do
            local lnum = find_anchor(index, snap.closed[i])
            if lnum and pcall(vim.cmd, lnum .. 'foldclose')
                and vim.fn.foldclosed(lnum) ~= lnum then
                -- no fold starts there any more; don't close its parent
                vim.cmd(lnum .. 'foldopen')
            end
        end
        local lnum = find_anchor(index, snap.cursor) or math.min(snap.cursor.lnum, #lines)
        -- pick the topline that puts the cursor back on its old screen row
        local top = lnum
        while top > 1 do
            local above = vim.fn.foldclosed(top - 1)
            above = above == -1 and top - 1 or above
            local rows = vim.api.nvim_win_text_height(0, { start_row = above - 1, end_row = lnum - 2 }).all
            if rows > snap.row then break end
            top = above
        end
        vim.fn.winrestview({ lnum = lnum, col = snap.col, curswant = snap.curswant, topline = top })
    end)
end

-- Folds are recomputed after the reload, maybe asynchronously (treesitter),
-- so wait until a line that was in a fold is in one again (~1s at most).
local function restore_when_folded(win, snap, tries)
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= snap.buf then return end
    tries = tries or 0
    local probe = snap.closed[1] or (snap.cursor_level > 0 and snap.cursor) or nil
    local lnum = probe and find_anchor(line_index(vim.api.nvim_buf_get_lines(snap.buf, 0, -1, false)), probe)
    local ready = not lnum or vim.api.nvim_win_call(win, function() return vim.fn.foldlevel(lnum) > 0 end)
    if ready or tries >= 40 then
        restore_folds(win, snap)
    else
        vim.defer_fn(function() restore_when_folded(win, snap, tries + 1) end, 25)
    end
end

vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
    callback = function(args) vim.b[args.buf].disk_mtime = disk_mtime(args.buf) end,
})
vim.api.nvim_create_autocmd('FileChangedShellPost', {
    callback = function(args)
        vim.b[args.buf].disk_mtime = disk_mtime(args.buf)
        for win, snap in pairs(fold_snapshots) do
            -- an unchanged changedtick means the reload was declined
            if snap.buf == args.buf and vim.b[args.buf].changedtick ~= snap.tick then
                vim.schedule(function() restore_when_folded(win, snap) end)
            end
        end
    end,
})

vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter', 'TermLeave', 'FocusGained' }, {
    callback = function()
        if vim.fn.getcmdwintype() ~= '' then return end
        fold_snapshots = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local mtime = vim.b[buf].disk_mtime
            if vim.bo[buf].buftype == '' and vim.wo[win].foldenable
                and vim.wo[win].foldmethod ~= 'manual'
                and mtime and mtime ~= disk_mtime(buf) then
                fold_snapshots[win] = snapshot_folds(win, buf)
            end
        end
        vim.cmd('checktime')
    end,
})

-- }}}

-- Commands {{{
vim.keymap.set('n', '<M-q>', [[q:]])
vim.keymap.set('n', 'qq', [[q:]])

-- command mode to search
vim.keymap.set('c', '<C-k>', '<Up>')
vim.keymap.set('c', '<C-j>', '<Down>')

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
vim.keymap.set('n', 'g[', function() move_cursor_to_link('b') end, { desc = 'Goto previous link' })
vim.keymap.set('n', 'g]', function() move_cursor_to_link('') end, { desc = 'Goto next link' })

-- yank the url under the cursor, either a bare url or the target of a markdown link
local function url_at_cursor()
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col('.') - 1
    local start = 0
    while true do
        local m = vim.fn.matchstrpos(line, vim.g.link_pattern, start)
        local text, s, e = m[1], m[2], m[3]
        if s == -1 or s > col then return nil end
        if col < e then
            -- for [linktext](url "title"), only look for the url after ](
            local target = text:sub(1, 1) == '[' and vim.fn.matchstr(text, [[\](\zs.*]]) or text
            local url = vim.fn.matchstr(target, vim.g.url_pattern)
            return url ~= '' and url or nil
        end
        start = e
    end
end
vim.keymap.set('n', '<Leader>y', function()
    local url = url_at_cursor()
    if not url then
        vim.notify('No url under cursor', vim.log.levels.WARN)
        return
    end
    vim.fn.setreg('+', url)
    vim.notify('Copied ' .. url)
end, { desc = 'Copy url under cursor' })

-- like gx, but open the url in Google Chrome instead of the default browser
vim.keymap.set('n', 'gX', function()
    local url = url_at_cursor() or vim.ui._get_urls()[1]
    if not url or url == '' then
        vim.notify('No url under cursor', vim.log.levels.WARN)
        return
    end
    vim.system({ 'open', '-a', 'Google Chrome', url }, {}, function(out)
        if out.code ~= 0 then
            vim.schedule(function()
                vim.notify('gX: ' .. vim.trim(out.stderr), vim.log.levels.ERROR)
            end)
        end
    end)
end, { desc = 'Open url under cursor in Google Chrome' })

-- diffthis
vim.api.nvim_create_user_command('Diffthis', function()
    vim.cmd.diffthis()
    vim.wo.wrap = true
    vim.api.nvim_feedkeys(k('<C-w>w'), 'n', true)
    vim.wo.wrap = true
    vim.cmd.diffthis()
end, {})

-- spell including cjk
-- https://stackoverflow.com/questions/18196399/exclude-capitalized-words-from-vim-spell-check
-- vim.cmd[[syn match myCapitalWords +\<\w*[A-Z]\K*\>\|'s+ contains=@NoSpell]]
local function toggle_spell(eng_dialect)
    if vim.opt.spell:get() then
        vim.opt_local.spell = false or nil
    else
        vim.opt_local.spell = true
        vim.opt_local.spelllang = 'en_' .. eng_dialect .. ',cjk'
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

-- Inspect
vim.keymap.set('n', '<M-i>', '<CMD>Inspect<CR>')


vim.api.nvim_create_user_command("TermRight", function()
    -- Get the directory of the current buffer; fallback to current working directory if empty
    local current_buf_dir = vim.fn.expand("%:p:h")
    if current_buf_dir == "" then
        current_buf_dir = vim.fn.getcwd()
    end

    -- Open a vertical terminal split at the far right using the buffer's directory
    vim.cmd("botright vsplit | lcd " .. vim.fn.fnameescape(current_buf_dir) .. " | terminal")
end, { desc = "Open a terminal split on the far right in current buffer directory" })

vim.api.nvim_create_user_command("DeleteOtherBuffers", function()
  local keep = vim.api.nvim_get_current_buf()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= keep
        and vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buflisted
        and not vim.bo[buf].modified then
      vim.api.nvim_buf_delete(buf, { force = false })
    end
  end
end, {})

-- Inbox
-- Read on every :InboxAdd, so `:let g:inbox_max_lines = 300` works live.
vim.g.inbox_max_lines = 200                 -- soft cap before the next Inbox NN.md
vim.g.inbox_date_format = '%Y-%m-%d %H:%M'  -- os.date() format of the entry heading
vim.g.inbox_open_cmd = 'tabedit'            -- when the current window is in use: split, vsplit, edit
vim.keymap.set('n', '<Leader>i', '<Cmd>InboxAdd<CR>', { desc = 'Add to Inbox' })

-- }}}

-- Abbreviations {{{
vim.keymap.set('ca', 'xfn', 'echo expand("%:p")')
vim.keymap.set('ca', 'xfnc', 'let @+ = expand("%:p")')
vim.keymap.set('ca', 'ss', function()
    vim.cmd [[bel 10new]]
    vim.wo.scrolloff = 0
end)
vim.keymap.set('ia', 'xdate', '<C-r>=strftime("%Y-%m-%d %H:%M:%S")<CR>')
-- }}}

require('lsp')

-- auto project-based dir
vim.o.autochdir = false
local root_markers = { ".git", "package.json", "Makefile", "pyproject.toml", "Cargo.toml" }
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function(args)
        local buf = args.buf
        -- skip unnamed/special buffers (terminals, help, etc.)
        if vim.bo[buf].buftype ~= "" then return end

        local root = vim.fs.root(buf, root_markers)
        if root and root ~= vim.fn.getcwd() then
            -- or lcd if wants per-window roots
            vim.cmd.cd(root)
        end
    end,
})

-- auto treesitter
vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
        if vim.bo[args.buf].filetype == 'markdown' then return end
        -- only when a parser actually exists for this filetype
        if vim.treesitter.get_parser(args.buf, nil, { error = false }) then
            -- optional: skip very large files, TS parses the whole buffer
            local name = vim.api.nvim_buf_get_name(args.buf)
            local st = name ~= '' and vim.uv.fs_stat(name)
            if st and st.size > 512 * 1024 then return end

            -- no need in new treesitter version
            -- vim.treesitter.start(args.buf)
            vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.wo[0][0].foldmethod = 'expr'
        end
    end,
})

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

-- StatusLine / TabLine / WinBar visibility, and gneovim's AOT window {{{
-- On/Off/Toggle only flip visibility (laststatus / showtabline); they never
-- touch how the content itself is built, so the Statusline augroup above
-- (and Neovim's own default tabline, never overridden here) still drive what
-- shows once either is back on. Off remembers whatever value was active so
-- On restores exactly that, instead of assuming a fixed "on" value.
local laststatus_on = vim.o.laststatus > 0 and vim.o.laststatus or 2
local showtabline_on = vim.o.showtabline > 0 and vim.o.showtabline or 1
-- 'winbar' has no separate visibility switch: an empty value is "off", so
-- WinBarOff remembers the content itself and WinBarOn puts it back. It is
-- also global-local: with a bang the commands cover the global value and
-- every window's own value (like the status line, everything at once);
-- without, only the current window's own value. A window cannot hide a
-- winbar it gets from the global value: an empty local value falls back to
-- the global one, and any non-empty one still takes up a row.
local winbar_global_on = vim.go.winbar
local winbar_locals_on = {} -- win -> local value, saved by WinBarOff!

vim.api.nvim_create_user_command('StatusLineOn', function()
    vim.o.laststatus = laststatus_on
end, { desc = 'Show the status line' })
vim.api.nvim_create_user_command('StatusLineOff', function()
    if vim.o.laststatus > 0 then laststatus_on = vim.o.laststatus end
    vim.o.laststatus = 0
end, { desc = 'Hide the status line' })
vim.api.nvim_create_user_command('StatusLineToggle', function()
    if vim.o.laststatus > 0 then
        vim.cmd.StatusLineOff()
    else
        vim.cmd.StatusLineOn()
    end
end, { desc = 'Toggle the status line' })

vim.api.nvim_create_user_command('TabLineOn', function()
    vim.o.showtabline = showtabline_on
end, { desc = 'Show the tab line' })
vim.api.nvim_create_user_command('TabLineOff', function()
    if vim.o.showtabline > 0 then showtabline_on = vim.o.showtabline end
    vim.o.showtabline = 0
end, { desc = 'Hide the tab line' })
vim.api.nvim_create_user_command('TabLineToggle', function()
    if vim.o.showtabline > 0 then
        vim.cmd.TabLineOff()
    else
        vim.cmd.TabLineOn()
    end
end, { desc = 'Toggle the tab line' })

local function winbar_local(win)
    return vim.api.nvim_get_option_value('winbar', { win = win, scope = 'local' })
end
local function set_winbar_local(win, value)
    vim.api.nvim_set_option_value('winbar', value, { win = win, scope = 'local' })
end

local function winbar_on(bang)
    if bang then
        vim.go.winbar = winbar_global_on
        for win, value in pairs(winbar_locals_on) do
            if vim.api.nvim_win_is_valid(win) then set_winbar_local(win, value) end
        end
        winbar_locals_on = {}
    end
    -- A window's own WinBarOff is undone by its WinBarOn, and by WinBarOn!.
    for _, win in ipairs(bang and vim.api.nvim_list_wins() or { vim.api.nvim_get_current_win() }) do
        local value = vim.w[win].winbar_off
        if value then
            set_winbar_local(win, value)
            vim.w[win].winbar_off = nil
        end
    end
end

local function winbar_off(bang)
    if bang then
        if vim.go.winbar ~= '' then winbar_global_on = vim.go.winbar end
        vim.go.winbar = ''
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local value = winbar_local(win)
            if value ~= '' then
                winbar_locals_on[win] = value
                set_winbar_local(win, '')
            end
        end
        return
    end
    if vim.go.winbar ~= '' then
        vim.notify('WinBarOff: a global winbar is set, which one window cannot hide; use :WinBarOff! to hide it everywhere')
        return
    end
    local value = winbar_local(0)
    if value ~= '' then
        vim.w.winbar_off = value
        set_winbar_local(0, '')
    end
end

local function winbar_shown(bang)
    for _, win in ipairs(bang and vim.api.nvim_list_wins() or { vim.api.nvim_get_current_win() }) do
        if vim.api.nvim_get_option_value('winbar', { win = win }) ~= '' then return true end
    end
    return false
end

vim.api.nvim_create_user_command('WinBarOn', function(opts)
    winbar_on(opts.bang)
end, { bang = true, desc = 'Show the window bar (bang: in every window)' })
vim.api.nvim_create_user_command('WinBarOff', function(opts)
    winbar_off(opts.bang)
end, { bang = true, desc = 'Hide the window bar (bang: in every window)' })
vim.api.nvim_create_user_command('WinBarToggle', function(opts)
    if winbar_shown(opts.bang) then
        winbar_off(opts.bang)
    else
        winbar_on(opts.bang)
    end
end, { bang = true, desc = 'Toggle the window bar (bang: in every window)' })

-- gneovim's always-on-top window: hide both, this instance only.
-- g:gneovim_aot_window is not set yet at this point in startup (gneovim sets
-- it over RPC after init.lua has already run); UIEnter is the first point
-- it is readable, per gneovim's neovim-api-surface.md.
vim.api.nvim_create_autocmd('UIEnter', {
    once = true,
    callback = function()
        if vim.g.gneovim_aot_window then
            vim.cmd.StatusLineOff()
            vim.cmd.TabLineOff()
        end
    end,
})
-- }}}
