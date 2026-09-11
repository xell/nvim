-- wordcount.lua : live, statusline friendly word counter
--
-- Separates three numbers:
--   * English words   : runs of [0-9A-Za-z], an inner ' - or right quote keeps
--                       the run together ("don't", "e-mail" are one word)
--   * English chars   : count of [0-9A-Za-z]
--   * Chinese chars   : CJK ideographs, plus CJK / fullwidth punctuation
--                       (comma, period, quotes, ellipsis, dash ...)
--
-- Live updates are driven by cursor and text autocmds. They can be turned off
-- completely (:WordCountOff / :WordCountToggle) which deletes the whole augroup,
-- so there is zero cost while writing all day with it disabled.
--
-- Integration: call require('wordcount').statusline() from your statusline
-- expression. It returns '' when disabled or when the buffer is not eligible,
-- so the segment simply vanishes.
--
--   -- inside a %! statusline function
--   require('wordcount').statusline(),
--
--   -- or a classic 'statusline' string
--   vim.o.statusline = vim.o.statusline .. "%{%v:lua.require'wordcount'.statusline()%}"
--
-- Raw numbers for your own formatting:
--   require('wordcount').counts()  -->  { words, chars, cjk, hanzi, cjk_punct }

local M = {}

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------

local defaults = {
    -- start with live updating on? (commands / API still work either way)
    enabled = false,

    -- nil = every normal (buftype == '') buffer; or an allow list of filetypes
    -- e.g. { 'markdown', 'text', 'tex', 'org', 'asciidoc' }
    filetypes = nil,

    -- skip counting (and hide the segment) above this many lines, so a stray
    -- huge file can never stall a redraw. Raise it if you want.
    max_lines = 100000,

    -- how statusline() renders the numbers
    format = function(c)
        return string.format('zh:%d en:%dw/%dc', c.cjk, c.words, c.chars)
    end,

    -- codepoint ranges [lo, hi, lo, hi, ...], inclusive
    hanzi_ranges = {
        0x3400, 0x4DBF,     -- CJK Extension A
        0x4E00, 0x9FFF,     -- CJK Unified Ideographs
        0xF900, 0xFAFF,     -- CJK Compatibility Ideographs
        0x20000, 0x2A6DF,   -- CJK Extension B
        0x2A700, 0x2EBEF,   -- CJK Extension C..F
        0x2F800, 0x2FA1F,   -- CJK Compatibility Ideographs Supplement
    },
    -- counted together with hanzi into the single "cjk" number
    cjk_punct_ranges = {
        0x3001, 0x303F,     -- CJK symbols and punctuation (skips U+3000 space)
        0xFE10, 0xFE19,     -- vertical forms
        0xFE30, 0xFE4F,     -- CJK compatibility forms
        0xFF01, 0xFF60,     -- fullwidth forms (punct, digits, latin, brackets)
        0xFFE0, 0xFFE6,     -- fullwidth signs
        0x2014, 0x2014,     -- em dash (Chinese --)
        0x2018, 0x201F,     -- curly quotes / low quotes
        0x2026, 0x2026,     -- horizontal ellipsis
        0x00B7, 0x00B7,     -- middle dot (name separator)
    },
}

local opts = vim.deepcopy(defaults)

-- ---------------------------------------------------------------------------
-- Scanning
-- ---------------------------------------------------------------------------

-- Iterate the Unicode codepoints of a byte string without allocating a list.
-- Malformed bytes are decoded loosely and simply will not match any range.
local function codepoints(s)
    local i, n = 1, #s
    return function()
        if i > n then return nil end
        local b = s:byte(i)
        local cp, len
        if b < 0x80 then
            cp, len = b, 1
        elseif b < 0xE0 then
            cp, len = b % 0x20, 2
        elseif b < 0xF0 then
            cp, len = b % 0x10, 3
        else
            cp, len = b % 0x08, 4
        end
        for j = 1, len - 1 do
            cp = cp * 0x40 + ((s:byte(i + j) or 0) % 0x40)
        end
        i = i + len
        return cp
    end
end

local function in_ranges(cp, ranges)
    for k = 1, #ranges, 2 do
        if cp >= ranges[k] and cp <= ranges[k + 1] then
            return true
        end
    end
    return false
end

local function zero()
    return { w = 0, c = 0, hanzi = 0, punct = 0 }
end

local function add(a, b)
    a.w = a.w + b.w
    a.c = a.c + b.c
    a.hanzi = a.hanzi + b.hanzi
    a.punct = a.punct + b.punct
    return a
end

local function sub(a, b)
    a.w = a.w - b.w
    a.c = a.c - b.c
    a.hanzi = a.hanzi - b.hanzi
    a.punct = a.punct - b.punct
    return a
end

-- Count one line.
local function scan(s)
    local w, c, hanzi, punct = 0, 0, 0, 0
    local in_word = false   -- currently inside an English word
    local joinable = false  -- previous char was alnum, or a joiner after alnum
    for cp in codepoints(s) do
        if (cp >= 48 and cp <= 57)     -- 0-9
            or (cp >= 65 and cp <= 90) -- A-Z
            or (cp >= 97 and cp <= 122) -- a-z
        then
            c = c + 1
            if not in_word and not joinable then
                w = w + 1
            end
            in_word = true
            joinable = true
        elseif cp == 0x27 or cp == 0x2D or cp == 0x2019 then
            -- ' or - or right single quote: an intra-word joiner. Only keeps a
            -- word open when it sits between two alnums; otherwise harmless.
            in_word = false
        elseif in_ranges(cp, opts.hanzi_ranges) then
            hanzi = hanzi + 1
            in_word, joinable = false, false
        elseif in_ranges(cp, opts.cjk_punct_ranges) then
            punct = punct + 1
            in_word, joinable = false, false
        else
            in_word, joinable = false, false
        end
    end
    return { w = w, c = c, hanzi = hanzi, punct = punct }
end

local function scan_lines(lines)
    local t = zero()
    for _, l in ipairs(lines) do
        add(t, scan(l))
    end
    return t
end

local function shape(t)
    return {
        words = t.w,
        chars = t.c,
        hanzi = t.hanzi,
        cjk_punct = t.punct,
        cjk = t.hanzi + t.punct,
    }
end

-- ---------------------------------------------------------------------------
-- Incremental per-buffer state
--
-- Invariant while live:  total  = every line except cur_line
--                        cur    = cur_line
--                        result = total + cur
-- so a keystroke rescans one line, and moving to another line rescans one line.
-- ---------------------------------------------------------------------------

local inc = {}  -- bufnr -> { total, cur, cur_line, nlines, tick }

local function buf_lines(buf)
    return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

local function too_big(buf)
    return vim.api.nvim_buf_line_count(buf) > opts.max_lines
end

-- Full rescan; rebuilds the incremental state for `buf`.
local function rebuild(buf)
    if too_big(buf) then
        inc[buf] = nil
        return nil
    end
    local lines = buf_lines(buf)
    local cl = 1
    if buf == vim.api.nvim_get_current_buf() then
        cl = vim.fn.line('.')
    end
    local everything = scan_lines(lines)
    local cur = scan(lines[cl] or '')
    local st = {
        total = sub(everything, cur),  -- everything now holds total
        cur = cur,
        cur_line = cl,
        nlines = #lines,
        tick = vim.b[buf].changedtick,
    }
    inc[buf] = st
    return st
end

-- Move the "current line" of the incremental state to `cl`, rescanning just
-- the old and the new current line.
local function rebase(st, cl)
    add(st.total, st.cur)                     -- fold old current line in
    st.cur = scan(vim.fn.getline(cl))
    sub(st.total, st.cur)                     -- pull new current line out
    st.cur_line = cl
end

local function wrong_window(buf)
    -- An edit or cursor event for a buffer that is not the active one: the
    -- window relative line('.') / getline() would be meaningless. Drop its
    -- incremental state, a later counts() call will do a clean full scan.
    if buf ~= vim.api.nvim_get_current_buf() then
        inc[buf] = nil
        return true
    end
    return false
end

-- TextChangedI: typing. Assume only the current line changed unless the line
-- count moved (Enter, join, multiline paste), in which case fall back.
local function on_text_insert(buf)
    if wrong_window(buf) or too_big(buf) then return end
    local st = inc[buf] or rebuild(buf)
    if not st then return end
    if vim.fn.line('$') ~= st.nlines then
        rebuild(buf)
        return
    end
    local cl = vim.fn.line('.')
    if cl ~= st.cur_line then
        rebase(st, cl)
    else
        st.cur = scan(vim.fn.getline(cl))
    end
    st.tick = vim.b[buf].changedtick
end

-- TextChanged: a normal mode change (p, dd, :s, macros, ...). Could touch any
-- line, so just rebuild.
local function on_text_normal(buf)
    if wrong_window(buf) then return end
    rebuild(buf)
end

-- CursorMoved / CursorMovedI: keep the invariant when the line changes.
local function on_cursor(buf)
    if wrong_window(buf) or too_big(buf) then return end
    local st = inc[buf]
    if not st then return end
    local cl = vim.fn.line('.')
    if cl == st.cur_line then return end
    if vim.fn.line('$') ~= st.nlines then
        rebuild(buf)
        return
    end
    rebase(st, cl)
end

-- ---------------------------------------------------------------------------
-- Public counts
-- ---------------------------------------------------------------------------

--- Word counts for a whole buffer.
--- @param buf integer|nil  buffer handle, defaults to the current buffer
--- @return table  { words, chars, cjk, hanzi, cjk_punct }
function M.counts(buf)
    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    local st = inc[buf]
    if st and st.tick == vim.b[buf].changedtick then
        local t, u = st.total, st.cur
        return shape({
            w = t.w + u.w,
            c = t.c + u.c,
            hanzi = t.hanzi + u.hanzi,
            punct = t.punct + u.punct,
        })
    end
    -- no trusted live state: one off full scan
    return shape(scan_lines(buf_lines(buf)))
end

--- Word counts for a line range (1-based, inclusive).
function M.counts_range(buf, first, last)
    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    return shape(scan_lines(vim.api.nvim_buf_get_lines(buf, first - 1, last, false)))
end

-- ---------------------------------------------------------------------------
-- Statusline
-- ---------------------------------------------------------------------------

local function eligible(buf)
    if not M.enabled then return false end
    if vim.bo[buf].buftype ~= '' then return false end
    if too_big(buf) then return false end
    if opts.filetypes and not vim.tbl_contains(opts.filetypes, vim.bo[buf].filetype) then
        return false
    end
    return true
end

--- String for a statusline. '' when live counting is off or the buffer is not
--- eligible, so the segment disappears cleanly.
function M.statusline()
    local buf = vim.api.nvim_get_current_buf()
    if not eligible(buf) then return '' end
    local ok, s = pcall(opts.format, M.counts(buf))
    return ok and s or ''
end

-- ---------------------------------------------------------------------------
-- Enable / disable  (the autocmds are the whole augroup, deleted when off)
-- ---------------------------------------------------------------------------

local AUG = 'wordcount'

M.enabled = false

function M.enable()
    if M.enabled then return end
    M.enabled = true
    vim.g.wordcount_enabled = true

    local grp = vim.api.nvim_create_augroup(AUG, { clear = true })
    local function au(events, fn)
        vim.api.nvim_create_autocmd(events, {
            group = grp,
            callback = function(a)
                if M.enabled then fn(a.buf) end
            end,
        })
    end

    au('TextChangedI', on_text_insert)
    au('TextChanged', on_text_normal)
    au({ 'CursorMoved', 'CursorMovedI' }, on_cursor)
    au({ 'BufEnter', 'InsertLeave', 'BufWinEnter' }, rebuild)

    vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
        group = grp,
        callback = function(a) inc[a.buf] = nil end,
    })

    -- prime the buffer we are sitting in
    pcall(rebuild, vim.api.nvim_get_current_buf())
    pcall(vim.cmd.redrawstatus)
end

function M.disable()
    M.enabled = false
    vim.g.wordcount_enabled = false
    pcall(vim.api.nvim_del_augroup_by_name, AUG)
    inc = {}
    pcall(vim.cmd.redrawstatus)
end

function M.toggle()
    if M.enabled then M.disable() else M.enable() end
end

function M.is_enabled()
    return M.enabled
end

-- ---------------------------------------------------------------------------
-- Commands
-- ---------------------------------------------------------------------------

local function create_commands()
    vim.api.nvim_create_user_command('WordCountOn', M.enable,
        { desc = 'Live word count: enable (adds the autocmds)' })
    vim.api.nvim_create_user_command('WordCountOff', M.disable,
        { desc = 'Live word count: disable (removes the autocmds)' })
    vim.api.nvim_create_user_command('WordCountToggle', M.toggle,
        { desc = 'Live word count: toggle' })

    vim.api.nvim_create_user_command('WordCount', function(a)
        local c, scope
        if a.range == 2 then
            c = M.counts_range(0, a.line1, a.line2)
            scope = string.format('lines %d-%d', a.line1, a.line2)
        else
            c = M.counts(0)
            scope = 'buffer'
        end
        vim.notify(string.format(
            'wordcount (%s)\n  Chinese : %d  (%d hanzi + %d punctuation)\n'
            .. '  English : %d words, %d chars',
            scope, c.cjk, c.hanzi, c.cjk_punct, c.words, c.chars))
    end, { range = true, desc = 'Word count for the buffer or a :range' })
end

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------

--- Optional. Requiring the module already registers the commands with defaults;
--- call setup() to change options or to start with live counting enabled.
function M.setup(user)
    opts = vim.tbl_deep_extend('force', vim.deepcopy(defaults), user or {})
    if opts.enabled then
        M.enable()
    else
        M.disable()
    end
end

create_commands()

return M
