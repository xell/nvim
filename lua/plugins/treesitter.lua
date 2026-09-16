-- vim:
return {
    -- https://neovim.io/doc/user/treesitter/
    -- https://github.com/nvim-treesitter/nvim-treesitter
    -- NOTE: the `main` branch is a rewrite (needs nvim >= 0.11). There is no
    -- `nvim-treesitter.configs` / module system any more: highlighting and
    -- indentation are enabled per buffer via a FileType autocmd, and parsers
    -- are installed with `require('nvim-treesitter').install()`.
    { 'nvim-treesitter/nvim-treesitter', -- {{{
        cond = not vim.g.vscode,
        branch = 'main',
        build = ':TSUpdate',
        config = function()
            local ts = require('nvim-treesitter')

            -- The only option `setup` takes on `main` is `install_dir`
            -- (defaults to stdpath('data') .. '/site').
            ts.setup({})

            -- Replaces `ensure_installed`. Async; no-op for parsers already installed.
            ts.install({
                'javascript', 'html', 'css', 'typescript',
                'json', 'rust', 'lua', 'c', 'diff',
                'markdown', 'vim', 'vimdoc', 'query',
            })

            -- Replaces `highlight.disable` / `indent.disable`.
            local no_highlight = { latex = true }
            local no_indent = { python = true }

            -- Replaces `auto_install`: remember what we already tried so a
            -- parser that fails to build isn't retried on every buffer.
            local attempted = {}

            local function attach(buf, lang)
                if not vim.api.nvim_buf_is_valid(buf) then return end
                if not no_highlight[lang] then
                    -- Replaces `highlight.enable`.
                    pcall(vim.treesitter.start, buf, lang)
                end
                if not no_indent[lang] then
                    -- Replaces `indent.enable`.
                    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end

            vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('my_treesitter', { clear = true }),
                callback = function(args)
                    local buf = args.buf
                    local lang = vim.treesitter.language.get_lang(args.match)
                    if not lang then return end

                    -- Parser already available?
                    if vim.treesitter.language.add(lang) then
                        attach(buf, lang)
                        return
                    end

                    -- Not installed: install it if nvim-treesitter knows it,
                    -- then attach once the install finishes.
                    if attempted[lang] or not require('nvim-treesitter.parsers')[lang] then
                        return
                    end
                    attempted[lang] = true
                    ts.install({ lang }):await(function(err)
                        if err then return end
                        vim.schedule(function()
                            if vim.treesitter.language.add(lang) then
                                attach(buf, lang)
                            end
                        end)
                    end)
                end,
            })

            -- Replaces the `incremental_selection` module, which was removed.
            -- Neovim 0.12 has this built in: `an` (parent node), `in` (child
            -- node), `]n`/`[n` (siblings) in visual mode. See
            -- :h treesitter-incremental-selection
            vim.keymap.set('n', '<LocalLeader>i', 'van', { remap = true, desc = 'Select node under cursor' })
            vim.keymap.set('x', '<LocalLeader>i', 'an', { remap = true, desc = 'Expand selection to parent node' })
            vim.keymap.set('x', '<LocalLeader>n', 'an', { remap = true, desc = 'Expand selection to parent node' })
            vim.keymap.set('x', '<LocalLeader>p', 'in', { remap = true, desc = 'Shrink selection to child node' })
        end,
    }, -- }}}
    -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    -- NOTE: `main` branch here too: it has its own `setup` for options, and
    -- keymaps are plain `vim.keymap.set` calls into its select/move/swap modules.
    { 'nvim-treesitter/nvim-treesitter-textobjects', -- {{{
        cond = not vim.g.vscode,
        branch = 'main',
        event = 'VeryLazy',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function ()
            require('nvim-treesitter-textobjects').setup({
                select = {
                    lookahead = true,
                    selection_modes = {
                        ['@parameter.outer'] = 'v', -- charwise
                        ['@function.outer'] = 'V', -- linewise
                        ['@class.outer'] = '<c-v>' -- blockwise
                    },
                },
                move = {
                    set_jumps = true, -- whether to set jumps in the jumplist
                },
            })

            local select = require('nvim-treesitter-textobjects.select')
            local move = require('nvim-treesitter-textobjects.move')
            local swap = require('nvim-treesitter-textobjects.swap')

            -- select
            local function sel(lhs, query, desc)
                vim.keymap.set({ 'x', 'o' }, lhs, function()
                    select.select_textobject(query, 'textobjects')
                end, { desc = desc })
            end
            sel('af', '@function.outer', 'a function')
            sel('if', '@function.inner', 'inner function')
            sel('ac', '@class.outer', 'a class')
            sel('ic', '@class.inner', 'inner class')

            -- move
            local function mv(lhs, fn, query, group, desc)
                vim.keymap.set({ 'n', 'x', 'o' }, lhs, function()
                    move[fn](query, group or 'textobjects')
                end, { desc = desc })
            end
            mv(']m', 'goto_next_start', '@function.outer', nil, 'Next function start')
            mv(']]', 'goto_next_start', '@class.outer', nil, 'Next class start')
            mv(']p', 'goto_next_start', '@local.scope', 'locals', 'Next scope')
            mv('[m', 'goto_previous_start', '@function.outer', nil, 'Previous function start')
            mv('[[', 'goto_previous_start', '@class.outer', nil, 'Previous class start')
            mv(']M', 'goto_next_end', '@function.outer', nil, 'Next function end')
            mv('][', 'goto_next_end', '@class.outer', nil, 'Next class end')
            mv('[M', 'goto_previous_end', '@function.outer', nil, 'Previous function end')
            mv('[]', 'goto_previous_end', '@class.outer', nil, 'Previous class end')
            mv(']D', 'goto_next', '@conditional.outer', nil, 'Next conditional')
            mv('[D', 'goto_previous', '@conditional.outer', nil, 'Previous conditional')

            -- swap
            vim.keymap.set('n', '<leader>wn', function()
                swap.swap_next('@parameter.inner')
            end, { desc = 'Swap with next parameter' })
            vim.keymap.set('n', '<leader>wp', function()
                swap.swap_previous('@parameter.inner')
            end, { desc = 'Swap with previous parameter' })
        end
    }, -- }}}
    -- https://github.com/stevearc/aerial.nvim
    { 'stevearc/aerial.nvim', -- {{{
        cond = not vim.g.vscode,
        opts = {},
        -- Optional dependencies
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'nvim-tree/nvim-web-devicons'
        },
        config = function()
            require('aerial').setup({
                backends = { 'treesitter', 'lsp', 'markdown', 'man' },
                -- optionally use on_attach to set keymaps when aerial has attached to a buffer
                on_attach = function(bufnr)
                    -- Jump forwards/backwards with '{' and '}'
                    vim.keymap.set('n', '{', '<cmd>AerialPrev<CR>', { buffer = bufnr })
                    vim.keymap.set('n', '}', '<cmd>AerialNext<CR>', { buffer = bufnr })
                end,
            })
            -- You probably also want to set a keymap to toggle aerial
            vim.keymap.set('n', '<Leader><Leader>a', '<cmd>AerialToggle<CR>')
            vim.keymap.set('n', '<Leader><Leader>A', '<cmd>AerialToggle!<CR>')
            require('telescope').load_extension('aerial')
            require('telescope').setup({
                extensions = {
                    aerial = {
                        -- Display symbols as <root>.<parent>.<symbol>
                        show_nesting = {
                            ['_'] = false, -- This key will be the default
                            json = true,   -- You can set the option for specific filetypes
                            yaml = true,
                        },
                    },
                },
            })
        end,
    }, -- }}}
    -- https://github.com/nvim-treesitter/nvim-treesitter-context
    { 'nvim-treesitter/nvim-treesitter-context',
        cond = not vim.g.vscode,
        config = function ()
            require 'treesitter-context'.setup {
                enable = false, -- Enable this plugin (Can be enabled/disabled later via commands)
                max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
                min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
                line_numbers = true,
                multiline_threshold = 20, -- Maximum number of lines to show for a single context
                trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
                mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
                -- Separator between context and content. Should be a single character string, like '-'.
                -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
                separator = nil,
                zindex = 20, -- The Z-index of the context window
                -- https://github.com/nvim-treesitter/nvim-treesitter-context/issues/172
                -- on_attach = function (bufnr)
                --     return vim.bo[bufnr].filetype ~= 'markdown'
                -- end,
            }
        end
    },
    -- https://github.com/adoyle-h/lsp-toggle.nvim
    { 'adoyle-h/lsp-toggle.nvim', -- {{{
        cond = not vim.g.vscode,
        dependencies = {
            'neovim/nvim-lspconfig',
        },
        config = function ()
            require('lsp-toggle').setup {
                create_cmds = true, -- Whether to create user commands
                telescope = false, -- Whether to load telescope extensions
            }
        end,
    }, -- }}}
}
