-- notegrep.lua : nvALT-style live search over notes (a telescope picker)
--
-- Every keystroke searches file names and file contents at once. The query is
-- split on spaces; each word is a plain substring (not fuzzy, not regex) and
-- all words must match, in any order. Smart case: a query with no uppercase
-- letter ignores case.
--
-- Results come in three tiers, files ordered by last modified, newest first:
--   1. files whose name contains every word, each one followed by
--   2. its lines containing any of the words
--   3. lines of other files, where each word is on the line or in the path
--
-- Scope: the cwd, recursively. A leading `<` ("concentrate") narrows it to the
-- folder of the buffer the picker was opened from (the cwd when that buffer
-- has no file). `\<` searches for a literal leading `<`. An empty query lists
-- every file.
--
-- ripgrep runs in the background, so the editor never waits on it: typing
-- cancels the search in progress and starts the next, closing the picker
-- cancels it for good. Big trees (`~`) are cut short, and the title says so:
-- the listing stops after MAX_FILES files, a search after MAX_HITS matched
-- lines, and either after TIMEOUT ms. What is shown is then whatever ripgrep
-- found first, not the newest.
--
-- <C-n> creates `<query>.md` in the same scope folder, starting with a
-- `# <query>` heading and not written until :w; an existing file is opened.
--
-- Opening a result sets the search register to the words, so `n` jumps on.
--
-- Integration:
--   vim.keymap.set('n', '<Leader>fg', function() require('notegrep').open() end)

local M = {}

-- matched lines show as a window of this many bytes around the first match
local MAX_TEXT = 300
-- bytes kept before the first match when a line has to be cut
local CONTEXT = 60
-- ripgrep cuts lines longer than this (base64 images, minified code); prose
-- paragraphs stay far below it, so every word of a query can still be found
local MAX_COLUMNS = 20000
-- the search stops after this many matched lines (the title then says so)
local MAX_HITS = 2000
-- the file listing stops after this many files (the title then says so)
local MAX_FILES = 20000
-- ripgrep is stopped after this many milliseconds (the title then says so)
local TIMEOUT = 10000

-- ---------------------------------------------------------------------------
-- Query and scope
-- ---------------------------------------------------------------------------

-- Split a prompt into the scope flag and the search words.
local function parse(prompt)
    local scoped = false
    if prompt:sub(1, 1) == '<' then
        scoped = true
        prompt = prompt:sub(2)
    elseif prompt:sub(1, 2) == '\\<' then
        prompt = prompt:sub(2)
    end
    return {
        scoped = scoped,
        text = vim.trim(prompt),
        words = vim.split(prompt, '%s+', { trimempty = true }),
        -- without uppercase the words are already lowercase
        ignore_case = not prompt:find('%u'),
    }
end

-- Folder of a buffer's file (or the buffer itself when it is a directory,
-- e.g. netrw); nil for buffers without one.
local function buffer_dir(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    if name == '' then return nil end
    name = vim.fn.fnamemodify(name, ':p')
    if vim.fn.isdirectory(name) == 1 then return vim.fs.normalize(name) end
    if vim.bo[buf].buftype ~= '' then return nil end
    local dir = vim.fs.dirname(name)
    if vim.fn.isdirectory(dir) == 1 then return vim.fs.normalize(dir) end
end

-- ---------------------------------------------------------------------------
-- Background ripgrep
-- ---------------------------------------------------------------------------

-- Run cmd in dir without waiting for it. Output is read as it arrives rather
-- than all at once (a short query in a big tree can produce gigabytes):
-- on_line(line) gets each line, ended by the byte sep ('\n' or '\0'), in a
-- fast event, so it must not call the API; it stops the process by returning
-- true. on_done(timed_out) then runs on the main loop. Returns the process,
-- for :kill().
local function stream(cmd, dir, sep, on_line, on_done)
    local partial, stopped, proc = '', false, nil
    proc = vim.system(cmd, {
        cwd = dir,
        timeout = TIMEOUT,
        stderr = false,
        stdout = function(_, data)
            if not data or stopped then return end
            data = partial .. data
            -- a plain find, not gmatch('([^\n]*)\n'): on the unfinished line
            -- at the end of a chunk that pattern retries from every byte, which
            -- takes seconds for a long line
            local start = 1
            while true do
                local stop = data:find(sep, start, true)
                if not stop then break end
                local line = data:sub(start, stop - 1)
                start = stop + 1
                if on_line(line) then
                    stopped = true
                    proc:kill('sigterm')
                    return
                end
            end
            partial = data:sub(start)
        end,
    }, function(res)
        vim.schedule(function() on_done(res.code == 124) end)
    end)
    return proc
end

-- List the files under dir (same ignore rules as the content search) and call
-- on_done(files, limit) with them newest first; limit says why the listing
-- stopped early, if it did. Returns the process.
local function list_files(dir, on_done)
    local rels = {}
    return stream({ 'rg', '--files', '--null', '.' }, dir, '\0', function(rel)
        rels[#rels + 1] = rel
        return #rels >= MAX_FILES
    end, function(timed_out)
        local files = {}
        for _, rel in ipairs(rels) do
            rel = rel:gsub('^%./', '')
            local abs = dir .. '/' .. rel
            local stat = vim.uv.fs_stat(abs)
            local name = vim.fs.basename(rel)
            files[#files + 1] = {
                rel = rel,
                abs = abs,
                name = name,
                rel_l = rel:lower(),
                name_l = name:lower(),
                mtime = stat and (stat.mtime.sec + stat.mtime.nsec * 1e-9) or 0,
            }
        end
        table.sort(files, function(a, b)
            if a.mtime ~= b.mtime then return a.mtime > b.mtime end
            return a.rel < b.rel
        end)
        on_done(files, #rels >= MAX_FILES and ('first ' .. MAX_FILES .. ' files')
            or timed_out and 'listing timed out' or nil)
    end)
end

-- Cut a long line for display to a window around its first match, so a word
-- at the end of a paragraph stays visible, without splitting a UTF-8 character.
local function shorten(text, q)
    text = text:gsub('\r$', ''):gsub('^%s+', '')
    if #text <= MAX_TEXT then return text end
    local hay = q.ignore_case and text:lower() or text
    local first
    for _, w in ipairs(q.words) do
        local s = hay:find(w, 1, true)
        if s and (not first or s < first) then first = s end
    end
    local start = math.max(1, (first or 1) - CONTEXT)
    -- step off UTF-8 continuation bytes
    while start > 1 and text:byte(start) >= 0x80 and text:byte(start) < 0xC0 do
        start = start + 1
    end
    local cut_end = start + MAX_TEXT - 1 < #text
    local out = text:sub(start, start + MAX_TEXT - 1)
    if cut_end then out = out:gsub('[\192-\255][\128-\191]*$', '') end
    return (start > 1 and '…' or '') .. out .. (cut_end and '…' or '')
end

-- ---------------------------------------------------------------------------
-- Search
-- ---------------------------------------------------------------------------

-- Search dir for a query and call on_done(results, limit) with the ordered
-- results, { file = f } rows and { file = f, hit = h } rows; limit says why the
-- search stopped early, if it did. Returns the process (none for no words).
local function search(dir, q, files, on_done)
    local results = {}
    if #q.words == 0 then
        for _, f in ipairs(files) do results[#results + 1] = { file = f } end
        on_done(results)
        return
    end

    local function contains_all(s)
        for _, w in ipairs(q.words) do
            if not s:find(w, 1, true) then return false end
        end
        return true
    end

    local listed, name_match = {}, {}
    for _, f in ipairs(files) do
        listed[f.rel] = true
        if contains_all(q.ignore_case and f.name_l or f.name) then name_match[f.rel] = true end
    end

    -- A word found in no path must be on every matched line, so ripgrep only
    -- needs to look for (the longest) one of those; otherwise for any word.
    local required
    for _, w in ipairs(q.words) do
        local in_some_path = false
        for _, f in ipairs(files) do
            if (q.ignore_case and f.rel_l or f.rel):find(w, 1, true) then
                in_some_path = true
                break
            end
        end
        if not in_some_path and (not required or #w > #required) then required = w end
    end

    local cmd = {
        'rg', '--null', '--with-filename', '--no-heading', '--line-number', '--column',
        '--color=never', '--fixed-strings', q.ignore_case and '--ignore-case' or '--case-sensitive',
        '--max-columns=' .. MAX_COLUMNS, '--max-columns-preview',
    }
    for _, w in ipairs(required and { required } or q.words) do
        vim.list_extend(cmd, { '-e', w })
    end
    cmd[#cmd + 1] = '.'

    -- ripgrep prints each file's lines together and in order
    local hits, count = {}, 0
    local function on_line(line)
        local rel, lnum, col, text = line:match('^(.-)%z(%d+):(%d+):(.*)$')
        if not rel then return end
        rel = rel:gsub('^%./', '')
        -- a file past MAX_FILES has no row to show its lines under
        if not listed[rel] then return end
        local keep = name_match[rel]
        if not keep then
            local text_f = q.ignore_case and text:lower() or text
            local rel_f = q.ignore_case and rel:lower() or rel
            keep = true
            for _, w in ipairs(q.words) do
                if not (text_f:find(w, 1, true) or rel_f:find(w, 1, true)) then
                    keep = false
                    break
                end
            end
        end
        if not keep then return end
        hits[rel] = hits[rel] or {}
        table.insert(hits[rel], { lnum = tonumber(lnum), col = tonumber(col), text = shorten(text, q) })
        count = count + 1
        return count >= MAX_HITS
    end

    return stream(cmd, dir, '\n', on_line, function(timed_out)
        for _, f in ipairs(files) do
            if name_match[f.rel] then
                results[#results + 1] = { file = f }
                for _, h in ipairs(hits[f.rel] or {}) do
                    results[#results + 1] = { file = f, hit = h, grouped = true }
                end
            end
        end
        for _, f in ipairs(files) do
            if not name_match[f.rel] then
                for _, h in ipairs(hits[f.rel] or {}) do
                    results[#results + 1] = { file = f, hit = h }
                end
            end
        end
        on_done(results, count >= MAX_HITS and ('first ' .. MAX_HITS .. ' lines')
            or timed_out and 'search timed out' or nil)
    end)
end

-- ---------------------------------------------------------------------------
-- Picker
-- ---------------------------------------------------------------------------

local function display(entry)
    local utils = require('telescope.utils')
    local r = entry.value
    if r.grouped then
        -- indented under its file row, which already shows the name
        local lnum = tostring(r.hit.lnum)
        return '    ' .. lnum .. ': ' .. r.hit.text, { { { 4, 4 + #lnum }, 'TelescopeResultsLineNr' } }
    end
    local path, path_style = utils.transform_path({}, r.file.rel)
    path_style = path_style or {}
    local text, style = path, {}
    if r.hit then
        local loc = ':' .. r.hit.lnum .. ':'
        style[1] = { { #path, #path + #loc }, 'TelescopeResultsLineNr' }
        text = path .. loc .. ' ' .. r.hit.text
    end
    style = utils.merge_styles(style, path_style, 0)
    local shown, icon_hl, icon = utils.transform_devicons(r.file.abs, text)
    if not icon then return shown, style end
    local icon_style = icon_hl and { { { 0, #icon }, icon_hl } } or {}
    return shown, utils.merge_styles(icon_style, style, #icon + 1)
end

local function make_entry(r)
    local entry = {
        value = r,
        path = r.file.abs,
        filename = r.file.abs,
        ordinal = r.file.rel,
        display = display,
    }
    if r.hit then
        entry.lnum, entry.col, entry.text = r.hit.lnum, r.hit.col, r.hit.text
        entry.ordinal = r.file.rel .. ' ' .. r.hit.text
    end
    return entry
end

-- Highlight every occurrence of each word in a result row.
local function highlighter(_, prompt, row)
    local q = parse(prompt)
    local hay = q.ignore_case and row:lower() or row
    local hls = {}
    for _, w in ipairs(q.words) do
        local init = 1
        while true do
            local s, e = hay:find(w, init, true)
            if not s then break end
            hls[#hls + 1] = { start = s, finish = e }
            init = e + 1
        end
    end
    return hls
end

function M.open()
    local pickers = require('telescope.pickers')
    local sorters = require('telescope.sorters')
    local actions = require('telescope.actions')
    local action_set = require('telescope.actions.set')
    local action_state = require('telescope.actions.state')
    local conf = require('telescope.config').values

    local cwd = vim.fs.normalize(vim.uv.cwd())
    local buf_dir = buffer_dir(vim.api.nvim_get_current_buf()) or cwd
    -- dir -> { files, limit } once listed, { waiting, proc } while listing;
    -- for this picker's lifetime
    local listings = {}
    local run, search_proc, closed = 0, nil, false
    local picker, shown_title

    local function scope_dir(q) return q.scoped and buf_dir or cwd end
    -- the limits that cut the results short, nil ones skipped
    local function title(dir, ...)
        local limits = {}
        for i = 1, select('#', ...) do limits[#limits + 1] = select(i, ...) end
        return 'Notes: ' .. vim.fn.fnamemodify(dir, ':~')
            .. (#limits > 0 and ('  (' .. table.concat(limits, ', ') .. ')') or '')
    end

    -- Call cb(files, limit) once dir is listed. A listing is not restarted by
    -- the next keystroke, so typing while a big tree is listed still ends.
    local function with_files(dir, cb)
        local l = listings[dir]
        if l and l.files then return cb(l.files, l.limit) end
        if not l then
            l = { waiting = {} }
            listings[dir] = l
            l.proc = list_files(dir, function(files, limit)
                if closed then return end
                l.files, l.limit, l.proc = files, limit, nil
                for _, w in ipairs(l.waiting) do w(files, limit) end
                l.waiting = nil
            end)
        end
        table.insert(l.waiting, cb)
    end

    -- Telescope calls this for every prompt and goes on without waiting; the
    -- results are handed over when ripgrep is done. Starting a new run makes
    -- the previous one's callbacks give up.
    local function find(prompt, process_result, process_complete)
        run = run + 1
        local this = run
        if search_proc then search_proc:kill('sigterm') end
        search_proc = nil
        local q = parse(prompt or '')
        local dir = scope_dir(q)
        with_files(dir, function(files, files_limit)
            if this ~= run then return end
            search_proc = search(dir, q, files, function(results, hits_limit)
                if this ~= run then return end
                search_proc = nil
                local t = title(dir, files_limit, hits_limit)
                if t ~= shown_title and picker.layout then
                    shown_title = t
                    picker.layout.prompt.border:change_title(t)
                end
                for i, r in ipairs(results) do
                    local entry = make_entry(r)
                    entry.index = i
                    -- true once telescope has moved on to a newer prompt
                    if process_result(entry) then return end
                end
                process_complete()
            end)
        end)
    end

    local function close()
        closed = true
        run = run + 1
        if search_proc then search_proc:kill('sigterm') end
        for _, l in pairs(listings) do
            if l.proc then l.proc:kill('sigterm') end
        end
    end

    local function new_note(prompt_bufnr)
        local q = parse(action_state.get_current_line())
        if q.text == '' then
            vim.notify('notegrep: type a title first', vim.log.levels.WARN)
            return
        end
        local name = q.text:gsub('[/\\:]', '-')
        local heading = name:gsub('%.md$', '')
        local path = scope_dir(q) .. '/' .. heading .. '.md'
        actions.close(prompt_bufnr)
        local exists = vim.uv.fs_stat(path) ~= nil
        vim.cmd.edit(vim.fn.fnameescape(path))
        if not exists and vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_get_current_line() == '' then
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { '# ' .. heading, '' })
            vim.api.nvim_win_set_cursor(0, { 2, 0 })
        end
    end

    picker = pickers.new({}, {
        prompt_title = title(cwd),
        finder = setmetatable({ close = close }, { __call = function(_, ...) find(...) end }),
        sorter = sorters.Sorter:new {
            -- equal scores keep the tiers in the order search() made them
            scoring_function = function() return 1 end,
            highlighter = highlighter,
        },
        previewer = conf.grep_previewer({}),
        debounce = 80,
        -- prompt on top, results read top-down: each file row above its lines
        sorting_strategy = 'ascending',
        layout_config = { prompt_position = 'top' },
        attach_mappings = function(prompt_bufnr, map)
            local pattern
            action_set.select:enhance {
                pre = function()
                    local q = parse(action_state.get_current_line())
                    if #q.words == 0 then return end
                    local words = vim.tbl_map(function(w) return vim.fn.escape(w, '\\') end, q.words)
                    pattern = '\\V' .. (q.ignore_case and '\\c' or '\\C') .. table.concat(words, '\\|')
                end,
                post = function()
                    if not pattern then return end
                    vim.fn.setreg('/', pattern)
                    vim.fn.histadd('search', pattern)
                    vim.v.hlsearch = 1
                end,
            }
            -- overrides the insert-mode default "next entry" (<C-j>/<Down> remain)
            map({ 'i', 'n' }, '<C-n>', new_note, { desc = 'new note from query' })
            return true
        end,
    })
    picker:find()
end

return M
