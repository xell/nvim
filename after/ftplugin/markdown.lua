local vol = vim.opt_local

if vim.g.gneovim then vim.keymap.set('n', '<Leader>M', function()
    vim.cmd('MarkdownLivePreviewToggle')
end, { buffer = true, desc = 'Toggle Markdown Live Preview' })
end

if not vim.g.vscode then
    vol.concealcursor = 'nc'
    vol.conceallevel = 2
    vol.breakindent = true
    vol.linebreak = true
    vol.formatoptions = 'mBlrocq'
    vol.foldmethod = 'expr'
    vol.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.o.foldexpr = 'v:lua.MarkdownLevel2()'

    function MarkdownLevel2()
        local line = vim.fn.getline(vim.v.lnum)
        local nextline = vim.fn.getline(vim.v.lnum + 1)

        if line:match('^# .*$') then
            return '>1'
        end
        if line:match('^## .*$') then
            return '>2'
        end
        if line:match('^### .*$') then
            return '>3'
        end
        if line:match('^#### .*$') then
            return '>4'
        end
        if line:match('^##### .*$') then
            return '>5'
        end
        if line:match('^###### .*$') then
            return '>6'
        end

        if line:match('^%s*$') and (nextline:match('^#%s') or nextline:match('^<div%sclass="rst%-rubric"')) then
            return '0'
        end
        if line:match('^%s*$') and nextline:match('^##%s') then
            return '1'
        end
        if line:match('^%s*$') and nextline:match('^###%s') then
            return '2'
        end
        if line:match('^%s*$') and nextline:match('^####%s') then
            return '3'
        end
        if line:match('^%s*$') and nextline:match('^#####%s') then
            return '4'
        end

        return '='
    end
end

if vim.g.vscode then
    vim.keymap.del('n', 'gO', { buffer = true })
end

vol.tabstop = 2
vol.shiftwidth = 2
vol.comments:append(':-')
vol.comments:remove('fb:-')

local vks = vim.keymap.set
vks('v', '<Leader>s', [[<ESC>`>a~~<ESC>`<i~~<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>b', [[<ESC>`>a**<ESC>`<i**<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>i', [[<ESC>`>a*<ESC>`<i*<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>t', [[<ESC>`>a}<ESC>`<i{=<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>c', [[<ESC>`>a`<ESC>`<i`<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>h', [[<ESC>`>a==<ESC>`<i==<ESC>`>ll]], { buffer = true })

-- Pair <> for <url> autolinks (and <tags>) only once the character typed right
-- after < is a letter, so a less-than sign (a < b, <=, <-) is left alone. When
-- a pair is open, typing > steps over the closing > instead of doubling it.
-- Typing <> literally leaves the cursor between the two.
local autolink_group = vim.api.nvim_create_augroup('markdown_autolink_pair', { clear = false })
vim.api.nvim_clear_autocmds({ group = autolink_group, buffer = 0 })
local lt_pos -- {row, col} right after a just-typed <
vim.api.nvim_create_autocmd('InsertCharPre', {
    group = autolink_group,
    buffer = 0,
    callback = function()
        local char = vim.v.char
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local line = vim.api.nvim_get_current_line()
        local after_lt = lt_pos and lt_pos[1] == row and lt_pos[2] == col
        lt_pos = nil
        if char == '<' then
            lt_pos = { row, col + 1 }
        elseif after_lt and char:match('%a') then
            vim.v.char = char .. '>'
            vim.api.nvim_feedkeys(vim.keycode('<C-g>U<Left>'), 'ni', false)
        elseif after_lt and char == '>' then
            -- a literal <> puts the cursor between the two
            vim.api.nvim_feedkeys(vim.keycode('<C-g>U<Left>'), 'ni', false)
        elseif char == '>' and line:sub(col + 1, col + 1) == '>'
            and line:sub(1, col):match('<[^<>%s]*$') then
            vim.v.char = ''
            vim.api.nvim_feedkeys(vim.keycode('<C-g>U<Right>'), 'ni', false)
        end
    end,
})

vim.cmd[[
let s:textbundle_filename = expand('%:r')

command! -buffer -nargs=0 ExportTextbundle call <SID>export_textbundle()
function! s:export_textbundle()
    " Is it already in a Textbundle?
    if expand('%:p:h:t') =~ '\.textbundle$'
        echohl ErrorMsg | echo "It's already a Textbundle." | echohl None
        return
    endif
    " Is there an assests directory?
    let current_dir = expand('%:p:h')
    if !isdirectory(current_dir . '/assets')
        echohl ErrorMsg | echo "There's no 'assets' directory." | echohl None
        return
    endif
    " CD to current directory to siimplify the following operations
    exec 'cd ' . current_dir
    let textbundle_filename = expand('%:t:r')
    " let textbundle_path = current_dir . '/' . textbundle_filename . '.textbundle'
    " call mkdir(textbundle_path)
    call mkdir(textbundle_filename . '.textbundle')
    echo system('cp -r assets "' . textbundle_filename . '.textbundle/"')
    echo system('cp "' . expand('%:p:t') . '" "' . textbundle_filename . '.textbundle/text.md"')
    let info_json_content = ['{', '"version" : 2,',
                \ '"type": "net.daringfireball.markdown",',
                \ '"transient" : true,',
                \ '"creatorURL" : "file:///Applications/MacVim.app",',
                \ '"creatorIdentifier" : "org.vim",',
                \ '"sourceURL": ""', '}']
    call writefile(info_json_content, 'info.json', )
    echo system('mv info.json "' . textbundle_filename . '.textbundle/"')
    " echohl MoreMsg
    echom textbundle_filename . '.textbundle'
    echom 'was successfully created in'
    echom current_dir
    " echohl None
endfunction
]]

vim.keymap.set('n', 'zM', function()
  -- Execute the default zM to close all folds
  vim.cmd('normal! zM')

  -- Get all lines in the current buffer
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local h1_count = 0

  -- Count top-level headings matching lines starting with single '#'
  for _, line in ipairs(lines) do
    if line:match('^#%s') then
      h1_count = h1_count + 1
      if h1_count > 1 then
        break
      end
    end
  end

  -- Open the top-level fold if exactly one H1 exists
  if h1_count == 1 then
    vim.cmd('normal! zo')
  end
end, { buffer = true, silent = true, desc = "Fold all, but keep H1 open if it's the only one" })

-- ---------------------------------------------------------------------------
-- Heading word-count / target markers
--
-- A heading line may end with one of three suffixes (anchored at end of
-- line, one space before the `|`):
--
--   # Title |@|          snapshot: just report the section's word count.
--   # Title |200|        target: 200 is the word-count goal for this section.
--
-- :MdWordCount rescans the buffer and rewrites every such heading in place:
--
--   |@|          -> |@198|            (198 = current word count)
--   |200|        -> |200/198/99%|     (target/actual/percentage)
--   |@198|       -> |@<new count>|    (re-snapshot, no target semantics ever)
--   |200/.../..%| -> |200/<new>/<pct>%| (target 200 kept, actual/pct redone)
--   |0/!/!|      -> |0/!/!|           (target 0 is invalid; `!/!` flags it)
--
-- `|@N|` and `|T/A/P%|` are permanently distinct shapes (the `@` marks a
-- snapshot forever), so -- unlike a bare `|N|`, which always means "target"
-- -- a snapshot's own leftover number is never mistaken for a target on a
-- later run.
--
-- "Word count" is the same English-word definition as require('wordcount')
-- uses (runs of [0-9A-Za-z]), independent of whether WordCountOn is active.
--
-- A section is the heading (inclusive) up to, but not including, the next
-- heading whose level is the same or *shallower* (fewer or equal '#'); a
-- deeper heading nested inside it does not end the section. Fenced code
-- blocks (``` / ~~~) are skipped when looking for headings, so a `#` typed
-- inside one is never mistaken for a heading. Text inside HTML comments
-- (`<!-- ... -->`, possibly spanning multiple lines) never counts, including
-- the delimiters themselves -- removed text is replaced with a single space
-- so words on either side of a comment don't get spliced together. Any
-- marker on a heading being counted as part of a *different* section's range
-- (e.g. a marked subsection inside a marked parent section) is stripped from
-- the word count the same way, so the tool's own metadata never inflates the
-- count it reports.
--
-- Known limitations: only ATX headings (`#` through `######`) are
-- recognised, not setext headings or ones inside blockquotes/lists; and a
-- heading is detected from the raw line, so the pathological case of an
-- HTML comment that opens on one line and closes on a later line straddling
-- a `#`, or straddling a section boundary, isn't specially handled.
-- ---------------------------------------------------------------------------

if not vim.b.loaded_md_wordcount then
    vim.b.loaded_md_wordcount = true

    local wc = require('wordcount')

    -- Level (1-6) of an ATX heading line, or nil if it isn't one.
    local function heading_level(line)
        local hashes = line:match('^(#+)%s')
        if hashes and #hashes <= 6 then return #hashes end
        return nil
    end

    -- The fence marker (``` or ~~~, 3+ chars) opening at the start of `line`,
    -- as { char = '`'|'~', len = N }, or nil if this isn't a fence-open line.
    local function opening_fence(line)
        local marker = line:match('^%s*(```+)') or line:match('^%s*(~~~+)')
        if marker then return { char = marker:sub(1, 1), len = #marker } end
        return nil
    end

    -- Whether `line` closes the given open `fence` (same char, run of only
    -- that char at least as long as the opener, nothing else on the line).
    local function is_closing_fence(line, fence)
        local body = line:match('^%s*(.-)%s*$')
        if body == '' or body:sub(1, 1) ~= fence.char then return false end
        return body:match('^%' .. fence.char .. '+$') ~= nil and #body >= fence.len
    end

    -- All ATX heading lines in `lines`, as { { idx = <1-based line>, level = N }, ... },
    -- skipping anything inside a fenced code block.
    local function scan_headings(lines)
        local headings, fence = {}, nil
        for i, line in ipairs(lines) do
            if fence then
                if is_closing_fence(line, fence) then fence = nil end
            else
                local of = opening_fence(line)
                if of then
                    fence = of
                else
                    local lvl = heading_level(line)
                    if lvl then headings[#headings + 1] = { idx = i, level = lvl } end
                end
            end
        end
        return headings
    end

    -- Replace every <!-- ... --> span (which may cross line boundaries) in
    -- `lines` with a single space, preserving the line count/positions so
    -- the result can still be indexed the same way as the original buffer.
    local function strip_html_comments(lines)
        local clean, in_comment = {}, false
        for i, line in ipairs(lines) do
            local out, pos = {}, 1
            while true do
                if in_comment then
                    local s, e = line:find('%-%->', pos)
                    out[#out + 1] = ' '
                    if not s then break end
                    pos, in_comment = e + 1, false
                else
                    local s, e = line:find('<!%-%-', pos)
                    if not s then
                        out[#out + 1] = line:sub(pos)
                        break
                    end
                    out[#out + 1] = line:sub(pos, s - 1)
                    pos, in_comment = e + 1, true
                end
            end
            clean[i] = table.concat(out)
        end
        return clean
    end

    -- Recognize a trailing marker on a heading line. Returns:
    --   kind='ratio',    prefix, target  for `|T/A/P%|` or `|T/!/!|`
    --   kind='target',   prefix, target  for a bare `|N|`
    --   kind='snapshot', prefix, nil     for `|@|` or `|@N|`
    --   nil                              if none of the three match
    -- `prefix` is the line with the marker (and the space before it) removed.
    local function parse_marker(line)
        local prefix, t = line:match('^(.-)%s*|(%d+)/%d+/%d+%%|%s*$')
        if prefix then return 'ratio', prefix, tonumber(t) end
        prefix, t = line:match('^(.-)%s*|(%d+)/!/!|%s*$')
        if prefix then return 'ratio', prefix, tonumber(t) end
        prefix, t = line:match('^(.-)%s*|(%d+)|%s*$')
        if prefix then return 'target', prefix, tonumber(t) end
        prefix = line:match('^(.-)%s*|@%d*|%s*$')
        if prefix then return 'snapshot', prefix, nil end
        return nil
    end

    local function format_marker(kind, target, actual)
        if kind == 'snapshot' then return string.format('|@%d|', actual) end
        if target == 0 then return string.format('|%d/!/!|', target) end
        local pct = math.floor(actual / target * 100 + 0.5)
        return string.format('|%d/%d/%d%%|', target, actual, pct)
    end

    -- 1-based index of the last line of the section starting at
    -- headings[hi] (i.e. up to, but not including, the next heading whose
    -- level is <= headings[hi].level).
    local function section_end(headings, hi, total_lines)
        local level = headings[hi].level
        for j = hi + 1, #headings do
            if headings[j].level <= level then return headings[j].idx - 1 end
        end
        return total_lines
    end

    -- English-word count of clean_lines[start_idx..end_idx], with any
    -- marker stripped from every heading line in range (not just the one
    -- being updated -- a nested marked subsection's marker must not count
    -- towards its parent's total either).
    local function words_in_range(clean_lines, heading_set, start_idx, end_idx)
        local slice = {}
        for i = start_idx, end_idx do
            local l = clean_lines[i]
            if heading_set[i] then
                local kind, prefix = parse_marker(l)
                if kind then l = prefix end
            end
            slice[#slice + 1] = l
        end
        return wc.words_in_lines(slice)
    end

    local function update_heading_counts()
        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local clean_lines = strip_html_comments(lines)
        local headings = scan_headings(lines)
        local heading_set = {}
        for _, h in ipairs(headings) do heading_set[h.idx] = true end

        local changed = 0
        for hi, h in ipairs(headings) do
            local kind, prefix, target = parse_marker(lines[h.idx])
            if kind then
                local send = section_end(headings, hi, #lines)
                local actual = words_in_range(clean_lines, heading_set, h.idx, send)
                local new_line = prefix .. ' ' .. format_marker(kind, target, actual)
                if new_line ~= lines[h.idx] then
                    lines[h.idx] = new_line
                    changed = changed + 1
                end
            end
        end

        if changed > 0 then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        end
        vim.notify(string.format('MdWordCount: %d heading%s updated', changed, changed == 1 and '' or 's'))
    end

    vim.api.nvim_buf_create_user_command(0, 'MdWordCount', update_heading_counts,
        { desc = 'Update |@N| / |T/A/P%| heading word-count markers' })
end

-- ---------------------------------------------------------------------------
-- ==highlight== marks
--
-- `==text==` gets the `MdHighlightMark` highlight group on its inner text,
-- with the `==` delimiters concealed (conceallevel=2, concealcursor='nc',
-- both set above). This isn't CommonMark/GFM syntax, and tree-sitter's
-- markdown grammar has no node for `==` -- a query file can only label nodes
-- the parser already produced, and the parser never produces one for this --
-- so it's done directly with extmarks (nvim_buf_set_extmark) instead.
--
-- Skips fenced code blocks (``` / ~~~), since `==` is an extremely common
-- comparison operator in real code. Does not special-case inline code spans
-- (`` `==` ``) -- a stray `==` pair inside inline code on an otherwise plain
-- line will still be concealed; rare enough not to be worth the extra
-- parsing for a feature this small.
-- ---------------------------------------------------------------------------

if not vim.g.vscode then
    vim.api.nvim_set_hl(0, 'MdHighlightMark', { default = true, link = 'Search' })

    local hl_ns = vim.api.nvim_create_namespace('md_highlight_mark')

    local function opening_fence(line)
        local marker = line:match('^%s*(```+)') or line:match('^%s*(~~~+)')
        if marker then return { char = marker:sub(1, 1), len = #marker } end
        return nil
    end

    local function is_closing_fence(line, fence)
        local body = line:match('^%s*(.-)%s*$')
        if body == '' or body:sub(1, 1) ~= fence.char then return false end
        return body:match('^%' .. fence.char .. '+$') ~= nil and #body >= fence.len
    end

    -- Rescans the whole buffer and replaces all `md_highlight_mark` extmarks.
    -- Content must be non-empty and not itself start/end with `=`, so a
    -- setext-heading underline (a whole line of `=`) or a run like `===foo===`
    -- never gets mismatched against the wrong pair of delimiters.
    local function update_highlight_marks(buf)
        if not vim.api.nvim_buf_is_valid(buf) then return end
        vim.api.nvim_buf_clear_namespace(buf, hl_ns, 0, -1)

        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local fence = nil

        for lnum, line in ipairs(lines) do
            if fence then
                if is_closing_fence(line, fence) then fence = nil end
            else
                local of = opening_fence(line)
                if of then
                    fence = of
                else
                    local row = lnum - 1
                    local init = 1
                    while true do
                        local s, e, content = line:find('==(.-)==', init)
                        if not s then break end
                        if content ~= '' and not content:match('^=') and not content:match('=$') then
                            vim.api.nvim_buf_set_extmark(buf, hl_ns, row, s - 1, {
                                end_col = s + 1,
                                conceal = '',
                            })
                            vim.api.nvim_buf_set_extmark(buf, hl_ns, row, s + 1, {
                                end_col = e - 2,
                                hl_group = 'MdHighlightMark',
                            })
                            vim.api.nvim_buf_set_extmark(buf, hl_ns, row, e - 2, {
                                end_col = e,
                                conceal = '',
                            })
                        end
                        init = e + 1
                    end
                end
            end
        end
    end

    if not vim.b.loaded_md_highlight_mark then
        vim.b.loaded_md_highlight_mark = true

        local buf = vim.api.nvim_get_current_buf()
        local group = vim.api.nvim_create_augroup('md_highlight_mark_' .. buf, { clear = true })
        -- While typing, rescan once after a pause instead of on every keystroke
        local timer = assert(vim.uv.new_timer())
        local rescan_later = vim.schedule_wrap(function() update_highlight_marks(buf) end)

        vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'InsertLeave' }, {
            buffer = buf,
            group = group,
            callback = function(ev)
                timer:stop()
                if ev.event == 'TextChangedI' then
                    timer:start(150, 0, rescan_later)
                else
                    update_highlight_marks(buf)
                end
            end,
            desc = 'Rescan ==highlight== marks',
        })
        vim.api.nvim_create_autocmd('BufWipeout', {
            buffer = buf,
            group = group,
            once = true,
            callback = function() timer:close() end,
        })

        update_highlight_marks(buf)
    end
end
