-- vim:
return {
    -- https://github.com/f-person/auto-dark-mode.nvim
    { 'f-person/auto-dark-mode.nvim', -- {{{
        cond = not vim.g.vscode,
        opts = {
            update_interval = 1000,
            set_dark_mode = function()
                vim.o.background = 'dark'
                -- vim.cmd('colorscheme onehalfdark')
                vim.cmd.colorscheme(({ 'onehalfdark', 'ayu-mirage' })[2])
                -- vim.cmd [[highlight Folded guifg='#D8DEE9' gui=NONE]]
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

    -- https://github.com/ipod825/taboverflow.vim
    { 'ipod825/taboverflow.vim',
        cond = not vim.g.vscode,
        -- enabled = false,
        init = function ()
            vim.cmd[[
function! s:TabLabel(n)
    let label = ''

    " Add '+' if one of the buffers in the tab page is modified
    let bufnrlist = tabpagebuflist(v:lnum)
    for bufnr in bufnrlist
        if getbufvar(bufnr, "&modified")
            " *✦★✷✸✹ 
            let label .= '✦ '
            break
        endif
    endfor

    let label .= tabpagenr()

    " Append the number of windows in the tab page if more than one
    "" let wincount = tabpagewinnr(v:lnum, '$')
    "" if wincount > 1
    ""   let label .= wincount
    "" endif
    "" if label != ''
    ""   let label .= ' '
    "" endif

    " Append the buffer name
     return string(a:n). bufname(bufnrlist[tabpagewinnr(v:lnum) - 1])
    "return label
endfunction
" This is the default implementation
function s:MyTabLabel(n)
    let buflist = tabpagebuflist(a:n)
    let winnr = tabpagewinnr(a:n)
    "let res = ' '.taboverflow#unicode_num(a:n)
    let res = ' '
    if a:n == tabpagenr()
        let res .= '%#TabLineSel#' 
    else
        let res .= '%#TabLine#'
    endif
    let res .= ' ' . string(a:n) . ' '
    let bufnr = buflist[winnr - 1]
    if getbufvar(bufnr, '&modified') == 1
        let res .= '*'
    endif
    let bufname = fnamemodify(bufname(bufnr), ':t')
    if empty(bufname) && a:n == tabpagenr()
        let bufname = '[ ]'
    endif
    let res .= bufname
    return res
endfunction
            let g:TaboverflowLabel = function('s:MyTabLabel')
            ]]
        end
    },
    -- https://github.com/nanozuki/tabby.nvim
    { 'nanozuki/tabby.nvim', -- {{{
        cond = not vim.g.vscode,
        enabled = false,
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
                            require 'tools'.sub_utf8(tab.name(), 1, 6),
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
        -- cmd = 'HighlightColors On',
        event = 'BufEnter *.vim',
        config = function()
            require('nvim-highlight-colors').setup {
                ---Render style
                ---@usage 'background'|'foreground'|'virtual'
                render = 'virtual',

                ---Set virtual symbol (requires render to be set to 'virtual') ■ 󱓻 
                virtual_symbol = '󱓻',

                ---Set virtual symbol suffix (defaults to '')
                virtual_symbol_prefix = '',

                ---Set virtual symbol suffix (defaults to ' ')
                virtual_symbol_suffix = ' ',

                ---Set virtual symbol position()
                ---@usage 'inline'|'eol'|'eow'
                ---inline mimics VS Code style
                ---eol stands for `end of column` - Recommended to set `virtual_symbol_suffix = ''` when used.
                ---eow stands for `end of word` - Recommended to set `virtual_symbol_prefix = ' ' and virtual_symbol_suffix = ''` when used.
                virtual_symbol_position = 'inline',

                ---Highlight hex colors, e.g. '#FFFFFF'
                enable_hex = true,

                ---Highlight short hex colors e.g. '#fff'
                enable_short_hex = true,

                ---Highlight rgb colors, e.g. 'rgb(0 0 0)'
                enable_rgb = true,

                ---Highlight hsl colors, e.g. 'hsl(150deg 30% 40%)'
                enable_hsl = true,

                ---Highlight CSS variables, e.g. 'var(--testing-color)'
                enable_var_usage = true,

                ---Highlight named colors, e.g. 'green'
                enable_named_colors = true,

                ---Highlight tailwind colors, e.g. 'bg-blue-500'
                enable_tailwind = true,

                ---Set custom colors
                ---Label must be properly escaped with '%' to adhere to `string.gmatch`
                --- :help string.gmatch
                custom_colors = {
                    { label = '%-%-theme%-primary%-color', color = '#0f1219' },
                    { label = '%-%-theme%-secondary%-color', color = '#5a5d64' },
                },

                -- Exclude filetypes or buftypes from highlighting e.g. 'exclude_buftypes = {'text'}'
                exclude_filetypes = {},
                exclude_buftypes = {}
            }
            require("nvim-highlight-colors").turnOff()
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

    -- https://github.com/mei28/luminate.nvim
    { 'mei28/luminate.nvim', -- {{{
        enabled = false,
        event = { 'VeryLazy' },
        config = function()
            require 'luminate'.setup({
                duration = 500,
            })
        end
    }, -- }}}
    -- https://github.com/tzachar/highlight-undo
    { 'tzachar/highlight-undo.nvim', -- {{{
        enabled = false,
        opts = {
            duration = 300,
            undo = {
                hlgroup = 'HighlightUndo',
                mode = 'n',
                lhs = 'u',
                map = 'undo',
                opts = {}
            },
            redo = {
                hlgroup = 'HighlightRedo',
                mode = 'n',
                lhs = '<C-r>',
                map = 'redo',
                opts = {}
            },
            highlight_for_count = true,
        },
    }, -- }}}

    -- https://github.com/joshuadanpeterson/typewriter.nvim
    { 'joshuadanpeterson/typewriter', -- {{{
        enabled = false,
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
        },
        config = function()
            require('typewriter').setup({
                keep_cursor_position = false,
            })
        end,
    }, -- }}}
    -- https://github.com/Aasim-A/scrollEOF.nvim
    { 'Aasim-A/scrollEOF.nvim', -- {{{
        event = { 'CursorMoved', 'WinScrolled' },
        opts = {},
        config = function ()
            require('scrollEOF').setup({
                -- The pattern used for the internal autocmd to determine
                -- where to run scrollEOF. See https://neovim.io/doc/user/autocmd.html#autocmd-pattern
                pattern = '*',
                -- Whether or not scrollEOF should be enabled in insert mode
                insert_mode = false,
                -- Whether or not scrollEOF should be enabled in floating windows
                floating = true,
                -- List of filetypes to disable scrollEOF for.
                disabled_filetypes = {},
                -- List of modes to disable scrollEOF for. see https://neovim.io/doc/user/builtin.html#mode()
                disabled_modes = {},
            })
        end
    }, -- }}}

    -- colorschemes
    -- https://github.com/shaunsingh/nord.nvim
    { 'shaunsingh/nord.nvim', -- {{{
        cond = not vim.g.vscode,
        init = function ()
            vim.g.nord_contrast = true
            vim.g.nord_borders = false
            vim.g.nord_disable_background = false
            vim.g.nord_italic = true
            vim.g.nord_bold = true
            vim.g.nord_uniform_diff_background = true
        end,
        config = function ()
            -- vim.api.nvim_set_hl(0, 'Folded', { fg = '#ECEFF4' })
            vim.cmd [[highlight! default link Folded Normal]]
        end,
    }, -- }}}
    -- https://github.com/Shatur/neovim-ayu
    { 'Shatur/neovim-ayu', -- {{{
        cond = not vim.g.vscode,
        config = function ()
            local colors = require('ayu.colors')
            colors.generate(true)
            -- vim.inspect(require('ayu.colors'))
            require('ayu').setup({
                mirage = true,
                overrides = {
                    Folded = { fg = colors.fg, bg = 'None' },
                    FoldColumn = { bg = 'None', fg = colors.guide_normal, },
                    Comment = { fg = colors.ui, italic = true, },
                    Normal = { bg = 'None' },
                    ColorColumn = { bg = 'None' },
                    SignColumn = { bg = 'None' },
                    CursorLine = { bg = 'None' },
                    CursorColumn = { bg = 'None' },
                    WhichKeyFloat = { bg = 'None' },
                    WinSeparator = { bg = 'None' },
                    Search = { bg = '#32522A', fg = colors.string },
                    Tabline = { fg = colors.ui, bg = 'None', },
                    TablineFill = { bg = 'None', },
                },
            })
            vim.cmd[[hi! TablineFill guibg=NONE]]
        end
    }, -- }}}

}
