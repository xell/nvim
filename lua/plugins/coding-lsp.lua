-- vim:foldlevel=1
return {
    -- https://github.com/neovim/nvim-lspconfig
    { 'neovim/nvim-lspconfig', -- {{{
        config = function()
            -- local lspconfig = require('lspconfig')

            -- Global mappings.
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
                    vim.keymap.del('n', 'K', { buffer = ev.buf })
                    -- Enable completion triggered by <c-x><c-o>
                    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

                    -- Buffer local mappings.
                    -- See `:help vim.lsp.*` for documentation on any of the below functions
                    local opts = { buffer = ev.buf }
                    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                    vim.keymap.set('n', '<Leader><Leader>h', vim.lsp.buf.hover, opts)
                    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                    vim.keymap.set('n', '<Leader><Leader>k', vim.lsp.buf.signature_help, opts)
                    vim.keymap.set('n', '<Leader><Leader>wa', vim.lsp.buf.add_workspace_folder, opts)
                    vim.keymap.set('n', '<Leader><Leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
                    vim.keymap.set('n', '<Leader><Leader>wl', function()
                        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                    end, opts)
                    vim.keymap.set('n', '<Leader><Leader>D', vim.lsp.buf.type_definition, opts)
                    vim.keymap.set('n', '<Leader><Leader>n', vim.lsp.buf.rename, opts)
                    vim.keymap.set({ 'n', 'v' }, '<Leader><Leader>ca', vim.lsp.buf.code_action, opts)
                    vim.keymap.set('n', '<Leader><Leader>r', vim.lsp.buf.references, opts)
                    vim.keymap.set('n', '<Leader><Leader>f', function() vim.lsp.buf.format { async = true } end, opts)
                end,
            })

            -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

            -- javascript typescript
            require'lspconfig'.tsserver.setup {
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

    -- https://github.com/hrsh7th/nvim-cmp
    { 'hrsh7th/nvim-cmp', -- {{{
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

            local luasnip = require'luasnip'
            -- Require function for tab to work with LUA-SNIP
            -- https://github.com/Abstract-IDE/Abstract/blob/820114632dbc047f8bbb62bb67fc949bd6433e90/lua/plugins/cmp.lua#L100-L121
            local has_words_before = function()
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and
                    vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
                    :sub(col, col)
                    :match('%s') == nil
            end

            local cmp = require'cmp'
            cmp.setup({ -- {{{
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
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
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
                }, {
                    { name = 'buffer' },
                })
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
                    name = 'cmdline'
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

    -- https://github.com/IsWladi/Gittory
    { 'IsWladi/Gittory', -- {{{
        -- for MVP version of the plugin
        branch = 'main',
        dependencies = {
            -- {'rcarriga/nvim-notify'}, -- optional
        },
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
        config = function()
            vim.keymap.set('n', '<Leader>gs', vim.cmd.G)
            vim.keymap.set('n', '<Leader>gd', vim.cmd.Gvdiffsplit)
        end,
    }, -- }}}
    -- https://github.com/lewis6991/gitsigns.nvim
    { 'lewis6991/gitsigns.nvim', -- {{{
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
}
