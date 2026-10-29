-- markdown_wikilink.lua : Obsidian-style [[wikilinks]] in Markdown buffers
--
-- Insert mode
--   [[            menu of notes under the cwd, the RECENT newest first;
--                 typing narrows it (fuzzy, words in any order)
--   <C-x><C-u>    open the menu by hand inside `[[` (after <C-e>, or in a
--                 link written earlier)
--   <C-n> <C-p>   move in the menu      <C-y> (or <CR>)  accept
--   <C-e>         close the menu
--
-- Normal mode, on a wikilink (anywhere else: the built-in command)
--   gf            open the note
--   gF            open the note, then pick a heading (,fH picker)
--   <C-w>f        open in a split       (also <C-w><C-f>)
--   <C-w>F        open in a vertical split; off a link too, in Markdown
--   <C-w>gf       open in a new tab
--   <C-w>gF       open in a new tab, then pick a heading
--
-- Completing
--   Accepting inserts the note's name without `.md`, or its path from the
--   cwd when another note has the same name, then steps over the closing
--   `]]` (added if missing). In an existing link it replaces the rest of the
--   old name and keeps an `|alias` or `#heading`.
--
-- Following
--   A name is looked up next to the current note, then in the cwd, then
--   anywhere under it (shortest path wins); `Folder/Name` also matches the
--   end of a path. `#Heading` and `#^block` jump there; `[[#Heading]]` is a
--   heading of the current note. The heading picker is skipped for a note
--   without headings; cancelling it leaves you where gf would. A missing
--   note gets a floating window offering to create it (c: create, q:
--   cancel), in the cwd, or next to the current note for a `./` link.
--
-- Requirements and limits
--   ripgrep lists the notes, in the background on every `[[` (and on gf
--   when the quick checks miss), so new notes show up and a big cwd (`~`)
--   never blocks; the listing stops after MAX_FILES notes or TIMEOUT ms.
--   gF and <C-w>gF need telescope-heading; without it they are the
--   built-ins (an error says so once per session).

if vim.g.vscode then return end

-- notes shown before anything is typed
local RECENT = 10
-- notes shown at most once something is typed
local MAX_ITEMS = 50
-- the listing stops after this many notes
local MAX_FILES = 20000
-- the listing is stopped after this many milliseconds
local TIMEOUT = 10000

local buf = vim.api.nvim_get_current_buf()
local group = vim.api.nvim_create_augroup('markdown_wikilink', { clear = false })
vim.api.nvim_clear_autocmds({ group = group, buffer = buf })

-- The link being typed: its row, the byte column its text starts at, and the
-- text so far; nil when the cursor is not inside `[[`.
local function context()
    local before = vim.api.nvim_get_current_line():sub(1, vim.fn.col('.') - 1)
    local start, query = before:match('()%[%[([^%[%]|#]*)$')
    if start then return { row = vim.fn.line('.'), col = start + 2, query = query } end
end

-- List the notes under dir in the background and call
-- on_done(notes, paths, limited) on the main loop, newest first; paths[i] is
-- notes[i].path, for matchfuzzy(), and limited is true when the listing was
-- cut short. Returns the process.
local function list_notes(dir, on_done)
    local chunks, found, proc = {}, 0, nil
    proc = vim.system({ 'rg', '--files', '--null', '-g', '*.md', '.' }, {
        cwd = dir,
        timeout = TIMEOUT,
        stderr = false,
        -- counted as it arrives, so a big tree stops at MAX_FILES
        stdout = function(_, data)
            if not data or found >= MAX_FILES then return end
            chunks[#chunks + 1] = data
            found = found + select(2, data:gsub('%z', ''))
            if found >= MAX_FILES then proc:kill('sigterm') end
        end,
    }, function(res)
        vim.schedule(function()
            local notes, count = {}, {}
            for _, rel in ipairs(vim.split(table.concat(chunks), '\0', { plain = true, trimempty = true })) do
                if #notes >= MAX_FILES then break end
                rel = rel:gsub('^%./', '')
                local path = rel:gsub('%.md$', '')
                local name = vim.fs.basename(path)
                local stat = vim.uv.fs_stat(dir .. '/' .. rel)
                notes[#notes + 1] = {
                    path = path,
                    name = name,
                    dir = vim.fs.dirname(path),
                    mtime = stat and (stat.mtime.sec + stat.mtime.nsec * 1e-9) or 0,
                }
                count[name] = (count[name] or 0) + 1
            end
            table.sort(notes, function(a, b)
                if a.mtime ~= b.mtime then return a.mtime > b.mtime end
                return a.path < b.path
            end)
            local paths = {}
            for i, n in ipairs(notes) do
                -- Obsidian's link text: the name, the path only when needed
                n.link = count[n.name] > 1 and n.path or n.name
                paths[i] = n.path
            end
            on_done(notes, paths, found >= MAX_FILES or res.code == 124)
        end)
    end)
end

-- while a link is being typed: { row, col, cot, proc, notes, paths, by_path,
-- shown (the text the menu was last made for) }
local session
-- set from accepting an item until its `]]` is stepped over
local accepting = false
-- b:changedtick right after that: the change is ours, not typing, so it
-- must not open the menu again (the cursor may still be inside the link)
local accepted_tick

local function stop()
    if not session then return end
    if session.proc then session.proc:kill('sigterm') end
    vim.bo[buf].completeopt = session.cot
    session = nil
end

-- <C-n>/<C-p> put the selected item's text, or back the typed text, in the
-- line: that is moving through the menu, not new text to search for.
local function moving(ctx)
    if ctx.query == session.shown then return true end
    local info = vim.fn.complete_info({ 'selected', 'items' })
    local item = info.items[info.selected + 1]
    return item ~= nil and item.word == ctx.query
end

-- The menu items for the text typed after `[[`.
local function items(query)
    local found
    if vim.trim(query) == '' then
        found = vim.list_slice(session.notes, 1, RECENT)
    else
        found = {}
        for _, path in ipairs(vim.fn.matchfuzzy(session.paths, query)) do
            found[#found + 1] = session.by_path[path]
            if #found >= MAX_ITEMS then break end
        end
    end
    local list = {}
    for _, n in ipairs(found) do
        list[#list + 1] = {
            word = n.link,
            abbr = n.name,
            menu = n.dir ~= '.' and n.dir or nil,
            -- the list is already filtered: Vim must not narrow it by prefix
            equal = 1,
            user_data = 'wikilink',
        }
    end
    return list
end

local function show(ctx)
    if vim.fn.mode() ~= 'i' then return end
    session.shown = ctx.query
    vim.fn.complete(ctx.col, items(ctx.query))
end

-- Start a session for the link at ctx: list the notes, then show the menu
-- if the cursor is still in that link.
local function start(ctx)
    local s = { row = ctx.row, col = ctx.col, cot = vim.bo[buf].completeopt }
    session = s
    -- first item preselected, so <CR> takes it; nothing inserted until then
    vim.bo[buf].completeopt = 'menuone,noinsert'
    s.proc = list_notes(vim.fn.getcwd(), function(notes, paths)
        if session ~= s then return end
        s.proc, s.notes, s.paths, s.by_path = nil, notes, paths, {}
        for _, n in ipairs(notes) do s.by_path[n.path] = n end
        -- the text may have changed while the notes were listed
        local now = context()
        if now and now.row == s.row and now.col == s.col then show(now) end
    end)
end

local function update()
    if accepting or vim.api.nvim_buf_get_changedtick(buf) == accepted_tick then return end
    local ctx = context()
    if not ctx then return stop() end
    if session and (session.row ~= ctx.row or session.col ~= ctx.col) then stop() end
    if not session then return start(ctx) end
    if session.notes and not moving(ctx) then show(ctx) end
end

-- <C-x><C-u> opens the menu by hand, e.g. after <C-e> or with the cursor
-- moved into an existing link. Before the notes are listed it starts the
-- listing and returns -3 (no menu yet); the menu comes up when it is done.
local function completefunc(findstart, base)
    if findstart == 1 then
        local ctx = context()
        if not ctx then return -3 end
        if session and (session.row ~= ctx.row or session.col ~= ctx.col) then stop() end
        if session and session.notes then return ctx.col - 1 end
        if not session then start(ctx) end
        return -3
    end
    if not (session and session.notes) then return {} end
    session.shown = base
    return items(base)
end

-- 'completefunc' takes a function name, not a closure: one global table
-- passes each call on to the current buffer's function.
_G.markdown_wikilink = _G.markdown_wikilink or {
    buffers = {},
    complete = function(findstart, base)
        local f = _G.markdown_wikilink.buffers[vim.api.nvim_get_current_buf()]
        if not f then return findstart == 1 and -3 or {} end
        return f(findstart, base)
    end,
}
_G.markdown_wikilink.buffers[buf] = completefunc
vim.bo[buf].completefunc = 'v:lua.markdown_wikilink.complete'
vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    buffer = buf,
    callback = function() _G.markdown_wikilink.buffers[buf] = nil end,
})

vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChangedP' }, {
    group = group,
    buffer = buf,
    callback = update,
})

vim.api.nvim_create_autocmd('CompleteDone', {
    group = group,
    buffer = buf,
    callback = function()
        if vim.v.event.reason ~= 'accept' or vim.v.completed_item.user_data ~= 'wikilink' then return end
        -- the accepted text changes the line, which would open the menu again
        accepting = true
        vim.schedule(function()
            accepting = false
            stop()
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            local after = vim.api.nvim_get_current_line():sub(col + 1)
            if not after:match('^[^%[%]]*%]%]') then
                -- an open link: close it
                vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { ']]' })
                vim.api.nvim_win_set_cursor(0, { row, col + 2 })
            else
                -- inside a closed link: the rest of the old name is replaced
                -- too, an |alias or #heading is kept
                local rest = after:match('^[^%[%]|#]*')
                if #rest > 0 then vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col + #rest, { '' }) end
                if after:sub(#rest + 1, #rest + 2) == ']]' then
                    vim.api.nvim_win_set_cursor(0, { row, col + 2 })
                end
            end
            accepted_tick = vim.api.nvim_buf_get_changedtick(buf)
        end)
    end,
})

vim.api.nvim_create_autocmd('InsertLeave', {
    group = group,
    buffer = buf,
    callback = stop,
})

-- ---------------------------------------------------------------------------
-- gf: follow a wikilink
-- ---------------------------------------------------------------------------

local function echo_error(err)
    err = tostring(err)
    vim.api.nvim_echo({ { err:match('E%d+:.*') or err, 'ErrorMsg' } }, true, {})
end

local function exists(path) return vim.uv.fs_stat(path) ~= nil end

-- The text inside the [[wikilink]] (or ![[embed]]) the cursor is on, or nil.
local function link_at_cursor()
    local line, col = vim.api.nvim_get_current_line(), vim.fn.col('.')
    for s, text, e in line:gmatch('()%[%[([^%[%]]*)%]%]()') do
        if col >= s and col < e then return text end
    end
end

-- Move to `# Heading` (any level, any case) or to the line ending in `^block`.
local function goto_heading(heading)
    if not heading or heading == '' then return end
    local want = heading:lower()
    for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        local h = want:sub(1, 1) == '^' and line:match('%s(%^[%w-]+)%s*$') or line:match('^#+%s+(.-)%s*$')
        if h and h:lower() == want then
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            return
        end
    end
    vim.notify('No heading "' .. heading .. '"', vim.log.levels.WARN)
end

-- Go to heading in the current note, or, with pick and no heading, let the
-- ,fH picker (telescope-heading) choose one. A note without headings stays
-- as gf leaves it, rather than showing an empty picker.
local function land(heading, pick)
    if heading and heading ~= '' then return goto_heading(heading) end
    if not pick then return end
    local ok, err = pcall(function()
        -- the extension's own heading search, so the two always agree
        local headings = require('telescope._extensions.heading.format.markdown')
            .ts_get_headings(vim.api.nvim_buf_get_name(0), 0)
        if #headings == 0 then
            vim.notify('No headings in ' .. vim.fn.expand('%:t'), vim.log.levels.INFO)
            return
        end
        require('telescope').extensions.heading.heading()
    end)
    if not ok then echo_error(err) end
end

local function open(cmd, path, heading, pick)
    local ok, err = pcall(vim.cmd[cmd], vim.fn.fnameescape(path))
    if not ok then return echo_error(err) end
    land(heading, pick)
end

-- An unsaved new note starting with `# Name`; its folder is made on :w.
local function create(cmd, path)
    local ok, err = pcall(vim.cmd[cmd], vim.fn.fnameescape(path))
    if not ok then return echo_error(err) end
    if vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_get_current_line() == '' then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { '# ' .. vim.fn.fnamemodify(path, ':t:r'), '' })
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
    end
    vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = 0,
        once = true,
        callback = function() vim.fn.mkdir(vim.fs.dirname(path), 'p') end,
    })
end

-- Ask in a floating window at the cursor whether to create path; on_yes()
-- if so. c, y or <CR> create; q, n, <Esc> or leaving the window cancel.
local function confirm_create(path, limited, on_yes)
    local lines = { 'No note ' .. vim.fn.fnamemodify(path, ':~:.') }
    if limited then lines[#lines + 1] = '(only the first ' .. MAX_FILES .. ' notes were searched)' end
    vim.list_extend(lines, { '', '[c]reate it   [q] cancel' })
    local width = 0
    for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
    local fbuf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(fbuf, 0, -1, false, lines)
    vim.bo[fbuf].modifiable = false
    vim.bo[fbuf].bufhidden = 'wipe'
    local win = vim.api.nvim_open_win(fbuf, true, {
        relative = 'cursor',
        row = 1,
        col = 0,
        width = width + 2,
        height = #lines,
        style = 'minimal',
        border = 'rounded',
        title = ' Create note? ',
        title_pos = 'center',
    })
    vim.wo[win].winhighlight = 'Normal:NormalFloat'
    local done = false
    local function close()
        if done then return end
        done = true
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end
    for _, key in ipairs({ 'c', 'y', '<CR>' }) do
        vim.keymap.set('n', key, function()
            close()
            on_yes()
        end, { buffer = fbuf, nowait = true })
    end
    for _, key in ipairs({ 'q', 'n', '<Esc>' }) do
        vim.keymap.set('n', key, close, { buffer = fbuf, nowait = true })
    end
    -- closing a window is not allowed while leaving it
    vim.api.nvim_create_autocmd('WinLeave', {
        buffer = fbuf,
        once = true,
        callback = function() vim.schedule(close) end,
    })
end

-- Open the note a link names with cmd ('edit', 'split', 'vsplit' or
-- 'tabedit'); pick: let the heading picker choose where in it.
local function follow(link, cmd, pick)
    local target = vim.trim((link:gsub('|.*', '')))
    local heading = target:match('#([^#]*)$')
    target = vim.trim((target:gsub('#.*', '')))
    local cwd = vim.fn.getcwd()
    local here = vim.api.nvim_buf_get_name(0)
    local here_dir = here ~= '' and vim.fs.dirname(here) or cwd

    -- [[#Heading]]: a heading of this note
    if target == '' then
        if here == '' or cmd == 'edit' then return land(heading, pick) end
        return open(cmd, here, heading, pick)
    end

    local relative = target:match('^%.%.?/') ~= nil
    local name = target:gsub('%.md$', '')
    -- quick checks first: an attachment as written, then the likely notes
    local tries = relative and { here_dir .. '/' .. target, here_dir .. '/' .. name .. '.md' }
        or { here_dir .. '/' .. target, cwd .. '/' .. target, here_dir .. '/' .. name .. '.md', cwd .. '/' .. name .. '.md' }
    for _, path in ipairs(tries) do
        if exists(path) and vim.fn.isdirectory(path) == 0 then
            return open(cmd, vim.fs.normalize(path), heading, pick)
        end
    end
    local new = vim.fs.normalize((relative and here_dir or cwd) .. '/' .. name .. '.md')
    if relative then
        return confirm_create(new, false, function() create(cmd, new) end)
    end

    -- anywhere under the cwd: the whole path, or its end after a /
    local want = name:lower()
    list_notes(cwd, function(notes, _, limited)
        local best
        for _, n in ipairs(notes) do
            local p = n.path:lower()
            if (p == want or p:sub(-#want - 1) == '/' .. want) and (not best or #n.path < #best.path) then
                best = n
            end
        end
        if best then return open(cmd, cwd .. '/' .. best.path .. '.md', heading, pick) end
        confirm_create(new, limited, function() create(cmd, new) end)
    end)
end

-- The heading picker of gF and <C-w>gF needs telescope and
-- telescope-heading. Without them those two are left as the built-in
-- commands, and an error says so once per session; the others still follow
-- wikilinks.
local has_picker = pcall(require, 'telescope')
    and pcall(require, 'telescope._extensions.heading.format.markdown')
if not has_picker and not vim.g.markdown_wikilink_warned then
    vim.g.markdown_wikilink_warned = true
    vim.api.nvim_echo({ {
        'markdown_wikilink: telescope-heading not found, so gF and <C-w>gF are the built-in commands',
        'ErrorMsg',
    } }, true, {})
end

-- gf and its variants: how each one opens the file, and whether it then
-- picks a heading (gF and <C-w>gF; <C-w>F is <C-w>f in a vertical split)
local variants = {
    ['gf'] = { 'edit' },
    ['gF'] = { 'edit', true },
    ['<C-w>f'] = { 'split' },
    ['<C-w>F'] = { 'vsplit' },
    ['<C-w><C-f>'] = { 'split' },
    ['<C-w>gf'] = { 'tabedit' },
    ['<C-w>gF'] = { 'tabedit', true },
}
if not has_picker then
    -- (clearing fields while traversing them with pairs() is allowed)
    for key, how in pairs(variants) do
        if how[2] then variants[key] = nil end
    end
end
for key, how in pairs(variants) do
    local cmd, pick = how[1], how[2] or false
    -- An expression mapping: off a wikilink it gives back the key itself,
    -- which then runs as the built-in command (not remapped), as if typed.
    vim.keymap.set('n', key, function()
        local link = link_at_cursor()
        if not link then
            -- <C-w>F splits vertically here, as on a wikilink, still going to
            -- the line number after the name
            if key == '<C-w>F' then
                return '<Cmd>vertical ' .. (vim.v.count > 0 and vim.v.count or '') .. 'wincmd F<CR>'
            end
            return key
        end
        -- the text and windows cannot change while the expression runs
        vim.schedule(function() follow(link, cmd, pick) end)
        return ''
    end, { buffer = buf, expr = true, desc = 'Follow the wikilink under the cursor, else ' .. key })
end
