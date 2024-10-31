-- https://github.com/nvim-telescope/telescope.nvim/issues/2778
local focus_preview = function(prompt_bufnr)
    local action_state = require('telescope.actions.state')
    local picker = action_state.get_current_picker(prompt_bufnr)
    local prompt_win = picker.prompt_win
    local previewer = picker.previewer
    local winid = previewer.state.winid
    local bufnr = previewer.state.bufnr
    vim.keymap.set('n', '<Tab>', function()
        vim.cmd(string.format('noautocmd lua vim.api.nvim_set_current_win(%s)', prompt_win))
    end, { buffer = bufnr })
    vim.cmd(string.format('noautocmd lua vim.api.nvim_set_current_win(%s)', winid))
    -- api.nvim_set_current_win(winid)
end
vim.keymap.set('n', '<Tab>', function ()
    focus_preview(vim.fn.bufnr())
end, { buffer = true })

-- for thesaurus telescope extension
vim.keymap.set('n', '<M-d>', function ()
    vim.ui.open('dict://' .. tostring(require('telescope.actions.state').get_selected_entry()[1]))
end, { buffer = true })
