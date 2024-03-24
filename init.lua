-- vim:fdm=marker
-- xell neovim nvim config
--      _/      _/  _/_/_/_/  _/        _/
--       _/  _/    _/        _/        _/
--        _/      _/_/_/    _/        _/
--     _/  _/    _/        _/        _/
--  _/      _/  _/_/_/_/  _/_/_/_/  _/_/_/_/

--[[ TODO
- cursor
- signcolumn
- c-k
- file operation https://github.com/tpope/vim-eunuch
--]]

-- https://www.reddit.com/r/neovim/comments/12bmzjk/reduce_neovim_startup_time_with_plugins/
vim.loader.enable()
local vo = vim.opt
local vol = vim.opt_local
local vg = vim.g
local vks = vim.keymap.set
local vf = vim.fn

-- General options {{{
vg.mapleader = ","
vo.number = true
vo.ignorecase = true
vo.smartcase = true
vo.iskeyword:append('-')
vo.autochdir = true
vo.breakindent = true
vo.breakindentopt = "list:-2"
vo.foldcolumn = 'auto' -- nvim-spec
vo.expandtab = true
vo.tabstop = 4
vo.shiftwidth = 4
vo.concealcursor = 'nc'
vo.laststatus = 2 -- nvim-spec
vo.shortmess:append('I')
vo.visualbell = true
vo.exrc = true
vo.shada = "'100,<1000,s500,h" -- ori viminfo
vo.whichwrap:append('<,>,[,],l,h')
vo.sessionoptions = 'buffers,curdir,folds,globals,help,resize,slash,tabpages,winpos,winsize,localoptions,options'
vo.nrformats:append('alpha')
vo.ignorecase = true
vo.smartcase = true
vo.incsearch = true
vo.wrapscan = false
vo.wildignore = '*.o,*.ojb,*.pyc,*.DS_Store,*.db,*.dll,*.exe,*.a'
vo.updatetime = 1000
vo.modelineexpr = true
vo.smoothscroll = true
-- "double" cannot be used if 'listchars' or 'fillchars' contains a character that would be double width.
vo.ambiwidth = 'single'
vo.report = 0
if vf.executable("rg") == 1 then
  vo.grepprg = "rg --vimgrep --no-heading --smart-case"
end
vo.splitright = true
vo.splitbelow = true
-- }}}

-- Special filetypes and cases {{{
-- ?? mathematica
vg.filetype_m = 'mma'
-- ?? sh filetype, see *sh.vim*
vg.is_bash = 1
vg.sh_fold_enabled = 3

-- xell Notes
local xell_note_root_raw = '~/Library/Mobile\\ Documents/iCloud~md~obsidian/Documents/Notes'
vg.xell_notes_root = vf.fnameescape(vf.glob(xell_note_root_raw))

-- official markdown fold
vg.markdown_folding = 1

-- https://www.reddit.com/r/neovim/comments/18ffxmc/exrcnvim_utilities_for_writing_and_managing/
vim.api.nvim_create_autocmd({'VimEnter', 'BufRead'}, {
    callback = function()
        local file = vim.secure.read(vf.getcwd() .. "/.nvim.lua")
        if file ~= nil then
            local f = loadstring(file)
            if f ~= nil then f() end
        end
    end,
})

-- }}}

-- Helper functions TODO {{{
local function k(keys) -- {{{ get keycodes
    return vim.api.nvim_replace_termcodes(keys, true, true, true)
end -- }}}

local function uri_encode(string) -- {{{
    return vf.substitute(vf.iconv(string, 'latin1', 'utf-8'),'[^A-Za-z0-9_.~-]','\\="%".printf("%02X",char2nr(submatch(0)))','g')
end -- }}}
-- }}}

-- Windows and tab {{{

-- window size TODO
vks('n', '<M-->', '<C-w>-')
vks('n', '<M-=>', '<C-w>+')
vks('n', '<M-,>', '<C-w><')
vks('n', '<M-.>', '<C-w>>')

-- <M-n> goes to the n window
for i = 1, 10 do
    vks('n', '<M-' .. i .. '>', i .. '<c-w><c-w>')
end

-- <M-h/j/k/l>
for c in ("hjkl"):gmatch"." do
    vks('n', '<M-' .. c .. '>', '<C-w>' .. c)
end

-- <Backspace> to jump between two recent windows
vks('n', '<Backspace>', function()
    local ori_win_nr = vim.api.nvim_win_get_number(0)
    -- vim.cmd('exec "normal \\<c-w>\\<c-p>"')
    vim.cmd.normal(k('<c-w><c-p>'))
    local cur_win_nr = vim.api.nvim_win_get_number(0)
    if ori_win_nr == cur_win_nr then
        vim.cmd.normal(k('<c-w><c-w>'))
    end
end, {silent = true})
-- \ to jump clockwise
vks('n', '\\', '<C-w>W')

-- split
vks('n', '<Leader>s', vim.cmd.split)
vks('n', '<Leader>v', vim.cmd.vsplit)

-- close
vks('n', '<Leader>c', '<C-w>c')
vks('n', '<Leader>o', '<C-w>o')

-- open window arrangment
vks('n', '<Leader>wh', function () vim.cmd[[topleft vertical split]] end)
vks('n', '<Leader>wj', function () vim.cmd[[botright split]] end)
vks('n', '<Leader>wk', function () vim.cmd[[topleft split]] end)
vks('n', '<Leader>wl', function () vim.cmd[[botright vertical split]] end)

-- tab, next and previous
vks('n', '<S-D-{>', 'gT')
vks('n', '<S-D-}>', 'gt')
for i = 1, 10, 1 do
    vks('n', '<D-' .. i .. '>', i .. 'gt')
end

-- easy edit file in new tab
vks('n', ']f', '<C-w>gf')

-- window full screen plugin
vks('n', '<C-Enter>', vim.cmd.WinFullScreen)

--- }}}

-- Mappings and commands {{{
vks('n', '<M-q>', [[q:]])
vks('n', 'zkk', function ()
    local current_foldlevel = vim.fn.foldlevel('.')
    local line = vim.fn.line('.')
    while line >= 1 do
        line = line - 1
        if vim.fn.foldlevel(line) < current_foldlevel then
            break
        end
    end
    vim.fn.cursor(line, 1)
end)
-- }}}

-- Editing {{{
-- - to $
vks('', '-', '$')
-- move in insert mode
vks('i', '<C-h>', '<Left>')
vks('i', '<C-l>', '<Right>')
vks('i', '<M-->', '<PageDown>')
vks('i', '<M-=>', '<PageUp>')
vks('i', '<M-6>', '<Home>')
vks('i', '<M-4>', '<End>')

-- <D-s> update/write
vks({ 'n', 'i' }, '<D-s>', function()
    -- no need to distinguish n and i and use <Esc> to escape the latter
    print(select(2, pcall(vim.cmd.update)))
end)

-- hack for highlight, re-set the filetype
vks('n', '<C-L>', function ()
    vol.filetype = vo.filetype:get()
    if vim.fn.foldlevel('.') > 0 then
        vim.cmd.normal[[zv]]
    end
    if vim.t.showtabline_ori ~= nil then
        vim.opt_local.number = false
    end
end)


-- source the visual selection
vks('v', '<C-s>', 'y:@"<CR>')

-- page up / down
vks('', '<C-k>', '<C-b>')
vks('', '<C-j>', '<C-f>')

-- search
vks('n', '<Leader>ns', function() vf.setreg('/', '') end)
vks('n', '<Leader>nh', function() vo.hlsearch = false end)
vks('n', '<Leader>h', function () vo.hlsearch = not vim.o.hlsearch end)
-- vks('v', '<Leader>/', function () pcall(vim.cmd.normal(k('y/<C-r>=@"<CR><CR>'))) end)
-- vks('v', '<Leader>/', function ()
--     print(select(2, pcall(
--     function ()
--         vim.cmd.normal(k('y/<C-r>=@"<CR><CR>'))
--     end)))
-- end)
vks('v', '<Leader>/', 'y/<C-r>=@"<CR><CR>')

-- highlight i.e. blink yank area
vim.api.nvim_create_autocmd(
{'TextYankPost'},
{
    pattern = { "*" },
    callback = function()
        vim.highlight.on_yank({timeout = 1000})
    end,
})

-- while opening file, jump to last known cursor position
-- see *lua-guide-autocommands-group*
local vim_startup_aug = vim.api.nvim_create_augroup('vimStartup', { clear = true })
vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
    pattern = '*',
    group = vim_startup_aug,
    callback = function()
        local reg_doublequote_position = vf.line([['"]])
        if reg_doublequote_position >= 1 and
            reg_doublequote_position <= vf.line('$') and
            vol.filetype:get() ~= 'commit' then
            vim.cmd.normal(k([[g`"]]))
        end
    end,
})

-- Capitalization of the current line
-- Capitalize all words in titles of publications and documents, except a, an, the, at, by, for, in, of, on, to, up, and, as, but, or, and nor.
-- https://taptoe.wordpress.com/2013/02/06/vim-capitalize-every-first-character-of-every-word-in-a-sentence/
vim.api.nvim_create_user_command('Capitalize', function ()
    vim.cmd[[s/\v^\a|\:\s\a|<%(a>|an>|and>|as>|at>|but>|by>|for>|in>|nor>|of>|on>|or>|the>|to>|up>)@!\a/\U&/g]]
end, {})

-- http://www.teifel.net/projects/vim/mappings.html
vks('v', '<Leader>(', [[<ESC>`>a)<ESC>`<i(<ESC>`>ll]])
vks('v', '<Leader><', [[<ESC>`>a><ESC>`<i<<ESC>`>ll]])
vks('v', '<Leader>[', [[<ESC>`>a]<ESC>`<i[<ESC>`>ll]])
vks('v', '<Leader>{', [[<ESC>`>a}<ESC>`<i{<ESC>`>ll]])
vks('v', '<Leader>$', [[<ESC>`>a$<ESC>`<i$<ESC>`>ll]])
vks('v', '<Leader>"', [[<ESC>`>a"<ESC>`<i"<ESC>`>ll]])
--- }}}

-- Completion {{{
vo.wildmenu = true
vo.omnifunc = 'syntaxcomplete#Complete'
vo.dictionary = '/usr/share/dict/words'
vo.complete:append('k')
vo.infercase = true
vks('i', '<D-d>', '<C-x><C-k>')
--- }}}

-- Plugins {{{

-- lazy {{{
-- https://github.com/folke/lazy.nvim
local lazypath = vf.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vf.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vo.rtp:prepend(lazypath)
-- }}}

require("lazy").setup({
    -- https://github.com/ybian/smartim
    { 'ybian/smartim',
        init = function () -- {{{
            vg.smartim_default = 'com.apple.keylayout.ABC'
            -- let g:smartim_disable = 1
            -- unlet g:smartim_disable
            -- autocmd InsertLeave * :silent !/usr/local/bin/im-select com.apple.keylayout.ABC
            -- autocmd UIEnter * set noimd
        end,
    }, -- }}}
    -- https://github.com/xiyaowong/fast-cursor-move.nvim remap j k
    { 'xiyaowong/fast-cursor-move.nvim',
        -- enabled = false,
    },
    -- https://github.com/vimpostor/vim-lumen
    { 'vimpostor/vim-lumen',
        config = function () -- {{{
            if vf.has('gui_running') == 1 then
                -- vim.print('gui_running')
                vim.cmd[[au User LumenLight nested colorscheme onehalflight]]
                vim.cmd[[au User LumenDark nested colorscheme onehalfdark]]
                vim.cmd.colorscheme(vim.o.background == 'light' and 'onehalflight' or 'onehalfdark')
            else
                vo.background = 'dark'
            end
        end,
    }, -- }}}
    -- https://github.com/easymotion/vim-easymotion
    { 'xell/vim-easymotion',
        init = function () -- {{{
            -- https://github.com/timsu92/vim-easymotion/pull/2/files
            -- https://github.com/easymotion/vim-easymotion/issues/484
            -- https://github.com/easymotion/vim-easymotion/issues/452
            vim.cmd[[
            let g:EasyMotion_leader_key=";"
            let g:EasyMotion_skipfoldedline=0
            let g:EasyMotion_space_jump_first=1
            let g:EasyMotion_move_highlight = 0
            let g:EasyMotion_use_migemo = 1
            ]]
        end,
        config = function ()
            vim.cmd[[
            " noremap s <Plug>(easymotion-overwin-f2)
            " s 和 surround 冲突, 比如 ds
            " onoremap z <Plug>(easymotion-f2)
            noremap f <Plug>(easymotion-fl)
            noremap F <Plug>(easymotion-Fl)
            noremap t <Plug>(easymotion-tl)
            noremap T <Plug>(easymotion-Tl)
            noremap ;. <Plug>(easymotion-repeat)
            noremap ;l <Plug>(easymotion-next)
            noremap ;h <Plug>(easymotion-prev)
            " noremap <Leader>/ <Plug>(easymotion-sn)
            nnoremap <Leader>/ <Plug>(easymotion-s)
            ]]
        end,
    }, -- }}}
    --  https://www.v2ex.com/t/856921
    'zzhirong/vim-easymotion-zh',
    -- https://github.com/nvim-lua/plenary
    'nvim-lua/plenary.nvim',
    -- https://github.com/xell/yode-nvim
    { 'xell/yode-nvim',
        dev = true,
        config = function () -- {{{
            -- according to readme, submodule should be used
            require('yode-nvim').setup({})
            -- vks({ '' }, '<Leader>yc', vim.cmd.YodeCreateSeditorFloating)
            -- vks('', '<Leader>yr', vim.cmd.YodeCreateSeditorReplace)
            -- vks('n', '<Leader>yd', vim.cmd.YodeBufferDelete)
            vim.cmd[[
            map <Leader>yc :YodeCreateSeditorFloating<CR>
            map <Leader>yr :YodeCreateSeditorReplace<CR>
            nmap <Leader>yd :YodeBufferDelete<cr>
            ]]
        end,
    }, -- }}}
    { dir = vf.stdpath('data') .. '/site' },
    { dir = vf.stdpath('data') .. '/site/pack/main/start/winfullscreen' },
    { dir = vf.stdpath('data') .. '/site/pack/xell/start/outlinex',
        init = function ()
            vg.seditor_table = {}
        end,
    },
    --  https://github.com/chentoast/marks.nvim
    { 'chentoast/marks.nvim',
        config = function () -- {{{
            -- https://www.reddit.com/r/neovim/comments/q7bgwo/marksnvim_a_plugin_for_viewing_and_interacting/
            require'marks'.setup {
                -- whether to map keybinds or not. default true
                default_mappings = true,
                -- which builtin marks to show. default {}
                builtin_marks = { ".", "<", ">", "^" },
                -- whether movements cycle back to the beginning/end of buffer. default true
                cyclic = true,
                -- whether the shada file is updated after modifying uppercase marks. default false
                force_write_shada = false,
                -- how often (in ms) to redraw signs/recompute mark positions. 
                -- higher values will have better performance but may cause visual lag, 
                -- while lower values may cause performance penalties. default 150.
                refresh_interval = 250,
                -- sign priorities for each type of mark - builtin marks, uppercase marks, lowercase
                -- marks, and bookmarks.
                -- can be either a table with all/none of the keys, or a single number, in which case
                -- the priority applies to all marks.
                -- default 10.
                sign_priority = { lower=10, upper=15, builtin=8, bookmark=20 },
                -- disables mark tracking for specific filetypes. default {}
                excluded_filetypes = {},
                -- disables mark tracking for specific buftypes. default {}
                excluded_buftypes = {},
                -- marks.nvim allows you to configure up to 10 bookmark groups, each with its own
                -- sign/virttext. Bookmarks can be used to group together positions and quickly move
                -- across multiple buffers. default sign is '!@#$%^&*()' (from 0 to 9), and
                -- default virt_text is "".
                bookmark_0 = {
                    sign = "⚑",
                    virt_text = "hello world",
                    -- explicitly prompt for a virtual line annotation when setting a bookmark from this group.
                    -- defaults to false.
                    annotate = false,
                },
                mappings = {}
            }
            vks('n', '<Leader>tm', function ()
                vim.cmd.MarksToggleSigns(vim.fn.bufnr('%'))
            end)
        end,
    }, -- }}}
    -- https://github.com/nvim-telescope/telescope.nvim
    { 'nvim-telescope/telescope.nvim',
        config = function () -- {{{
            -- call win_getid() or win_gotoid(win_findbuf(bufnr)[0])
            -- https://www.reddit.com/r/neovim/comments/11otu7l/using_telescope_selection_for_custom_function/
            -- https://github.com/nvim-telescope/telescope.nvim/issues/2188
            local actions = require("telescope.actions")
            local map_s_cr = {
                i = { ["<S-CR>"] = actions.select_tab_drop },
                n = { ["<S-CR>"] = actions.select_tab_drop },
            }
            -- layout https://www.reddit.com/r/neovim/comments/1ar56k0/how_to_see_deeply_nested_file_names_in_telescope/
            require'telescope'.setup {
                defaults = {
                    path_display = { "truncate" }, -- "smart"
                },
                pickers = {
                    buffers = {
                        mappings = map_s_cr,
                    },
                    find_files = {
                        mappings = map_s_cr,
                    },
                    git_files = {
                        mappings = map_s_cr,
                    },
                    old_files = {
                        mappings = map_s_cr,
                    },
                    live_grep = {
                        mappings = map_s_cr,
                    },
                    grep_string = {
                        mappings = map_s_cr,
                    },
                    -- https://github.com/nvim-telescope/telescope.nvim/issues/2115#issuecomment-1366575821
                    current_buffer_fuzzy_find = {

                    },
                },
            }
            vim.cmd[[
            nnoremap <D-S-f> <cmd>Telescope grep_string search=<cr>
            " https://github.com/nvim-telescope/telescope.nvim/issues/564#issuecomment-1173167550
            nnoremap <Leader>fg <cmd>Telescope live_grep<cr>
            nnoremap <D-p> <cmd>Telescope find_files follow=true<cr>
            nnoremap <leader>ff <cmd>Telescope oldfiles<cr>
            nnoremap <leader>fb <cmd>Telescope buffers<cr>
            nnoremap <leader>fh <cmd>Telescope help_tags<cr>
            nnoremap <leader>ft <cmd>Telescope tags<cr>
            nnoremap <leader>fc <cmd>Telescope commands<cr>
            nnoremap <leader>fC <cmd>Telescope commands_history<cr>
            nnoremap <leader>fm <cmd>Telescope marks<cr>
            nnoremap <leader>fr <cmd>Telescope registers<cr>
            " https://github.com/nvim-telescope/telescope.nvim/issues/394
            nnoremap <leader>fv <cmd>Telescope find_files follow=true search_dirs=~/.local/share/nvim<cr>
            nnoremap <leader>fn :Telescope find_files search_dirs=<C-R>=g:xell_notes_root<CR><cr>
            nnoremap <leader>fl :Telescope current_buffer_fuzzy_find<cr>
            nnoremap <leader>fR :Telescope resume<cr>
            " nmap <Leader>fl :BLines<CR>
            " nmap <Leader>fL :Lines<CR>
            " nmap <Leader>fw :Windows<CR>
            ]]
        end,
    }, -- }}}
    -- https://github.com/nvim-telescope/telescope-fzf-native.nvim
    { 'nvim-telescope/telescope-fzf-native.nvim',
    -- build = 'make', -- {{{
    -- https://www.reddit.com/r/neovim/comments/13cyyhn/search_within_current_buffer/
    config = function ()
        require('telescope').setup {
            extensions = {
                fzf = {
                    fuzzy = true,                    -- false will only do exact matching
                    override_generic_sorter = true,  -- override the generic sorter
                    override_file_sorter = true,     -- override the file sorter
                    case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                    -- the default case_mode is "smart_case"
                }
            }
        }
        -- To get fzf loaded and working with telescope, you need to call
        -- load_extension, somewhere after setup function:
        require('telescope').load_extension('fzf')
        end,
    }, -- }}}
    -- https://github.com/debugloop/telescope-undo.nvim/
    { "debugloop/telescope-undo.nvim",
        dependencies = { { -- {{{
            "nvim-telescope/telescope.nvim",
            dependencies = { "nvim-lua/plenary.nvim" },
        }, },
        keys = { { -- lazy style key map
                "<leader>u",
                "<cmd>Telescope undo<cr>",
                desc = "undo history",
        }, },
        opts = {
            -- don't use `defaults = { }` here, do this in the main telescope spec
            extensions = {
                undo = {
                    -- telescope-undo.nvim config, see below
                },
            },
        },
        config = function(_, opts)
            require("telescope").setup(opts)
            require("telescope").load_extension("undo")
        end,
    }, -- }}}
    -- https://github.com/neovim/nvim-lspconfig
    { 'neovim/nvim-lspconfig',
    config = function () -- {{{
        local lspconfig = require('lspconfig')

        -- https://github.com/neovim/nvim-lspconfig
        -- Global mappings. {{{
        -- See `:help vim.diagnostic.*` for documentation on any of the below functions
        vks('n', '<Leader><Leader>e', vim.diagnostic.open_float)
        vks('n', '[d', vim.diagnostic.goto_prev)
        vks('n', ']d', vim.diagnostic.goto_next)
        vks('n', '<Leader><Leader>q', vim.diagnostic.setloclist)

        -- Use LspAttach autocommand to only map the following keys
        -- after the language server attaches to the current buffer
        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('UserLspConfig', {}),
            callback = function(ev)
                -- lsp-defaults-disable
                vim.keymap.del("n", "K", { buffer = ev.buf })
                -- Enable completion triggered by <c-x><c-o>
                vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

                -- Buffer local mappings.
                -- See `:help vim.lsp.*` for documentation on any of the below functions
                local opts = { buffer = ev.buf }
                vks('n', 'gD', vim.lsp.buf.declaration, opts)
                vks('n', 'gd', vim.lsp.buf.definition, opts)
                vks('n', '<D-.>', vim.lsp.buf.hover, opts)
                vks('n', 'gi', vim.lsp.buf.implementation, opts)
                vks('n', '<D-k>', vim.lsp.buf.signature_help, opts)
                vks('n', '<Leader><Leader>wa', vim.lsp.buf.add_workspace_folder, opts)
                vks('n', '<Leader><Leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
                vks('n', '<Leader><Leader>wl', function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, opts)
                vks('n', '<Leader><Leader>D', vim.lsp.buf.type_definition, opts)
                vks('n', '<Leader><Leader>rn', vim.lsp.buf.rename, opts)
                vks({ 'n', 'v' }, '<Leader><Leader>ca', vim.lsp.buf.code_action, opts)
                vks('n', 'gr', vim.lsp.buf.references, opts)
                vks('n', '<Leader><Leader>f', function()
                    vim.lsp.buf.format { async = true }
                end, opts)
            end,
        }) -- }}}

        -- lua
        -- {{{
        -- https://www.reddit.com/r/neovim/comments/13uklyy/lua_ls_lspconfig_not_working/
        -- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/lua_ls.lua
        require'lspconfig'.lua_ls.setup {
            settings = {
                Lua = {
                    runtime = {
                        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                        version = 'LuaJIT',
                    },
                    diagnostics = {
                        -- Get the language server to recognize the `vim` global
                        globals = {'vim'},
                    },
                    workspace = {
                        -- Make the server aware of Neovim runtime files
                        library = vim.api.nvim_get_runtime_file("", true),
                        checkThirdParty = false,
                    },
                    -- Do not send telemetry data containing a randomized but unique identifier
                    telemetry = {
                        enable = false,
                    },
                },
            },
        }
        -- }}}
        -- vim
        -- {{{
        -- https://github.com/iamcco/vim-language-server
        -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#vimls
        require'lspconfig'.vimls.setup{
            cmd = { "vim-language-server", "--stdio" },
            filetype = { 'vim' },
            init_options = {
                diagnostic = {
                    enable = true
                },
                indexes = {
                    count = 3,
                    gap = 100,
                    projectRootPatterns = { "strange-root-pattern", "runtime", "nvim", ".git", "autoload", "plugin" },
                    runtimepath = true
                },
                isNeovim = true,
                iskeyword = "@,48-57,_,192-255,-#",
                runtimepath = "/Users/xell/.config/nvim,/Users/xell/.local/share/nvim/site",
                vimruntime = "",
                suggest = {
                    fromRuntimepath = true,
                    fromVimruntime = true
                },
            },
            single_file_support = true,
        }
        -- }}}
    end,
    }, -- }}}
    -- https://github.com/stevearc/aerial.nvim
    { 'stevearc/aerial.nvim',
        opts = {}, -- {{{
        -- Optional dependencies
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons"
        },
        config = function ()
            require("aerial").setup({
                backends = { "treesitter", "lsp", "markdown", "man" },
                -- optionally use on_attach to set keymaps when aerial has attached to a buffer
                on_attach = function(bufnr)
                    -- Jump forwards/backwards with '{' and '}'
                    vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
                    vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
                end,
            })
            -- You probably also want to set a keymap to toggle aerial
            vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>")
            require("telescope").load_extension("aerial")
            require("telescope").setup({
                extensions = {
                    aerial = {
                        -- Display symbols as <root>.<parent>.<symbol>
                        show_nesting = {
                            ["_"] = false, -- This key will be the default
                            json = true, -- You can set the option for specific filetypes
                            yaml = true,
                        },
                    },
                },
            })
        end,
    }, -- }}}
    -- https://github.com/hrsh7th/nvim-cmp
    { 'hrsh7th/nvim-cmp',
    -- event = "InsertEnter", -- {{{
    dependencies = { -- {{{
        'neovim/nvim-lspconfig',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-cmdline',
        'hrsh7th/nvim-cmp',
        -- 'hrsh7th/cmp-vsnip',
        -- 'hrsh7th/vim-vsnip',
        'L3MON4D3/LuaSnip',
        'saadparwaiz1/cmp_luasnip',
    }, -- }}}
    config = function ()
        -- Set up lspconfig.
        -- local capabilities_ = require('cmp_nvim_lsp').default_capabilities()
        -- local lspconfig = require('lspconfig')

        -- local servers = { 'vimls', 'lua_ls' }
        -- for _, lsp in ipairs(servers) do
        --     require('lspconfig')[lsp].setup {
        --         capabilities = capabilities_
        --     }
        -- end

        -- Set up lspconfig.
        local capabilities = require('cmp_nvim_lsp').default_capabilities()
        -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
        require('lspconfig')['vimls'].setup {
            capabilities = capabilities
        }

        local cmp = require'cmp'
        local luasnip = require'luasnip'
        -- Require function for tab to work with LUA-SNIP
        -- https://github.com/Abstract-IDE/Abstract/blob/820114632dbc047f8bbb62bb67fc949bd6433e90/lua/plugins/cmp.lua#L100-L121
        local has_words_before = function()
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            return col ~= 0 and
        	vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
        		:sub(col, col)
        		:match("%s") == nil
        end

        cmp.setup({ -- {{{
            snippet = {
                -- REQUIRED - you must specify a snippet engine
                expand = function(args)
                    -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            window = {
                -- completion = cmp.config.window.bordered(),
                -- documentation = cmp.config.window.bordered(),
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                -- https://www.reddit.com/r/neovim/comments/1axmx9e/trigger_completion_suggestions_manually_with/
                ['<M-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
                ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item()),
                ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item()),
                ['<Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif has_words_before() then
                        cmp.complete()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                -- { name = 'vsnip' }, -- For vsnip users.
                { name = 'luasnip' }, -- For luasnip users.
            }, {
                { name = 'buffer' },
            })
        })

        -- https://github.com/hrsh7th/nvim-cmp/issues/299
        -- https://github.com/hrsh7th/nvim-cmp/issues/1652
        -- `/` cmdline setup.
        cmp.setup.cmdline('/', {
          mapping = cmp.mapping.preset.cmdline(),
          sources = {
            { name = 'buffer' }
          }
        })

        -- `:` cmdline setup.
        cmp.setup.cmdline(':', {
          mapping = cmp.mapping.preset.cmdline(),
          sources = cmp.config.sources({
            { name = 'path' }
          }, {
            { name = 'cmdline' }
          })
        })
        -- }}}

        local cmp_enabled = true -- {{{
        -- https://github.com/hrsh7th/nvim-cmp/issues/106
        vim.api.nvim_create_user_command("CmpAutoCompleteToggle", function()
            if cmp_enabled then
                require("cmp").setup.buffer({ enabled = false })
                cmp_enabled = false
            else
                require("cmp").setup.buffer({ enabled = true })
                cmp_enabled = true
            end
        end, {})

        vim.api.nvim_create_user_command("CmpAutoCompleteEnable", function()
            require("cmp").setup.buffer({ enabled = true })
        end, {})
        vim.api.nvim_create_user_command("CmpAutoCompleteDisable", function()
            require("cmp").setup.buffer({ enabled = false })
        end, {})
        -- }}}

    end,
    }, -- }}}
    -- https://github.com/folke/trouble.nvim
    { "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" }, -- {{{
        config = function ()
            local tr = require('trouble')
            vks("n", "<leader>xx", function() tr.toggle() end)
            vks("n", "<leader>xw", function() tr.toggle("workspace_diagnostics") end)
            vks("n", "<leader>xd", function() tr.toggle("document_diagnostics") end)
            vks("n", "<leader>xq", function() tr.toggle("quickfix") end)
            vks("n", "<leader>xl", function() tr.toggle("loclist") end)
            vks("n", "gR", function() tr.toggle("lsp_references") end)
        end,
        -- https://github.com/folke/trouble.nvim/issues/369
        opts = {
            icons = true,
            signs = {
                error = "",
                warning = "",
                hint = "",
                information = "",
                other = "",
            },
            use_diagnostic_signs = true,
        },
    }, -- }}}
    -- https://github.com/sontungexpt/url-open
    { "sontungexpt/url-open",
    event = "VeryLazy", -- {{{
        cmd = "URLOpenUnderCursor",
        config = function()
            local status_ok, url_open = pcall(require, "url-open")
            if not status_ok then
                return
            end
            url_open.setup ({
                open_only_when_cursor_on_url = false,
                deep_pattern = true,
                -- a list of patterns to open url under cursor
                extra_patterns = {
                    {
                        -- FIXME it's too general
                        pattern = "([^/ %[]+%.%a%w%w*)",
                        prefix = "file://" .. string.gsub(vg.xell_notes_root, '\\', '') .. '/Notes/res/',
                        suffix = '',
                        file_patterns = "%w+%.md",
                        excluded_file_patterns = nil,
                        extra_condition = nil,
                    },
                    -- {
                    -- 	  pattern = '["]([^%s]*)["]:%s*"[^"]*%d[%d%.]*"',
                    -- 	  prefix = "https://www.npmjs.com/package/",
                    -- 	  suffix = "",
                    -- 	  file_patterns = { "package%.json" },
                    -- 	  excluded_file_patterns = nil,
                    -- 	  extra_condition = function(pattern_found)
                    -- 	    return not vim.tbl_contains({ "version", "proxy" }, pattern_found)
                    -- 	  end,
                    -- },
                    -- so the url will be https://www.npmjs.com/package/[pattern_found]


                    -- {
                    -- 	  pattern = '["]([^%s]*)["]:%s*"[^"]*%d[%d%.]*"',
                    -- 	  prefix = "https://www.npmjs.com/package/",
                    -- 	  suffix = "/issues",
                    -- 	  file_patterns = { "package%.json" },
                    -- 	  excluded_file_patterns = nil,
                    -- 	  extra_condition = function(pattern_found)
                    -- 	    return not vim.tbl_contains({ "version", "proxy" }, pattern_found)
                    -- 	  end,
                    -- },
                    --
                    -- so the url will be https://www.npmjs.com/package/[pattern_found]/issues
                },
            })
            -- https://sbulav.github.io/vim/neovim-opening-urls/
            -- map[''].gx = {'<Cmd>call jobstart(["open", expand("<cfile>")], {"detach": v:true})<CR>'}
            vks("n", "gx", vim.cmd.URLOpenUnderCursor)
        end,
    }, -- }}}
    -- https://github.com/wellle/context.vim
    { "wellle/context.vim",
        init = function () -- {{{
            vg.context_presenter = 'nvim-float'
            vg.context_add_autocmds = 0 -- slows down in large files
            vg.context_add_mappings = 0 -- conflicts with yode delbuf
        end,
        config = function ()
            vks('n', '<Leader><Leader>c', function ()
                vim.cmd[[ContextActivate]]
                vim.cmd[[ContextUpdate]]
                vim.cmd[[ContextPeek]]
            end)
            vks('n', '<Leader><Leader>C', [[:ContextToggleWindow<CR>]])
        end
    }, -- }}}
    -- https://github.com/tpope/vim-fugitive
    { 'tpope/vim-fugitive',
        config = function () -- {{{
            vks('n', '<Leader>gs', vim.cmd.G)
            vks('n', '<Leader>gd', vim.cmd.Gvdiffsplit)
        end,
    }, -- }}}
    -- https://github.com/Sam-programs/cmdline-hl.nvim
    { 'Sam-programs/cmdline-hl.nvim',
        event = 'UiEnter', -- {{{context_add_autocmds
        enabled = false,
        opts = {
            type_signs = {
                [":"] = { " ", "Title" },
                ["/"] = { " ", "Title" },
                ["?"] = { " ", "Title" },
                ["="] = { " ", "Title" },
            },
            -- custom formatting/highlight for commands
            custom_types = {
                -- ["command-name"] = {
                -- [icon],[icon_hl], default to `:` icon and highlight
                -- [lang], defaults to vim
                -- [showcmd], defaults to false
                -- [pat], defaults to "%w*%s*(.*)"
                -- [code], defaults to nil
                -- }
                -- lang is the treesitter language to use for the commands
                -- showcmd is true if the command should be displayed or to only show the icon
                -- pat is used to extract the part of the command that needs highlighting
                -- the part is matched against the raw command you don't need to worry about ranges
                -- e.g. in 's,>'s/foo/bar/
                -- pat is checked against s/foo/bar
                -- you could also use the 'code' function to extract the part that needs highlighting
                ["lua"] = { icon = " ", icon_hl = "Title", lang = "lua" },
                ["help"] = { icon = "? ", icon_hl = "Title" },
                ["substitute"] = { pat = "%w(.*)", lang = "regex", show_cmd = true },
            },
            input_hl = "Title",
            -- used to highlight the range in the command e.g. '<,>' in '<,>'s
            range_hl = "FloatBorder",
        },
    }, -- }}}
    -- https://github.com/lukas-reineke/indent-blankline.nvim
    { 'lukas-reineke/indent-blankline.nvim',
        main = "ibl", -- {{{
        -- wait for 20231218 Virtual text in indented word-wrapped area
        -- https://github.com/neovim/neovim/issues/23108
        enabled = false,
        opt = {
            -- ￨ ｜ ▏
            indent = { char = '￨', highlight = { "Whitespace" }},
        },
        config = function()
            require("ibl").setup()
        end,
    }, -- }}}
    -- https://github.com/jackMort/ChatGPT.nvim
    { "jackMort/ChatGPT.nvim",
        event = "VeryLazy", -- {{{
        config = function()
            require("chatgpt").setup({
                api_key_cmd = "op read op://Personal/OpenAI/credential --no-newline",
                openai_params = {
                    model = "gpt-4-turbo-preview",
                    -- model = "gpt-4",
                    max_tokens = 3000,
                },
                openai_edit_params = {
                    model = "gpt-4-turbo-preview",
                    -- model = "gpt-4",
                    max_tokens = 3000,
                },
            })
            vks('n', '<Leader><Leader>g', [[:ChatGPT<CR>]])
            vks('n', '<Leader><Leader>G', function ()
                require("chatgpt.flows.chat").chat:redraw()
                vim.print("ChatGPT redrew.")
            end)
        end,
        dependencies = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "folke/trouble.nvim",
            "nvim-telescope/telescope.nvim"
        },
    }, -- }}}
    -- https://github.com/numToStr/Comment.nvim
    { 'numToStr/Comment.nvim',
        opts = { -- {{{
            -- add any options here
        },
        config = function()
            require('Comment').setup()
        end,
        lazy = false,
    }, -- }}}
    -- https://github.com/IsWladi/Gittory
    { "IsWladi/Gittory",
    branch = "main", -- {{{
    dependencies = {
        -- {"rcarriga/nvim-notify"}, -- optional
    },
    config = true,
    opts = { -- you can omit this, is the default
          -- notify = "yes", -- by default "yes":
          atStartUp = "yes" -- by default "yes": If you want to initialize Gittory when Neovim starts
    },
  }, -- }}}
    -- https://github.com/folke/twilight.nvim
    { "folke/twilight.nvim",
    opts = { -- {{{
        dimming = {
            alpha = 0.25, -- amount of dimming
            -- we try to get the foreground from the highlight groups or fallback color
            color = { "Normal", "#ffffff" },
            term_bg = "#000000", -- if guibg=NONE, this will be used to calculate text color
            inactive = false, -- when true, other windows will be fully dimmed (unless they contain the same buffer)
        },
        context = 2, -- amount of lines we will try to show around the current line
        treesitter = false, -- use treesitter when available for the filetype
        -- treesitter is used to automatically expand the visible text,
        -- but you can further control the types of nodes that should always be fully expanded
        expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
            "function",
            "method",
            "table",
            "if_statement",
        },
        exclude = {}, -- exclude these filetypes
    }, -- }}}
    -- https://github.com/junegunn/limelight.vim
    { "junegunn/limelight.vim",
        init = function() -- {{{
            vg.limelight_paragraph_span = 1
            vg.limelight_priority = -1
        end,
    }, -- }}}
    -- https://github.com/karb94/neoscroll.nvim
    { "karb94/neoscroll.nvim",
        config = function () -- {{{
            require('neoscroll').setup()
        end
    }, -- }}}
},
}, {
    dev = {
        path = "~/Developer/vim/scripts",
        fallback = true,
    },
})

-- }}}

-- Misc {{{
-- vks('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })
-- toggle fold
vim.cmd[[nnoremap <Space> @=((foldclosed(line('.')) < 0)?'zc':'zo')<CR>]]
-- command mode to search
vks('c', '<C-k>', '<Up>')
vks('c', '<C-j>', '<Down>')

-- source / run
vks('n', '<D-r>', [[:so %<CR>]])

-- google search selection
-- or better https://github.com/lalitmee/browse.nvim
vks('v', '<D-g>', function ()
    -- os.execute("sleep " .. tostring(0.5))
    vim.cmd.normal[["zy]]
    vim.ui.open("https://www.google.com/search?q=" .. uri_encode(vf.eval('@z')) .. "")
end)

-- look up word in dictionary
vks('n', '<D-d>', function ()
    vim.ui.open('dict://' .. vf.expand("<cword>"))
end)

-- goto for next or previous link {{{
vg.url_pattern = [[[[:alpha:]-]\+:\/\/[^ "'>\])]\+]]
vg.markdown_link_pattern = [[\(\[[^\^]\{-}\]\([:\[]\)\@!\(([^ ]\{-}\%(\s"[^"]\{-}"\)\?)\)\?\)]]
vg.link_pattern = vg.url_pattern .. [[\|]] .. vg.markdown_link_pattern
-- vg.link_pattern = [[\(\[[^\^]\{-}\]\([:\[]\)\@!\(([^ ]\{-}\%(\s"[^"]\{-}"\)\?)\)\?\)\|[[:alpha:]-]\+:\/\/[^ "'>\])]\+]]
local function move_cursor_to_link (backward)
    local link_pattern = vim.b.link_pattern or vg.link_pattern
    vf.search(link_pattern, 's' .. backward)
end
vks('n', 'gn', function () move_cursor_to_link('') end)
vks('n', 'gN', function () move_cursor_to_link('b') end)
-- }}}

-- get word count -- {{{
vim.cmd[[
command! -range=% Num :call NumberOfChars()
function! NumberOfChars() range
	"count double-byte characters
	redir => numChs
	"silent! execute a:firstline.",".a:lastline."s/[^\\x00-\\xff]/&/gn"
	silent! execute "'<,'>s/[^\\x00-\\xff]/&/gn"
	redir END
	if match(numChs,"E486") > 0
		let numC = 0
	else
		let numC = strpart(numChs, 0, stridx(numChs," "))
	endif

	"count english words
	redir => numEng
	silent! execute "'<,'>s/\\<\\(\\w\\|-\\|'\\)\\+\\>/&/gn"
	redir END
	if match(numEng,"E486") > 0
		let numE = 0
    else
		let numE = strpart(numEng, 0, stridx(numEng," "))
	endif

	"echo to vim
	echo ""
	echo numC . " 个中文字符"
	echo numE . " 个英文词语"
endfunction
]] -- }}}

-- diffthis
vim.api.nvim_create_user_command('Diffthis', function ()
    vim.cmd.diffthis()
    vim.cmd.normal(k('<C-w>w'))
    vim.cmd.diffthis()
end, {})

-- spell including cjk
vim.api.nvim_create_user_command('Spell', function ()
    if vol.spell:get() then
        vol.spell = false
    else
        vol.spell = true
        vol.spelllang = 'en_gb,cjk'
        -- https://stackoverflow.com/questions/18196399/exclude-capitalized-words-from-vim-spell-check
        -- vim.cmd[[syn match myExCapitalWords +\<\w*[A-Z]\K*\>\|'s+ contains=@NoSpell]]
    end
end, {})

-- abbrevs
vks('ca', 'xfn', 'echo expand("%:p")')
vks('ia', 'xdate', '<C-r>=strftime("%Y-%m-%d %H:%M:%S")<CR>')

-- https://vi.stackexchange.com/questions/25130/close-buffer-in-the-other-instance
-- https://github.com/vim/vim/blob/master/runtime/pack/dist/opt/editexisting/plugin/editexisting.vim
-- vim.cmd.runtime('macros/editexisting.vim')

-- }}}

-- UI GUI {{{
vo.equalalways = false
vo.scrolloff = 10
vo.listchars = 'tab:▸\\ ,eol:¬'
--- nvim-spec
-- vo.fillchars = 'vert: ,eob: '
vo.fillchars = {
    fold = " ",
    foldopen = "",
    foldclose = "",
    foldsep = " ",
    diff = "╱",
    eob = " ",
    vert = " ",
}
vim.cmd[[hi default link WinSeparator VertSplit]]
--- TUI cursor
if vf.has('gui_running') == 0 then
    vim.api.nvim_create_autocmd(
    {'VimLeave', 'VimSuspend'},
    {
        pattern = { "*" },
        callback = function ()
            vo.guicursor = 'a:hor20-blinkon0'
        end
    })
end
-- set lsp diagnostic signs
-- https://www.reddit.com/r/neovim/comments/13vlv9z/how_would_i_change_the_icon_of_the_error_message/
-- https://www.reddit.com/r/neovim/comments/10j0vyf/finally_figured_out_a_statuscolumn_i_am_happy/
vf.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
vf.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
vf.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
vf.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })
-- vertical separator
vim.cmd[[hi default link Pmenu WildMenu]]
-- reload current colorscheme
vim.api.nvim_create_user_command('ReloadColorscheme', function ()
    vim.cmd.colorscheme(vim.api.nvim_exec2('colorscheme', {output = true})["output"])
end, {})
-- toggle relativenumber
vks('n', '<Leader>nn', function ()
    vo.relativenumber = not vo.relativenumber:get()
end)
-- set colorcolumn cc
vks('n', '<Leader>hc', function ()
    local col = vf.virtcol('.')
    local colorcolumn_list = vo.colorcolumn:get()
    for _, v in pairs(colorcolumn_list) do
        if v == '' .. col then
            vo.colorcolumn:remove('' .. v)
            return
        end
    end
    vo.colorcolumn:append('' .. col)
end)
--- }}}

