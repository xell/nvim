-- vim:

vim.g.pkm_base = vim.fn.fnameescape(vim.fn.glob('~/Documents/My'))
vim.g.project_bases = {
    vim.g.pkm_base,
    vim.fn.fnameescape(vim.fn.glob('~/.config/nvim')), }

vim.keymap.set('n', '<Leader>N', function()
    if vim.bo.modified == false and
        vim.fn.getline('1') == '' and
        vim.fn.line('$') == 1 then
        -- current buffer is new, open here
        vim.cmd('e ' .. vim.g.pkm_base)
    else
        vim.cmd('tabe ' .. vim.g.pkm_base)
    end
end, { desc = "My"})

--- Reverse fnameescape(): it only ever inserts a backslash right before a
--- character to escape it, so stripping those backslashes recovers the
--- original string. (There is no builtin fnameunescape().)
local function ai_fnameunescape(s)
  return (s:gsub('\\(.)', '%1'))
end

--- Resolve `filepath` against vim.g.project_bases, returning either the
--- path relative to the matching base, or the absolute path if no base
--- matches. Entries in vim.g.project_bases are expected to be
--- fnameescape()-d absolute paths (as produced above via fnameescape() +
--- glob()).
local function ai_relative_path(filepath)
  for _, base in ipairs(vim.g.project_bases or {}) do
    local b = vim.fn.fnamemodify(ai_fnameunescape(base), ':p')
    b = b:gsub('/+$', '')
    if filepath == b then
      return vim.fn.fnamemodify(filepath, ':t')
    elseif filepath:sub(1, #b + 1) == b .. '/' then
      return filepath:sub(#b + 2)
    end
  end
  return filepath
end

--- Format the current/last visual selection ('v' or 'V') as a reference
--- string of the form:
---
---   `@path/to/file.md#L5-6` "quoted selected text"
---
--- - the path is relative to whichever vim.g.project_bases entry contains
---   the file, or the absolute path otherwise.
--- - the `#L` part has one line number if the selection spans a single
---   line, two (start-end) otherwise.
--- - the quoted text is appended only for charwise ('v') selections, and
---   is omitted for linewise ('V') selections.
--- - special case: a 'v' selection of exactly one character (e.g. hitting
---   `v` and doing nothing else) yields just `@path/to/file.md`, with no
---   `#L` or quoted text at all.
---
--- Returns nil (and does nothing else) if the last visual selection wasn't
--- 'v'/'V'. Meant to be called right after leaving a visual selection.
local function ai_format_ref()
  local mode = vim.fn.visualmode()
  if mode ~= 'v' and mode ~= 'V' then
    return nil
  end

  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line, end_line = start_pos[2], end_pos[2]

  local filepath = vim.fn.expand('%:p')
  local path_part = ai_relative_path(filepath)

  if mode == 'v' and start_line == end_line and start_pos[3] == end_pos[3] then
    return ('`@%s`'):format(path_part)
  end

  local line_part
  if start_line == end_line then
    line_part = ('L%d'):format(start_line)
  else
    line_part = ('L%d-%d'):format(start_line, end_line)
  end

  local result = ('`@%s#%s`'):format(path_part, line_part)

  if mode == 'v' then
    local lines = vim.fn.getregion(start_pos, end_pos, { type = 'v' })
    result = result .. ' "' .. table.concat(lines, '\n') .. '"'
  end

  return result
end

--- Format the current/last visual selection via ai_format_ref() and write
--- it to the system clipboard register ("+").
function _G.AiCopyRef()
  local result = ai_format_ref()
  if not result then
    vim.notify('AiCopyRef: last visual selection was not v/V', vim.log.levels.WARN)
    return
  end
  vim.fn.setreg('+', result)
end

vim.api.nvim_create_user_command('CopyRef', function()
  AiCopyRef()
end, { range = true })

vim.keymap.set('x', '<leader>cr', ':CopyRef<CR>')

--- Return the winid of the terminal window in tabpage `tabnr` (current
--- tabpage by default), or nil if there isn't one. Built for the simple
--- one-terminal-per-tabpage case: if several exist, the last one found
--- wins rather than erroring.
local function ai_terminal_win(tabnr)
  local found
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabnr or 0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == 'terminal' then
      found = win
    end
  end
  return found
end

--- Send `text` to the pty of the current tabpage's terminal window (i.e.
--- type it into whatever job is running there - a shell, the Claude Code
--- CLI, ...), then move focus into that window and enter terminal mode.
---
--- This writes to the job's stdin via its channel; where the text lands
--- on screen is entirely up to the program reading it (for a readline- or
--- TUI-style prompt that's normally wherever its own input cursor is).
--- Neovim's terminal-window cursor position can't be used to steer this -
--- a terminal buffer is a rendered view of the pty, not an editable
--- buffer we can insert into at an arbitrary row/col.
function _G.AiSendToTerm(text)
  local win = ai_terminal_win(0)
  if not win then
    vim.notify('AiSendToTerm: no terminal window in this tabpage', vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_win_get_buf(win)
  vim.fn.chansend(vim.bo[buf].channel, text)

  vim.api.nvim_set_current_win(win)
  vim.cmd('startinsert')
end

vim.api.nvim_create_user_command('SendToTerm', function()
  local result = ai_format_ref()
  if not result then
    vim.notify('SendToTerm: last visual selection was not v/V', vim.log.levels.WARN)
    return
  end
  AiSendToTerm(result)
end, { range = true })

vim.keymap.set('x', '<leader>cs', ':SendToTerm<CR>', { desc = 'Send selection to terminal' })

