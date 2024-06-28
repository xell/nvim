-- vim:
return {
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

    -- https://github.com/lukas-reineke/indent-blankline.nvim
    { 'lukas-reineke/indent-blankline.nvim', -- {{{
        main = 'ibl',
        config = function()
            require('ibl').setup({
                indent = { char = '│', highlight = { 'Whitespace' } },
            })
        end,
    }, -- }}}

    -- https://github.com/nanozuki/tabby.nvim
    { 'nanozuki/tabby.nvim', -- {{{
        event = 'VimEnter',
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
                            require'tools'.sub_utf8(tab.name(), 1, 6),
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

    -- https://github.com/brenoprata10/nvim-highlight-colors
    { 'brenoprata10/nvim-highlight-colors', -- {{{
        cmd = 'HighlightColors',
        config = function()
            require('nvim-highlight-colors').setup {
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
    { 'Pocco81/HighStr.nvim', -- {{{
        config = function()
            require('high-str').setup({
                verbosity = 0,
                saving_path = '/tmp/highstr/',
                highlight_colors = {
                    -- color_id = {'bg_hex_code',<'fg_hex_code'/'smart'>}
                    color_0 = { '#0c0d0e', 'smart' }, -- Cosmic charcoal
                    color_1 = { '#e5c07b', 'smart' }, -- Pastel yellow
                    color_2 = { '#7FFFD4', 'smart' }, -- Aqua menthe
                    color_3 = { '#8A2BE2', 'smart' }, -- Proton purple
                    color_4 = { '#FF4500', 'smart' }, -- Orange red
                    color_5 = { '#008000', 'smart' }, -- Office green
                    color_6 = { '#0000FF', 'smart' }, -- Just blue
                    color_7 = { '#FFC0CB', 'smart' }, -- Blush pink
                    color_8 = { '#FFF9E3', 'smart' }, -- Cosmic latte
                    color_9 = { '#7d5c34', 'smart' }, -- Fallow brown
                }
            })
        end,
    }, -- }}}
}
