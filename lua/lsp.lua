
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

-- Enable one or more servers
vim.lsp.enable('lua_ls')

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

        map('n', 'K', vim.lsp.buf.hover, 'LSP Hover')
        map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
        map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
        map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
        map('n', 'gr', vim.lsp.buf.references, 'References')
        map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
        map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, 'Code action')
        map('n', '<leader>f', function()
            vim.lsp.buf.format({ async = true })
        end, 'Format buffer')
        map("n", "<leader>e", vim.diagnostic.open_float, "Show diagnostic Error messages")
        map("n", "<leader>q", vim.diagnostic.setloclist, "Open diagnostic Quickfix list")
        map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
        map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
    end,
})
