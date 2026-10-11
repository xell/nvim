-- writeroom, a simple zen-mode

-- What StartWriteRoom changed, for EndWriteRoom to undo. A plain Lua table
-- rather than t:/w: variables: StartWriteRoom may move to a new tab, and
-- EndWriteRoom may be run from anywhere. vim.g.writeroom stays the public
-- on/off flag.
local saved = {}

-- Non-floating windows on the current tab.
local function tab_windows()
    return vim.tbl_filter(function(win)
        return vim.api.nvim_win_get_config(win).relative == ''
    end, vim.api.nvim_tabpage_list_wins(0))
end

local function startWriteRoom()
    if vim.g.writeroom == 1 then return end
    vim.g.writeroom = 1
    saved = {}
    -- Writeroom shows a single window. If the current one shares its tab,
    -- open the buffer alone in a temporary tab instead (:tab split keeps the
    -- cursor, view and window options).
    if #tab_windows() > 1 then
        saved.origin_win = vim.api.nvim_get_current_win()
        vim.cmd('tab split')
        saved.temp_tab = vim.api.nvim_get_current_tabpage()
    end
    vim.o.title = false
    vim.cmd.TabLineOff()
    vim.cmd.StatusLineOff()
    vim.cmd.WinBarOff({ bang = true })
    saved.cmdheight = vim.o.cmdheight
    vim.o.cmdheight = 0
    -- Remember which window got the bigger scrolloff, so EndWriteRoom can
    -- restore that window even when it is run from a different one.
    saved.win = vim.api.nvim_get_current_win()
    saved.scrolloff = vim.wo.scrolloff
    vim.wo.scrolloff = 25
    -- Inside gneovim, also hide the native tab bar and traffic lights. A
    -- no-op when this was itself triggered by GneovimZenEnter.
    if vim.fn.exists(':GneovimZenOn') == 2 then vim.cmd.GneovimZenOn() end
end

local function endWriteRoom()
    if vim.g.writeroom ~= 1 then return end
    vim.g.writeroom = 0
    vim.o.title = true
    vim.cmd.TabLineOn()
    vim.cmd.StatusLineOn()
    vim.cmd.WinBarOn({ bang = true })
    vim.o.cmdheight = saved.cmdheight or 1
    local win = saved.win
    if win and vim.api.nvim_win_is_valid(win) then
        vim.wo[win].scrolloff = saved.scrolloff or 10
    end
    local origin = saved.origin_win
    local temp_tab = saved.temp_tab
    if origin and vim.api.nvim_win_is_valid(origin) then
        -- Carry the cursor and view back from the temporary window, as long
        -- as it still shows the same buffer.
        if win and vim.api.nvim_win_is_valid(win)
            and vim.api.nvim_win_get_buf(win) == vim.api.nvim_win_get_buf(origin) then
            local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
            vim.api.nvim_win_call(origin, function() vim.fn.winrestview(view) end)
        end
        vim.api.nvim_set_current_win(origin)
        if temp_tab and vim.api.nvim_tabpage_is_valid(temp_tab) then
            -- pcall: closing can still fail, e.g. a modified buffer shown
            -- nowhere else with 'nohidden'; the tab then just stays.
            pcall(vim.cmd.tabclose, vim.api.nvim_tabpage_get_number(temp_tab))
        end
    end
    saved = {}
    if vim.fn.exists(':GneovimZenOff') == 2 then vim.cmd.GneovimZenOff() end
end

vim.api.nvim_create_user_command('StartWriteRoom', startWriteRoom, { desc = "Start WriteRoom" })
vim.api.nvim_create_user_command('EndWriteRoom', endWriteRoom, { desc = "End WriteRoom" })

-- gneovim's View > Zen Mode (Cmd+Option+Z) fires these; they never fire in a
-- terminal Neovim. The vim.g.writeroom guards above stop the round trip.
-- nested: the :tab split / :tabclose inside must fire their own WinNew,
-- WinEnter etc., which is how gneovim learns the new window is a markdown
-- live preview; without it Neovim skips autocmds inside this callback and the
-- window renders as a plain grid.
local group = vim.api.nvim_create_augroup('writeroom_gneovim_zen', { clear = true })
vim.api.nvim_create_autocmd('User', { group = group, pattern = 'GneovimZenEnter', nested = true, callback = startWriteRoom })
vim.api.nvim_create_autocmd('User', { group = group, pattern = 'GneovimZenLeave', nested = true, callback = endWriteRoom })
