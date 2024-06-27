
-- outlinex restart, would have
-- number
-- lbr?

function Start_writeroom() -- {{{
    -- Get the current tabpage
    local tabpage = vim.api.nvim_get_current_tabpage()
    -- List all windows in the current tabpage
    local wins = vim.api.nvim_tabpage_list_wins(tabpage)
    -- Get the count of windows
    local count = #wins
    if count > 1 then
        vim.api.nvim_err_writeln('Only allow one window, please close other(s) manually.')
        return
    end

    -- hide tabline
    vim.t.showtabline_ori = 1
    vim.opt.showtabline = 0

    -- hide foldcolumn
    vim.t.foldcolumn_ori = print(vim.opt.foldcolumn:get())
    vim.opt_local.foldcolumn = "0"

    -- hide fillchars vert
    vim.t.fillchars_vert_ori = tostring(vim.opt.fillchars:get()['vert'])
    vim.opt.fillchars:remove('vert')
    vim.opt.fillchars:prepend{ vert = ' ' }
-- se fillchars=vert:\ 

    -- setup laststatus
    vim.t.laststatus_ori = 2
    vim.opt.laststatus = 0

    -- width
    local width_ori = vim.opt.columns:get()
    vim.g.writeroom_win_width = 85
    if width_ori > (vim.g.writeroom_win_width + 6) then
        local sidewin_width = math.floor((width_ori - vim.g.writeroom_win_width) / 2)
        vim.cmd.vsplit()
        vim.cmd.vsplit()
        vim.cmd.normal[[1\<C-w>]]
        vim.api.nvim_win_set_width(0, sidewin_width)
        vim.cmd.enew()
        vim.opt_local.number = false
        vim.cmd.normal[[3\<C-w>]]
        vim.api.nvim_win_set_width(0, sidewin_width)
        vim.cmd.enew()
        vim.opt_local.number = false
        vim.cmd.normal[[2\<C-w>]]
        vim.opt_local.number = false
    end
    vim.cmd[[hi link WinSeparator Normal]]

    -- height
    vim.t.scrolloff_ori = vim.opt.scrolloff:get()
    vim.opt_local.scrolloff = 99
    local height_ori = vim.opt.lines:get()
    local buf_line_count_ori = vim.api.nvim_buf_line_count(0)
    local half_height = math.floor(height_ori / 2)

    for _ = 1, half_height, 1 do
        vim.api.nvim_buf_set_lines(0, 0, 0, true, {""})
    end
    for _ = 1, half_height, 1 do
        vim.api.nvim_buf_set_lines(0, half_height + buf_line_count_ori, half_height + buf_line_count_ori, true, {""})
    end
    vim.keymap.set('n', 'gg', function ()
        local i = 1
        local text
        while true do
            text = vim.api.nvim_buf_get_lines(0, i - 1, i, true)[1]
            if text == '' then
                i = i + 1
            else
                vim.fn.cursor(i, 1)
                break
            end
        end
    end, { buffer = true })
    vim.keymap.set('n', 'G', function ()
        local i = vim.api.nvim_buf_line_count(0)
        local text
        while true do
            text = vim.api.nvim_buf_get_lines(0, i - 1, i, true)[1]
            if text == '' then
                i = i - 1
            else
                vim.fn.cursor(i, 1)
                break
            end
        end
    end, { buffer = true })

    -- hide winbar
    vim.t.winbar_ori = vim.opt.winbar:get()
    vim.opt_local.winbar = ''

    vim.cmd.normal[[zz]]

end -- }}}

function Exit_writeroom() -- {{{
    -- show tabline
    vim.opt.showtabline = vim.t.showtabline_ori
    vim.t.showtabline_ori = nil

    -- restore foldcolumn
    vim.opt_local.foldcolumn = vim.t.foldcolumn_ori
    vim.t.foldcolumn_ori = nil

    -- restore fillchars vert
    vim.opt.fillchars:remove('vert')
    vim.opt.fillchars:prepend{ vert = vim.t.fillchars_vert_ori }
    vim.t.fillchars_vert_ori = nil

    -- setup laststatus
    vim.opt.laststatus = vim.t.laststatus_ori
    vim.t.laststatus_ori = nil


    -- width
    -- close side windows if any
    local tabpage = vim.api.nvim_get_current_tabpage()
    local wins = vim.api.nvim_tabpage_list_wins(tabpage)
    local count = #wins
    if count > 1 then
        vim.cmd.normal[[1\<C-w>]]
        vim.cmd.wincmd('c')
        vim.cmd.normal[[3\<C-w>]]
        vim.cmd.wincmd('c')
    end
    vim.opt_local.number = true
    vim.cmd[[hi link WinSeparator VertSplit]]

    -- height
    -- FIX ME in 1 blank line buffer
    vim.opt_local.scrolloff = vim.t.scrolloff_ori
    vim.t.scrolloff_ori = nil
    local text
    while true do
        text = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
        if text == '' then
            vim.api.nvim_buf_set_lines(0, 0, 1, false, {})
        else
            break
        end
    end
    local i = vim.api.nvim_buf_line_count(0)
    while true do
        text = vim.api.nvim_buf_get_lines(0, i - 1, i, true)[1]
        if text == '' then
            vim.api.nvim_buf_set_lines(0, i - 1, i, false, {})
        else
            break
        end
        i = i - 1
    end
    vim.keymap.del('n', 'gg', { buffer = 0 })
    vim.keymap.del('n', 'G', { buffer = 0 })

    -- show winbar
    vim.opt_local.winbar = vim.t.winbar_ori
    vim.t.width_ori = nil

end -- }}}

vim.api.nvim_create_user_command('WRS', Start_writeroom, {})
vim.api.nvim_create_user_command('WRE', Exit_writeroom, {})

-- vim:fdm=marker
