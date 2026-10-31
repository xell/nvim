-- "Add to Inbox" (lua/inbox.lua):
--
--   :InboxAdd                          from inside any Neovim
--   open "gneovim://action/inbox"      from anywhere, e.g. BetterTouchTool
--   gneovim --action inbox             from a shell
--
-- `nested = true` so gneovim's own BufWinEnter autocmds run for the opened
-- file and it becomes a markdown island rather than a plain grid.

vim.api.nvim_create_user_command('InboxAdd', function()
    require('inbox').add()
end, { desc = 'Add a timestamped entry on top of the current Inbox file' })

vim.api.nvim_create_autocmd('User', {
    pattern = 'GneovimAction',
    nested = true,
    callback = function(ev)
        if ev.data.name ~= 'inbox' then return end
        require('inbox').add()
    end,
})
