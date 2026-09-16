
-- Example: extend the built-in / lspconfig-provided config for lua_ls
vim.lsp.config('lua_ls', {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { { '.luarc.json', '.luarc.jsonc', '.git' } },
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            completion = {
                enable = true,
            },
            diagnostics = {
                enable = true,
                globals = { 'vim' },
            },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                    '${3rd}/luv/library',
                },
            },
            telemetry = { enable = false },
        },
    },
})


-- https://writewithharper.com/docs/integrations/neovim
vim.lsp.config('harper-ls', {
    cmd = {
        'harper-ls',
        '--stdio',
    },
    capabilities = { textDocument = { semanticTokens = { multilineTokenSupport = true } } },
    root_markers = { '.git' },
    filetypes = { 'markdown' },
    settings = {
        ["harper-ls"] = {
            userDictPath = "~/.config/harper/dict.txt",
            linters = {
                AvoidCurses = false,
                SpellCheck = true,
                SpelledNumbers = false,
                AnA = true,
                SentenceCapitalization = true,
                UnclosedQuotes = true,
                WrongApostrophe = false,
                LongSentences = true,
                RepeatedWords = true,
                Spaces = true,
                CorrectNumberSuffix = true
            },
            markdown = {
                IgnoreLinkTitle = false
            },
            dialect = "British",
        },
    }
})

-- Enable one or more servers
-- vim.lsp.enable('lua_ls')
vim.lsp.enable({
    'lua_ls',
    -- 'harper-ls',
})

vim.diagnostic.config({
    severity_sort = true,
    update_in_insert = false,
    float = {
        border = 'rounded',
        source = 'if_many',
        style = "minimal",
    },
    underline = true,
    -- virtual_text = {
    --     spacing = 2,
    --     source = 'if_many',
    --     prefix = '●',
    -- },
    virtual_lines = {
        current_line = true, -- only show for the line your cursor is on, keeps it from being noisy
        overflow = "wrap",   -- 'trunc' | 'scroll' | 'wrap' | 'auto' (default: auto)
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
        },
    },
    jump = {
        on_jump = function(_, bufnr)
            vim.diagnostic.open_float({ bufnr = bufnr, scope = 'cursor', focus = false })
        end,
    },
})

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local bufnr = args.buf
        local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map('n', '<Leader><Leader>h', vim.lsp.buf.hover, 'LSP Hover')
        map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
        map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
        map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
        map('n', 'gr', vim.lsp.buf.references, 'References')
        map('n', '<Leader><Leader>n', vim.lsp.buf.rename, 'Rename symbol')
        map({ 'n', 'v' }, '<Leader><Leader>c', vim.lsp.buf.code_action, 'Code action')
        map('n', '<Leader><Leader>f', function()
            vim.lsp.buf.format({ async = true })
        end, 'Format buffer')
        map("n", "<Leader><Leader>e", vim.diagnostic.open_float, "Show diagnostic Error messages")
        map("n", "<Leader><Leader>q", vim.diagnostic.setloclist, "Open diagnostic Quickfix list")
        map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
        map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")

        -- local disabled_filetypes = { "markdown", }
        -- local current_ft = vim.bo[args.buf].filetype
        --
        -- if vim.tbl_contains(disabled_filetypes, current_ft) then
        --     -- Defer detachment until Neovim finishes attaching the client
        --     vim.schedule(function()
        --         if vim.api.nvim_buf_is_valid(args.buf) then
        --             vim.lsp.buf_detach_client(args.buf, args.data.client_id)
        --         end
        --     end)
        --     return
        -- end

        -- Diagnostic toggle hide or show
        vim.keymap.set('n', '<Leader><Leader>H', function ()
            -- first time, setup b:diagnostic_show and hide
            if vim.b.diagnostic_show == nil then
                vim.diagnostic.hide(nil, 0)
                vim.b.diagnostic_show = false
                vim.print('Hide the diagnostic info.')
            elseif vim.b.diagnostic_show == true then
                vim.diagnostic.hide(nil, 0)
                vim.b.diagnostic_show = false
                vim.print('Hide the diagnostic info.')
            elseif vim.b.diagnostic_show == false then
                vim.diagnostic.show(nil, 0)
                vim.b.diagnostic_show = true
                vim.print('Show the diagnostic info.')
            end
        end, { desc = 'Diagnostic toggle hide or show' })

    end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspDisable", { clear = true }),
    callback = function(args)
        local disabled_filetypes = { "markdown", "text", "gitcommit" }
        local current_ft = vim.bo[args.buf].filetype

        if vim.tbl_contains(disabled_filetypes, current_ft) then
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client then
                vim.lsp.buf_detach_client(args.buf, client.id)
            end
        end
    end,
})

