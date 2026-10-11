-- Swap-file takeover.
--
-- Every nvim instance already listens for RPC on an auto-assigned socket
-- (v:servername), but that address lives under a per-instance random
-- directory (stdpath('run')), so it can't be derived from a PID alone.
-- Instead, each instance publishes "my pid -> my v:servername" into a
-- registry file under stdpath('data'), which *is* a fixed, shared location
-- for a given user/config. Because swapinfo() gives us the PID of the
-- process holding a swapfile, any instance can look up that process's
-- address in the registry and talk to it over RPC
-- (`nvim --server <addr> --remote-expr ...`).
--
-- "Takeover" asks the *other* process to save the buffer, then to release it
-- (:bdelete, which also removes its swapfile), and only then proceeds to load
-- the file locally. If either remote step fails, we never touch v:swapchoice
-- in a way that would open the file for editing here -- we fall back to
-- readonly so nothing can be lost or clobbered.

local M = {}

function M.registry_dir()
    local dir = vim.fn.stdpath('data') .. '/swap_takeover_servers'
    vim.fn.mkdir(dir, 'p')
    return dir
end

function M.registry_path_for_pid(pid)
    return M.registry_dir() .. '/' .. tostring(pid)
end

-- Called once at startup by every instance so it can be found later.
function M.setup_server()
    if vim.v.servername == '' then
        local ok, err = pcall(vim.fn.serverstart)
        if not ok then
            vim.notify('swap_takeover: failed to start RPC listener: ' .. tostring(err), vim.log.levels.WARN)
            return
        end
    end
    local pid = vim.fn.getpid()
    vim.fn.writefile({ vim.v.servername }, M.registry_path_for_pid(pid))
    vim.api.nvim_create_autocmd('VimLeavePre', {
        once = true,
        callback = function()
            pcall(vim.fn.delete, M.registry_path_for_pid(pid))
        end,
    })
end

-- Looks up the registered RPC address for a given pid, or nil if none/stale.
function M.address_for_pid(pid)
    local path = M.registry_path_for_pid(pid)
    if vim.fn.filereadable(path) == 0 then return nil end
    local lines = vim.fn.readfile(path, '', 1)
    local addr = lines[1]
    if not addr or addr == '' then return nil end
    return addr
end

local function vim_str_literal(s)
    return "'" .. s:gsub("'", "''") .. "'"
end

-- Runs `nvim --server addr --remote-expr expr` and returns (result, nil) or (nil, error).
-- Uses v:progpath (the exact binary running right now) rather than a bare
-- "nvim" lookup on $PATH, which may resolve to nothing, or to a different
-- nvim, depending on how the shell/terminal that launched us set PATH.
function M.remote_expr(addr, expr, timeout_ms)
    local ok, result = pcall(function()
        return vim.system(
            { vim.v.progpath, '--server', addr, '--remote-expr', expr },
            { text = true, timeout = timeout_ms or 5000 }
        ):wait()
    end)
    if not ok then
        return nil, 'failed to spawn ' .. vim.v.progpath .. ': ' .. tostring(result)
    end
    if result.code ~= 0 then
        local msg = vim.trim((result.stderr or '') .. (result.stdout or ''))
        if result.signal and result.signal > 0 then
            msg = msg .. (msg ~= '' and ' ' or '') .. '(killed by signal ' .. result.signal ..
                ', likely timeout)'
        end
        return nil, msg ~= '' and msg or ('exit code ' .. tostring(result.code))
    end
    return vim.trim(result.stdout or '')
end

-- Resolves symlinks (e.g. macOS /tmp -> /private/tmp) so paths compare
-- equal no matter which form (symlinked or resolved) they arrived in.
local function canonical(path)
    local rp = (vim.uv or vim.loop).fs_realpath(path)
    return rp or vim.fn.fnamemodify(path, ':p')
end

local function find_buf(fname)
    local target = canonical(fname)
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) then
            local name = vim.api.nvim_buf_get_name(b)
            if name ~= '' and canonical(name) == target then
                return b
            end
        end
    end
    return nil
end

-- Remote-side: save the buffer for fname if it's modified. Called via luaeval
-- from the *other* process, so it executes in the target instance.
function M.remote_save(fname)
    local ok, res = pcall(function()
        local b = find_buf(fname)
        if not b then return 'ERR:not_found' end
        if vim.bo[b].buftype ~= '' then return 'ERR:special_buffer' end
        if not vim.bo[b].modified then return 'OK:not_modified' end
        local werr
        vim.api.nvim_buf_call(b, function()
            local success, e = pcall(vim.cmd, 'silent write')
            if not success then werr = e end
        end)
        if werr then return 'ERR:' .. tostring(werr) end
        return 'OK'
    end)
    if not ok then return 'ERR:' .. tostring(res) end
    return res
end

-- Remote-side: give up the buffer for fname (removes it and its swapfile).
-- Refuses if the buffer is still modified, as a last-resort safety net.
-- Before deleting, any window showing the buffer is switched to a throwaway
-- scratch buffer carrying an explanatory message, so the split survives and
-- doesn't just show Vim's bland auto-created "[No Name]" buffer instead.
function M.remote_release(fname, taker_pid)
    local ok, res = pcall(function()
        local b = find_buf(fname)
        if not b then return 'ERR:not_found' end
        if vim.bo[b].modified then return 'ERR:still_modified' end

        local bufname = vim.api.nvim_buf_get_name(b)
        local msg = string.format('%s has been opened in nvim %s', bufname, tostring(taker_pid or '?'))

        local wins = vim.fn.win_findbuf(b)
        if #wins > 0 then
            local scratch = vim.api.nvim_create_buf(false, true)
            vim.bo[scratch].buftype = 'nofile'
            vim.bo[scratch].bufhidden = 'wipe'
            vim.bo[scratch].swapfile = false
            vim.api.nvim_buf_set_lines(scratch, 0, -1, false, { msg })
            vim.bo[scratch].modifiable = false
            vim.bo[scratch].modified = false
            for _, win in ipairs(wins) do
                vim.api.nvim_win_set_buf(win, scratch)
            end
        end

        local success, e = pcall(vim.api.nvim_buf_delete, b, { force = false })
        if not success then return 'ERR:' .. tostring(e) end
        return 'OK'
    end)
    if not ok then return 'ERR:' .. tostring(res) end
    return res
end

function M.handle_swap_exists()
    -- gneovim answers this itself for gneovim:// URL / CLI shim opens.
    if vim.g.gneovim_swap_policy then return end
    local swapname = vim.v.swapname
    local info = vim.fn.swapinfo(swapname)
    local target_file = canonical(vim.fn.expand('<afile>:p'))

    -- Vim's swapfile header truncates the host field to a fixed length, so a
    -- long real hostname (info.host) can come back cut short. Compare as a
    -- prefix match rather than exact equality; if it's genuinely a different
    -- host, the RPC connect below will simply fail (unix socket, local-only)
    -- and we fall back to readonly regardless.
    local hostname = (vim.uv or vim.loop).os_gethostname()
    local same_host = (info.host == nil or info.host == ''
        or info.host == hostname
        or hostname:sub(1, #info.host) == info.host)

    local prompt = string.format(
        'Swapfile found for %s (pid=%s user=%s host=%s).',
        vim.fn.fnamemodify(target_file, ':~'),
        info.pid or '?', info.user or '?', info.host or '?'
    )
    local choice = vim.fn.confirm(prompt, '&Let go\n&Readonly\n&Takeover', 1)

    if choice == 0 or choice == 1 then
        vim.v.swapchoice = 'q' -- let go: don't open here, leave the other process alone
        return
    elseif choice == 2 then
        vim.v.swapchoice = 'o' -- readonly
        vim.bo.modifiable = false
        return
    end

    -- choice == 3: takeover
    if not same_host then
        vim.notify('swap_takeover: swapfile owner is on a different host (' .. tostring(info.host)
            .. '); opening readonly instead', vim.log.levels.ERROR)
        vim.v.swapchoice = 'o'
        return
    end

    local pid = info.pid
    if not pid or pid == 0 then
        vim.notify('swap_takeover: no PID recorded in swapfile; opening readonly instead', vim.log.levels.ERROR)
        vim.v.swapchoice = 'o'
        return
    end

    vim.fn.system({ 'kill', '-0', tostring(pid) })
    if vim.v.shell_error ~= 0 then
        local ans = vim.fn.confirm(
            'Process ' .. pid .. ' is not running (stale swapfile). Recover from it instead?',
            '&Recover\n&Readonly\n&Cancel', 1)
        if ans == 1 then
            vim.v.swapchoice = 'r'
        elseif ans == 2 then
            vim.v.swapchoice = 'o'
        else
            vim.v.swapchoice = 'q'
        end
        return
    end

    local addr = M.address_for_pid(pid)
    if not addr then
        vim.notify('swap_takeover: no RPC registry entry for pid ' .. pid
            .. ' (it may not be running this config, or exited uncleanly). Falling back to readonly.',
            vim.log.levels.ERROR)
        vim.v.swapchoice = 'o'
        return
    end
    local remote_pid, ping_err = M.remote_expr(addr, 'getpid()', 1500)
    if not remote_pid or tonumber(remote_pid) ~= pid then
        vim.notify('swap_takeover: could not reach nvim process ' .. pid .. ' via RPC ('
            .. (ping_err or 'no response') .. '). Falling back to readonly.', vim.log.levels.ERROR)
        vim.v.swapchoice = 'o'
        return
    end

    local fname_lit = vim_str_literal(target_file)

    local save_result, save_err = M.remote_expr(
        addr, string.format("luaeval(\"require('swap_takeover').remote_save(_A)\", %s)", fname_lit))
    if not save_result or save_result:match('^ERR') then
        vim.notify('swap_takeover: remote save failed (' .. tostring(save_result or save_err)
            .. '). Aborting takeover; opening readonly.', vim.log.levels.ERROR)
        vim.v.swapchoice = 'o'
        return
    end

    local release_args = string.format('[%s, %d]', fname_lit, vim.fn.getpid())
    local release_result, release_err = M.remote_expr(
        addr,
        string.format("luaeval(\"require('swap_takeover').remote_release(_A[1], _A[2])\", %s)", release_args))
    if not release_result or release_result:match('^ERR') then
        vim.notify('swap_takeover: remote release failed (' .. tostring(release_result or release_err)
            .. ') after saving successfully -- the other process still owns the buffer. Opening readonly.',
            vim.log.levels.ERROR)
        vim.v.swapchoice = 'o'
        return
    end

    vim.notify('swap_takeover: took over ' .. vim.fn.fnamemodify(target_file, ':~') .. ' from pid ' .. pid,
        vim.log.levels.INFO)
    vim.v.swapchoice = 'e'
end

return M
