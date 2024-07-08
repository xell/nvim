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
vol.breakindentopt = 'list:-2'
vol.iskeyword:append('#')
vol.foldcolumn = '0'
-- vol.breakindentopt = 'shift:2'
-- }}}

local vks = vim.keymap.set
-- keymaps {{{
vks('v', '<Leader>b', [[<ESC>`>a**<ESC>`<i**<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>i', [[<ESC>`>a*<ESC>`<i*<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>t', [[<ESC>`>a}<ESC>`<i{=<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>c', [[<ESC>`>a`<ESC>`<i`<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>h', [[<ESC>`>a==}<ESC>`<i{==<ESC>`>ll]], { buffer = true })
-- https://www.reddit.com/r/neovim/comments/voc9qt/passing_an_initial_search_term_to_telescopes_find/
-- Telescope current_buffer_fuzzy_find default_text='##title
vks('n', '<Leader><Leader>t', [[:Telescope current_buffer_fuzzy_find default_text='##title<CR><Esc>]], { buffer = true, desc = 'Telescope ##title' })
vks('n', '<Leader><Leader>p', function ()
    vim.cmd[[w! test.md]]
    -- https://help.obsidian.md/Extending+Obsidian/Obsidian+URI#Shorthand%20formats
    vim.system({'open', 'obsidian://vault/Documents/Notes/Notes/test.md'})
end, { buffer = true, desc = 'Open in Obsidian' })
vks('n', '<Leader><Leader>P', function ()
    vim.cmd[[w! test.md]]
    vim.cmd[[silent !open -a /Applications/Marked\ 2.app/ -- test.md]]
end, { buffer = true, desc = 'Open in Marked 2' })
-- }}}

-- TODO
-- split by first level to several md files to facilitate iphone opening

-- helper functions {{{

-- comments -- {{{
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

-- return ( startline, lastline ), ( 0, 0 )
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

-- add record to table, use t['str_id'} instead of t[id] to avoid ugly vim.NIL
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
            -- vim.print('...')
            if not (lastline < range[1] or firstline > range[2]) then
                return seditor_id
            end
        end
        return 0
    end
end -- }}}

-- }}}

-- better o insert new line -- {{{
vim.keymap.set('n', 'o', function ()
    local cur_linenr = vim.fn.line('.')
    local cur_line = vim.fn.getline(cur_linenr)
    local insert_linenr = 0
    local line_head_length = 0
    local line_head = ''

    if cur_line == '' then
        insert_linenr = cur_linenr
        line_head = '- '
        line_head_length = 2
    else
        local _, lastlinenr = get_fold_range(0, cur_linenr)

        local foldclosed_linenr = vim.fn.foldclosed(cur_linenr)
        local foldclosed = (foldclosed_linenr == cur_linenr and lastlinenr > cur_linenr) and true or false
        insert_linenr = foldclosed and lastlinenr or cur_linenr

        line_head_length = string.find(cur_line, '-') + 1
        line_head = string.sub(cur_line, 1, line_head_length)
        if lastlinenr > cur_linenr and (not foldclosed) then
            -- it's a real open fold, add a sub item instead of an equal one
            line_head = '  ' .. line_head
            line_head_length = line_head_length + 2
        end
    end

    vim.api.nvim_buf_set_lines(0, insert_linenr, insert_linenr, true, { line_head })
    vim.fn.cursor(insert_linenr + 1, line_head_length)
    vim.cmd.startinsert()
end, { buffer = true, desc = 'Redefine o new line' }) -- }}}

-- DetectWrongIndentation
-- check wrong indentations to quickfix list -- {{{
local function detect_wrong_indentation()
    local lastline = vim.api.nvim_buf_line_count(0)
    local startline, text
    for i = 1, lastline, 1 do
        text = vim.api.nvim_buf_get_lines(0, i - 1, i, true)[1]
        if string.find(text, '^ *- ') then
            startline= i
            break
        end
    end
    local bufnr = vim.fn.bufnr('%')
    local qflist = {}
    local cur_fold_level, pre_fold_level
    for i = startline + 1, lastline, 1 do
        _, cur_fold_level = get_fold_level(bufnr, i)
        _, pre_fold_level = get_fold_level(bufnr, i - 1)

        if cur_fold_level - pre_fold_level > 1 then
            local entry = { bufnr = bufnr, lnum = i, col = 1, text = string.sub(vim.fn.getbufoneline(bufnr, i), 1, 20), }
            table.insert(qflist, entry)
        end
    end
    vim.fn.setqflist(qflist)
    vim.cmd.cwindow()
end

vim.api.nvim_buf_create_user_command(0, 'DetectWrongIndentation', detect_wrong_indentation, {})
-- }}}

-- zoom in, focus
vks('n', "<M-'>", function () -- {{{
    local bufnr = vim.fn.bufnr('%')
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    if vim.call('foldlevel', '.') == 0 then
        vim.api.nvim_err_writeln("There's no fold here.")
        return
    end

    if not string.find(bufname, 'yodeX') then
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
    vim.opt_local.filetype = 'outlinex'
    vim.cmd.normal[[zo]]
    -- vim.print('done')
    -- vim.opt_local.winbar = '%!luaeval("WinbarText()")'
end) -- }}}

-- zoom out, hoist
vks('n', '<M-;>', function () -- {{{
    local bufnr = vim.fn.bufnr('%')
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local relative_cursor_linenr = vim.fn.line('.')
    local actual_cursor_line

    if not string.find(bufname, 'yodeX') then
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
                    vim.opt_local.filetype = 'outlinex'
                    vim.cmd.normal[[zv]]
                    return
                else
                    up_linenr = up_linenr - 1
                end
            end
        end
    end
end) -- }}}

-- override bdelete -- {{{
local outlinex_bd_aug = vim.api.nvim_create_augroup("OverrideBDCommand", { clear = true })
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = outlinex_bd_aug,
    pattern = 'yodeX-*',
    callback = function()
        vks('ca', 'bd', "lua require'yode-nvim'.bufferDelete()", { buffer = true })
    end,
}) -- }}}

-- https://nuxsh.is-a.dev/blog/custom-nvim-statusline.html
local tools = require 'tools'
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
            line = tools.sub_utf8((select(1, string.gsub(line,'^ *- ', ''))), 1, item_length) .. ' '
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

-- yode winbar and breadcrumbs level up function {{{
local outlinex_winbar_aug = vim.api.nvim_create_augroup('outlinex', { clear = true })
vim.api.nvim_create_autocmd(
    { 'BufWinEnter', 'WinEnter', 'BufRead', 'CursorHold' },
    {
        pattern = 'yodeX-*',
        group = outlinex_winbar_aug,
        callback = function()
            if vim.t.winbar_ori ~= nil then return end

            vim.opt_local.winbar = '%!luaeval("WinbarText()")'

            if vim.b.seditor_info == nil then return end
            -- { bufnr, firstline, lastline, seditorBufferId, seditorName }
            local bi = vim.b.seditor_info
            local ori_bufnr = bi[1]
            local cur_line = bi[2]

            local cur_fold_level = (select(2, get_fold_level(ori_bufnr, cur_line)))

            vim.keymap.set('n', ',g0', yode.bufferDelete, { buffer = true, desc = 'Goto original' })

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

_G.CreateSeditorByLinenr =  function (bufnr, linenr)
    local firstline, lastline = get_fold_range(bufnr, linenr)
    yode.bufferDelete()
    yode.createSeditorReplace(firstline, lastline, bufnr)
    local bi = vim.b.seditor_info
    add_seditor_record(bufnr, bi[4], bi[2], bi[3])
end
-- }}}

-- fold {{{

-- foldmethod foldexpr {{{ ss

vol.foldmethod = 'expr'

-- Temp fix for E490: no fold found with tree-sitter
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = vim.api.nvim_create_augroup('OutlinexFoldmethod', { clear = true }),
    buffer = 0,
    callback = function(_)
        vim.wo.foldmethod = 'expr'
    end,
    once = true,
})


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
vol.foldexpr = 'v:lua.outlinexFold()'

-- 1 space-> 1 foldlevel, 3->2, 5->3
-- blank line is 0
_G.outlinexFold = function ()
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

-- }}}

-- ufo foldtext {{{
local handler_item = function(virtText, lnum, endLnum, _, _)
    local line_head1 = virtText[1][1]
    local line_head2 = virtText[2][1]

    local circle_symbol = {'●', '', '', ''}
    local other_circle_symbol = {'◇', '󰽷', '', '󰇙', '󰆢', '', '', '⊙', '⋗'}
    if endLnum - lnum > 0 then
        if string.match(line_head1, '^-') ~= nil then
            virtText[1][1] = string.gsub(line_head1, '-', vim.env.TERM_PROGRAM == 'WezTerm' and circle_symbol[2] or circle_symbol[4], 1)
            virtText[1][2] = 'LineNr'
        else
            virtText[2][1] = string.gsub(line_head2, '-', vim.env.TERM_PROGRAM == 'WezTerm' and circle_symbol[2] or circle_symbol[4], 1)
            virtText[2][2] = 'LineNr'
        end
    else
        if string.match(line_head1, '^-') ~= nil then
            virtText[1][1] = string.gsub(line_head1, '-', vim.env.TERM_PROGRAM == 'WezTerm' and other_circle_symbol[7] or other_circle_symbol[7], 1)
            virtText[1][2] = 'LineNr'
        else
            virtText[2][1] = string.gsub(line_head2, '-', vim.env.TERM_PROGRAM == 'WezTerm' and other_circle_symbol[7] or other_circle_symbol[7], 1)
            virtText[2][2] = 'LineNr'
        end
    end

    return virtText
end

local bufnr = vim.api.nvim_get_current_buf()
require('ufo').setFoldVirtTextHandler(bufnr, handler_item)
-- }}}

-- }}}

-- paste below (cousin) or inside (child) {{{
-- for a (closed) fold in the current cursor line, you may want to
-- 1) paste after(below) it, at same level, as a cousin, but it's important to position the new cousin to the end (right above the original next cousin), or else it will devour the original child(ren) if any 
--   A1
--     A1.1
--     A1.2
-- after pasting ...
--   A1
--   NEW1
--     A1.1 (now being the child of NEW)
--     A1.2
-- it should be ...
--   A1
--     A1.1
--     A1.2
--   NEW1
-- 2) paste inside it, sub level, as the new FIRST child; add two spaces

local function paste(inside)
    if inside == nil then inside = true end
    local content = vim.fn.getreginfo('"') -- unnamed register
    if content.regtype == 'V' then -- only for linewise
        local copied_content = content.regcontents
        local cur_line = vim.api.nvim_get_current_line()
        local target_level = string.find(cur_line, '[^ ]') - 1
        local copied_level = string.find(copied_content[1], '[^ ]') - 1
        local spaces = nil

        if target_level >= copied_level then -- paste in sub level
            if inside then
                spaces = string.rep(' ', target_level - copied_level + 2)
            else
                spaces = string.rep(' ', target_level - copied_level)
            end
            for i = 1, #copied_content do
                copied_content[i] = spaces .. copied_content[i]
            end
        elseif target_level < copied_level then -- paste in higher level
            if inside then
                spaces = copied_level - target_level - 2
            else
                spaces = copied_level - target_level + 1
            end
            for i = 1, #copied_content do
                copied_content[i] = string.sub(copied_content[i], spaces)
            end
        end

        local line_number = vim.api.nvim_win_get_cursor(0)[1]  -- Get the current line number
        if not inside then --
            local temp_line_number = line_number + 1
            local temp_line_content = nil
            local temp_level = -1
            while temp_line_number <= vim.api.nvim_buf_line_count(0) do
                temp_line_content = vim.fn.getline(temp_line_number)
                if temp_line_content == '' then
                    break
                end
                temp_level = string.find(temp_line_content, '[^ ]') - 1
                if temp_level <= target_level then
                    line_number = temp_line_number - 1
                    break
                end
                temp_line_number = temp_line_number + 1
            end
        end
        vim.api.nvim_buf_set_lines(0, line_number, line_number, false, copied_content)
    else
        print('The content is not linewise.')
    end
end

vim.api.nvim_buf_create_user_command(0, 'PInside', function ()
    paste()
end, {})
vim.api.nvim_buf_create_user_command(0, 'PBelow', function ()
    paste(false)
end, {})
-- }}}

-- vim:fdm=marker
