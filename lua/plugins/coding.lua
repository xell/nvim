-- vim:
return {
    -- https://github.com/neovim/nvim-lspconfig
    { 'neovim/nvim-lspconfig', -- {{{
        cond = not vim.g.vscode,
        config = function()
            -- local lspconfig = require('lspconfig')

            -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

            -- ltex
            require 'lspconfig'.ltex.setup {
                filetypes = { 'bib', 'markdown', 'org', 'plaintex', 'rst', 'rnoweb', 'tex' },
                ---@diagnostic disable-next-line: unused-local
                on_attach = function(client, bufnr)
                    print('Loading ltex ...')
                    require('ltex_extra').reload()
                    vim.wo.signcolumn = 'yes'
                end,
                autostart = false,
                settings = {
                    ltex = {
                        checkFrequency = ({ 'edit', 'save', })[1],
                        sentenceCacheSize = 6000,
                        -- https://valentjn.github.io/ltex/settings.html#language
                        language = 'en-US', -- 'en-GB' 'en-US' 'zh-CN'
                        disabledRules = {
                            ['en-US'] = { 'PROFANITY' }, -- Don't censor my speech :-)
                        },
                        additionalRules = {
                            enablePickyRules = true,
                            motherTongue = 'zh-CN',
                            -- https://medium.com/@Erik_Krieg/free-and-open-source-grammar-correction-in-neovim-using-ltex-and-n-grams-dea9d10bc964
                            -- test: This is there last chance to escape.
                            languageModel = vim.fn.expand('~') .. '/Resources/Libs/lsp-language-model/ngrams/',
                        },
                        -- https://seniormars.com/posts/neovim-workflow/
                        diagnosticSeverity = {
                            EN_A_VS_AN = 'error',
                            MORFOLOGIK_RULE_EN_US = 'error',
                            EN_CONTRACTION_SPELLING = 'error',
                            CONFUSED_WORDS = 'warning',
                            DATE_WEEKDAY = 'warning',
                            UPPERCASE_SENTENCE_START = 'warning',
                            AI_EN_LECTOR_MISSING_PUNCTUATION_COMMA = 'hint',
                            APOS_AR = 'hint',
                            DOUBLE_HYPHEN = 'hint',
                            EN_SPECIFIC_CASE = 'hint',
                            IN_A_X_MANNER = 'hint',
                            PASSIVE_VOICE = 'hint',
                            SENT_START_CONJUNCTIVE_LINKING_ADVERB_COMMA = 'hint',
                            default = 'information',
                        },
                        -- https://valentjn.github.io/ltex/settings.html#ltexdictionary
                        -- configurationTarget
                    },
                },

            }

            -- javascript typescript
            require 'lspconfig'.ts_ls.setup {
                init_options = {
                    -- plugins = {
                    --     {
                    --         name = '@vue/typescript-plugin',
                    --         location = '/usr/local/lib/node_modules/@vue/typescript-plugin',
                    --         languages = {'javascript', 'typescript', 'vue'},
                    --     },
                    -- },
                },
                filetypes = {
                    'javascript',
                    'typescript',
                    -- 'vue',
                },
            }

            -- lua
            require 'lspconfig'.lua_ls.setup {
                -- https://www.reddit.com/r/neovim/comments/13uklyy/lua_ls_lspconfig_not_working/
                -- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/lua_ls.lua
                settings = {
                    Lua = {
                        hint = {
                            enable = true, -- necessary
                        },
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
                                vim.api.nvim_get_runtime_file('', true),
                                vim.env.VIMRUNTIME,
                                '/Users/xell/Developer/src/yazi/yazi-plugin/preset',
                                '/Users/xell/Developer/src/yazi/yazi-plugin/preset/components',
                                '/Users/xell/Developer/src/yazi/yazi-plugin/preset/plugins',
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

            -- vim
            require 'lspconfig'.vimls.setup {
                -- https://github.com/iamcco/vim-language-server
                -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#vimls
                cmd = { 'vim-language-server', '--stdio' },
                filetype = { 'vim' },
                init_options = {
                    diagnostic = {
                        enable = true
                    },
                    indexes = {
                        count = 3,
                        gap = 100,
                        projectRootPatterns = { 'strange-root-pattern', 'runtime', 'nvim', '.git', 'autoload', 'plugin' },
                        runtimepath = true
                    },
                    isNeovim = true,
                    iskeyword = '@,48-57,_,192-255,-#',
                    runtimepath = '/Users/xell/.config/nvim,/Users/xell/.local/share/nvim',
                    vimruntime = vim.env.VIMRUNTIME,
                    suggest = {
                        fromRuntimepath = true,
                        fromVimruntime = true
                    },
                },
                single_file_support = true,
            }
        end,
    }, -- }}}
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
    -- https://github.com/aznhe21/actions-preview.nvim
    { 'aznhe21/actions-preview.nvim',
        cond = not vim.g.vscode,
        config = function()
            require('actions-preview').setup {
                diff = {
                    algorithm = 'patience',
                    ignore_whitespace = false,
                },
                -- telescope = require('telescope.themes').get_dropdown(), -- { winblend = 10 },
                telescope = {
                    layout_strategy = 'flex',
                    layout_config = {
                        flex = { flip_columns = 110, },
                        preview_cutoff = 10,
                    },
                },
                backend = { 'telescope', 'nui' },
                highlight_command = {
                    require('actions-preview.highlight').delta('delta --no-gitconfig --side-by-side --wrap-max-lines unlimited')
                },
            }
            vim.keymap.set({ 'v', 'n' }, '<Leader><Leader>C', require('actions-preview').code_actions, { desc = 'LSP code action preview' })
        end,
    },
    -- https://github.com/ray-x/lsp_signature.nvim
    { 'ray-x/lsp_signature.nvim', -- {{{
        -- for keys, see ../lsp.lua
        cond = not vim.g.vscode,
        event = 'VeryLazy',
        opts = {},
        config = function(_, opts)
            require 'lsp_signature'.setup(opts)
        end,
    }, -- }}}

    -- https://github.com/rachartier/tiny-inline-diagnostic.nvim
    { 'rachartier/tiny-inline-diagnostic.nvim', -- {{{
        cond = not vim.g.vscode,
        event = 'VeryLazy',
        config = function()
            -- vim.opt.updatetime = 100
            require('tiny-inline-diagnostic').setup({
                signs = {
                    left = ({'', ''})[1],
                    right = ({'', ''})[1],
                    diag = '●',
                    arrow = '    ',
                    up_arrow = '    ',
                    vertical = ' │',
                    vertical_end = ' └'
                },
                hi = {
                    error = 'DiagnosticError',
                    warn = 'DiagnosticWarn',
                    info = 'DiagnosticInfo',
                    hint = 'DiagnosticHint',
                    arrow = 'NonText',
                    background = 'CursorLine', -- Can be a highlight or a hexadecimal color (#RRGGBB)
                    mixing_color = 'None',  -- Can be None or a hexadecimal color (#RRGGBB). Used to blend the background color with the diagnostic background color with another color.
                },
                blend = {
                    factor = 0.27,
                },
                options = {
                    -- Throttle the update of the diagnostic when moving cursor, in milliseconds.
                    -- You can increase it if you have performance issues.
                    -- Or set it to 0 to have better visuals.
                    throttle = 20,

                    -- The minimum length of the message, otherwise it will be on a new line.
                    softwrap = 15,

                    -- If multiple diagnostics are under the cursor, display all of them.
                    multiple_diag_under_cursor = true,

                    overflow = {
                        -- Manage the overflow of the message.
                        --    - wrap: when the message is too long, it is then displayed on multiple lines.
                        --    - none: the message will not be truncated, and will be displayed on a single line.
                        mode = "wrap",
                    },

                    --- Enable it if you want to always have message with `after` characters length.
                    break_line = {
                        enabled = false,
                        after = 30,
                    },

                    virt_texts = {
                        priority = 2048,
                    },
                },
            })
            local inline_diagnostic = vim.api.nvim_create_augroup('inlineDiagnostic', { clear = true })
            -- https://github.com/rachartier/tiny-inline-diagnostic.nvim/issues/18
            vim.api.nvim_create_autocmd({ 'LspAttach', 'ColorScheme' }, {
                pattern = '*',
                group = inline_diagnostic,
                callback = function(_)
                    if vim.o.background == 'light' then
                        require('tiny-inline-diagnostic').change({ factor = 10 }, { mixing_color = 'None' })
                    else
                        require('tiny-inline-diagnostic').change({ factor = 0.27 }, { mixing_color = 'None' })
                    end
                end,
            })
        end
    }, -- }}}
    -- https://github.com/j-hui/fidget.nvim
    { 'j-hui/fidget.nvim', -- {{{
        cond = not vim.g.vscode,
        opts = {},
    }, -- }}}

    -- https://github.com/hrsh7th/nvim-cmp
    { 'hrsh7th/nvim-cmp', -- {{{
        cond = not vim.g.vscode,
        -- event = 'InsertEnter',
        dependencies = { -- {{{
            'neovim/nvim-lspconfig',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            -- 'hrsh7th/cmp-vsnip',
            -- 'hrsh7th/vim-vsnip',
            'L3MON4D3/LuaSnip',
            'saadparwaiz1/cmp_luasnip',
            'onsails/lspkind.nvim',
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

            local luasnip = require 'luasnip'
            -- Require function for tab to work with LUA-SNIP
            -- https://github.com/Abstract-IDE/Abstract/blob/820114632dbc047f8bbb62bb67fc949bd6433e90/lua/plugins/cmp.lua#L100-L121
            local has_words_before = function()
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and
                    vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
                        :sub(col, col)
                        :match('%s') == nil
            end

            local cmp = require 'cmp'
            cmp.setup({ -- {{{
                -- completion = {
                --     -- completeopt = 'menu,menuone,noinsert',
                --     completeopt = 'menu,noinsert',
                -- },
                -- preselect = cmp.PreselectMode.Item,
                experimental = { ghost_text = true },
                formatting = {
                    -- https://github.com/brenoprata10/nvim-highlight-colors/
                    format = function(entry, item)
                        local color_item = require("nvim-highlight-colors").format(entry, { kind = item.kind })
                        item = require("lspkind").cmp_format({
                            -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
                            mode = 'symbol',
                            maxwidth = 50,
                            ellipsis_char = '...',
                            show_labelDetails = true,
                        })(entry, item)
                        if color_item.abbr_hl_group then
                            item.kind_hl_group = color_item.abbr_hl_group
                            item.kind = color_item.abbr
                        end
                        return item
                    end
                },
                snippet = {
                    -- REQUIRED - you must specify a snippet engine
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                    end,
                },
                window = {
                    -- completion = cmp.config.window.bordered(),
                    -- documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-k>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-j>'] = cmp.mapping.scroll_docs(4),
                    -- https://www.reddit.com/r/neovim/comments/1axmx9e/trigger_completion_suggestions_manually_with/
                    ['<C-Space>'] = cmp.mapping.complete(),
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
                    { name = 'luasnip' }, -- For luasnip users.
                    {
                        name = 'dictionary',
                        keyword_length = 3,
                    },
                }, { { name = 'buffer' }, })
            })

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
                        name = 'cmdline',
                    } }),
                matching = { disallow_symbol_nonprefix_matching = false },
            })
            -- }}}

            local cmp_enabled = true -- {{{
            -- https://github.com/hrsh7th/nvim-cmp/issues/106
            vim.api.nvim_create_user_command('CmpAutoCompleteToggle', function()
                if cmp_enabled then
                    require('cmp').setup.buffer({ enabled = false })
                    cmp_enabled = false
                else
                    require('cmp').setup.buffer({ enabled = true })
                    cmp_enabled = true
                end
            end, {})

            vim.api.nvim_create_user_command('CmpAutoCompleteEnable', function()
                require('cmp').setup.buffer({ enabled = true })
            end, {})
            vim.api.nvim_create_user_command('CmpAutoCompleteDisable', function()
                require('cmp').setup.buffer({ enabled = false })
            end, {})

            vim.api.nvim_create_autocmd('FileType', {
                pattern = { 'markdown', 'outlinex' },
                callback = function()
                    -- require('cmp').setup.buffer({ enabled = false })
                    require('cmp').setup.buffer({
                        completion = {
                            autocomplete = false,
                        },
                    })
                end,
            })
            -- }}}
        end,
    }, -- }}}
    -- https://github.com/uga-rosa/cmp-dictionary
    { 'uga-rosa/cmp-dictionary', -- {{{
        cond = not vim.g.vscode,
        dependencies = {
            'hrsh7th/nvim-cmp',
        },
        config = function ()
            require('cmp_dictionary').setup({
                paths = { '/usr/share/dict/words' },
                exact_length = 3,
                first_case_insensitive = true,
                document = {
                    enable = true,
                    command = { 'wn', '${label}', '-over' },
                },
                -- external = {
                --     enable = true,
                --     command = { 'look', '${prefix}', '${path}' },
                -- },
            })
        end,
    }, -- }}}

    -- https://github.com/IsWladi/Gittory
    { 'IsWladi/Gittory', -- {{{
        cond = not vim.g.vscode,
        -- for MVP version of the plugin
        branch = 'main',
        dependencies = {
            { 'rcarriga/nvim-notify' }, -- optional
        },
        config = function ()
            require("notify").setup({
                background_colour = "#f00000",
            })
        end,
        opts = { -- you can omit this, is the default
            atStartUp = true, -- If you want to initialize Gittory when Neovim starts

            notifySettings = {
                enabled = true, -- This flag enables the notification system, allowing Gittory to send alerts about its operational status changes.

                -- rcarriga/nvim-notify serves as the default notification plugin. However, alternative plugins can be used, provided they include the <plugin-name>.notify(message) method.
                -- you can change the order of priority for the plugins or remove those you don't use.
                -- If one of the specified notification plugins is not installed, the next one in the list will be used.
                -- 'print' is the native notification plugin for Neovim; it will print messages to the command line.
                -- The 'print' string is included for clarity. If removed, 'print' will still be used if the other specified plugins are not installed.
                availableNotifyPlugins =  {'notify', 'print'} -- for example; you can use 'fidget' instead of 'notify'
            }
        },
    }, -- }}}
    -- https://github.com/tpope/vim-fugitive
    { 'tpope/vim-fugitive', -- {{{
        cond = not vim.g.vscode,
        config = function()
            vim.keymap.set('n', '<Leader>gs', vim.cmd.G, { desc = 'Open git status' })
            vim.keymap.set('n', '<Leader>gd', vim.cmd.Gvdiffsplit, { desc = 'Open git diff vert' })
        end,
    }, -- }}}
    -- https://github.com/lewis6991/gitsigns.nvim
    { 'lewis6991/gitsigns.nvim', -- {{{
        cond = not vim.g.vscode,
        config = function()
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
                    end, { desc = 'Gitsigns next hunk' })

                    map('n', '[c', function()
                        if vim.wo.diff then
                            vim.cmd.normal({ '[c', bang = true })
                        else
                            gitsigns.nav_hunk('prev')
                        end
                    end, { desc = 'Gitsigns previous hunk' })
                    map('n', '<Leader>hd', gitsigns.diffthis, { desc = 'Gitsigns diffthis' })
                    map('n', '<Leader>hD', function() gitsigns.diffthis('~') end, { desc = 'Gitsigns diffthis ~' })
                end,
            }
        end
    }, -- }}}

    -- https://github.com/nvim-treesitter/nvim-treesitter
    { 'nvim-treesitter/nvim-treesitter', -- {{{
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup({
                modules = {},
                ensure_installed = { 'c', 'lua', 'vim', 'vimdoc', 'query', 'markdown', 'markdown_inline', },
                markdown = {
                    enable = true,
                    -- configuration here or nothing for defaults
                },
                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,
                -- Automatically install missing parsers when entering buffer
                auto_install = true,
                -- List of parsers to ignore installing (or 'all')
                ignore_install = {},
                highlight = {
                    enable = true,
                    -- additional_vim_regex_highlighting = { 'markdown', 'markdown_line', 'outlinex', 'help', },
                    additional_vim_regex_highlighting = { 'markdown', 'outlinex', 'help', },
                },
                indent = {
                    enable = true
                },
                matchup = {
                    enable = true, -- mandatory, false will disable the whole extension
                    -- disable = { "c", "ruby" }, -- optional, list of language that will be disabled
                },
            })
            vim.treesitter.language.register('markdown', 'outlinex')
            -- vim.treesitter.language.register('markdown_inline', 'outlinex')
        end,
    }, -- }}}
    -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    { 'nvim-treesitter/nvim-treesitter-textobjects', -- {{{
        event = 'InsertEnter',
        config = function ()
            require('nvim-treesitter.configs').setup({
                highlight = {enable = true, disable = {'latex'}},
                indent = {enable = true, disable = {'python'}},
                textobjects = {
                    move = {
                        enable = true,
                        set_jumps = true, -- whether to set jumps in the jumplist
                        goto_next_start = {
                            [']m'] = '@function.outer',
                            [']]'] = {query = '@class.outer', desc = 'Next class start'},
                            [']p'] = {
                                query = '@scope',
                                query_group = 'locals',
                                desc = 'Next scope'
                            }
                        },
                        goto_previous_start = {
                            ['[m'] = '@function.outer',
                            ['[['] = '@class.outer'
                        },
                        goto_next_end = {
                            [']M'] = '@function.outer',
                            [']['] = '@class.outer'
                        },
                        goto_previous_end = {
                            ['[M'] = '@function.outer',
                            ['[]'] = '@class.outer'
                        },
                        goto_next = {[']D'] = '@conditional.outer'},
                        goto_previous = {['[D'] = '@conditional.outer'}
                    },
                    swap = {
                        enable = true,
                        swap_next = {['<leader>wn'] = '@parameter.inner'},
                        swap_previous = {['<leader>wp'] = '@parameter.inner'}
                    },
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ['af'] = '@function.outer',
                            ['if'] = '@function.inner',
                            ['ac'] = '@class.outer',
                            ['ic'] = '@class.inner'
                        },
                        selection_modes = {
                            ['@parameter.outer'] = 'v', -- charwise
                            ['@function.outer'] = 'V', -- linewise
                            ['@class.outer'] = '<c-v>' -- blockwise
                        }
                    }
                },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = '<LocalLeader>i',
                        scope_incremental = '<LocalLeader>i',
                        node_incremental = '<LocalLeader>n',
                        node_decremental = '<LocalLeader>p'
                    }
                }
            })
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
            vim.keymap.set('n', '<Leader><Leader>a', '<cmd>AerialToggle!<CR>')
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
                on_attach = function (bufnr)
                    return vim.bo[bufnr].filetype ~= 'markdown'
                end,
            }
        end
    }
}
