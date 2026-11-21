-- serverlist.lua : pick another running Nvim session and switch to it
-- (a telescope picker, like `:FzfLua serverlist`)
--
-- Lists this session (marked ●, first; picking it just closes the picker) and
-- every other Nvim server whose socket lives in stdpath('run'), found with
-- serverlist({ peer = true }) (Nvim 0.12+). Each entry shows what the session
-- is shown in (gneovim, tui, headless), its cwd and current file; the preview
-- shows its listed buffers (`+` = modified) and the lines visible in its
-- current window.
--
-- Picking a session shown in a gneovim window:
--   <CR>, <C-x>  bring that gneovim window (or gui-tab) to the front. Works
--                from any UI, the TUI included: the picker asks that session
--                to run gneovim's :GneovimFocusSession on its own address.
-- Picking a headless session (no UI at all, e.g. one left by :detach) from
-- a gneovim window:
--   <CR>, <C-x>  open it in a new gui-tab (gneovim attaches to its socket)
-- Picking any other session:
--   <CR>   :connect: this UI leaves the current server, which keeps running
--          headless and shows up in this list, so you can come back
--   <C-x>  :connect!: same, but stops the server you leave when no other UI
--          is attached to it
--
-- Only the built-in TUI can :connect. A UI that hasn't implemented the
-- "connect" UI event (gneovim, most GUIs) turns :connect into :detach: the UI
-- goes away and does not show the other session (gneovim closes the window
-- and leaves its session running headless). So unless every attached UI is
-- the TUI, picking a session shown in a terminal only warns.
--
-- Every server is asked once over RPC when the picker opens. A server waiting
-- for input (a hit-enter or confirm prompt) is not asked anything that would
-- block: it is listed as "busy" and can still be picked. Stale sockets are
-- skipped.
--
-- Integration:
--   vim.keymap.set('n', '<Leader>fs', function() require('serverlist').open() end)

local M = {}

-- Runs inside each remote server; must return plain data.
local REMOTE_INFO = [[
    local bufs = {}
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].buflisted then
            table.insert(bufs, { name = vim.api.nvim_buf_get_name(b), modified = vim.bo[b].modified })
        end
    end
    -- client name of each attached UI: 'gneovim', 'nvim-tui', ...
    local uis = {}
    for _, ui in ipairs(vim.api.nvim_list_uis()) do
        local client = ui.chan and vim.api.nvim_get_chan_info(ui.chan).client
        table.insert(uis, client and client.name ~= '' and client.name or '?')
    end
    return {
        uis = uis,
        pid = vim.fn.getpid(),
        cwd = vim.fn.getcwd(),
        file = vim.api.nvim_buf_get_name(0),
        filetype = vim.bo.filetype,
        bufs = bufs,
        lines = vim.api.nvim_buf_get_lines(0, vim.fn.line('w0') - 1, vim.fn.line('w$'), false),
    }
]]

-- Ask one server about itself; nil when the socket is stale.
local function query(addr)
    local ok, ch = pcall(vim.fn.sockconnect, 'pipe', addr, { rpc = true })
    if not ok or ch <= 0 then return nil end
    local info = { addr = addr }
    local ok_mode, mode = pcall(vim.rpcrequest, ch, 'nvim_get_mode')
    if not ok_mode then
        info = nil
    elseif mode.blocking then
        info.busy = true
    else
        local ok_info, remote = pcall(vim.rpcrequest, ch, 'nvim_exec_lua', REMOTE_INFO, {})
        if ok_info then info = vim.tbl_extend('force', info, remote) else info.busy = true end
    end
    pcall(vim.fn.chanclose, ch)
    return info
end

local function peers()
    local own = {}
    for _, addr in ipairs(vim.fn.serverlist()) do own[addr] = true end
    -- this session first, read directly: an RPC request to itself would deadlock
    local this = load(REMOTE_INFO)()
    this.addr, this.current = vim.v.servername, true
    local out = { this }
    for _, addr in ipairs(vim.fn.serverlist({ peer = true })) do
        if not own[addr] then
            local info = query(addr)
            if info then table.insert(out, info) end
        end
    end
    return out
end

-- True when :connect would move the UI rather than just detach it: every UI
-- attached to this session is the built-in TUI (client name "nvim-tui").
local function can_connect()
    local uis = vim.api.nvim_list_uis()
    if #uis == 0 then return false end
    for _, ui in ipairs(uis) do
        local client = ui.chan and vim.api.nvim_get_chan_info(ui.chan).client
        if not (client and client.name == 'nvim-tui') then return false end
    end
    return true
end

-- What a session is shown in: 'gneovim', 'tui', 'headless' (no UI), or the
-- first UI's client name. nil for a busy session, which was not asked.
local function kind(s)
    if not s.uis then return nil end
    if #s.uis == 0 then return 'headless' end
    if vim.tbl_contains(s.uis, 'gneovim') then return 'gneovim' end
    if vim.tbl_contains(s.uis, 'nvim-tui') then return 'tui' end
    return s.uis[1]
end

-- Bring the gneovim window showing the session at `addr` to the front, by
-- asking that session to run :GneovimFocusSession on its own address (so
-- this works from any UI). rpcrequest, not rpcnotify: closing the channel
-- right after a notification can lose it. False when the session is busy or
-- gone.
local function focus(addr)
    local ok, ch = pcall(vim.fn.sockconnect, 'pipe', addr, { rpc = true })
    if not ok or ch <= 0 then return false end
    local ok_mode, mode = pcall(vim.rpcrequest, ch, 'nvim_get_mode')
    local done = ok_mode and not mode.blocking
        and pcall(vim.rpcrequest, ch, 'nvim_exec_lua', 'GneovimFocusSession(vim.v.servername)', {})
    pcall(vim.fn.chanclose, ch)
    return done
end

local function label(s)
    if s.busy then return ('[busy]  %s'):format(s.addr) end
    local file = s.file ~= '' and vim.fn.fnamemodify(s.file, ':~:.') or '[No Name]'
    return ('%s %-8s %s  %s'):format(s.current and '●' or ' ', kind(s),
        vim.fn.fnamemodify(s.cwd, ':~'), file)
end

local function preview_lines(s)
    local lines = { 'socket: ' .. s.addr .. (s.current and '  (this session)' or '') }
    if s.busy then
        table.insert(lines, '(waiting for input; no details)')
        return lines
    end
    table.insert(lines, 'pid:    ' .. s.pid)
    table.insert(lines, 'ui:     ' .. kind(s))
    table.insert(lines, 'cwd:    ' .. vim.fn.fnamemodify(s.cwd, ':~'))
    table.insert(lines, '')
    table.insert(lines, ('buffers (%d):'):format(#s.bufs))
    for _, b in ipairs(s.bufs) do
        local name = b.name ~= '' and vim.fn.fnamemodify(b.name, ':~') or '[No Name]'
        table.insert(lines, ('  %s %s'):format(b.modified and '+' or ' ', name))
    end
    table.insert(lines, '')
    table.insert(lines, ('── %s ──'):format(s.file ~= '' and vim.fn.fnamemodify(s.file, ':t') or '[No Name]'))
    vim.list_extend(lines, s.lines)
    return lines
end

function M.open(opts)
    opts = opts or {}
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local previewers = require('telescope.previewers')
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local conf = require('telescope.config').values

    local servers = peers()

    local function connect(bang)
        return function(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            local s = entry and entry.value
            if not s or s.current then
                actions.close(prompt_bufnr)
                return
            end
            if kind(s) == 'gneovim' then
                actions.close(prompt_bufnr)
                if not focus(s.addr) then
                    vim.notify('serverlist: could not reach that session (busy or gone)',
                        vim.log.levels.WARN)
                end
                return
            end
            -- _G.GneovimFocusSession exists only in a gneovim window; with no
            -- gneovim window to raise and no other UI, it opens the session in
            -- a new gui-tab.
            if kind(s) == 'headless' and _G.GneovimFocusSession then
                actions.close(prompt_bufnr)
                _G.GneovimFocusSession(s.addr)
                return
            end
            if not can_connect() then
                vim.notify("serverlist: that session is shown elsewhere or busy, and :connect would close this UI",
                    vim.log.levels.WARN)
                return
            end
            actions.close(prompt_bufnr)
            vim.cmd({ cmd = 'connect', args = { s.addr }, bang = bang })
        end
    end

    pickers.new(opts, {
        prompt_title = 'Nvim servers',
        finder = finders.new_table({
            results = servers,
            entry_maker = function(s)
                local text = label(s)
                return { value = s, display = text, ordinal = text .. ' ' .. (s.file or '') }
            end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer({
            title = 'Session',
            define_preview = function(self, entry)
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, preview_lines(entry.value))
            end,
        }),
        attach_mappings = function(_, map)
            actions.select_default:replace(connect(false))
            map({ 'i', 'n' }, '<C-x>', connect(true))
            return true
        end,
    }):find()
end

return M
