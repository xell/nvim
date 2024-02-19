local vol = vim.opt_local
-- options {{{
vol.tabstop = 2
vol.shiftwidth = 2
vol.concealcursor = 'nc'
vol.conceallevel = 2
vol.breakindent = true
vol.linebreak = true
vol.formatoptions = 'mBlrocq'
vol.comments:append(':-')
vol.comments:remove('fb:-')
vol.formatlistpat = '^\\s*\\d\\+\\.\\s\\+\\|^\\s*[-*+]\\s\\+\\|^\\[^\\ze[^\\]]\\+\\]:\\&^.\\{4\\}'
vol.breakindentopt = "list:-2"
-- vol.breakindentopt = "shift:2"
-- }}}

local vks = vim.keymap.set
-- keymaps {{{
vks('v', '<Leader>b', [[<ESC>`>a**<ESC>`<i**<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>i', [[<ESC>`>a*<ESC>`<i*<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>t', [[<ESC>`>a}<ESC>`<i{=<ESC>`>ll]], { buffer = true })
-- }}}

-- notes -- {{{
-- zoom in to range (b, e) workflow:
-- if (normal buffer)
--   if (yode(b, ...) for bufnr exists) ???
--     warning and return
--    else
--      createSeditorReplace(b, e, bufnr)
--    end
-- else (yode buffer)
--    delete current yode, window auto kept
--    createSeditorReplace(b, e, bufnr)
-- end
-- record
-- ----
-- zoom out
-- if (foldlevel == 1)
--   delete this yode, auto back to ori buf
-- else
--   it seems no need to check, because the algorith of creating will stop potential nested
--   calculate one level up range
--   delete current yode
--   createSeditorReplace
--   record
-- end
--
--  getbufline(a, b) = nvim_buf_get_lines(a-1, b) for real lines a to b

-- vg.seditor_record = {}
-- { ['bufnr1'] = { { sedID, firstline, endline }, {  } }, ['bufnr2'] = {} }

-- local createSeditor = require('yode-nvim.createSeditor')
-- }}}

-- TODO
-- use function CreateSeditorByLinenr()

local yode = require('yode-nvim')
local t = tostring

-- return ( REAL fold line, fold level )
local function get_fold_level(bufnr, linenr) -- {{{
    local line
    local up_linenr = linenr
    while true do
        line = vim.api.nvim_buf_get_lines(bufnr, up_linenr - 1, up_linenr, true)[1]
        if line == '' then return up_linenr, 0 end
        if string.find(line, '^ *-') then
            return up_linenr, ((string.find(line, '[^ ]') + 1) / 2)
        else
            up_linenr = up_linenr - 1
        end
    end
end -- }}}

-- return ( starline, lastline ), ( 0, 0 )
local function get_fold_range(bufnr, linenr) -- {{{
    local fold_startline, fold_level = get_fold_level(bufnr, linenr)
    if fold_level == 0 then return 0, 0 end
    local down_fold_level
    local buf_lastline = vim.api.nvim_buf_line_count(bufnr)
    local line

    local fold_lastline = linenr + 1
    while fold_lastline <= buf_lastline do
        _, down_fold_level = get_fold_level(bufnr, fold_lastline)
        line = vim.api.nvim_buf_get_lines(bufnr, fold_lastline - 1, fold_lastline, true)[1]
        if down_fold_level == 0 then return fold_startline, fold_lastline - 1 end
        if down_fold_level <= fold_level and string.find(line, '^ *-') then
            return fold_startline, fold_lastline - 1
        else
            fold_lastline = fold_lastline + 1
        end
    end
end -- }}}

-- add record to table, use t["str_id"} instead of t[id] to avoid ugly vim.NIL
local function add_seditor_record(bufnr, seditor_id, firstline, lastline) -- {{{
    local dummy = vim.g.seditor_table
    if dummy[t(bufnr)] == nil then
        dummy[t(bufnr)] = {}
        vim.g.seditor_table = dummy
    end
    dummy[t(bufnr)][t(seditor_id)] = { firstline, lastline }
    vim.g.seditor_table = dummy
end -- }}}

-- check if the upcoming seditor nested in or outside one of the existed
local function is_nested_seditor(bufnr, firstline, lastline) -- {{{
    -- FIXME no need to determine this?
    if vim.g.seditor_table[t(bufnr)] == nil then
        vim.print('NIL')
        return 0
    else
        for seditor_id, range in pairs(vim.g.seditor_table[t(bufnr)]) do
            -- if range ~= vim.NIL and not (lastline <= range[1] or firstline >= range[2]) then
            -- vim.print(seditor_id)
            -- vim.print(lastline .. '<' .. range[1] .. 'or' .. firstline .. '>' .. range[2])
            -- vim.print("...")
            if not (lastline < range[1] or firstline > range[2]) then
                return seditor_id
            end
        end
        return 0
    end
end -- }}}

-- zoom in, focus
vks('n', "<D-'>", function () -- {{{
    local bufnr = vim.fn.bufnr('%')
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    if not string.find(bufname, 'yode://') then
        -- normal buffer
        local cur_linenr = vim.fn.line('.')
        local firstline, lastline = get_fold_range(bufnr, cur_linenr)

        -- firstly, check record
        if vim.g.seditor_table[t(bufnr)] ~= nil then
            local existed_seditor = is_nested_seditor(bufnr, firstline, lastline)
            if existed_seditor ~= 0 then
                -- TODO ask 1) abandon; 2) reuse existed;
                -- 3) save and delete existed, and create new range
                vim.cmd.b(existed_seditor)
                vim.api.nvim_err_writeln('nested fold exists!')
                return
            end
        end

        -- then, create a new seditor
        yode.createSeditorReplace(firstline, lastline, bufnr)
        -- record the info to vim.g.seditor_table
        -- { bufnr, firstline, lastline, seditorBufferId, seditorName }
        local bi = vim.b.seditor_info
        add_seditor_record(bufnr, bi[4], bi[2], bi[3])
    else
        -- yode buffer, level down
        -- { bufnr, firstline, lastline, seditorBufferId, seditorName }
        local bi = vim.b.seditor_info
        local ori_bufnr = bi[1]
        -- line number in buf is b:firstline + current line - 1
        local cur_linenr = bi[2] + vim.fn.line('.') - 1

        -- look up new range in updated original buffur,
        -- because there might be modifications of content
        local firstline, lastline = get_fold_range(ori_bufnr, cur_linenr)

        yode.bufferDelete()
        yode.createSeditorReplace(firstline, lastline, ori_bufnr)
        bi = vim.b.seditor_info
        add_seditor_record(ori_bufnr, bi[4], bi[2], bi[3])
    end
    vim.print("done")
    -- vim.opt_local.winbar = '%!luaeval("WinbarText()")'
end) -- }}}

-- zoom out, hoist
vks('n', '<D-;>', function () -- {{{
    local bufnr = vim.fn.bufnr('%')
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local relative_cursor_linenr = vim.fn.line('.')
    local actual_cursor_line

    if not string.find(bufname, 'yode://') then
        -- normal buffer
        vim.api.nvim_err_writeln('this is a normal buffer.')
    else
        -- { bufnr, firstline, lastline, seditorBufferId, seditorName }
        local bi = vim.b.seditor_info
        local ori_bufnr = bi[1]
        local ori_linenr = bi[2]
        local firstline, ori_fold_level = get_fold_level(ori_bufnr, ori_linenr)

        actual_cursor_line = ori_linenr + relative_cursor_linenr

        if  ori_fold_level == 1 then
            -- it's level 1 fold, just delete and go back
            yode.bufferDelete()
        else
            local up_linenr = firstline - 1
            local up_fold_level, lastline
            -- go up to look for the father fold beginning
            while up_linenr >= 1 do
                firstline, up_fold_level = get_fold_level(ori_bufnr, up_linenr)
                if up_fold_level < ori_fold_level then
                    firstline, lastline = get_fold_range(ori_bufnr, firstline)
                    yode.bufferDelete()
                    yode.createSeditorReplace(firstline, lastline, ori_bufnr)
                    bi = vim.b.seditor_info
                    add_seditor_record(ori_bufnr, bi[4], bi[2], bi[3])

                    actual_cursor_line = actual_cursor_line - firstline
                    vim.fn.cursor(actual_cursor_line, 1)
                    return
                else
                    up_linenr = up_linenr - 1
                end
            end
        end
    end
end) -- }}}

-- %-0{minwid}.{maxwid}{item}
_G.WinbarText =  function() -- {{{
    if vim.b.seditor_info == nil then
        return '%-t'
        -- vim.fn.bufname(vim.fn.bufnr('%'))
    end

    local text = ''
    -- { bufnr, firstline, lastline, seditorBufferId, seditorName }
    local bi = vim.b.seditor_info
    local ori_bufnr = bi[1]
    local cur_line = bi[2]

    local cur_fold_level = (select(2, get_fold_level(ori_bufnr, cur_line)))

    if cur_fold_level == 1 then
        return '0 ROOT'
    end

    local line
    local fold_level
    local up_linenr = cur_line - 1
    local item_length = 15 - cur_fold_level

    while up_linenr >= 1 do
        fold_level = (select(2, get_fold_level(ori_bufnr, up_linenr)))
        if fold_level < cur_fold_level then
            line = vim.api.nvim_buf_get_lines(ori_bufnr, up_linenr - 1, up_linenr, true)[1]
            line = string.sub((select(1, string.gsub(line,'^ *- ', ''))), 1, item_length) .. ' '
            text = '' .. fold_level .. ' ' .. line .. '/ ' .. text
            cur_fold_level = fold_level
        end
        if fold_level == 1 then break end
        up_linenr = up_linenr - 1
    end

    -- line = string.sub((select(1, string.gsub(line,'^ *- ', ''))), 1, 10) .. ' '
    -- text = (select(2, get_fold_level(ori_bufnr, cur_line))) .. ' ' .. line
    return string.sub(' 0 / ' .. text, 1, -3)
end -- }}}

-- yode winbar and breadcrumbs level up function
-- {{{
local outlinex_aug = vim.api.nvim_create_augroup('outlinex', { clear = true })
vim.api.nvim_create_autocmd(
    { 'BufWinEnter', 'WinEnter', 'BufRead', 'CursorHold' },
    {
    pattern = 'yode://*',
    group = outlinex_aug,
    callback = function()
        vim.opt_local.winbar = '%!luaeval("WinbarText()")'

        if vim.b.seditor_info == nil then return end
        -- { bufnr, firstline, lastline, seditorBufferId, seditorName }
        local bi = vim.b.seditor_info
        local ori_bufnr = bi[1]
        local cur_line = bi[2]

        local cur_fold_level = (select(2, get_fold_level(ori_bufnr, cur_line)))

        vim.keymap.set('n', ',g0', yode.bufferDelete, { buffer = true })

        local up_linenr = cur_line - 1
        local up_fold_level
        local cmdtext = {}

        while up_linenr >= 1 do
            up_fold_level = (select(2, get_fold_level(ori_bufnr, up_linenr)))
            if up_fold_level < cur_fold_level then
                cmdtext[up_fold_level] = 'nmap <Leader>g' .. up_fold_level ..
                  ' :lua CreateSeditorByLinenr(' .. ori_bufnr .. ', ' ..
                  up_linenr .. ')<CR>'
                cur_fold_level = up_fold_level
            end
            if up_fold_level == 1 then break end
            up_linenr = up_linenr - 1
        end

        local all_cmdtext = ''
        for _, value in pairs(cmdtext) do
            all_cmdtext = all_cmdtext .. value .. '\n'
        end
        vim.cmd(all_cmdtext)
    end,
})

-- vim.api.nvim_create_autocmd({ 'BufWinLeave', 'WinLeave', 'WinClosed' }, {
--     pattern = 'yode://*',
--     group = outlinex_aug,
--     callback = function()
--         vim.opt_local.winbar = nil
--     end,
-- })

-- }}}

_G.CreateSeditorByLinenr =  function (bufnr, linenr)
    local firstline, lastline = get_fold_range(bufnr, linenr)
    yode.bufferDelete()
    yode.createSeditorReplace(firstline, lastline, bufnr)
    local bi = vim.b.seditor_info
    add_seditor_record(bufnr, bi[4], bi[2], bi[3])
end

-- fold {{{
-- TODO
vol.foldminlines = 1
vol.foldmethod = 'expr'

-- folding https://github.com/kevinhwang91/nvim-ufo
-- https://www.reddit.com/r/neovim/comments/10q2mjq/i_dont_really_get_folding/
-- refer to https://github.com/masukomi/vim-markdown-folding/blob/master/after/ftplugin/markdown/folding.vim

-- https://www.reddit.com/r/neovim/comments/193n9fx/how_to_reference_local_function_for_foldexpr/
-- ?? vim.opt.foldexpr = [[luaevel('MKDFold')()]]
-- or
-- --- e.g. config/folding.lua
-- local M = {}
-- function M.get_my_foldlevel() ... end
-- return M
-- vim.o.foldexpr = 'v:lua.require("config.folding").get_my_foldlevel()'
vol.foldexpr = 'v:lua.MKDFold()'
vol.foldtext = 'v:lua.MKDfoldText()'

-- 1->1, 3->2, 5->3
-- blank line is 0
_G.MKDFold = function ()
    local line = vim.fn.getline(vim.v.lnum)
    local level = string.find(line, '[^ ]')
    if level >= 1 then
        if string.find(line, '^ *-') then
          return ('>' .. ((level + 1) / 2))
        else
          -- this will treat mutliline item as a fold
          -- return ('' .. ((level - 1) / 2))
          -- return ('>' .. (((level - 1) / 2)) - 1)
          -- this will NOT treat mutliline item as a fold FIXME
          -- return '-1'
        end
    end
    return '='
end

_G.MKDfoldText = function ()
    local fs = vim.v.foldstart
    local fs_next = fs + 1
    local line = vim.fn.getline(fs)
    -- line = string.sub(line, 1, 50)
    -- ⊙ ○ ● ✪ ⊕ ⌾ ⊗ ⊘ ⊚
    --         󰺕 󱎕 󰧞 󰧟 󰅙      󰻃󰝦
    --   󰺕 󰻃
    if vim.fn.foldlevel(fs) < vim.fn.foldlevel(fs_next) then
      -- it's a real fold with sub items underneath
      line = string.gsub(line, '-', '●', 1)
      -- line = string.gsub(line, '-', '', 1)
    else
      -- it's only a lone, wrapped line fold by 'foldminlines'
      -- ﹥﹥
      line = string.gsub(line, '-', '◇', 1)
      -- line = string.gsub(line, '-', '⋗', 1)
      -- line = string.gsub(line, '-', '', 1)
      -- line = string.gsub(line, '-', '󰧞', 1)
      -- line = string.gsub(line, '-', '', 1)
      -- line = string.gsub(line, '-', '⊙', 1)
      -- line = string.gsub(line, '-', '󰺕', 1)
      -- line = string.gsub(line, '-', '', 1)
    end
    return line
end
-- }}}
-- vim:fdm=marker
