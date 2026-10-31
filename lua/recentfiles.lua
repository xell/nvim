-- recentfiles.lua : recent files, then frequently used ones (a telescope picker)
--
-- Two parts in one list, told apart by the first column:
--   1. the RECENT files opened last, newest first, whatever their scores;
--      the column says when (5m, 2h, 31h, 3d, 10-12)
--   2. every other file in telescope-frecency's database, by score, then by
--      number of visits; the column says how many visits (x87)
-- The current file is left out. Typing filters both parts (fuzzy, on the
-- name and folder) and keeps them in that order.
--
-- Columns: when / visits, status, icon, name, folder. Status marks:
--   ●  open in this session    +  unsaved changes    ✗  file is gone
-- Colours (all overridable, `:hi RecentFilesFresh ...`):
--   RecentFilesFresh   opened within the hour      RecentFilesVisits  x87
--   RecentFilesToday   opened today                RecentFilesLoaded  ●
--   RecentFilesOlder   before today                RecentFilesModified +
--   RecentFilesDir     the folder                  RecentFilesMissing ✗
--
-- When a file was opened comes from the frecency database and, for buffers
-- of this session, from the last time the buffer was used (the database
-- keeps only the first time per session).
--
-- Integration:
--   vim.keymap.set('n', '<Leader>ff', function() require('recentfiles').open() end)

local M = {}

-- files in the recent part
local RECENT = 20
-- the name column is at most this wide
local MAX_NAME = 40

local function set_highlights()
    for name, link in pairs({
        RecentFilesFresh = 'DiagnosticOk',
        -- not Normal: its background would show in telescope's window
        RecentFilesToday = 'TelescopeResultsNormal',
        RecentFilesOlder = 'Comment',
        RecentFilesVisits = 'Number',
        RecentFilesLoaded = 'DiagnosticInfo',
        RecentFilesModified = 'DiagnosticWarn',
        RecentFilesMissing = 'DiagnosticError',
        RecentFilesDir = 'Comment',
    }) do
        vim.api.nvim_set_hl(0, name, { link = link, default = true })
    end
end

-- Noon of t's day, so whole days between two of them survive DST changes.
local function noon(t)
    local x = os.date('*t', t)
    return os.time({ year = x.year, month = x.month, day = x.day, hour = 12 })
end

-- How long ago t was, short, and its highlight group.
-- Today and yesterday in hours (at most 47h), then calendar days.
local function ago(t, now)
    local d = now - t
    local days = math.floor((noon(now) - noon(t)) / 86400 + 0.5)
    if d < 60 then return 'now', 'RecentFilesFresh' end
    if d < 3600 then return math.floor(d / 60) .. 'm', 'RecentFilesFresh' end
    if days == 0 then return math.floor(d / 3600) .. 'h', 'RecentFilesToday' end
    if days == 1 then return math.floor(d / 3600) .. 'h', 'RecentFilesOlder' end
    if days < 7 then return days .. 'd', 'RecentFilesOlder' end
    return os.date('%m-%d', t), 'RecentFilesOlder'
end

local function realpath(path)
    return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

-- The two parts: { path, time?, visits?, recent } items, recent ones first.
local function collect()
    local items, by_path = {}, {}
    local ok, records = pcall(function()
        return require('frecency').query({ record = true, limit = math.huge })
    end)
    for _, r in ipairs(ok and records or {}) do
        local item = { path = r.path, time = r.reference_time + r.last_accessed, visits = r.num_accesses, score = r.score }
        items[#items + 1] = item
        by_path[r.path] = item
    end
    -- buffers of this session: the last time each was used
    for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
        if info.name ~= '' and vim.bo[info.bufnr].buftype == '' then
            local path = realpath(info.name)
            local item = by_path[path]
            if not item then
                item = { path = path, time = 0, visits = 0, score = 0 }
                items[#items + 1] = item
                by_path[path] = item
            end
            item.time = math.max(item.time, info.lastused)
        end
    end
    local current = vim.api.nvim_buf_get_name(0)
    current = current ~= '' and realpath(current) or nil
    items = vim.tbl_filter(function(i) return i.path ~= current end, items)

    table.sort(items, function(a, b)
        if a.time ~= b.time then return a.time > b.time end
        return a.path < b.path
    end)
    local recent = vim.list_slice(items, 1, RECENT)
    local rest = vim.list_slice(items, RECENT + 1)
    table.sort(rest, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        if a.visits ~= b.visits then return a.visits > b.visits end
        return a.path < b.path
    end)
    for _, i in ipairs(recent) do i.recent = true end
    local n_recent, n_rest = #recent, #rest
    return vim.list_extend(recent, rest), n_recent, n_rest
end

-- Fill in what the row shows: name, folder, status.
local function describe(item)
    item.name = vim.fs.basename(item.path)
    item.dir = vim.fn.fnamemodify(vim.fs.dirname(item.path), ':~:.')
    if item.dir == '' then item.dir = '.' end
    item.missing = vim.uv.fs_stat(item.path) == nil
    local bufnr = vim.fn.bufnr(item.path)
    item.loaded = bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr)
    item.modified = item.loaded and vim.bo[bufnr].modified
end

function M.open()
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local sorters = require('telescope.sorters')
    local action_state = require('telescope.actions.state')
    local conf = require('telescope.config').values
    local utils = require('telescope.utils')
    local entry_display = require('telescope.pickers.entry_display')
    local fzy = require('telescope.algos.fzy')

    set_highlights()
    local items, n_recent, n_rest = collect()
    local name_w = 0
    for _, item in ipairs(items) do
        describe(item)
        name_w = math.max(name_w, vim.fn.strdisplaywidth(item.name))
    end
    name_w = math.min(name_w, MAX_NAME)
    local now = os.time()

    local function display(entry)
        local item = entry.value
        local parts, hls = {}, {}
        local function add(text, hl)
            local start = #table.concat(parts)
            parts[#parts + 1] = text
            if hl then hls[#hls + 1] = { { start, start + #text }, hl } end
            return start
        end
        local mark, mark_hl
        if item.recent then
            mark, mark_hl = ago(item.time, now)
        else
            mark, mark_hl = 'x' .. item.visits, 'RecentFilesVisits'
        end
        add(string.rep(' ', 5 - #mark) .. mark, mark_hl)
        add(' ')
        if item.missing then add('✗', 'RecentFilesMissing')
        elseif item.loaded then add('●', 'RecentFilesLoaded')
        else add(' ') end
        if item.modified then add('+', 'RecentFilesModified') else add(' ') end
        add(' ')
        local icon, icon_hl = utils.get_devicons(item.name)
        if icon and icon ~= '' then
            add(icon, icon_hl)
            add(' ')
        end
        local name = entry_display.truncate(item.name, name_w)
        local name_start = add(name)
        add(string.rep(' ', name_w - vim.fn.strdisplaywidth(name) + 2))
        local dir_start = add(item.dir, 'RecentFilesDir')
        -- the letters the prompt matched, in the name or the folder
        local prompt = action_state.get_current_line()
        if prompt ~= '' then
            for _, p in ipairs(fzy.positions(prompt, entry.ordinal)) do
                local col
                if p <= #item.name then
                    if p <= #name then col = name_start + p - 1 end
                elseif p > #item.name + 1 then
                    col = dir_start + p - #item.name - 2
                end
                if col then hls[#hls + 1] = { { col, col + 1 }, 'TelescopeMatching' } end
            end
        end
        return table.concat(parts), hls
    end

    pickers.new({}, {
        prompt_title = 'Recent & frequent files',
        results_title = n_recent .. ' recent, ' .. n_rest .. ' by visits',
        finder = finders.new_table {
            results = items,
            entry_maker = function(item)
                return {
                    value = item,
                    ordinal = item.name .. ' ' .. item.dir,
                    display = display,
                    filename = item.path,
                    path = item.path,
                }
            end,
        },
        sorter = sorters.Sorter:new {
            -- Smaller is better. The recent part always comes first; within
            -- a part the best matches do, then the list's own order.
            scoring_function = function(_, prompt, line, entry)
                local part = entry.value.recent and 0 or 2
                local order = entry.index / (#items + 1)
                if prompt == '' then return part + order end
                if not fzy.has_match(prompt, line) then return -1 end
                -- as telescope's fzy sorter: 0 for an exact match, up to 1
                -- for a poor one
                local quality = 1 / (fzy.score(prompt, line) - fzy.get_score_floor())
                return part + quality + order * 1e-6
            end,
            -- matches are highlighted by display(), on the name and folder only
            highlighter = function() return {} end,
        },
        previewer = conf.file_previewer({}),
        -- prompt on top, list read top-down
        sorting_strategy = 'ascending',
        layout_config = { prompt_position = 'top' },
    }):find()
end

return M
