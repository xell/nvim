-- vim:fdm=marker:foldlevel=0
-- xell neovim nvim config

-- init-old, to be removed

-- leftovers {{{
-- https://www.reddit.com/r/neovim/comments/12bmzjk/reduce_neovim_startup_time_with_plugins/
vim.loader.enable()
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua;"
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua;"

-- https://vi.stackexchange.com/questions/3964/timeoutlen-breaks-leader-and-vim-commentary
-- vo.timeoutlen = 500
-- vo.ttimeoutlen = 0

-- ?? mathematica
vg.filetype_m = 'mma'
-- ?? sh filetype, see *sh.vim*
vg.is_bash = 1
vg.sh_fold_enabled = 3

-- https://www.reddit.com/r/neovim/comments/18ffxmc/exrcnvim_utilities_for_writing_and_managing/
vim.o.exrc = true
vim.api.nvim_create_autocmd({ 'VimEnter', 'BufRead' }, {
    callback = function()
        local file = vim.secure.read(vf.getcwd() .. "/.nvim.lua")
        if file ~= nil then
            local f = loadstring(file)
            if f ~= nil then f() end
        end
    end,
})

vim.cmd [[hi default link WinSeparator VertSplit]]
--- TUI cursor
if vf.has('gui_running') == 0 then
    vim.api.nvim_create_autocmd(
        { 'VimLeave', 'VimSuspend' },
        {
            pattern = { "*" },
            callback = function()
                -- vo.guicursor = 'a:hor20-blinkon0'
            end
        })
end
-- vertical separator ???
vim.cmd [[hi default link Pmenu WildMenu]]
-- }}}

-- vks('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })
-- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- lua print(require'nvim-treesitter.parsers'.has_parser('markdown'))

-- Plugins {{{

-- disabled {{{
local _ = {
    -- https://github.com/ybian/smartim
    {
        'xell/smartim',
        enabled = false, -- {{{
        dev = true,
        init = function()
            vg.smartim_default = 'com.apple.keylayout.ABC'
        end,
    }, -- }}}
    -- https://github.com/vimpostor/vim-lumen
    {
        'vimpostor/vim-lumen',
        enabled = false,
        init = function() -- {{{
            if vim.env.TERM_PROGRAM == 'WezTerm' then
                vim.g.lumen_light_colorscheme = 'onehalflight'
                vim.g.lumen_dark_colorscheme = 'onehalfdark'
            else
                vim.g.lumen_light_colorscheme = 'onehalflight'
                vim.g.lumen_dark_colorscheme = 'onehalfdark'
            end
        end,
        config = function()
            vim.cmd [[au User LumenLight nested colorscheme onehalflight]]
            vim.cmd [[au User LumenDark nested colorscheme onehalfdark]]
            vim.cmd.colorscheme(vim.o.background == 'light' and 'onehalflight' or 'onehalfdark')
        end,
    }, -- }}}
    -- https://github.com/Sam-programs/cmdline-hl.nvim
    {
        'Sam-programs/cmdline-hl.nvim',
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
    -- https://github.com/numToStr/Comment.nvim
    {
        'numToStr/Comment.nvim',
        enabled = false,
        opts = { -- {{{
            -- add any options here
        },
        config = function()
            require('Comment').setup()
        end,
        lazy = false,
    }, -- }}}
    -- https://github.com/vhyrro/hologram.nvim
    {
        'vhyrro/hologram.nvim',
        enabled = false, -- {{{
        config = function()
            require("hologram").setup({
                auto_display = true,
            })
        end,
    }, -- }}}
    -- https://github.com/zzhirong/hop-zh-by-flypy
    {
        'xell/hop-zh-by-flypy',
        enabled = false,
        dev = true, -- {{{
        dependencies = {
            'smoka7/hop.nvim',
        },
        config = function()
            local hop_flypy = require "hop-zh-by-flypy"
            hop_flypy.setup({
                -- 注意: 本扩展的默认映射覆盖掉了一些常用的映射: f, F, t, T, s
                -- 设置 set_default_mappings 为 false 可关闭默认映射.
                set_default_mappings = true,
            })
        end
    }, -- }}}
    -- https://github.com/mcchrish/zenbones.nvim
    {
        "mcchrish/zenbones.nvim",
        enabled = false, -- {{{
        dependencies = {
            "rktjmp/lush.nvim",
        },
    }, -- }}}
}
-- }}}

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
    -- https://github.com/keaising/im-select.nvim
    {
        'keaising/im-select.nvim',
        config = function() -- {{{
            require("im_select").setup({
                -- IM will be set to `default_im_select` in `normal` mode
                -- For Windows/WSL, default: "1033", aka: English US Keyboard
                -- For macOS, default: "com.apple.keylayout.ABC", aka: US
                -- For Linux, default:
                --               "keyboard-us" for Fcitx5
                --               "1" for Fcitx
                --               "xkb:us::eng" for ibus
                -- You can use `im-select` or `fcitx5-remote -n` to get the IM's name
                default_im_select       = "com.apple.keylayout.ABC",

                -- Can be binary's name or binary's full path,
                -- e.g. 'im-select' or '/usr/local/bin/im-select'
                -- For Windows/WSL, default: "im-select.exe"
                -- For macOS, default: "im-select"
                -- For Linux, default: "fcitx5-remote" or "fcitx-remote" or "ibus"
                default_command         = '/usr/local/bin/im-select',

                -- Restore the default input method state when the following events are triggered
                -- set_default_events = { "VimEnter", "FocusGained", "InsertLeave", "CmdlineLeave" },
                set_default_events      = { "VimEnter", "InsertLeave", "CmdlineLeave" },

                -- Restore the previous used input method state when the following events
                -- are triggered, if you don't want to restore previous used im in Insert mode,
                -- e.g. deprecated `disable_auto_restore = 1`, just let it empty
                -- as `set_previous_events = {}`
                set_previous_events     = { "InsertEnter" },

                -- Show notification about how to install executable binary when binary missed
                keep_quiet_on_no_binary = false,

                -- Async run `default_command` to switch IM or not
                async_switch_im         = true,
            })
        end,
    }, -- }}}
    -- https://github.com/xiyaowong/fast-cursor-move.nvim remap j k
    {
        'xiyaowong/fast-cursor-move.nvim',
        dev = true, -- {{{
        -- lazy = false,
        -- priority = 1000,
    }, -- }}}
    -- https://github.com/f-person/auto-dark-mode.nvim?tab=readme-ov-file
    {
        "f-person/auto-dark-mode.nvim",
        opts = { -- {{{
            update_interval = 1000,
            set_dark_mode = function()
                vo.background = 'dark'
                vim.cmd("colorscheme onehalfdark")
            end,
            set_light_mode = function()
                vo.background = 'light'
                vim.cmd("colorscheme onehalflight")
            end,
        },
    }, -- }}}
    -- https://github.com/easymotion/vim-easymotion
    {
        'xell/vim-easymotion',
        init = function() -- {{{
            -- added temp fix for fold
            -- https://github.com/timsu92/vim-easymotion/pull/2/files
            -- https://github.com/easymotion/vim-easymotion/issues/484
            -- https://github.com/easymotion/vim-easymotion/issues/452
            vim.cmd [[
            let g:EasyMotion_leader_key=";"
            let g:EasyMotion_skipfoldedline=0
            let g:EasyMotion_space_jump_first=1
            let g:EasyMotion_move_highlight = 0
            let g:EasyMotion_use_migemo = 1
            ]]
        end,
        config = function()
            vim.cmd [[
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
            nnoremap ;/ <Plug>(easymotion-s)
            ]]
        end,
    }, -- }}}
    --  https://www.v2ex.com/t/856921
    { 'zzhirong/vim-easymotion-zh' },
    -- https://github.com/smoka7/hop.nvim
    {
        'smoka7/hop.nvim',
        version = "*", -- {{{
        config = function()
            local hop = require('hop')
            hop.setup {
                keys = 'etovxqpdygfblzhckisuran',
                multi_windows = true,
                create_hl_autocmd = true,
            }
            vks('', '<Leader>/', function()
                hop.hint_patterns()
            end)
        end,
    }, -- }}}
    -- https://github.com/nvim-lua/plenary
    { 'nvim-lua/plenary.nvim' },
    -- https://github.com/xell/yode-nvim
    {
        'xell/yode-nvim',
        dev = true,
        config = function() -- {{{
            -- according to readme, submodule should be used
            require('yode-nvim').setup({})
            -- vks({ '' }, '<Leader>yc', vim.cmd.YodeCreateSeditorFloating)
            -- vks('', '<Leader>yr', vim.cmd.YodeCreateSeditorReplace)
            -- vks('n', '<Leader>yd', vim.cmd.YodeBufferDelete)
            vim.cmd [[
            map <Leader>yc :YodeCreateSeditorFloating<CR>
            map <Leader>yr :YodeCreateSeditorReplace<CR>
            nmap <Leader>yd :YodeBufferDelete<cr>
            ]]
        end,
    }, -- }}}
    -- { dir = vf.stdpath('data') .. '/site' },
    { dir = vf.stdpath('config') .. '/pack/main/start/winfullscreen' },
    {
        dir = vf.stdpath('config') .. '/pack/xell/start/outlinex',
        init = function() -- {{{
            vg.seditor_table = {}
        end,
    }, -- }}}
    --  https://github.com/chentoast/marks.nvim
    {
        'chentoast/marks.nvim',
        config = function() -- {{{
            -- https://www.reddit.com/r/neovim/comments/q7bgwo/marksnvim_a_plugin_for_viewing_and_interacting/
            require 'marks'.setup {
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
                sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
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
            vks('n', '<Leader>mt', function()
                vim.cmd.MarksToggleSigns(vim.fn.bufnr('%'))
            end)
        end,
    }, -- }}}
    -- https://github.com/nvim-telescope/telescope.nvim
    {
        'nvim-telescope/telescope.nvim',
        config = function() -- {{{
            -- call win_getid() or win_gotoid(win_findbuf(bufnr)[0])
            -- https://www.reddit.com/r/neovim/comments/11otu7l/using_telescope_selection_for_custom_function/
            -- https://github.com/nvim-telescope/telescope.nvim/issues/2188
            local actions = require("telescope.actions")
            local map_s_cr = {
                i = { ["<S-CR>"] = actions.select_tab_drop },
                n = { ["<S-CR>"] = actions.select_tab_drop },
            }
            -- layout https://www.reddit.com/r/neovim/comments/1ar56k0/how_to_see_deeply_nested_file_names_in_telescope/
            require 'telescope'.setup {
                defaults = {
                    path_display = { "truncate" }, -- "smart"
                    -- color_devicons = true,
                    layout_strategy = "flex",
                    layout_config = {
                        -- vertical = { width = 0.5 },
                        flex = { flip_columns = 110, },
                        preview_cutoff = 10,
                    },
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
            vim.cmd [[
            nnoremap <Leader>fF <cmd>Telescope grep_string search=<cr>
            " https://github.com/nvim-telescope/telescope.nvim/issues/564#issuecomment-1173167550
            nnoremap <Leader>fg <cmd>Telescope live_grep<cr>
            nnoremap <Leader>fp <cmd>Telescope find_files follow=true<cr>
            nnoremap <Leader>ff <cmd>Telescope oldfiles<cr>
            nnoremap <Leader>fb <cmd>Telescope buffers<cr>
            nnoremap <Leader>fh <cmd>Telescope help_tags<cr>
            nnoremap <Leader>fH <cmd>Telescope heading<cr>
            nnoremap <Leader>ft <cmd>Telescope tags<cr>
            nnoremap <Leader>fc <cmd>Telescope commands<cr>
            nnoremap <Leader>fC <cmd>Telescope colorscheme<cr>
            nnoremap <Leader>fm <cmd>Telescope marks<cr>
            nnoremap <Leader>fr <cmd>Telescope registers<cr>
            " https://github.com/nvim-telescope/telescope.nvim/issues/394
            nnoremap <Leader>fv <cmd>Telescope find_files follow=true search_dirs=~/.local/share/nvim<cr>
            nnoremap <Leader>fn :Telescope find_files search_dirs=<C-R>=g:xell_notes_root<CR><cr>
            nnoremap <Leader>fl :Telescope current_buffer_fuzzy_find<cr>
            nnoremap <Leader>fR :Telescope resume<cr>
            " nmap <Leader>fl :BLines<CR>
            " nmap <Leader>fL :Lines<CR>
            " nmap <Leader>fw :Windows<CR>
            ]]
        end,
    }, -- }}}
    -- https://github.com/nvim-telescope/telescope-fzf-native.nvim
    {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- build = 'make', -- {{{
        -- https://www.reddit.com/r/neovim/comments/13cyyhn/search_within_current_buffer/
        config = function()
            require('telescope').setup {
                extensions = {
                    fzf = {
                        fuzzy = true,                   -- false will only do exact matching
                        override_generic_sorter = true, -- override the generic sorter
                        override_file_sorter = true,    -- override the file sorter
                        case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
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
    {
        "debugloop/telescope-undo.nvim",
        dependencies = { { -- {{{
            "nvim-telescope/telescope.nvim",
            dependencies = { "nvim-lua/plenary.nvim" },
        }, },
        -- lazy style key map
        keys = {
            { "<leader>u", [[:Telescope undo<CR><Esc>]], desc = "undo history", },
        },
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
    {
        'neovim/nvim-lspconfig',
        config = function() -- {{{
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
                    vks('n', '<Leader><Leader>h', vim.lsp.buf.hover, opts)
                    vks('n', 'gi', vim.lsp.buf.implementation, opts)
                    vks('n', '<Leader><Leader>k', vim.lsp.buf.signature_help, opts)
                    vks('n', '<Leader><Leader>wa', vim.lsp.buf.add_workspace_folder, opts)
                    vks('n', '<Leader><Leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
                    vks('n', '<Leader><Leader>wl', function()
                        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                    end, opts)
                    vks('n', '<Leader><Leader>D', vim.lsp.buf.type_definition, opts)
                    vks('n', '<Leader><Leader>n', vim.lsp.buf.rename, opts)
                    vks({ 'n', 'v' }, '<Leader><Leader>ca', vim.lsp.buf.code_action, opts)
                    vks('n', '<Leader><Leader>r', vim.lsp.buf.references, opts)
                    vks('n', '<Leader><Leader>f', function()
                        vim.lsp.buf.format { async = true }
                    end, opts)
                end,
            }) -- }}}

            -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

            -- javascript typescript
            -- {{{
            require 'lspconfig'.tsserver.setup {
                init_options = {
                    -- plugins = {
                    --     {
                    --         name = "@vue/typescript-plugin",
                    --         location = "/usr/local/lib/node_modules/@vue/typescript-plugin",
                    --         languages = {"javascript", "typescript", "vue"},
                    --     },
                    -- },
                },
                filetypes = {
                    "javascript",
                    "typescript",
                    -- "vue",
                },
            }
            -- }}}
            -- lua
            -- {{{
            -- https://www.reddit.com/r/neovim/comments/13uklyy/lua_ls_lspconfig_not_working/
            -- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/lua_ls.lua
            require 'lspconfig'.lua_ls.setup {
                settings = {
                    Lua = {
                        runtime = {
                            -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                            version = 'LuaJIT',
                        },
                        diagnostics = {
                            -- Get the language server to recognize the `vim` global
                            globals = { 'vim' },
                        },
                        workspace = {
                            -- Make the server aware of Neovim runtime files
                            library = {
                                vim.api.nvim_get_runtime_file("", true),
                                vim.env.VIMRUNTIME,
                                "/Users/xell/Developer/src/yazi/yazi-plugin/preset",
                                "/Users/xell/Developer/src/yazi/yazi-plugin/preset/components",
                                "/Users/xell/Developer/src/yazi/yazi-plugin/preset/plugins",
                            },
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
            require 'lspconfig'.vimls.setup {
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
    -- https://github.com/nvim-treesitter/nvim-treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate", -- {{{
        config = function()
            require("nvim-treesitter.configs").setup({
                modules = {},
                ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown" },
                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,
                -- Automatically install missing parsers when entering buffer
                auto_install = true,
                -- List of parsers to ignore installing (or "all")
                ignore_install = {},
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = { 'markdown', 'markdown_line', 'outlinex' },
                    custom_captures = { ["highlighted_text"] = "Error", },
                },
                indent = {
                    enable = true
                },
            })
            -- local ft_to_parser = require('nvim-treesitter.parsers').filetype_to_parsername
            -- ft_to_parser.outlinex = "markdown"
            vim.treesitter.language.register('markdown', 'outlinex')
            -- vim.treesitter.language.register('markdown_inline', 'outlinex')
            -- https://stackoverflow.com/questions/78392167/how-to-create-a-new-capture-group-with-treesitter-for-updating-highlight-priorit
            -- vim.cmd([[ highlight! link @markup.strikethrough.markdown @type ]])
            -- Highlight the @foo.bar capture group with the "Identifier" highlight group
            -- vim.api.nvim_set_hl(0, "@highlighted_text", { link = "Identifier" })
        end,
    }, -- }}}
    -- https://github.com/stevearc/aerial.nvim
    {
        'stevearc/aerial.nvim',
        opts = {}, -- {{{
        -- Optional dependencies
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons"
        },
        config = function()
            require("aerial").setup({
                backends = { "treesitter", "lsp", "markdown", "man" },
                -- optionally use on_attach to set keymaps when aerial has attached to a buffer
                on_attach = function(bufnr)
                    -- Jump forwards/backwards with '{' and '}'
                    vks("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
                    vks("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
                end,
            })
            -- You probably also want to set a keymap to toggle aerial
            vks("n", "<leader>a", "<cmd>AerialToggle!<CR>")
            require("telescope").load_extension("aerial")
            require("telescope").setup({
                extensions = {
                    aerial = {
                        -- Display symbols as <root>.<parent>.<symbol>
                        show_nesting = {
                            ["_"] = false, -- This key will be the default
                            json = true,   -- You can set the option for specific filetypes
                            yaml = true,
                        },
                    },
                },
            })
        end,
    }, -- }}}
    -- https://github.com/hrsh7th/nvim-cmp
    {
        'hrsh7th/nvim-cmp',
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
        config = function()
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

            local cmp = require 'cmp'
            local luasnip = require 'luasnip'
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
            cmp.setup.cmdline({ '/', '?' }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = 'buffer' }
                }
            })

            -- `:` cmdline setup.
            cmp.setup.cmdline(':', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({ {
                    name = 'path',
                    option = {
                        trailing_slash = true,
                    },
                } }, { {
                    name = 'cmdline'
                } }),
                matching = { disallow_symbol_nonprefix_matching = false },
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

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "markdown", "outlinex" },
                callback = function()
                    require("cmp").setup.buffer({ enabled = false })
                end,
            })
            -- }}}
        end,
    }, -- }}}
    -- https://github.com/folke/trouble.nvim
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" }, -- {{{
        opts = {
        },
        cmd = "Trouble",
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Diagnostics (Trouble)",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Buffer Diagnostics (Trouble)",
            },
            {
                "<leader>xs",
                "<cmd>Trouble symbols toggle focus=false<cr>",
                desc = "Symbols (Trouble)",
            },
            {
                "<leader>xl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "LSP Definitions / references / ... (Trouble)",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Location List (Trouble)",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Quickfix List (Trouble)",
            },
        },
    }, -- }}}
    -- https://github.com/sontungexpt/url-open
    {
        "sontungexpt/url-open",
        event = "VeryLazy", -- {{{
        cmd = "URLOpenUnderCursor",
        config = function()
            local status_ok, url_open = pcall(require, "url-open")
            if not status_ok then
                return
            end
            url_open.setup({
                open_only_when_cursor_on_url = false,
                highlight_url = {
                    all_urls = {
                        enabled = false,
                        fg = "#21d5ff", -- "text" or "#rrggbb"
                        -- fg = "text", -- text will set underline same color with text
                        bg = nil,       -- nil or "#rrggbb"
                        underline = true,
                    },
                    cursor_move = {
                        enabled = false,
                        fg = "#199eff", -- "text" or "#rrggbb"
                        -- fg = "text", -- text will set underline same color with text
                        bg = nil,       -- nil or "#rrggbb"
                        underline = true,
                    },
                },
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
    {
        "wellle/context.vim",
        init = function()               -- {{{
            vg.context_presenter = 'nvim-float'
            vg.context_add_autocmds = 0 -- slows down in large files
            vg.context_add_mappings = 0 -- conflicts with yode delbuf
        end,
        config = function()
            vks('n', '<Leader><Leader>c', function()
                vim.cmd [[ContextActivate]]
                vim.cmd [[ContextUpdate]]
                vim.cmd [[ContextPeek]]
            end)
            vks('n', '<Leader><Leader>C', [[:ContextToggleWindow<CR>]])
        end
    }, -- }}}
    -- https://github.com/tpope/vim-fugitive
    {
        'tpope/vim-fugitive',
        config = function() -- {{{
            vks('n', '<Leader>gs', vim.cmd.G)
            vks('n', '<Leader>gd', vim.cmd.Gvdiffsplit)
        end,
    }, -- }}}
    -- https://github.com/lukas-reineke/indent-blankline.nvim
    {
        'lukas-reineke/indent-blankline.nvim',
        main = "ibl", -- {{{
        config = function()
            require("ibl").setup({
                indent = { char = '│', highlight = { "Whitespace" } },
            })
        end,
    }, -- }}}
    -- https://github.com/jackMort/ChatGPT.nvim
    {
        "jackMort/ChatGPT.nvim",
        -- event = "VeryLazy", -- {{{
        cmd = "ChatGPT",
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
            vks('n', '<Leader><Leader>G', function()
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
    -- https://github.com/IsWladi/Gittory
    {
        "IsWladi/Gittory",
        branch = "main", -- {{{
        dependencies = {
            -- {"rcarriga/nvim-notify"}, -- optional
        },
        config = true,
        opts = {              -- you can omit this, is the default
            -- notify = "yes", -- by default "yes":
            atStartUp = "yes" -- by default "yes": If you want to initialize Gittory when Neovim starts
        },
    },                        -- }}}
    -- https://github.com/folke/twilight.nvim
    {
        "folke/twilight.nvim",
        opts = {              -- {{{
            dimming = {
                alpha = 0.25, -- amount of dimming
                -- we try to get the foreground from the highlight groups or fallback color
                color = { "Normal", "#ffffff" },
                term_bg = "#000000", -- if guibg=NONE, this will be used to calculate text color
                inactive = false,    -- when true, other windows will be fully dimmed (unless they contain the same buffer)
            },
            context = 2,             -- amount of lines we will try to show around the current line
            treesitter = false,      -- use treesitter when available for the filetype
            -- treesitter is used to automatically expand the visible text,
            -- but you can further control the types of nodes that should always be fully expanded
            expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
                "function",
                "method",
                "table",
                "if_statement",
            },
            exclude = {}, -- exclude these filetypes
        },
    },                    -- }}}
    -- https://github.com/junegunn/limelight.vim
    {
        "junegunn/limelight.vim",
        init = function() -- {{{
            vg.limelight_paragraph_span = 1
            vg.limelight_priority = -1
        end,
    }, -- }}}
    -- https://github.com/karb94/neoscroll.nvim
    {
        "karb94/neoscroll.nvim",
        config = function() -- {{{
            require('neoscroll').setup()
        end
    }, -- }}}
    -- https://github.com/camspiers/luarocks
    -- https://github.com/vhyrro/luarocks.nvim
    {
        "camspiers/luarocks",
        enabled = true, -- {{{
        -- priority = 1001,
        -- config = true,
        opts = {
            rocks = { "magick" }, -- Specify LuaRocks packages to install
        },
    },                            -- }}}
    -- https://github.com/3rd/image.nvim
    {
        '3rd/image.nvim',
        enabled = true,
        cond = vf.has('gui_running') == 0, -- {{{
        event = "VeryLazy",
        dependencies = {
            {
                "nvim-treesitter/nvim-treesitter",
            },
        },
        opts = {
            -- backend = "ueberzug",
            backend = "kitty",
            integrations = {
                markdown = {
                    enabled = true,
                    clear_in_insert_mode = false,
                    download_remote_images = true,
                    only_render_image_at_cursor = true,
                    filetypes = { "markdown", "vimwiki", "outlinex" }, -- markdown extensions (ie. quarto) can go here
                },
                neorg = {
                    enabled = true,
                    clear_in_insert_mode = false,
                    download_remote_images = true,
                    only_render_image_at_cursor = false,
                    filetypes = { "norg" },
                },
                html = {
                    enabled = false,
                },
                css = {
                    enabled = false,
                },
            },
            max_width = nil,
            max_height = nil,
            max_width_window_percentage = nil,
            max_height_window_percentage = 50,
            kitty_method = "normal",
            -- kitty_method = "unicode-placeholders",
            window_overlap_clear_enabled = false,                                     -- toggles images when windows are overlapped
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "scrollview", "scrollview_sign" },
            editor_only_render_when_focused = false,                                  -- auto show/hide images when the editor gains/looses focus
            tmux_show_only_in_active_window = false,                                  -- auto show/hide images in the correct Tmux window (needs visual-activity off)
            hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" }, -- render image files as images when opened
        },
    },                                                                                -- }}}
    -- https://github.com/prichrd/netrw.nvim
    {
        'prichrd/netrw.nvim',
        config = function() -- {{{
            require 'netrw'.setup {
                -- icons = {
                --     symlink = '', -- Symlink icon (directory and file)
                --     directory = '', -- Directory icon
                --     file = '', -- File icon
                -- },
                use_devicons = true, -- Uses nvim-web-devicons if true, otherwise use the file icon specified above
                mappings = {},       -- Custom key mappings
            }
        end,
    }, -- }}}
    -- https://github.com/nanozuki/tabby.nvim
    {
        'nanozuki/tabby.nvim',
        event = 'VimEnter', -- {{{
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function()
            local theme = {
                fill = 'TabLineFill',
                -- Also you can do this: fill = { fg='#f2e9de', bg='#907aa9', style='italic' }
                head = 'TabLine',
                current_tab = 'TabLineSel',
                tab = 'TabLine',
                win = 'TabLine',
                tail = 'TabLine',
            }
            require('tabby.tabline').set(function(line)
                return {
                    {
                        -- { '  ', hl = theme.head },
                        { '  ', hl = theme.head },
                        -- line.sep('', theme.head, theme.fill),
                    },
                    line.tabs().foreach(function(tab)
                        local hl = tab.is_current() and theme.current_tab or theme.tab
                        return {
                            -- line.sep('', hl, theme.fill),
                            -- tab.is_current() and '' or '󰆣',
                            tab.is_current() and '' or '',
                            tab.number(),
                            tools.sub_utf8(tab.name(), 1, 6),
                            -- tab.close_btn(''),
                            tab.close_btn(''),
                            -- line.sep('', hl, theme.fill),
                            hl = hl,
                            margin = ' ',
                        }
                    end),
                    line.spacer(),
                    line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
                        return {
                            -- line.sep('', theme.win, theme.fill),
                            -- win.is_current() and '' or '',
                            win.is_current() and '' or '',
                            win.buf_name(),
                            -- line.sep('', theme.win, theme.fill),
                            hl = theme.win,
                            margin = ' ',
                        }
                    end),
                    {
                        -- line.sep('', theme.tail, theme.fill),
                        -- { '  ', hl = theme.tail },
                        { ' ', hl = theme.tail },
                    },
                    hl = theme.fill,
                }
            end)
        end,
    }, -- }}}
    -- https://github.com/sophacles/vim-processing
    {
        'sophacles/vim-processing',
        init = function() -- {{{
            vg.processing_fold = 1
        end,
    }, -- }}}
    -- https://github.com/kkharji/sqlite.lua
    { "kkharji/sqlite.lua" },
    -- https://github.com/xell/instant.nvim
    {
        "xell/instant.nvim",
        init = function() -- {{{
            vg.instant_username = "Xell"
        end,
    }, -- }}}
    -- https://github.com/okuuva/auto-save.nvim
    {
        "okuuva/auto-save.nvim",
        opts = {            -- {{{
            enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
            execution_message = {
                enabled = true,
                message = function() -- message to print on save
                    return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
                end,
                dim = 0.18,                                    -- dim the color of `message`
                cleaning_interval = 1250,                      -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
            },
            trigger_events = {                                 -- See :h events
                immediate_save = { "BufLeave", "FocusLost" },  -- vim events that trigger an immediate save
                defer_save = { "InsertLeave", "TextChanged" }, -- vim events that trigger a deferred save (saves after `debounce_delay`)
                cancel_defered_save = { "InsertEnter" },       -- vim events that cancel a pending deferred save
            },
            condition = nil,
            write_all_buffers = false, -- write all buffers when the current one meets `condition`
            noautocmd = false,         -- do not execute autocmds when saving
            lockmarks = false,         -- lock marks when saving, see `:h lockmarks` for more details
            debounce_delay = 1000,     -- delay after which a pending save is executed
            -- log debug messages to 'auto-save.log' file in neovim cache directory, set to `true` to enable
            debug = false,
        },
    }, -- }}}
    -- https://github.com/subnut/nvim-ghost.nvim
    { 'subnut/nvim-ghost.nvim' },
    -- https://github.com/brenoprata10/nvim-highlight-colors
    {
        'brenoprata10/nvim-highlight-colors',
        cmd = 'HighlightColors', -- {{{
        config = function()
            require("nvim-highlight-colors").setup {
                ---Render style
                ---@usage 'background'|'foreground'|'virtual'
                render = 'virtual',

                ---Set virtual symbol (requires render to be set to 'virtual')
                -- ■ 󱓻 
                virtual_symbol = '',

                ---Highlight named colors, e.g. 'green'
                enable_named_colors = true,

                ---Highlight tailwind colors, e.g. 'bg-blue-500'
                enable_tailwind = false,

                ---Set custom colors
                ---Label must be properly escaped with '%' to adhere to `string.gmatch`
                --- :help string.gmatch
                custom_colors = {
                    { label = '%-%-theme%-primary%-color',   color = '#0f1219' },
                    { label = '%-%-theme%-secondary%-color', color = '#5a5d64' },
                }
            }
        end,
    }, -- }}}
    -- https://github.com/pocco81/high-str.nvim
    {
        'Pocco81/HighStr.nvim',
        config = function() -- {{{
            require("high-str").setup({
                verbosity = 0,
                saving_path = "/tmp/highstr/",
                highlight_colors = {
                    -- color_id = {"bg_hex_code",<"fg_hex_code"/"smart">}
                    color_0 = { "#0c0d0e", "smart" }, -- Cosmic charcoal
                    color_1 = { "#e5c07b", "smart" }, -- Pastel yellow
                    color_2 = { "#7FFFD4", "smart" }, -- Aqua menthe
                    color_3 = { "#8A2BE2", "smart" }, -- Proton purple
                    color_4 = { "#FF4500", "smart" }, -- Orange red
                    color_5 = { "#008000", "smart" }, -- Office green
                    color_6 = { "#0000FF", "smart" }, -- Just blue
                    color_7 = { "#FFC0CB", "smart" }, -- Blush pink
                    color_8 = { "#FFF9E3", "smart" }, -- Cosmic latte
                    color_9 = { "#7d5c34", "smart" }, -- Fallow brown
                }
            })
        end,
    }, -- }}}
    -- https://github.com/lervag/vimtex
    {
        "lervag/vimtex",
        lazy = false, -- we don't want to lazy load VimTeX {{{
        init = function()
            vg.vimtex_fold_enabled = 1
            -- vg.vimtex_fold_manual = 1
            vg.vimtex_compiler_method = 'tectonic'
            vg.vimtex_view_method = 'skim'
            vg.vimtex_view_skim_activate = 1
            vg.vimtex_view_skim_sync = 1
            vg.vimtex_view_skim_reading_bar = 0
            vg.vimtex_view_skim_no_select = 1
            vg.vimtex_quickfix_autoclose_after_keystrokes = 5
            vg.vimtex_matchparen_enabled = 0
        end,
    }, -- }}}
    -- https://github.com/crispgm/telescope-heading.nvim
    {
        'crispgm/telescope-heading.nvim',
        config = function() -- {{{
            require('telescope').setup {
                extensions = {
                    heading = {
                        treesitter = true,
                    },
                }
            }
            require('telescope').load_extension('heading')
        end
    }, -- }}}
    -- https://github.com/mikavilpas/yazi.nvim
    {
        "mikavilpas/yazi.nvim",
        event = "VeryLazy", -- {{{
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        keys = {
            {
                "<leader>-",
                function()
                    require("yazi").yazi()
                end,
                desc = "Open the file manager",
            },
            {
                -- Open in the current working directory
                "<leader>_",
                function()
                    require("yazi").yazi(nil, vim.fn.getcwd())
                end,
                desc = "Open the file manager in nvim's working directory",
            },
        },
        opts = {
            open_for_directories = false,
        },
    }, -- }}}
    -- https://github.com/lewis6991/gitsigns.nvim
    {
        "lewis6991/gitsigns.nvim",
        config = function() -- {{{
            require('gitsigns').setup {
                signs                        = {
                    add          = { text = '┃' },
                    change       = { text = '┃' },
                    delete       = { text = '_' },
                    topdelete    = { text = '‾' },
                    changedelete = { text = '~' },
                    untracked    = { text = '┆' },
                },
                signcolumn                   = true,  -- Toggle with `:Gitsigns toggle_signs`
                numhl                        = false, -- Toggle with `:Gitsigns toggle_numhl`
                linehl                       = false, -- Toggle with `:Gitsigns toggle_linehl`
                word_diff                    = false, -- Toggle with `:Gitsigns toggle_word_diff`
                watch_gitdir                 = {
                    follow_files = true
                },
                auto_attach                  = true,
                attach_to_untracked          = false,
                current_line_blame           = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
                current_line_blame_opts      = {
                    virt_text = true,
                    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
                    delay = 1000,
                    ignore_whitespace = false,
                    virt_text_priority = 100,
                },
                current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
                sign_priority                = 6,
                update_debounce              = 100,
                status_formatter             = nil,   -- Use default
                max_file_length              = 40000, -- Disable if file is longer than this (in lines)
                preview_config               = {
                    -- Options passed to nvim_open_win
                    border = 'single',
                    style = 'minimal',
                    relative = 'cursor',
                    row = 0,
                    col = 1
                },
                on_attach                    = function(bufnr)
                    local gitsigns = require('gitsigns')

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Navigation
                    map('n', ']c', function()
                        if vim.wo.diff then
                            vim.cmd.normal({ ']c', bang = true })
                        else
                            gitsigns.nav_hunk('next')
                        end
                    end)

                    map('n', '[c', function()
                        if vim.wo.diff then
                            vim.cmd.normal({ '[c', bang = true })
                        else
                            gitsigns.nav_hunk('prev')
                        end
                    end)
                    map('n', '<leader>hd', gitsigns.diffthis)
                    map('n', '<leader>hD', function() gitsigns.diffthis('~') end)
                end,
            }
        end
    }, -- }}}
    -- https://github.com/kevinhwang91/nvim-ufo
    {
        "kevinhwang91/nvim-ufo",
        dependencies = { -- {{{
            "kevinhwang91/promise-async",
        },
        config = function()
            local ftMap = {
                git = '',
                outlinex = '',
                tex = '',
            }
            local handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
                local suffix = (' ↓ %d '):format(endLnum - lnum)
                local sufWidth = vim.fn.strdisplaywidth(suffix)
                local targetWidth = width - sufWidth
                local curWidth = 0
                for _, chunk in ipairs(virtText) do
                    local chunkText = chunk[1]
                    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    if targetWidth > curWidth + chunkWidth then
                        table.insert(newVirtText, chunk)
                    else
                        chunkText = truncate(chunkText, targetWidth - curWidth)
                        local hlGroup = chunk[2]
                        table.insert(newVirtText, { chunkText, hlGroup })
                        chunkWidth = vim.fn.strdisplaywidth(chunkText)
                        -- str width returned from truncate() may less than 2nd argument, need padding
                        if curWidth + chunkWidth < targetWidth then
                            suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                        end
                        break
                    end
                    curWidth = curWidth + chunkWidth
                end
                table.insert(newVirtText, { suffix, 'MoreMsg' })
                return newVirtText
            end
            require('ufo').setup({
                open_fold_hl_timeout = 0,
                provider_selector = function(bufnr, filetype, _)
                    if vim.bo[bufnr].bt == 'nofile' then
                        return ''
                    end
                    return ftMap[filetype] or { 'treesitter', 'indent' }
                end,
                fold_virt_text_handler = handler,
            })
            vks('n', 'zR', require('ufo').openAllFolds)
            vks('n', 'zM', require('ufo').closeAllFolds)
            vks('n', 'zx', function()
                require('ufo').closeAllFolds()
                vim.cmd.normal [[zv]]
            end)
            vks('n', '<Leader>p', require('ufo').peekFoldedLinesUnderCursor)

            -- https://github.com/kevinhwang91/nvim-ufo/issues/150
            -- Ensure our ufo foldlevel is set for the buffer
            vim.api.nvim_create_autocmd("BufReadPre", {
                callback = function()
                    vim.b.ufo_foldlevel = 0
                end
            })
            ---@param num integer Set the fold level to this number
            local set_buf_foldlevel = function(num)
                vim.b.ufo_foldlevel = num
                require("ufo").closeFoldsWith(num)
            end
            ---@param num integer The amount to change the UFO fold level by
            local change_buf_foldlevel_by = function(num)
                local foldlevel = vim.b.ufo_foldlevel or 0
                -- Ensure the foldlevel can't be set negatively
                if foldlevel + num >= 0 then
                    foldlevel = foldlevel + num
                else
                    foldlevel = 0
                end
                set_buf_foldlevel(foldlevel)
            end
            -- Keymaps
            vim.keymap.set("n", "zm", function()
                local count = vim.v.count
                if count == 0 then
                    count = 1
                end
                change_buf_foldlevel_by(-(count))
            end, { desc = "UFO: Fold More" })
            vim.keymap.set("n", "zr", function()
                local count = vim.v.count
                if count == 0 then
                    count = 1
                end
                change_buf_foldlevel_by(count)
            end, { desc = "UFO: Fold Less" })
        end,
    }, -- }}}
}, {
    dev = {
        path = "~/Developer/vim/scripts",
        fallback = true,
    },
})

-- }}}


