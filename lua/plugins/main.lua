-- vim:foldlevel=1
return {
    -- https://github.com/xiyaowong/fast-cursor-move.nvim remap j k
    { 'xiyaowong/fast-cursor-move.nvim', 
        config = function ()
            vim.defer_fn(function ()
                -- map j and k to their original in visual line mode
                -- TODO
                vim.cmd[[xnoremap <expr> j mode() =~ '\C[CV]' ? 'j' : 'gj']]
                vim.cmd[[xnoremap <expr> k mode() =~ '\C[CV]' ? 'k' : 'gk']]
            end, 1000)
        end,
    },

    -- https://github.com/keaising/im-select.nvim
    { 'keaising/im-select.nvim', -- {{{
        config = function()
            require('im_select').setup({
                -- IM will be set to `default_im_select` in `normal` mode
                -- For Windows/WSL, default: '1033', aka: English US Keyboard
                -- For macOS, default: 'com.apple.keylayout.ABC', aka: US
                -- For Linux, default:
                --               'keyboard-us' for Fcitx5
                --               '1' for Fcitx
                --               'xkb:us::eng' for ibus
                -- You can use `im-select` or `fcitx5-remote -n` to get the IM's name
                default_im_select       = 'com.apple.keylayout.ABC',

                -- Can be binary's name or binary's full path,
                -- e.g. 'im-select' or '/usr/local/bin/im-select'
                -- For Windows/WSL, default: 'im-select.exe'
                -- For macOS, default: 'im-select'
                -- For Linux, default: 'fcitx5-remote' or 'fcitx-remote' or 'ibus'
                default_command         = '/usr/local/bin/im-select',

                -- Restore the default input method state when the following events are triggered
                -- set_default_events = { 'VimEnter', 'FocusGained', 'InsertLeave', 'CmdlineLeave' },
                set_default_events      = { 'VimEnter', 'InsertLeave', 'CmdlineLeave' },

                -- Restore the previous used input method state when the following events
                -- are triggered, if you don't want to restore previous used im in Insert mode,
                -- e.g. deprecated `disable_auto_restore = 1`, just let it empty
                -- as `set_previous_events = {}`
                set_previous_events     = { 'InsertEnter' },

                -- Show notification about how to install executable binary when binary missed
                keep_quiet_on_no_binary = false,

                -- Async run `default_command` to switch IM or not
                async_switch_im         = true,
            })
        end,
    }, -- }}}

    -- https://github.com/f-person/auto-dark-mode.nvim
    { 'f-person/auto-dark-mode.nvim', -- {{{
        opts = {
            update_interval = 1000,
            set_dark_mode = function()
                vim.o.background = 'dark'
                vim.cmd('colorscheme onehalfdark')
            end,
            set_light_mode = function()
                vim.o.background = 'light'
                vim.cmd('colorscheme onehalflight')
            end,
        },
    }, -- }}}

    -- https://github.com/easymotion/vim-easymotion
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
    --  https://www.v2ex.com/t/856921
    { 'zzhirong/vim-easymotion-zh' },
    -- https://github.com/smoka7/hop.nvim
    { 'smoka7/hop.nvim', -- {{{
        version = '*',
        config = function()
            local hop = require('hop')
            hop.setup {
                keys = 'etovxqpdygfblzhckisuran',
                multi_windows = true,
                create_hl_autocmd = true,
            }
            vim.keymap.set('', '<Leader>/', function()
                hop.hint_patterns()
            end)
        end,
    }, -- }}}

    -- https://github.com/nvim-lua/plenary.nvim
    { 'nvim-lua/plenary.nvim' },

    -- https://github.com/okuuva/auto-save.nvim
    { 'okuuva/auto-save.nvim', -- {{{
        opts = {
            enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
            execution_message = {
                enabled = true,
                message = function() -- message to print on save
                    return ('AutoSave: saved at ' .. vim.fn.strftime('%H:%M:%S'))
                end,
                dim = 0.18,                                    -- dim the color of `message`
                cleaning_interval = 1250,                      -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
            },
            trigger_events = {                                 -- See :h events
                immediate_save = { 'BufLeave', 'FocusLost' },  -- vim events that trigger an immediate save
                defer_save = { 'InsertLeave', 'TextChanged' }, -- vim events that trigger a deferred save (saves after `debounce_delay`)
                cancel_defered_save = { 'InsertEnter' },       -- vim events that cancel a pending deferred save
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
}
