-- vim:fdm=marker
-- Diagnostic signs {{{
-- https://www.reddit.com/r/neovim/comments/1d8tq14/setting_up_signs_with_vimdiagnostic/
local diagnostic_icons = {
    ERROR = '',
    WARN =  '',
    HINT =  ({ '', '', '󰌵' })[1],
    INFO =  '',
}

vim.diagnostic.config {
    -- update_in_insert = true,
    virtual_text = ({ {
        -- source = true,  -- Or "if_many"
        prefix = '',
        spacing = 2,
        format = function(diagnostic)
            local icon = diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]]
            local message = vim.split(diagnostic.message, '\n')[1]
            return string.format('%s %s ', icon, message)
        end,
    }, false, })[2],
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = diagnostic_icons.ERROR,
            [vim.diagnostic.severity.WARN] = diagnostic_icons.WARN,
            [vim.diagnostic.severity.INFO] = diagnostic_icons.INFO,
            [vim.diagnostic.severity.HINT] = diagnostic_icons.HINT
        },
    },
    float = {
        border = 'rounded',
        -- format = function(d)
        --     return ('%s (%s) [%s]'):format(d.message, d.source, d.code or d.user_data.lsp.code)
        -- end,
        -- source = true,  -- Or "if_many"
        source = 'if_many',
        -- Show severity icons as prefixes.
        prefix = function(diag)
            local level = vim.diagnostic.severity[diag.severity]
            local prefix = string.format(' %s ', diagnostic_icons[level])
            return prefix, 'Diagnostic' .. level:gsub('^%l', string.upper)
        end,
    },
    underline = true,
    jump = {
        float = true,
    },
}

-- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
local show_handler = vim.diagnostic.handlers.virtual_text.show
assert(show_handler)
local hide_handler = vim.diagnostic.handlers.virtual_text.hide
---@diagnostic disable-next-line: inject-field
vim.diagnostic.handlers.virtual_text = {
    show = function(ns, bufnr, diagnostics, opts)
        table.sort(diagnostics, function(diag1, diag2)
            return diag1.severity > diag2.severity
        end)
        return show_handler(ns, bufnr, diagnostics, opts)
    end,
    hide = hide_handler,
}

-- }}}

-- Global mappings {{{
vim.keymap.set('n', '<Leader><Leader>e', vim.diagnostic.open_float, { desc = 'Diagnostic info' })
-- vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'LSP goto previous' })
-- vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'LSP goto next' })
vim.keymap.set('n', '[d', function ()
    vim.diagnostic.goto_prev({ float = false })
end, { desc = 'LSP goto previous' })
vim.keymap.set('n', ']d', function ()
    vim.diagnostic.goto_next({ float = false })
end, { desc = 'LSP goto next' })
vim.keymap.set('n', '<Leader><Leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostic loclist' })
-- }}}

-- LspAttach mappings {{{
-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true }),
    callback = function(ev)
        -- lsp-defaults-disable
        -- vim.keymap.del('n', 'K', { buffer = ev.buf })
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- information
        vim.keymap.set('n', '<Leader><Leader>h', vim.lsp.buf.hover, { buffer = ev.buf, desc = 'LSP hover' })
        vim.keymap.set('n', '<Leader><Leader>k', vim.lsp.buf.signature_help, { buffer = ev.buf, desc = 'LSP signature_help' })
        vim.keymap.set('n', '<Leader><Leader>o', vim.lsp.buf.document_highlight, { buffer = ev.buf, desc = 'LSP highlight' }) -- TODO autocommand
        vim.keymap.set('n', '<Leader><Leader>O', vim.lsp.buf.clear_references, { buffer = ev.buf, desc = 'LSP highlight' })

        -- Diagnostic toggle update in insert
        vim.keymap.set('n', '<Leader><Leader>E', function ()
            vim.diagnostic.config{ update_in_insert = not vim.diagnostic.config().update_in_insert }
            vim.print('Now the update_in_insert is ' .. tostring(vim.diagnostic.config().update_in_insert) .. '.')
        end, { desc = 'Diagnostic toggle update in insert' })

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

        require('lsp_signature').on_attach({
            hint_enable = false, -- virtual hint enable
            hint_prefix = ({ '🐼 ', '!', })[1],  -- Panda for parameter, NOTE: for the terminal not support emoji, might crash
            -- or, provide a table with 3 icons
            -- hint_prefix = {
            --     above = "↙ ",  -- when the hint is on the line above the current line
            --     current = "← ",  -- when the hint is on the same line
            --     below = "↖ "  -- when the hint is on the line below the current line
            -- }
            hint_inline = function() return 'right_align' end,  -- should the hint be inline(nvim 0.10 only)?  default false
            -- return true | 'inline' to show hint inline, return 'eol' to show hint at end of line, return false to disable
            -- return 'right_align' to display hint right aligned in the current line
            hi_parameter = "LspSignatureActiveParameter", -- how your parameter will be highlight
            auto_close_after = nil, -- autoclose signature float win after x sec, disabled if nil
            transparency = nil, -- disabled by default, allow floating win transparent value 1~100
            toggle_key = '<M-x>', -- toggle signature on and off in insert mode,  e.g. toggle_key = '<M-x>'
            select_signature_key = '<M-n>', -- cycle to next signature, e.g. '<M-n>' function overloading
            move_cursor_key = '<M-p>', -- imap, use nvim_set_current_win to move cursor between current win and floating window
            -- e.g. move_cursor_key = '<M-p>',
            -- once moved to floating window, you can use <M-d>, <M-u> to move cursor up and down
        }, ev.buf)

        -- inlay hint {{{
        -- https://github.com/neovim/neovim/issues/28261#issuecomment-2130338921
        -- https://github.com/chrisgrieser/nvim-lsp-endhints
        -- https://github.com/MysticalDevil/inlay-hints.nvim
        local methods = vim.lsp.protocol.Methods
        local inlay_hint_handler = vim.lsp.handlers[methods["textDocument_inlayHint"]]
        vim.lsp.handlers[methods["textDocument_inlayHint"]] = function(err, result, ctx, config)
            local client = vim.lsp.get_client_by_id(ctx.client_id)
            if client then
                local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
                result = vim.iter(result)
                    :filter(function(hint)
                        return hint.position.line + 1 == row
                    end)
                    :totable()
            end
            inlay_hint_handler(err, result, ctx, config)
        end

        -- onAttach
        local inlay_hints_group = vim.api.nvim_create_augroup('LSP_inlayHints', { clear = false })
        vim.api.nvim_create_autocmd({ 'InsertEnter', 'CursorHoldI' }, {
            group = inlay_hints_group,
            desc = 'Update inlay hints on line change',
            buffer = ev.buf,
            callback = function()
                vim.lsp.inlay_hint.enable(true, {bufnr = ev.buf})
            end,
        })

        -- vim.lsp.inlay_hint.enable(true)
        -- local inlay_hints_group = vim.api.nvim_create_augroup('xell/toggle_inlay_hints', { clear = false })
        -- -- Initial inlay hint display.
        -- -- Idk why but without the delay inlay hints aren't displayed at the very start.
        -- vim.defer_fn(function()
        --     local mode = vim.api.nvim_get_mode().mode
        --     vim.lsp.inlay_hint.enable(mode == 'n' or mode == 'v', { bufnr = ev.buf })
        -- end, 500)
        --
        -- vim.api.nvim_create_autocmd('InsertEnter', {
        --     group = inlay_hints_group,
        --     desc = 'Enable inlay hints',
        --     buffer = ev.buf,
        --     callback = function()
        --         vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        --     end,
        -- })
        vim.api.nvim_create_autocmd('InsertLeave', {
            group = inlay_hints_group,
            desc = 'Disable inlay hints',
            buffer = ev.buf,
            callback = function()
                vim.lsp.inlay_hint.enable(false, { bufnr = ev.buf })
            end,
        })
        -- }}}

        -- not supported by lua
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = ev.buf, desc = 'LSP declaration' })

        -- main
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf, desc = 'LSP definition' })
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = ev.buf, desc = 'LSP implementation' })
        vim.keymap.set('n', '<Leader><Leader>D', vim.lsp.buf.type_definition, { buffer = ev.buf, desc = 'LSP type definition' })
        vim.keymap.set('n', '<Leader><Leader>r', vim.lsp.buf.references, { buffer = ev.buf, desc = 'LSP references' })

        -- action
        vim.keymap.set('n', '<Leader><Leader>n', vim.lsp.buf.rename, { buffer = ev.buf, desc = 'LSP rename' })
        vim.keymap.set({ 'n', 'v' }, '<Leader><Leader>c', vim.lsp.buf.code_action, { buffer = ev.buf, desc = 'LSP code action' })
        vim.keymap.set('n', '<Leader><Leader>f', function() vim.lsp.buf.format { async = true } end, { buffer = ev.buf, desc = 'LSP buf format' })

        -- workspace
        vim.keymap.set('n', '<Leader><Leader>wa', vim.lsp.buf.add_workspace_folder, { buffer = ev.buf, desc = 'LSP add workspace folder' })
        vim.keymap.set('n', '<Leader><Leader>wr', vim.lsp.buf.remove_workspace_folder, { buffer = ev.buf, desc = 'LSP remove workspace folder' })
        vim.keymap.set('n', '<Leader><Leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, { buffer = ev.buf, desc = 'LSP list workspace folder' })
    end,
})
-- }}}

-- Float window beautified {{{
local md_namespace = vim.api.nvim_create_namespace 'mariasolos/lsp_float'

--- Adds extra inline highlights to the given buffer.
---@param buf integer
local function add_inline_highlights(buf)
    for l, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        for pattern, hl_group in pairs {
            ['@%S+'] = '@parameter',
            ['^%s*(Parameters:)'] = '@text.title',
            ['^%s*(Return:)'] = '@text.title',
            ['^%s*(See also:)'] = '@text.title',
            ['{%S-}'] = '@parameter',
            ['|%S-|'] = '@text.reference',
        } do
            local from = 1 ---@type integer?
            while from do
                local to
                from, to = line:find(pattern, from)
                if from then
                    vim.api.nvim_buf_set_extmark(buf, md_namespace, l - 1, from - 1, {
                        end_col = to,
                        hl_group = hl_group,
                    })
                end
                from = to and to + 1 or nil
            end
        end
    end
end

--- LSP handler that adds extra inline highlights, keymaps, and window options.
--- Code inspired from `noice`.
---@param handler fun(err: any, result: any, ctx: any, config: any): integer?, integer?
---@param focusable boolean
---@return fun(err: any, result: any, ctx: any, config: any)
local function enhanced_float_handler(handler, focusable)
    return function(err, result, ctx, config)
        local bufnr, winnr = handler(
            err,
            result,
            ctx,
            vim.tbl_deep_extend('force', config or {}, {
                border = 'rounded',
                focusable = focusable,
                max_height = math.floor(vim.o.lines * 0.5),
                max_width = math.floor(vim.o.columns * 0.4),
            })
        )

        if not bufnr or not winnr then
            return
        end

        -- Conceal everything.
        vim.wo[winnr].concealcursor = 'n'

        -- Extra highlights.
        add_inline_highlights(bufnr)

        -- Add keymaps for opening links.
        if focusable and not vim.b[bufnr].markdown_keys then
            vim.keymap.set('n', 'K', function()
                -- Vim help links.
                local url = (vim.fn.expand '<cWORD>' --[[@as string]]):match '|(%S-)|'
                if url then
                    return vim.cmd.help(url)
                end

                -- Markdown links.
                local col = vim.api.nvim_win_get_cursor(0)[2] + 1
                local from, to
                from, to, url = vim.api.nvim_get_current_line():find '%[.-%]%((%S-)%)'
                if from and col >= from and col <= to then
                    vim.system({ 'xdg-open', url }, nil, function(res)
                        if res.code ~= 0 then
                            vim.notify('Failed to open URL' .. url, vim.log.levels.ERROR)
                        end
                    end)
                end
            end, { buffer = bufnr, silent = true })
            vim.b[bufnr].markdown_keys = true
        end
    end
end
local methods = vim.lsp.protocol.Methods
vim.lsp.handlers[methods.textDocument_hover] = enhanced_float_handler(vim.lsp.handlers.hover, true)
vim.lsp.handlers[methods.textDocument_signatureHelp] = enhanced_float_handler(vim.lsp.handlers.signature_help, false)
-- }}}

vim.cmd[[
"autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, { focus = false })
"autocmd CursorHold,CursorHoldI * lua vim.lsp.buf.hover()
]]
