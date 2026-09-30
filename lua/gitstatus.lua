-- gitstatus.lua : cheap, non real time git segment for the statusline
--
-- One async `git status --porcelain=v2 --branch -z` per BufReadPost /
-- BufWritePost, cached in b:gitstatus. The statusline only reads that cached
-- string, so a redraw never runs git. Refresh by hand with `:e %`.
--
-- Shape:  <branch or short commit> [↑ahead ↓behind] [file marks] [· repo marks]
--   marks (same as git's __git_ps1):
--     +  staged changes      *  unstaged changes
--     %  untracked           !  merge conflict
--   e.g.  main ↑1 * · repo +*%   (this file modified; repo has more going on)
--         main · repo *%          (this file clean, repo dirty)
--
-- Integration: require('gitstatus').get() returns '' outside a repo.

local M = {}

local function marks(m)
    return (m.staged and '+' or '') .. (m.unstaged and '*' or '')
        .. (m.untracked and '%' or '') .. (m.conflict and '!' or '')
end

-- Fold one status entry (kind, XY) into a marks table.
local function note(m, kind, xy)
    if kind == '1' or kind == '2' then
        m.staged = m.staged or xy:sub(1, 1) ~= '.'
        m.unstaged = m.unstaged or xy:sub(2, 2) ~= '.'
    elseif kind == 'u' then
        m.conflict = true
    elseif kind == '?' then
        m.untracked = true
    end
end

-- Path of an entry (repo-root relative, unquoted thanks to -z).
local PATH_PATTERNS = {
    ['1'] = '^1' .. (' %S+'):rep(7) .. ' (.*)$',
    ['2'] = '^2' .. (' %S+'):rep(8) .. ' (.*)$',
    ['u'] = '^u' .. (' %S+'):rep(9) .. ' (.*)$',
    ['?'] = '^%? (.*)$',
}

local function parse(out, rel)
    local oid, head, ab = nil, nil, ''
    local file, repo = {}, {}
    local records = vim.split(out, '\0', { trimempty = true })
    local i = 1
    while i <= #records do
        local line = records[i]
        local k, v = line:match('^# branch%.(%S+) (.+)$')
        if k == 'oid' then oid = v
        elseif k == 'head' then head = v
        elseif k == 'ab' then
            local a, b = v:match('^%+(%d+) %-(%d+)$')
            if a and a ~= '0' then ab = ab .. ' ↑' .. a end
            if b and b ~= '0' then ab = ab .. ' ↓' .. b end
        else
            local kind = line:sub(1, 1)
            local xy = line:sub(3, 4)
            note(repo, kind, xy)
            local pat = PATH_PATTERNS[kind]
            if pat and line:match(pat) == rel then note(file, kind, xy) end
            -- a rename's original path is its own -z record: skip it
            if kind == '2' then i = i + 1 end
        end
        i = i + 1
    end
    if not head then return '' end
    if head == '(detached)' then
        head = (oid and oid ~= '(initial)') and oid:sub(1, 7) or 'detached'
    end
    local fm, rm = marks(file), marks(repo)
    return head .. ab .. (fm ~= '' and ' ' .. fm or '')
        .. (rm ~= '' and ' · repo ' .. rm or '')
end

function M.refresh(buf)
    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    if vim.bo[buf].buftype ~= '' then return end
    local file = vim.api.nvim_buf_get_name(buf)
    if file == '' then return end
    local real = vim.uv.fs_realpath(file) or vim.fn.fnamemodify(file, ':p')
    local root = vim.fs.root(real, '.git')
    if not root then
        vim.b[buf].gitstatus = ''
        return
    end
    root = vim.uv.fs_realpath(root) or root
    local rel = real:sub(#root + 2)
    vim.system(
        { 'git', '--no-optional-locks', 'status', '--porcelain=v2', '--branch', '-z' },
        { cwd = root, text = true },
        function(r)
            local s = r.code == 0 and parse(r.stdout or '', rel) or ''
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(buf) then return end
                vim.b[buf].gitstatus = s
                pcall(vim.cmd.redrawstatus)
            end)
        end
    )
end

--- Cached segment for the current buffer, '' when unknown or not in a repo.
function M.get()
    return vim.b.gitstatus or ''
end

vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
    group = vim.api.nvim_create_augroup('gitstatus', { clear = true }),
    callback = function(a) M.refresh(a.buf) end,
})

return M
