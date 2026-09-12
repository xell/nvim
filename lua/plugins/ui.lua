-- vim:
return {

    { 'Aasim-A/scrollEOF.nvim',
        event = { 'CursorMoved', 'WinScrolled' },
        opts = {},
    },
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
        cond = not vim.g.vscode,
        main = 'ibl',
        config = function()
            require('ibl').setup({
                indent = { char = '│', highlight = { 'Whitespace' } },
            })
            vim.api.nvim_create_autocmd("User", {
                pattern = "GneovimMarkdownPreviewChanged",
                callback = function(event)
                    require("ibl").setup_buffer(event.data.buf, {
                        enabled = not event.data.preview,
                    })
                end,
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
