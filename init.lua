-- vim:fdm=marker
-- xell neovim nvim config

--[[ TODO
- cursor
- url open web
- signcolumn
--]]

-- vim.print("hello")

-- https://www.reddit.com/r/neovim/comments/12bmzjk/reduce_neovim_startup_time_with_plugins/
vim.loader.enable()

vim.g.mapleader = ","
vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.iskeyword:append('-')
vim.opt.autochdir = true
vim.opt.breakindent = true
vim.opt.breakindentopt = "list:-2"
vim.opt.foldcolumn = 'auto' -- nvim-spec
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.concealcursor = 'nc'
vim.opt.laststatus = 2 -- nvim-spec
vim.opt.shortmess:append('I')
vim.opt.visualbell = true
vim.opt.exrc = true

local xell_note_root_raw = '~/Library/Mobile\\ Documents/iCloud~md~obsidian/Documents/Notes'
vim.g.xell_notes_root = vim.fn.fnameescape(vim.fn.glob(xell_note_root_raw))

-- Helper functions {{{
local function k(keys) -- {{{ get keycodes
    return vim.api.nvim_replace_termcodes(keys, true, true, true)
end -- }}}

local function uri_encode(string) -- {{{
    return vim.fn.substitute(vim.fn.iconv(string, 'latin1', 'utf-8'),'[^A-Za-z0-9_.~-]','\\="%".printf("%02X",char2nr(submatch(0)))','g')
end -- }}}
-- }}}

-- Windows and tab {{{

-- window size TODO
vim.keymap.set('n', '<M-->', '<C-w>-')
vim.keymap.set('n', '<M-=>', '<C-w>+')
vim.keymap.set('n', '<M-,>', '<C-w><')
vim.keymap.set('n', '<M-.>', '<C-w>>')

-- <M-n> goes to the n window
for i = 1, 10 do
    vim.keymap.set(
        'n',
        '<M-' .. i .. '>',
        i .. '<c-w><c-w>'
        )
end

-- <M-h/j/k/l>
for c in ("hjkl"):gmatch"." do
    vim.keymap.set('n', '<M-' .. c .. '>', '<C-w>' .. c)
end

-- <Backspace> to jump between two recent windows
vim.keymap.set('n', '<Backspace>', function()
    local ori_win_nr = vim.api.nvim_win_get_number(0)
    -- vim.cmd('exec "normal \\<c-w>\\<c-p>"')
    vim.cmd.normal(k('<c-w><c-p>'))
    local cur_win_nr = vim.api.nvim_win_get_number(0)
    if ori_win_nr == cur_win_nr then
        vim.cmd.normal(k('<c-w><c-w>'))
    end
end, {silent = true})

-- split
vim.keymap.set('n', '<Leader>s', vim.cmd.split)
vim.keymap.set('n', '<Leader>v', vim.cmd.vsplit)

-- close
vim.keymap.set('n', '<Leader>c', '<C-w>c')
vim.keymap.set('n', '<Leader>o', '<C-w>o')

-- tab, next and previous
vim.keymap.set('n', '<S-D-{>', 'gT')
vim.keymap.set('n', '<S-D-}>', 'gt')

-- window full screen plugin
vim.keymap.set('n', '<C-Enter>', vim.cmd.WinFullScreen)

--- }}}

-- Editing {{{

-- <D-s> update/write
vim.keymap.set({ 'n', 'i' }, '<D-s>', function()
    -- no need to distinguish n and i and use <Esc> to escape the latter
    print(select(2, pcall(vim.cmd.update)))
end)

-- hack for highlight, re-set the filetype
vim.keymap.set('n', '<C-L>', function ()
    vim.opt_local.filetype = vim.opt.filetype:get()
end)

-- - to $
vim.keymap.set('', '-', '$')

-- source the visual selection
vim.keymap.set('v', '<C-s>', 'y:@"<CR>')

-- page up / down
vim.keymap.set('', '<C-k>', '<C-b>')
vim.keymap.set('', '<C-j>', '<C-f>')

-- search
vim.keymap.set('n', '<Leader>ns', function() vim.fn.setreg('/', '') end)
vim.keymap.set('n', '<Leader>nh', function() vim.opt.hlsearch = false end)
vim.keymap.set('n', '<Leader>h', function () vim.opt.hlsearch = not vim.o.hlsearch end)

vim.api.nvim_create_autocmd(
{'TextYankPost'},
{
    pattern = { "*" },
    callback = function()
        vim.highlight.on_yank({timeout = 1000})
    end,
})
--- }}}

-- Completion {{{
vim.opt.omnifunc = 'syntaxcomplete#Complete'
vim.opt.dictionary = '/usr/share/dict/words'
vim.opt.complete:append('k')
vim.opt.infercase = true
vim.keymap.set('i', '<D-d>', '<C-x><C-k>')
--- }}}

-- Plugins {{{

-- lazy {{{
-- https://github.com/folke/lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
-- }}}

require("lazy").setup({
    -- https://github.com/ybian/smartim
    { 'ybian/smartim',
        init = function () -- {{{
            vim.g.smartim_default = 'com.apple.keylayout.ABC'
            -- let g:smartim_disable = 1
            -- unlet g:smartim_disable
            -- autocmd InsertLeave * :silent !/usr/local/bin/im-select com.apple.keylayout.ABC
            -- autocmd UIEnter * set noimd
        end,
    }, -- }}}
    -- https://github.com/xiyaowong/fast-cursor-move.nvim remap j k
    'xiyaowong/fast-cursor-move.nvim',
    -- https://github.com/vimpostor/vim-lumen
    { 'vimpostor/vim-lumen',
        config = function () -- {{{
            if vim.fn.has('gui_running') == 1 then
                -- vim.print('gui_running')
                vim.cmd[[au User LumenLight nested colorscheme onehalflight]]
                vim.cmd[[au User LumenDark nested colorscheme onehalfdark]]
                vim.cmd.colorscheme(vim.o.background == 'light' and 'onehalflight' or 'onehalfdark')
            else
                vim.opt.background = 'dark'
            end
        end,
    }, -- }}}
    -- https://github.com/easymotion/vim-easymotion
    { 'easymotion/vim-easymotion',
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
            noremap <Leader>/ <Plug>(easymotion-s)
            ]]
        end,
    }, -- }}}
    --  https://www.v2ex.com/t/856921
    'zzhirong/vim-easymotion-zh',
    -- https://github.com/nvim-lua/plenary
    'nvim-lua/plenary.nvim',
    -- https://github.com/hoschi/yode-nvim
    { 'hoschi/yode-nvim',
        config = function () -- {{{
            -- according to readme, submodule should be used
            require('yode-nvim').setup({})
            -- vim.keymap.set({ '' }, '<Leader>yc', vim.cmd.YodeCreateSeditorFloating)
            -- vim.keymap.set('', '<Leader>yr', vim.cmd.YodeCreateSeditorReplace)
            -- vim.keymap.set('n', '<Leader>yd', vim.cmd.YodeBufferDelete)
            vim.cmd[[
            map <Leader>yc :YodeCreateSeditorFloating<CR>
            map <Leader>yr :YodeCreateSeditorReplace<CR>
            nmap <Leader>yd :YodeBufferDelete<cr>
            ]]
        end,
    }, -- }}}
    { dir = vim.fn.stdpath('data') .. '/site' },
    { dir = vim.fn.stdpath('data') .. '/site/pack/main/start/winfullscreen' },
    { dir = vim.fn.stdpath('data') .. '/site/pack/xell/start/outlinex' },
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
    -- https://github.com/neovim/nvim-lspconfig
    { 'neovim/nvim-lspconfig',
    config = function () -- {{{
        local lspconfig = require('lspconfig')

        -- https://github.com/neovim/nvim-lspconfig
        -- Global mappings. {{{
        -- See `:help vim.diagnostic.*` for documentation on any of the below functions
        vim.keymap.set('n', '<Leader><Leader>e', vim.diagnostic.open_float)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
        vim.keymap.set('n', '<Leader><Leader>q', vim.diagnostic.setloclist)

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
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                vim.keymap.set('n', '<D-.>', vim.lsp.buf.hover, opts)
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
                vim.keymap.set('n', '<Leader><Leader>wa', vim.lsp.buf.add_workspace_folder, opts)
                vim.keymap.set('n', '<Leader><Leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
                vim.keymap.set('n', '<Leader><Leader>wl', function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, opts)
                vim.keymap.set('n', '<Leader><Leader>D', vim.lsp.buf.type_definition, opts)
                vim.keymap.set('n', '<Leader><Leader>rn', vim.lsp.buf.rename, opts)
                vim.keymap.set({ 'n', 'v' }, '<Leader><Leader>ca', vim.lsp.buf.code_action, opts)
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
                vim.keymap.set('n', '<Leader><Leader>f', function()
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
        }) -- }}}

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
            vim.keymap.set("n", "<leader>xx", function() tr.toggle() end)
            vim.keymap.set("n", "<leader>xw", function() tr.toggle("workspace_diagnostics") end)
            vim.keymap.set("n", "<leader>xd", function() tr.toggle("document_diagnostics") end)
            vim.keymap.set("n", "<leader>xq", function() tr.toggle("quickfix") end)
            vim.keymap.set("n", "<leader>xl", function() tr.toggle("loclist") end)
            vim.keymap.set("n", "gR", function() tr.toggle("lsp_references") end)
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
            vim.keymap.set("n", "gx", vim.cmd.URLOpenUnderCursor)
        end,
    }, -- }}}
})

-- }}}

-- Misc {{{
-- vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })
-- toggle fold
vim.cmd[[nnoremap <Space> @=((foldclosed(line('.')) < 0)?'zc':'zo')<CR>]]
-- command mode to search
vim.keymap.set('c', '<C-k>', '<Up>')
vim.keymap.set('c', '<C-j>', '<Down>')

-- source / run
vim.keymap.set('n', '<D-r>', [[:so %<CR>]])

-- google search selection
-- or better https://github.com/lalitmee/browse.nvim
vim.keymap.set('v', '<D-g>', function ()
    -- os.execute("sleep " .. tostring(0.5))
    vim.cmd.normal[["zy]]
    vim.ui.open("https://www.google.com/search?q=" .. uri_encode(vim.fn.eval('@z')) .. "")
end)

-- look up word in dictionary
vim.keymap.set('n', '<D-d>', function ()
    vim.ui.open('dict://' .. vim.fn.expand("<cword>"))
end)

-- goto for next or previous link {{{
vim.g.url_pattern = [[[[:alpha:]-]\+:\/\/[^ "'>\])]\+]]
vim.g.markdown_link_pattern = [[\(\[[^\^]\{-}\]\([:\[]\)\@!\(([^ ]\{-}\%(\s"[^"]\{-}"\)\?)\)\?\)]]
vim.g.link_pattern = vim.g.url_pattern .. [[\|]] .. vim.g.markdown_link_pattern
-- vim.g.link_pattern = [[\(\[[^\^]\{-}\]\([:\[]\)\@!\(([^ ]\{-}\%(\s"[^"]\{-}"\)\?)\)\?\)\|[[:alpha:]-]\+:\/\/[^ "'>\])]\+]]
local function move_cursor_to_link (backward)
    local link_pattern = vim.b.link_pattern or vim.g.link_pattern
    vim.fn.search(link_pattern, 's' .. backward)
end
vim.keymap.set('n', 'gn', function () move_cursor_to_link('') end)
vim.keymap.set('n', 'gN', function () move_cursor_to_link('b') end)
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

-- }}}

--- UI GUI {{{
    --- nvim-spec
    -- vim.opt.fillchars = 'vert: ,eob: '
    vim.opt.fillchars = {
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
    if vim.fn.has('gui_running') == 0 then
        vim.api.nvim_create_autocmd(
        {'VimLeave', 'VimSuspend'},
        {
            pattern = { "*" },
            callback = function ()
                vim.opt.guicursor = 'a:hor20-blinkon0'
            end
        })
    end
    -- set lsp diagnostic signs
    -- https://www.reddit.com/r/neovim/comments/13vlv9z/how_would_i_change_the_icon_of_the_error_message/
    -- https://www.reddit.com/r/neovim/comments/10j0vyf/finally_figured_out_a_statuscolumn_i_am_happy/
    vim.fn.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
    vim.fn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
    vim.fn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
    vim.fn.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })
    -- vertical separator
    vim.cmd[[hi default link Pmenu WildMenu]]
--- }}}

-- https://github.com/tyru/open-browser.vim uri

-- https://www.reddit.com/r/neovim/comments/18ffxmc/exrcnvim_utilities_for_writing_and_managing/
vim.api.nvim_create_autocmd({'VimEnter', 'BufRead'}, {
    callback = function()
        local file = vim.secure.read(vim.fn.getcwd() .. "/.nvim.lua")
        if file ~= nil then
            local f = loadstring(file)
            if f ~= nil then f() end
        end
    end,
})

vim.g.markdown_folding = 1
