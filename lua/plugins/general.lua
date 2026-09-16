-- ufo fold
return {
    -- https://github.com/xiyaowong/fast-cursor-move.nvim remap j k
    { 'xiyaowong/fast-cursor-move.nvim', -- {{{
        cond = not vim.g.vscode,
        config = function ()
            vim.defer_fn(function ()
                -- map j and k to original in visual linewise & blockwise modes
                vim.cmd[[xnoremap <expr> j mode() =~ 'V\\|' ? 'j' : 'gj']]
                vim.cmd[[xnoremap <expr> k mode() =~ 'V\\|' ? 'k' : 'gk']]
            end, 1000)
        end,
    }, -- }}}

    -- https://github.com/easymotion/vim-easymotion
    -- https://github.com/xell/vim-easymotion
    { 'xell/vim-easymotion', -- {{{
        init = function()
            -- added temp fix for fold
            -- https://github.com/timsu92/vim-easymotion/pull/2/files
            -- https://github.com/easymotion/vim-easymotion/issues/484
            -- https://github.com/easymotion/vim-easymotion/issues/452
            vim.cmd [[
            let g:EasyMotion_leader_key=';'
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
    -- https://www.v2ex.com/t/856921
    -- https://github.com/zzhirong/vim-easymotion-zh
    -- https://github.com/xell/vim-easymotion-zh 2026-09-12
    { 'xell/vim-easymotion-zh', },
    -- https://github.com/smoka7/hop.nvim
    -- https://github.com/xell/hop.nvim 2026-09-12
    { 'xell/hop.nvim', -- {{{
        version = '*',
        config = function()
            local hop = require('hop')
            hop.setup {
                keys = 'etovxqpdygfblzhckisuran',
                multi_windows = true,
                create_hl_autocmd = true,
            }
            vim.keymap.set('n', '<Leader>/', function()
                hop.hint_patterns()
            end, { desc = 'Hop hint patterns' })
        end,
    }, -- }}}

    -- https://github.com/okuuva/auto-save.nvim
    { 'okuuva/auto-save.nvim', -- {{{
        cond = not vim.g.vscode,
        opts = {
            enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
            -- https://github.com/okuuva/auto-save.nvim/commit/1747cf2#diff-b335630551682c19a781afebcf4d07bf978fb1f8ac04c6bf87428ed5106870f5
            -- execution_message = {
            --     enabled = true,
            --     message = function() -- message to print on save
            --         return ('AutoSave: saved at ' .. vim.fn.strftime('%H:%M:%S'))
            --     end,
            --     dim = 0.18,                                    -- dim the color of `message`
            --     cleaning_interval = 1250,                      -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
            -- },
            trigger_events = {                                 -- See :h events
                immediate_save = { 'BufLeave', 'FocusLost' },  -- vim events that trigger an immediate save
                defer_save = { 'InsertLeave', 'TextChanged' }, -- vim events that trigger a deferred save (saves after `debounce_delay`)
                cancel_deferred_save = { 'InsertEnter' },       -- vim events that cancel a pending deferred save
            },
            condition = nil,
            write_all_buffers = false, -- write all buffers when the current one meets `condition`
            noautocmd = false,         -- do not execute autocmds when saving
            lockmarks = false,         -- lock marks when saving, see `:h lockmarks` for more details
            debounce_delay = 800,     -- delay after which a pending save is executed
            -- log debug messages to 'auto-save.log' file in neovim cache directory, set to `true` to enable
            debug = false,
        },
    }, -- }}}

    -- https://github.com/m4xshen/autoclose.nvim
    { 'm4xshen/autoclose.nvim', -- {{{
        cond = not vim.g.vscode,
        config = function ()
            require("autoclose").setup({
                options = {
                    disabled_filetypes = { "TelescopePrompt" },
                },
                keys = {
                    ["$"] = {
                        escape = true,
                        close = true,
                        pair = "$$",
                        disabled_filetypes = { 'markdown', 'text', 'outlinex' },
                        disable_command_mode = true,
                    },
                    ["'"] = {
                        escape = true,
                        close = true,
                        pair = "''",
                        disabled_filetypes = { 'markdown', 'text', 'outlinex' },
                    },
                },
            })
        end
    }, -- }}}

    -- https://github.com/folke/which-key.nvim
    { 'folke/which-key.nvim', -- {{{
        cond = not vim.g.vscode,
        event = 'VeryLazy',
        -- init = function()
        --     vim.o.timeout = true
        --     vim.o.timeoutlen = 500 -- 1000
        -- end,
        opts = {
            delay = function(ctx)
                return ctx.plugin and 0 or 500 -- 200
            end,
            --- Mappings are sorted using configured sorters and natural sort of the keys
            --- Available sorters:
            --- * local: buffer-local mappings first
            --- * order: order of the items (Used by plugins like marks / registers)
            --- * group: groups last
            --- * alphanum: alpha-numerical first
            --- * mod: special modifier keys last
            --- * manual: the order the mappings were added
            --- * case: lower-case first
            -- sort = { 'local', 'order', 'group', 'alphanum', 'mod' },
            sort = { 'alphanum', },
            layout = {
                width = { min = 20 },
            },
        },
        keys = {
            {
                '<Leader>?',
                function()
                    require('which-key').show({ global = false })
                end,
                desc = 'Buffer Local Keymaps (which-key)',
            },
        },
    }, -- }}}

    -- https://github.com/mikavilpas/yazi.nvim
    { 'mikavilpas/yazi.nvim', -- {{{
        cond = not vim.g.vscode,
        version = "*", -- use the latest stable version
        event = "VeryLazy",
        dependencies = {
            { "nvim-lua/plenary.nvim", lazy = true },
            { "folke/snacks.nvim" },
        },
        keys = {
            -- 👇 in this section, choose your own keymappings!
            {
                "<leader>-",
                mode = { "n", "v" },
                "<cmd>Yazi<cr>",
                desc = "Open yazi at the current file",
            },
            {
                -- Open in the current working directory
                "<leader>=",
                "<cmd>Yazi cwd<cr>",
                desc = "Open the file manager in nvim's working directory",
            },
            {
                "<leader>_",
                "<cmd>Yazi toggle<cr>",
                desc = "Resume the last yazi session",
            },
        },
        opts = {
            -- if you want to open yazi instead of netrw, see below for more info
            open_for_directories = false,
            keymaps = {
                show_help = "<f1>",
                cycle_open_buffers = "<c-b>",
            },
        },
    }, -- }}}

    -- https://github.com/ctechols/vim-HideShow
    { 'ctechols/vim-HideShow', -- {{{
        cond = not vim.g.vscode,
    }, -- }}}

    -- https://github.com/AndrewRadev/linediff.vim
    { 'AndrewRadev/linediff.vim', -- {{{
        cond = not vim.g.vscode,
    }, -- }}}
    -- https://github.com/rickhowe/diffchar.vim
    { 'rickhowe/diffchar.vim', -- {{{
        cond = not vim.g.vscode,
        init = function ()
            vim.g.DiffColors = 0
            vim.g.DiffPairVisible = 3
        end
    }, -- }}}



}
