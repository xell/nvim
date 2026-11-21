-- inbox.lua : "Add to Inbox", quick capture into the vault's Inbox folder
--
-- Files are `<pkm_base>/Inbox/Inbox NN.md`. The highest number is the current
-- file; once it has more than g:inbox_max_lines lines (a soft cap, checked before
-- adding), the next entry starts `Inbox NN+1`. Newest entry on top:
--
--   # Inbox 03
--
--   ## 2026-10-31 12:30
--
--   <cursor, normal mode>
--
--   ## 2026-10-31 09:15
--   ...
--
-- If the newest entry has no body yet, it is reused with a fresh timestamp
-- instead of stacking another empty one. Nothing is written to disk.
--
-- Where the file opens: a window already showing it (this tabpage first),
-- else the current window if it is untouched (empty, unnamed, unmodified),
-- else g:inbox_open_cmd (a new tabpage by default). If another Neovim has it open, swap_takeover.lua takes
-- it over without asking (vim.g.swap_takeover_auto).
--
-- Integration (see plugin/inbox.lua):
--   :InboxAdd                        from inside any Neovim
--   open "gneovim://action/inbox"    from anywhere, via gneovim

local M = {}

-- Settings, read on every call so a live `:let g:inbox_...` takes effect.
local function max_lines() return vim.g.inbox_max_lines or 200 end
local function date_format() return vim.g.inbox_date_format or '%Y-%m-%d %H:%M' end
local function open_cmd() return vim.g.inbox_open_cmd or 'tabedit' end

-- vim.g.pkm_base is fnameescape()d for Ex commands (init.lua); undo that
-- for file system calls.
local function inbox_dir()
    local base = vim.g.pkm_base:gsub('\\(.)', '%1')
    return base .. '/Inbox'
end

local function current_number(dir)
    local max = 0
    for name, type in vim.fs.dir(dir) do
        local n = type == 'file' and name:match('^Inbox (%d+)%.md$')
        if n then max = math.max(max, tonumber(n)) end
    end
    return max
end

local function path_for(dir, n)
    return string.format('%s/Inbox %02d.md', dir, n)
end

local function line_count(path)
    local b = require('swap_takeover').find_buf(path)
    if b then return vim.api.nvim_buf_line_count(b) end
    if vim.fn.filereadable(path) == 0 then return 0 end
    return #vim.fn.readfile(path)
end

local function target_path()
    local dir = inbox_dir()
    vim.fn.mkdir(dir, 'p')
    local n = math.max(current_number(dir), 1)
    local path = path_for(dir, n)
    if line_count(path) > max_lines() then
        path = path_for(dir, n + 1)
    end
    return path
end

local function is_untouched(buf)
    return vim.api.nvim_buf_get_name(buf) == ''
        and vim.bo[buf].buftype == ''
        and not vim.bo[buf].modified
        and vim.api.nvim_buf_line_count(buf) == 1
        and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ''
end

-- Shows path in some window and makes it current. Returns its buffer, or nil
-- if it could not be opened for editing (takeover refused or failed).
local function open(path)
    local b = require('swap_takeover').find_buf(path)
    if b then
        local wins = vim.fn.win_findbuf(b)
        local tab = vim.api.nvim_get_current_tabpage()
        table.sort(wins, function(x, y)
            return (vim.api.nvim_win_get_tabpage(x) == tab) and not (vim.api.nvim_win_get_tabpage(y) == tab)
        end)
        if wins[1] then
            vim.api.nvim_set_current_win(wins[1])
            return b
        end
    end

    local cmd = is_untouched(vim.api.nvim_get_current_buf()) and 'edit' or open_cmd()
    vim.g.swap_takeover_auto = true
    local ok, err = pcall(vim.cmd, cmd .. ' ' .. vim.fn.fnameescape(path))
    vim.g.swap_takeover_auto = nil
    if not ok then
        vim.notify('inbox: could not open ' .. path .. ': ' .. tostring(err), vim.log.levels.ERROR)
        return nil
    end

    b = vim.api.nvim_get_current_buf()
    if require('swap_takeover').find_buf(path) ~= b then
        vim.notify('inbox: ' .. path .. ' was not opened', vim.log.levels.WARN)
        return nil
    end
    if vim.bo[b].readonly or not vim.bo[b].modifiable then
        vim.notify('inbox: ' .. path .. ' is open readonly; no entry added', vim.log.levels.WARN)
        return nil
    end
    return b
end

-- 1-based indexes of the `## ` headings outside fenced code blocks.
local function h2_lines(lines)
    local found, fence = {}, nil
    for i, l in ipairs(lines) do
        local f = l:match('^%s*(```)') or l:match('^%s*(~~~)')
        if f then
            if not fence then fence = f elseif fence == f then fence = nil end
        elseif not fence and l:match('^## ') then
            table.insert(found, i)
        end
    end
    return found
end

-- Puts a new entry on top and returns the row for the cursor.
local function insert_entry(buf, title)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local heading = '## ' .. os.date(date_format())
    local h2 = h2_lines(lines)

    if h2[1] then
        local first, stop = h2[1], (h2[2] or #lines + 1)
        local body_empty = true
        for i = first + 1, stop - 1 do
            if lines[i]:match('%S') then body_empty = false break end
        end
        -- reuse an empty newest entry, else push the old one down
        local replace_to = body_empty and stop - 1 or first - 1
        local block = { heading, '', '' }
        if body_empty and h2[2] or not body_empty then table.insert(block, '') end
        vim.api.nvim_buf_set_lines(buf, first - 1, replace_to, false, block)
        return first + 2
    end

    -- no entry yet: after the H1 and its blank line, adding the H1 if missing
    local h1
    for i, l in ipairs(lines) do
        if l:match('^# ') then h1 = i break end
    end
    if not h1 then
        local empty = #lines == 1 and lines[1] == ''
        vim.api.nvim_buf_set_lines(buf, 0, empty and 1 or 0, false,
            { '# ' .. title, '', heading, '', '' })
        return 5
    end
    local has_blank = lines[h1 + 1] == ''
    local at = has_blank and h1 + 1 or h1
    local block = has_blank and { heading, '', '' } or { '', heading, '', '' }
    if lines[at + 1] ~= nil then table.insert(block, '') end
    vim.api.nvim_buf_set_lines(buf, at, at, false, block)
    return at + (has_blank and 3 or 4)
end

function M.add()
    local path = target_path()
    local buf = open(path)
    if not buf then return end
    local row = insert_entry(buf, vim.fn.fnamemodify(path, ':t:r'))
    vim.cmd('stopinsert')
    vim.api.nvim_win_set_cursor(0, { row, 0 })
    vim.cmd('normal! zv')
end

return M
