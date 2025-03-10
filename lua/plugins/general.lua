-- vim:
return {
    -- https://github.com/xiyaowong/fast-cursor-move.nvim remap j k
    { 'xiyaowong/fast-cursor-move.nvim', -- {{{
        config = function ()
            vim.defer_fn(function ()
                -- map j and k to original in visual linewise & blockwise modes
                vim.cmd[[xnoremap <expr> j mode() =~ 'V\\|' ? 'j' : 'gj']]
                vim.cmd[[xnoremap <expr> k mode() =~ 'V\\|' ? 'k' : 'gk']]
            end, 1000)
        end,
    }, -- }}}

    -- https://github.com/rlue/vim-barbaric
    { 'rlue/vim-barbaric', -- {{{
        dev = true,
        init = function ()
            vim.g.barbaric_ime = 'macism'
            vim.g.barbaric_default = 'com.apple.keylayout.ABC'
            -- The scope where alternate input methods persist (buffer, window, tab, global)
            vim.g.barbaric_scope = 'buffer'
            -- vim.o.ttimeoutlen = 0 -- default 50
        end
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
    { 'zzhirong/vim-easymotion-zh', },
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
            vim.keymap.set('n', '<Leader>/', function()
                hop.hint_patterns()
            end, { desc = 'Hop hint patterns' })
        end,
    }, -- }}}

    -- https://github.com/nvim-lua/plenary.nvim
    { 'nvim-lua/plenary.nvim', },

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

    -- https://github.com/sontungexpt/url-open
    { 'sontungexpt/url-open', -- {{{
        event = 'VeryLazy',
        cmd = 'URLOpenUnderCursor',
        config = function()
            local status_ok, url_open = pcall(require, 'url-open')
            if not status_ok then
                return
            end
            url_open.setup({
                open_only_when_cursor_on_url = false,
                highlight_url = {
                    all_urls = {
                        enabled = false,
                        fg = '#21d5ff', -- 'text' or '#rrggbb'
                        -- fg = 'text', -- text will set underline same color with text
                        bg = nil,       -- nil or '#rrggbb'
                        underline = true,
                    },
                    cursor_move = {
                        enabled = false,
                        fg = '#199eff', -- 'text' or '#rrggbb'
                        -- fg = 'text', -- text will set underline same color with text
                        bg = nil,       -- nil or '#rrggbb'
                        underline = true,
                    },
                },
                deep_pattern = true,
                -- a list of patterns to open url under cursor
                extra_patterns = {
                    -- {
                    --     -- FIXME it's too general
                    --     pattern = '([^/ %[]+%.%a%w%w*)',
                    --     prefix = 'file://' .. string.gsub(vim.g.xell_notes_root, '\\', '') .. '/Notes/res/',
                    --     suffix = '',
                    --     file_patterns = '%w+%.md',
                    --     excluded_file_patterns = nil,
                    --     extra_condition = nil,
                    -- },
                    -- {
                    -- 	  pattern = '["]([^%s]*)["]:%s*"[^"]*%d[%d%.]*"',
                    -- 	  prefix = 'https://www.npmjs.com/package/',
                    -- 	  suffix = '',
                    -- 	  file_patterns = { 'package%.json' },
                    -- 	  excluded_file_patterns = nil,
                    -- 	  extra_condition = function(pattern_found)
                    -- 	    return not vim.tbl_contains({ 'version', 'proxy' }, pattern_found)
                    -- 	  end,
                    -- },
                    -- so the url will be https://www.npmjs.com/package/[pattern_found]


                    -- {
                    -- 	  pattern = '["]([^%s]*)["]:%s*"[^"]*%d[%d%.]*"',
                    -- 	  prefix = 'https://www.npmjs.com/package/',
                    -- 	  suffix = '/issues',
                    -- 	  file_patterns = { 'package%.json' },
                    -- 	  excluded_file_patterns = nil,
                    -- 	  extra_condition = function(pattern_found)
                    -- 	    return not vim.tbl_contains({ 'version', 'proxy' }, pattern_found)
                    -- 	  end,
                    -- },
                    --
                    -- so the url will be https://www.npmjs.com/package/[pattern_found]/issues
                },
            })
            -- https://sbulav.github.io/vim/neovim-opening-urls/
            -- map[''].gx = {'<Cmd>call jobstart(['open', expand('<cfile>')], {'detach': v:true})<CR>'}
            vim.keymap.set('n', 'gx', vim.cmd.URLOpenUnderCursor)
        end,
    }, -- }}}
    -- https://github.com/kevinhwang91/nvim-ufo
    { 'kevinhwang91/nvim-ufo', -- {{{
        cond = not vim.g.vscode,
        dependencies = {
            'kevinhwang91/promise-async',
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
            -- Ensure our ufo foldlevel is set for the buffer TODO
            vim.api.nvim_create_autocmd('BufReadPre', {
                callback = function()
                    vim.b.ufo_foldlevel = 0
                end
            })

            vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
            vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
            vim.keymap.set('n', 'zx', function()
                require('ufo').closeAllFolds()
                vim.cmd.normal [[zv]]
            end)
            vim.keymap.set('n', '<Leader>p', require('ufo').peekFoldedLinesUnderCursor, { desc = 'Peek fold content by UFO' })
            -- https://github.com/kevinhwang91/nvim-ufo/issues/150
            -- ---@param num integer Set the fold level to this number
            -- local set_buf_foldlevel = function(num)
            --     vim.b.ufo_foldlevel = num
            --     require('ufo').closeFoldsWith(num)
            -- end
            -- ---@param num integer The amount to change the UFO fold level by
            -- local change_buf_foldlevel_by = function(num)
            --     local foldlevel = vim.b.ufo_foldlevel or 0
            --     -- Ensure the foldlevel can't be set negatively
            --     if foldlevel + num >= 0 then
            --         foldlevel = foldlevel + num
            --     else
            --         foldlevel = 0
            --     end
            --     set_buf_foldlevel(foldlevel)
            -- end
            -- -- Keymaps
            -- vim.keymap.set('n', 'zm', function()
            --     local count = vim.v.count
            --     if count == 0 then
            --         count = 1
            --     end
            --     change_buf_foldlevel_by(-(count))
            -- end, { desc = 'UFO: Fold More' })
            -- vim.keymap.set('n', 'zr', function()
            --     local count = vim.v.count
            --     if count == 0 then
            --         count = 1
            --     end
            --     change_buf_foldlevel_by(count)
            -- end, { desc = 'UFO: Fold Less' })
            -- -- https://github.com/kevinhwang91/nvim-ufo/issues/42
            -- local function hateRepeatFold(char)
            --     local function setScrollOff(val)
            --         local view = vim.fn.winsaveview()
            --         vim.wo.so = val
            --         vim.fn.winrestview(view)
            --     end
            --
            --     local event = require('ufo.lib.event')
            --     event:emit('setOpenFoldHl')
            --     vim.keymap.set('n', 'h', function()
            --         local shouldClose = vim.fn.foldlevel('.') ~= 0
            --         if shouldClose then
            --             event:emit('setOpenFoldHl', false)
            --             setScrollOff(10)
            --         end
            --         return shouldClose and 'zc' or 'h'
            --     end, {buffer = 0, expr = true})
            --     vim.keymap.set('n', 'l', function()
            --         local shouldOpen = vim.fn.foldclosed('.') ~= -1
            --         if shouldOpen then
            --             event:emit('setOpenFoldHl', false)
            --             setScrollOff(10)
            --         end
            --         return shouldOpen and 'zo' or 'l'
            --     end, {buffer = 0, expr = true})
            --     vim.api.nvim_create_autocmd('CursorMoved', {
            --         group = vim.api.nvim_create_augroup('HateRepeatFoldAug', {}),
            --         buffer = 0,
            --         once = true,
            --         callback = function()
            --             pcall(vim.keymap.del, 'n', 'h', {buffer = 0})
            --             pcall(vim.keymap.del, 'n', 'l', {buffer = 0})
            --             setScrollOff(0)
            --             event:emit('setOpenFoldHl')
            --         end
            --     })
            --     return 'mzz' .. char
            -- end
            --
            -- for _, c in ipairs({'c', 'o', 'a', 'C', 'O', 'A', 'v'}) do
            --     vim.keymap.set('n', 'z' .. c, function() return hateRepeatFold(c) end, {expr = true})
            -- end
        end,
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

    -- https://github.com/xell/yode-nvim
    { 'xell/yode-nvim', -- {{{
        dev = true,
        config = function()
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

    -- https://github.com/3rd/image.nvim
    { '3rd/image.nvim', -- {{{
        cond = vim.fn.has('gui_running') == 0 or not vim.g.vscode,
        event = 'VeryLazy',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
        },
        config = function ()
            require 'image'.setup({
                backend = ({ 'kitty', 'ueberzug', })[1],
                integrations = {
                    syslang = {
                        enabled = false,
                    },
                    markdown = {
                        enabled = false,
                        clear_in_insert_mode = false,
                        download_remote_images = true,
                        only_render_image_at_cursor = false,
                        filetypes = { 'markdown', 'vimwiki', 'outlinex' }, -- markdown extensions (ie. quarto) can go here
                    },
                    neorg = {
                        enabled = false,
                        clear_in_insert_mode = false,
                        download_remote_images = true,
                        only_render_image_at_cursor = false,
                        filetypes = { 'norg' },
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
                max_height_window_percentage = 100, -- 50
                kitty_method = 'normal',
                -- kitty_method = 'unicode-placeholders',
                window_overlap_clear_enabled = false,                                     -- toggles images when windows are overlapped
                window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', 'scrollview', 'scrollview_sign' },
                editor_only_render_when_focused = false,                                  -- auto show/hide images when the editor gains/looses focus
                tmux_show_only_in_active_window = false,                                  -- auto show/hide images in the correct Tmux window (needs visual-activity off)
                hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp' }, -- render image files as images when opened
            })
            vim.api.nvim_del_augroup_by_name('image.nvim')
        end,
    },                                                                                -- }}}

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
        event = 'VeryLazy',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        keys = {
            {
                '<leader>-',
                function()
                    require('yazi').yazi()
                end,
                desc = 'Open the file manager',
            },
            {
                -- Open in the current working directory
                '<leader>_',
                function()
                    require('yazi').yazi(nil, vim.fn.getcwd())
                end,
                desc = "Open the file manager in nvim's working directory",
            },
        },
        opts = {
            open_for_directories = false,
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
