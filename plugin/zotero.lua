-- Zotero helpers for writing in Markdown with pandoc and Better BibTeX:
--
--   :ZoteroUpdateCollection  fill a Zotero collection with the references a
--                            pandoc-build.yaml project cites
--   :ZoteroCite, <C-x><C-z>  Zotero's citation dialog: edit the pandoc
--                            citation under the cursor, or insert a new one
--
-- Both need Zotero running with Better BibTeX.

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

-- :ZoteroCite and <C-x><C-z> (Insert mode)
--
-- Zotero's citation dialog, driven like a word processor does it, through
-- Zotero's HTTP integration protocol (the one Better BibTeX's CAYW uses).
-- With the cursor inside a pandoc citation such as
--   [see @key1, pp. 3-5; -@key2, chap. 2]
-- or a narrative one such as  @key [p. 3]  (only if the key is in the library)
-- the dialog opens with it for editing, and the edited citation replaces it
-- on Accept; a narrative citation stays narrative while it is a single item.
-- An @key that is not in the library (a typo, an outdated key) is replaced by
-- the picked citation, keeping its page; after a cross-reference such as
-- @fig:map a new citation goes after it. Anywhere else a new citation is inserted: in Insert mode at the
-- caret, from the command after the character under the cursor. Cancel
-- changes nothing. Items come back in the citation style's order. Afterwards
-- the app that was frontmost (gneovim or the terminal) is brought back.

local CONNECTOR = 'http://127.0.0.1:23119/connector/document'
local DOC_ID = 'gneovim'
local CODE_PREFIX = 'ITEM CSL_CITATION '
local cite_ns = vim.api.nvim_create_namespace('zotero_cite')
local citing = false

local function cite_notify(msg, level)
  vim.notify('ZoteroCite: ' .. msg, level or vim.log.levels.INFO)
end

-- Pandoc locator terms and the CSL labels Zotero uses for them
local TERM_LABEL = {
  p = 'page', pp = 'page', page = 'page', pages = 'page',
  chap = 'chapter', chaps = 'chapter', chapter = 'chapter', chapters = 'chapter',
  sec = 'section', secs = 'section', section = 'section', sections = 'section',
  ['§'] = 'section', ['§§'] = 'section',
  fig = 'figure', figs = 'figure', figure = 'figure', figures = 'figure',
  l = 'line', ll = 'line', line = 'line', lines = 'line',
  n = 'note', nn = 'note', note = 'note', notes = 'note',
  para = 'paragraph', paras = 'paragraph', paragraph = 'paragraph', paragraphs = 'paragraph',
  ['¶'] = 'paragraph', ['¶¶'] = 'paragraph',
  v = 'verse', vv = 'verse', verse = 'verse', verses = 'verse',
  vol = 'volume', vols = 'volume', volume = 'volume', volumes = 'volume',
  bk = 'book', bks = 'book', book = 'book', books = 'book',
  col = 'column', cols = 'column', column = 'column', columns = 'column',
  fol = 'folio', fols = 'folio', folio = 'folio', folios = 'folio',
  no = 'number', nos = 'number', number = 'number', numbers = 'number',
  op = 'opus', opp = 'opus', opus = 'opus', opera = 'opus',
  pt = 'part', pts = 'part', part = 'part', parts = 'part',
  ['s.v'] = 'sub verbo', ['s.vv'] = 'sub verbo', ['sub verbo'] = 'sub verbo',
}
local TERMS = vim.tbl_keys(TERM_LABEL)
table.sort(TERMS, function(a, b) return #a > #b end)
-- CSL label -> pandoc term, singular and plural
local LABEL_TERM = {
  page = { 'p.', 'pp.' }, chapter = { 'chap.', 'chaps.' }, section = { 'sec.', 'secs.' },
  figure = { 'fig.', 'figs.' }, line = { 'l.', 'll.' }, note = { 'n.', 'nn.' },
  paragraph = { 'para.', 'paras.' }, verse = { 'v.', 'vv.' }, volume = { 'vol.', 'vols.' },
  book = { 'bk.', 'bks.' }, column = { 'col.', 'cols.' }, folio = { 'fol.', 'fols.' },
  number = { 'no.', 'nos.' }, opus = { 'op.', 'opp.' }, part = { 'pt.', 'pts.' },
  ['sub verbo'] = { 's.v.', 's.vv.' },
}

--- Read a locator ("pp. 3-5", "chap. 2", "12") from the start of `s`;
--- returns label, locator, rest, or nil.
local function read_locator(s)
  local function value(t)
    local v, rest = t:match('^([%w][%w%-–:]*)(.*)$')
    if not v then return nil end
    while true do -- lists such as "33, 35-37"
      local more, r = rest:match('^(,%s*%d[%w%-–:]*)(.*)$')
      if not more then break end
      v, rest = v .. more, r
    end
    return v, rest
  end
  local lower = s:lower()
  for _, term in ipairs(TERMS) do
    if lower:sub(1, #term) == term then
      local after = s:sub(#term + 1):gsub('^%.', '')
      if after:match('^%s') or after:match('^%d') then
        local v, rest = value((after:gsub('^%s+', '')))
        if v then return TERM_LABEL[term], v, rest end
      end
    end
  end
  if s:match('^%d') then -- a bare number is a page
    local v, rest = value(s)
    if v then return 'page', v, rest end
  end
end

--- Read the citation key after the `@` at index `at` of `s`; returns the key
--- and the index just after it, or nil.
local function read_key(s, at)
  if s:sub(at + 1, at + 1) == '{' then
    local key = s:match('^{(.-)}', at + 1)
    if key and key ~= '' then return key, at + 3 + #key end
    return nil
  end
  local run = s:match('^[%w_:.#$%%&%-+?<>~/]+', at + 1)
  if not run then return nil end
  local key = run:gsub('[:.#$%%&%-+?<>~/]+$', '') -- internal punctuation only
  if key == '' then return nil end
  return key, at + 1 + #key
end

--- Locator and suffix of the text after a key ("p. 3, emphasis added",
--- "and passim") into `item`.
local function read_locator_suffix(item, text)
  local braced, after = text:match('^{(.-)}(.*)$')
  local label, loc, tail = read_locator(braced or text)
  if label and braced then loc, tail = vim.trim(loc .. tail), after end
  if label then
    item.label, item.locator, text = label, loc, tail
  end
  item.suffix = vim.trim(text)
end

--- Parse the inside of a bracketed pandoc citation into citation items,
--- or nil if it is not a citation.
local function parse_citation(inner)
  local items = {}
  for part in (inner .. ';'):gmatch('(.-);') do
    local at = part:find('@', 1, true)
    if not at then return nil end
    local prefix, suppress = part:sub(1, at - 1), false
    if prefix:match('%-$') then suppress, prefix = true, prefix:sub(1, -2) end
    local key, stop = read_key(part, at)
    if not key then return nil end
    local rest = part:sub(stop)
    local item = { key = key, prefix = vim.trim(prefix), suppress = suppress }
    local body = rest:match('^%s*,%s*(.*)$')
    if body then
      read_locator_suffix(item, body)
      if not item.locator then item.suffix = vim.trim(rest) end -- a comma but no locator
    else
      item.suffix = vim.trim(rest)
    end
    table.insert(items, item)
  end
  return items
end

local function format_key(key)
  return key:match('^[%w_]+$') and '@' .. key or '@{' .. key .. '}'
end

--- "pp. 3-5" for an item's locator, or ''.
local function format_locator(it)
  if not it.locator or it.locator == '' then return '' end
  local terms = LABEL_TERM[it.label or 'page']
  local plural = it.locator:find('[-–,&]') ~= nil
  return (terms and terms[plural and 2 or 1] or it.label) .. ' ' .. it.locator
end

--- Join text and a suffix the way pandoc writes it.
local function add_suffix(text, suffix)
  if not suffix or suffix == '' then return text end
  if text == '' then return (suffix:gsub('^,%s*', '')) end
  return text .. (suffix:match('^[,.;:]') and '' or ' ') .. suffix
end

--- Pandoc text for citation items {key, prefix, suppress, label, locator, suffix}.
local function format_citation(items)
  local out = {}
  for _, it in ipairs(items) do
    local s = (it.prefix ~= '' and it.prefix .. ' ' or '') .. (it.suppress and '-' or '') .. format_key(it.key)
    local loc = format_locator(it)
    table.insert(out, add_suffix(loc ~= '' and s .. ', ' .. loc or s, it.suffix))
  end
  return '[' .. table.concat(out, '; ') .. ']'
end

--- Narrative pandoc text for one item: @key [p. 3, suffix].
local function format_narrative(it)
  local inner = add_suffix(format_locator(it), it.suffix)
  return format_key(it.key) .. (inner ~= '' and ' [' .. inner .. ']' or '')
end

--- The citation around the cursor: start col (1-based), end col, items; or nil.
--- `caret` is true in Insert mode, where the cursor sits between characters.
local function citation_at_cursor(line, col, caret)
  local p = col + 1
  for s, e in line:gmatch('()%b[]()') do
    e = e - 1
    local inside
    if caret then inside = p > s and p <= e else inside = p >= s and p <= e end
    local is_link = line:sub(e + 1, e + 1):match('[%(%[]') or line:sub(s - 1, s - 1) == '!'
    if inside and not is_link then
      local items = parse_citation(line:sub(s + 1, e - 1))
      if items then return s, e, items end
    end
  end
end

--- A narrative citation around the cursor (@key or @key [p. 3]): start col,
--- end col, its single item; or nil. Whether the key is in the library is
--- checked by the caller. A cross-reference (@fig:map) gives start, end,
--- nil, 'crossref'.
local function narrative_at_cursor(line, col, caret)
  local p = col + 1
  local from = 1
  while true do
    local at = line:find('@', from, true)
    if not at then return nil end
    local prev = line:sub(at - 1, at - 1)
    local key, stop = nil, nil
    if not prev:match('[%w_%-]') then key, stop = read_key(line, at) end -- not an email or -@key
    if key then
      local e = stop - 1
      local bs, be = line:find('^ ?%b[]', stop)
      local inner
      if bs and not line:sub(be + 1, be + 1):match('[%(%[]') then
        inner, e = line:sub(line:sub(bs, bs) == ' ' and bs + 2 or bs + 1, be - 1), be
      end
      local inside
      if caret then inside = p > at and p <= e else inside = p >= at and p <= e end
      if inside then
        local prefix = key:match('^(%a+):')
        if prefix and CROSSREF_PREFIXES[prefix] then return at, e, nil, 'crossref' end
        local item = { key = key, prefix = '', suppress = false }
        if inner then read_locator_suffix(item, inner) end
        return at, e, { item }
      end
    end
    from = at + 1
  end
end

local function sql_quote(s) return "'" .. s:gsub("'", "''") .. "'" end

--- Look up citation keys in a fresh copy of zotero.sqlite: the library URI
--- and, for each key, the Zotero item id and key.
local function zotero_sqlite()
  local ok, cfg = pcall(function() return require('zotcite.config').get_config() end)
  if ok and cfg and cfg.zotero_sqlite_path then return cfg.zotero_sqlite_path end
  -- Zotero's own setting for a custom data directory
  for _, prefs in ipairs(vim.fn.glob('~/Library/Application Support/Zotero/Profiles/*/prefs.js', false, true)) do
    for _, l in ipairs(vim.fn.readfile(prefs)) do
      local dir = l:match('^user_pref%("extensions%.zotero%.dataDir", "(.-)"%);')
      if dir then return dir .. '/zotero.sqlite' end
    end
  end
  return vim.fn.expand('~/Zotero/zotero.sqlite')
end

local function lookup_items(keys)
  local src = zotero_sqlite()
  if not vim.uv.fs_stat(src) then return nil, 'Zotero database not found: ' .. src end
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  local db = dir .. '/z.sqlite'
  vim.uv.fs_copyfile(src, db)
  if vim.uv.fs_stat(src .. '-wal') then vim.uv.fs_copyfile(src .. '-wal', db .. '-wal') end
  local query = "SELECT key, value FROM settings WHERE setting = 'account' AND key IN ('userID', 'localUserKey');"
    .. ' SELECT v.value AS citekey, i.itemID AS id, i.key AS key FROM items i'
    .. ' JOIN itemData d ON d.itemID = i.itemID JOIN fields f ON f.fieldID = d.fieldID'
    .. ' JOIN itemDataValues v ON v.valueID = d.valueID'
    .. " WHERE f.fieldName = 'citationKey' AND i.libraryID = 1"
    .. ' AND i.itemID NOT IN (SELECT itemID FROM deletedItems)'
    .. ' AND v.value IN (' .. table.concat(vim.tbl_map(sql_quote, keys), ', ') .. ');'
  local obj = vim.system({ 'sqlite3', '-json', db, query }, { text = true }):wait()
  vim.fn.delete(dir, 'rf')
  if obj.code ~= 0 then return nil, 'could not read the Zotero database: ' .. (obj.stderr or '') end
  -- sqlite3 prints one JSON array per statement
  local account, items = {}, {}
  for chunk in obj.stdout:gmatch('%b[]') do
    for _, row in ipairs(vim.json.decode(chunk)) do
      if row.citekey then items[row.citekey] = row else account[row.key] = row.value end
    end
  end
  local user = account.userID and tostring(account.userID) or ('local/' .. tostring(account.localUserKey))
  return 'http://zotero.org/users/' .. user .. '/items/', items
end

--- Zotero field code for parsed citation items, or nil and the unknown keys.
local function field_code(items, text)
  local keys = vim.tbl_map(function(it) return it.key end, items)
  local base, found = lookup_items(keys)
  if not base then return nil, found end
  local unknown, citation_items = {}, {}
  for _, it in ipairs(items) do
    local row = found[it.key]
    if not row then
      table.insert(unknown, it.key)
    else
      table.insert(citation_items, {
        id = row.id, uris = { base .. row.key },
        locator = it.locator, label = it.locator and (it.label or 'page') or nil,
        prefix = it.prefix ~= '' and it.prefix or nil,
        suffix = it.suffix ~= '' and it.suffix or nil,
        ['suppress-author'] = it.suppress or nil,
      })
    end
  end
  if #unknown > 0 then return nil, 'not in the Zotero library: ' .. table.concat(unknown, ', ') end
  return CODE_PREFIX .. vim.json.encode({
    citationID = vim.fn.sha256(text .. vim.uv.hrtime()):sub(1, 8),
    properties = { formattedCitation = text, plainCitation = text, noteIndex = 0 },
    citationItems = citation_items,
    schema = 'https://github.com/citation-style-language/schema/raw/master/csl-citation.json',
  })
end

--- Citation items of a Zotero field code.
local function code_to_items(code)
  local ok, citation = pcall(vim.json.decode, code:sub(#CODE_PREFIX + 1))
  if not ok then return nil, 'unreadable citation from Zotero' end
  local items = {}
  for _, ci in ipairs(citation.citationItems or {}) do
    local key = type(ci.itemData) == 'table' and ci.itemData['citation-key']
    if not key then return nil, 'Zotero sent an item without a citation key' end
    table.insert(items, {
      key = key, prefix = ci.prefix or '', suppress = ci['suppress-author'] == true,
      label = ci.label, locator = ci.locator, suffix = ci.suffix,
    })
  end
  if #items == 0 then return nil, 'Zotero sent an empty citation' end
  return items
end

--- Run one addEditCitation transaction. `field` is the citation under the
--- cursor (or nil for a new one); on_done(err, fields, deleted) gets the
--- final fields.
local function run_transaction(field, on_done)
  local fields = field and { field } or {}
  local deleted = false
  local data = ('<data data-version="3"><session id="%s"/>'
    .. '<style id="http://www.zotero.org/styles/apa" locale="en-US" hasBibliography="1" bibliographyStyleHasBeenSet="1"/>'
    .. '<prefs><pref name="fieldType" value="Http"/><pref name="noteType" value="0"/></prefs></data>'):format(DOC_ID)

  local function find(id)
    for i, f in ipairs(fields) do if f.id == id then return f, i end end
    error('unknown field ' .. tostring(id))
  end

  local function reply(command, args)
    local id = args[2]
    if command == 'Application.getActiveDocument' then
      return { documentID = DOC_ID, outputFormat = 'html', supportedNotes = { 'footnotes' }, processorName = 'gneovim' }
    elseif command == 'Document.displayAlert' then
      vim.schedule(function() cite_notify('Zotero: ' .. tostring(args[2]), vim.log.levels.WARN) end)
      return 0
    elseif command == 'Document.activate' or command == 'Document.convert'
      or command == 'Document.setBibliographyStyle' or command == 'Document.insertText'
      or command == 'Field.select' then
      return vim.NIL
    elseif command == 'Document.canInsertField' then return true
    elseif command == 'Document.cursorInField' then return field or vim.NIL
    elseif command == 'Document.getDocumentData' then return data
    elseif command == 'Document.setDocumentData' then data = args[2]; return vim.NIL
    elseif command == 'Document.getFields' then return fields
    elseif command == 'Document.insertField' then
      local f = { id = tostring(#fields + 1), code = '', text = '{Placeholder}', noteIndex = 0, adjacent = false }
      table.insert(fields, f)
      return f
    elseif command == 'Field.delete' then
      local _, i = find(id); table.remove(fields, i); deleted = true; return vim.NIL
    elseif command == 'Field.removeCode' then find(id).code = ''; return vim.NIL
    elseif command == 'Field.setText' then find(id).text = args[3]; return vim.NIL
    elseif command == 'Field.getText' then return find(id).text
    elseif command == 'Field.setCode' then find(id).code = args[3]; return vim.NIL
    end
    error('unsupported command ' .. command)
  end

  local function post(path, payload, cb)
    vim.system({ 'curl', '-s', '-w', '\n%{http_code}', '-X', 'POST',
      '-H', 'Content-Type: application/json', '-H', 'zotero-allowed-request: true',
      '--data-binary', '@-', CONNECTOR .. path }, { stdin = vim.json.encode(payload), text = true }, function(obj)
      local out, status = (obj.stdout or ''):match('^(.*)\n(%d+)$')
      if obj.code ~= 0 or not status or status == '000' then return on_done('cannot reach Zotero; is it running?') end
      if status == '503' then return on_done('Zotero is busy with another citation dialog') end
      if status ~= '200' then return on_done('Zotero answered HTTP ' .. status .. ': ' .. out) end
      local ok, res = pcall(vim.json.decode, out ~= '' and out or 'null')
      if not ok then return on_done('unreadable answer from Zotero') end
      cb(res)
    end)
  end

  local function step(res)
    if type(res) ~= 'table' or not res.command then return on_done('unexpected answer from Zotero') end
    if res.command == 'Document.complete' then return on_done(nil, fields, deleted) end
    local ok, payload = pcall(reply, res.command, res.arguments or {})
    if not ok then
      -- always answer, so Zotero does not stay stuck in the transaction
      return post('/respond', { error = 'GneovimError', message = tostring(payload), stack = vim.NIL },
        function() on_done(tostring(payload)) end)
    end
    post('/respond', payload, step)
  end

  post('/execCommand', { command = 'addEditCitation', docId = DOC_ID }, step)
end

--- Pid of the frontmost app, to give it focus back when the dialog closes.
local function frontmost_pid()
  local out = vim.fn.system({ 'osascript', '-e',
    'tell application "System Events" to get unix id of first process whose frontmost is true' })
  return vim.v.shell_error == 0 and tonumber(vim.trim(out)) or nil
end

local function refocus(pid)
  if not pid then return end
  vim.system({ 'osascript', '-e', ('tell application "System Events" to set frontmost of '
    .. '(first process whose unix id is %d) to true'):format(pid) })
end

--- `caret` is true when called from Insert mode.
local function cite(caret)
  if citing then return cite_notify('the Zotero citation dialog is already open', vim.log.levels.WARN) end
  local buf = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  local field, mark
  local s, e, items = citation_at_cursor(line, col, caret)
  local narrative, unknown, after_word = false, nil, nil
  if not s then
    local ns, ne, nitems, kind = narrative_at_cursor(line, col, caret)
    if kind == 'crossref' then
      after_word = ne -- a new citation goes after the cross-reference
    elseif ns then
      -- a bare @word is a citation only if the library has that key; if not,
      -- it is probably a typo, which the picked citation replaces
      local _, found = lookup_items({ nitems[1].key })
      if type(found) == 'table' and found[nitems[1].key] then
        s, e, items, narrative = ns, ne, nitems, true
      else
        unknown, narrative = { s = ns, e = ne, item = nitems[1] }, true
      end
    end
  end
  local lead = '' -- text put before a new citation
  if s then
    local text = line:sub(s, e)
    local code, err = field_code(items, text)
    if not code then return cite_notify(err, vim.log.levels.ERROR) end
    field = { id = '1', code = code, text = text, noteIndex = 0, adjacent = false }
    mark = vim.api.nvim_buf_set_extmark(buf, cite_ns, row - 1, s - 1, { end_row = row - 1, end_col = e })
  elseif unknown then
    mark = vim.api.nvim_buf_set_extmark(buf, cite_ns, row - 1, unknown.s - 1, { end_row = row - 1, end_col = unknown.e })
  else
    if after_word then
      col, lead = after_word, ' '
    elseif not caret and #line > 0 then
      col = col + 1 + vim.str_utf_end(line, col + 1)
    end
    mark = vim.api.nvim_buf_set_extmark(buf, cite_ns, row - 1, col, {})
  end

  local original_code = field and field.code -- Zotero updates `field` in place
  local pid = frontmost_pid()
  citing = true
  run_transaction(field, vim.schedule_wrap(function(err, fields, deleted)
    citing = false
    refocus(pid)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    local pos = vim.api.nvim_buf_get_extmark_by_id(buf, cite_ns, mark, { details = true })
    vim.api.nvim_buf_del_extmark(buf, cite_ns, mark)
    if err then return cite_notify(err, vim.log.levels.ERROR) end
    local r1, c1 = pos[1], pos[2]
    local r2, c2 = pos[3].end_row or r1, pos[3].end_col or c1

    local new_text
    if deleted then
      new_text = ''
    else
      local f = fields[#fields]
      if not f or f.code == '' or f.code == original_code then return end -- cancelled
      local new_items, perr = code_to_items(f.code)
      if not new_items then return cite_notify(perr, vim.log.levels.ERROR) end
      local one = new_items[1]
      if unknown and #new_items == 1 and not one.locator and (one.suffix or '') == '' then
        -- keep the page of the citation being fixed
        one.label, one.locator, one.suffix = unknown.item.label, unknown.item.locator, unknown.item.suffix
      end
      if narrative and #new_items == 1 and one.prefix == '' and not one.suppress then
        new_text = format_narrative(one)
      else
        new_text = format_citation(new_items)
        if narrative then
          cite_notify('a narrative citation holds one reference without prefix or suppressed author, '
            .. 'so it became a bracketed citation')
        end
      end
      new_text = lead .. new_text
    end
    vim.api.nvim_buf_set_text(buf, r1, c1, r2, c2, { new_text })
    if vim.api.nvim_get_current_buf() == buf and new_text ~= '' then
      local in_insert = vim.api.nvim_get_mode().mode:sub(1, 1) == 'i'
      vim.api.nvim_win_set_cursor(0, { r1 + 1, c1 + #new_text - (in_insert and 0 or 1) })
    end
  end))
end

vim.api.nvim_create_user_command('ZoteroCite', function() cite(false) end, {
  desc = "Edit the citation under the cursor in Zotero's dialog, or insert a new one after the cursor",
})
vim.keymap.set('i', '<C-x><C-z>', function() cite(true) end, {
  desc = "Zotero citation dialog: edit the citation around the caret, or insert one",
})
