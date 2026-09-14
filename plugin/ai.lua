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
---
--- The result is written to the system clipboard register ("+").
---
--- Meant to be called right after leaving a visual selection, e.g. wrapped
--- in a user command:
---
vim.api.nvim_create_user_command('CopyRef', function()
  AiCopyRef()
end, { range = true })

vim.keymap.set('x', '<leader>cr', ':CopyRef<CR>')

function _G.AiCopyRef()
  local mode = vim.fn.visualmode()
  if mode ~= 'v' and mode ~= 'V' then
    vim.notify('AiCopyRef: last visual selection was not v/V', vim.log.levels.WARN)
    return
  end

  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line, end_line = start_pos[2], end_pos[2]

  local filepath = vim.fn.expand('%:p')
  local path_part = ai_relative_path(filepath)

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

  vim.fn.setreg('+', result)
end

