-- vim:
return {

    -- https://github.com/onewu867/ime-smart.nvim
    { "onewu867/ime-smart.nvim",
      enabled = false,
      opts = {
        command = "/opt/homebrew/bin/im-select",
        english_id = "com.apple.keylayout.ABC",
        comment_id = "com.apple.inputmethod.SCIM.Shuangpin",
        insert_leave_delay_ms = 30,
        remember_last_insert = false,
        contextual_switch = true,
      },
    },

    -- https://github.com/chojs23/im-switch.nvim
    { "chojs23/im-switch.nvim",
      enabled = true,
      event = "VeryLazy",
      build = "make build", -- or "make build-wsl-win" for WSL
      config = function()
        require('im-switch').setup({
          -- Configuration options (see below)
          -- Path to the binary (auto-detected if not specified)
          binary_path = 'im-select',

          -- Default input method ID (platform-specific defaults)
          -- macOS: 'com.apple.keylayout.ABC'
          -- WSL: 'en-US'
          -- Linux: 'us' (XKB), 'xkb:us::eng' (IBus), 'keyboard-us' (Fcitx)
          -- Windows: 'en-US'
          default_input = 'com.apple.keylayout.ABC', -- Uses platform default

          -- Auto-switch to default input in normal mode (default: true)
          auto_switch = true,

          -- Turn Caps Lock off while switching to default input (default: true)
          auto_capslock_off = true,

          -- Enable debug logging (default: false)
          debug = false,
        })
      end,
    },

    -- https://github.com/keaising/im-select.nvim
    { "keaising/im-select.nvim",
        enabled = false,
        config = function()
            require('im_select').setup({
            -- IM will be set to `default_im_select` in `normal` mode
            -- For Windows/WSL, default: "1033", aka: English US Keyboard
            -- For macOS, default: "com.apple.keylayout.ABC", aka: US
            -- For Linux, default:
            --               "keyboard-us" for Fcitx5
            --               "1" for Fcitx
            --               "xkb:us::eng" for ibus
            -- You can use `im-select` or `fcitx5-remote -n` to get the IM's name
            default_im_select  = "com.apple.keylayout.ABC",

            -- Can be binary's name, binary's full path, or a table, e.g. 'im-select',
            -- '/usr/local/bin/im-select' for binary without extra arguments,
            -- or { "AIMSwitcher.exe", "--imm" } for binary need extra arguments to work.
            -- For Windows/WSL, default: "im-select.exe"
            -- For macOS, default: "macism"
            -- For Linux, default: "fcitx5-remote" or "fcitx-remote" or "ibus"
            default_command = "macism",

            -- Restore the default input method state when the following events are triggered
            -- "VimEnter" and "FocusGained" were removed for causing problems, add it by your needs
            set_default_events = { "InsertLeave", "CmdlineLeave" },

            -- Restore the previous used input method state when the following events
            -- are triggered, if you don't want to restore previous used im in Insert mode,
            -- e.g. deprecated `disable_auto_restore = 1`, just let it empty
            -- as `set_previous_events = {}`
            set_previous_events = { "InsertEnter" },

            -- Show notification about how to install executable binary when binary missed
            keep_quiet_on_no_binary = false,

            -- Async run `default_command` to switch IM or not
            async_switch_im = true
            })
        end,
    },

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
            vim.lsp.config('vimls', {
            -- require('lspconfig')['vimls'].setup {
                capabilities = capabilities
            })
            vim.lsp.enable('vimls')

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
                    -- relative to the buffer's directory; triggers after `./`, `../`, `~/` or `/`
                    { name = 'path' },
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

    -- https://github.com/andymass/vim-matchup {{{
    { 'andymass/vim-matchup',
        cond = not vim.g.vscode,
        init = function()
            vim.g.matchup_matchparen_offscreen = { method = 'popup' }
        end,
    }, -- }}}

    -- https://github.com/meanderingprogrammer/render-markdown.nvim {{{
    { "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            -- Add this only if you do not already load another icon provider:
            -- "nvim-tree/nvim-web-devicons",
        },
        opts = {
            enabled = true,

            -- These are the upstream defaults. They make the grid renderer
            -- active in Normal, command line, and terminal modes.
            render_modes = { "n", "c", "t" },

            -- Keep the plugin's normal grid mode table renderer enabled.
            -- Gneovim disables the whole plugin while CM6 preview is active,
            -- so it cannot compete with the island's semantic HTML tables.
            pipe_table = {
                enabled = true,
            },
        },
        config = function(_, opts)
            local render_markdown = require("render-markdown")
            render_markdown.setup(opts)

            local group = vim.api.nvim_create_augroup(
                "gneovim_render_markdown",
                { clear = true }
            )

            -- render-markdown is buffer scoped, whereas Gneovim preview is
            -- window scoped. If any visible window for this buffer uses CM6,
            -- choose the safe buffer wide policy and disable render-markdown.
            local function buffer_has_live_preview(buf)
                for _, win in ipairs(vim.fn.win_findbuf(buf)) do
                    if vim.w[win].gnv_md_preview == 1 then
                        return true
                    end
                end
                return false
            end

            local function sync(buf, preferred_win)
                if not vim.api.nvim_buf_is_valid(buf) then
                    return
                end

                local win = preferred_win
                if not win
                    or not vim.api.nvim_win_is_valid(win)
                    or vim.api.nvim_win_get_buf(win) ~= buf
                then
                    win = vim.fn.bufwinid(buf)
                end
                if win == -1 then
                    return
                end

                vim.api.nvim_win_call(win, function()
                    render_markdown.set_buf(not buffer_has_live_preview(buf))
                end)
            end

            vim.api.nvim_create_autocmd("User", {
                group = group,
                pattern = "GneovimMarkdownPreviewChanged",
                callback = function(event)
                    sync(event.data.buf, event.data.win)
                end,
            })

            -- Covers the rare case where this plugin is lazy loaded after the
            -- initial Gneovim preview event was already emitted.
            vim.schedule(function()
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == "markdown" then
                        sync(buf, win)
                    end
                end
            end)
        end,
    } -- }}}
}
