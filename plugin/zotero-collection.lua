-- :ZoteroUpdateCollection
--
-- Make a Zotero collection contain exactly the references cited by a pandoc
-- project. The project is the nearest `pandoc-build.yaml` above the current
-- file (a pandoc defaults file, built with `pandoc -d pandoc-build.yaml`):
--
--   input-files:
--     - 01.md
--     - 02.md
--   metadata:
--     zotero-collection: "My Thesis"   # "Parent/Child" for a nested one
--
-- Citations are extracted by pandoc itself, cross-references (@fig:, @sec:,
-- ...) are skipped, and the collection is filled by Better BibTeX's
-- collection.scanAUX, so Zotero must be running. The collection mirrors the
-- document: items no longer cited are removed from it. Citation keys that
-- are not in the library are left out, reported, and listed in
-- citation-error.log next to pandoc-build.yaml (removed when there are none).

local BUILD_FILE = 'pandoc-build.yaml'
local LOG_FILE = 'citation-error.log'
local RPC_URL = 'http://127.0.0.1:23119/better-bibtex/json-rpc'
local CROSSREF_PREFIXES = { fig = true, sec = true, tbl = true, eq = true, lst = true }

--- Run by `pandoc lua`: read the defaults file, then print as JSON the
--- collection name, the input files and every citation id they contain.
local PANDOC_HELPER = [[
local f = assert(io.open(arg[1]))
local defaults = pandoc.read('---\n' .. f:read('a') .. '\n---\n', 'markdown').meta
f:close()
local str = function(v) return v ~= nil and pandoc.utils.stringify(v) or nil end
local files = {}
for _, v in ipairs(defaults['input-files'] or {}) do table.insert(files, str(v)) end
if defaults['input-file'] then table.insert(files, str(defaults['input-file'])) end
local reader = str(defaults['from'] or defaults['reader']) or 'markdown'
local keys, seen = {}, {}
for _, file in ipairs(files) do
  local fh = assert(io.open(file))
  local doc = pandoc.read(fh:read('a'), reader)
  fh:close()
  doc:walk({
    Cite = function(cite)
      for _, c in ipairs(cite.citations) do
        if not seen[c.id] then
          seen[c.id] = true
          table.insert(keys, c.id)
        end
      end
    end,
  })
end
local metadata = defaults['metadata'] or {}
print(pandoc.json.encode({
  collection = str(metadata['zotero-collection']) or '',
  files = files,
  keys = keys,
}))
]]

local running = false

local function notify(msg, level)
  vim.notify('ZoteroUpdateCollection: ' .. msg, level or vim.log.levels.INFO)
end

local function fail(msg)
  running = false
  notify(msg, vim.log.levels.ERROR)
end

--- Call a Better BibTeX JSON-RPC method; cb(result) on success, cb(nil, err)
--- on failure, where err has a `message` (and `code` for RPC errors).
local function rpc(method, params, cb)
  local body = vim.json.encode({ jsonrpc = '2.0', method = method, params = params, id = 1 })
  vim.system(
    { 'curl', '-s', '-m', '120', '-X', 'POST', '-H', 'Content-Type: application/json',
      '--data-binary', '@-', RPC_URL },
    { stdin = body, text = true },
    vim.schedule_wrap(function(obj)
      if obj.code ~= 0 or obj.stdout == '' then
        return cb(nil, { message = 'cannot reach Zotero; is it running with Better BibTeX?' })
      end
      local ok, res = pcall(vim.json.decode, obj.stdout)
      if not ok then return cb(nil, { message = 'unexpected reply: ' .. obj.stdout }) end
      if res.error then return cb(nil, res.error) end
      cb(res.result)
    end)
  )
end

--- Where `key` is cited in `files` (relative to `root`), as "file:line" strings.
local function find_locations(root, files, key)
  local locations = {}
  local needle = '@' .. key
  for _, file in ipairs(files) do
    local path = vim.fs.joinpath(root, file)
    if vim.fn.filereadable(path) == 1 then
      for lnum, line in ipairs(vim.fn.readfile(path)) do
        local from = 1
        while true do
          local s, e = line:find(needle, from, true)
          if not s then break end
          local before, after = line:sub(s - 1, s - 1), line:sub(e + 1, e + 1)
          if not before:find('[%w_]') and not after:find('[%w_]') then
            table.insert(locations, file .. ':' .. lnum)
            break
          end
          from = e + 1
        end
      end
    end
  end
  return locations
end

local function write_log(root, collection, missing, files)
  local log = vim.fs.joinpath(root, LOG_FILE)
  if #missing == 0 then
    vim.fn.delete(log)
    return
  end
  local lines = {
    'ZoteroUpdateCollection ' .. os.date('%Y-%m-%d %H:%M:%S'),
    'Collection: ' .. collection,
    '',
    'Citation keys not found in the Zotero library (' .. #missing .. '):',
  }
  for _, key in ipairs(missing) do
    local where = find_locations(root, files, key)
    table.insert(lines, key .. '  ' .. (#where > 0 and table.concat(where, ', ') or '(location not found)'))
  end
  vim.fn.writefile(lines, log)
end

--- Fill the collection with `found` keys, then log and report.
local function scan_into_collection(root, info, found, missing)
  local aux = vim.fn.tempname() .. '.aux'
  vim.fn.writefile(#found > 0 and { '\\citation{' .. table.concat(found, ',') .. '}' } or {}, aux)
  rpc('collection.scanAUX', { '//' .. info.collection, aux }, function(_, err)
    vim.fn.delete(aux)
    if err then return fail('Better BibTeX: ' .. tostring(err.message)) end
    write_log(root, info.collection, missing, info.files)
    running = false
    local msg = string.format('%d item(s) in "%s"', #found, info.collection)
    if #missing > 0 then
      notify(string.format('%s; %d missing key(s), see %s', msg, #missing, LOG_FILE), vim.log.levels.WARN)
    else
      notify(msg)
    end
  end)
end

--- Split the cited keys into those Better BibTeX knows and those it doesn't.
local function check_keys(root, info)
  local keys = vim.tbl_filter(function(k)
    local prefix = k:match('^(%a+):')
    return not (prefix and CROSSREF_PREFIXES[prefix])
  end, info.keys)
  if #keys == 0 then return scan_into_collection(root, info, {}, {}) end

  rpc('item.collections', { keys, false }, function(result, err)
    -- A reply with no matches at all comes back as an error (code -32602)
    if err and err.code ~= -32602 then return fail('Better BibTeX: ' .. tostring(err.message)) end
    local known = type(result) == 'table' and result or {}
    local found, missing = {}, {}
    for _, k in ipairs(keys) do
      table.insert(known[k] ~= nil and found or missing, k)
    end
    scan_into_collection(root, info, found, missing)
  end)
end

local function update_collection()
  if running then return notify('already running', vim.log.levels.WARN) end

  local start = vim.api.nvim_buf_get_name(0)
  start = start ~= '' and vim.fs.dirname(start) or vim.fn.getcwd()
  local build = vim.fs.find(BUILD_FILE, { upward = true, path = start, type = 'file' })[1]
  if not build then return notify('no ' .. BUILD_FILE .. ' found above this file', vim.log.levels.ERROR) end
  local root = vim.fs.dirname(build)
  running = true

  -- pandoc reads the files from disk, so save modified buffers in the project first
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(b)
    if vim.bo[b].modified and name:sub(1, #root + 1) == root .. '/' and name:match('%.md$') then
      vim.api.nvim_buf_call(b, function() vim.cmd('silent write') end)
    end
  end

  local helper = vim.fn.stdpath('cache') .. '/zotero-collection-cites.lua'
  vim.fn.writefile(vim.split(PANDOC_HELPER, '\n'), helper)
  vim.system({ 'pandoc', 'lua', helper, BUILD_FILE }, { cwd = root, text = true }, vim.schedule_wrap(function(obj)
    if obj.code ~= 0 then return fail('pandoc failed: ' .. vim.trim(obj.stderr or '')) end
    local ok, info = pcall(vim.json.decode, obj.stdout)
    if not ok then return fail('could not read the citations: ' .. obj.stdout) end
    info.collection = vim.trim(info.collection or ''):gsub('^/+', '')
    if info.collection == '' then
      return fail('no `metadata: zotero-collection:` in ' .. BUILD_FILE)
    end
    check_keys(root, info)
  end))
end

vim.api.nvim_create_user_command('ZoteroUpdateCollection', update_collection, {
  desc = 'Fill the Zotero collection named in pandoc-build.yaml with the cited references',
})
