-- The full (multibyte-aware) character before the cursor
local function prev_char()
  local col = vim.fn.col('.') - 1
  if col == 0 then return '' end
  local before = vim.api.nvim_get_current_line():sub(1, col)
  return vim.fn.strcharpart(before, vim.fn.strchars(before) - 1)
end

local openers = {
  [''] = true, ['('] = true, ['['] = true, ['{'] = true,
  ['“'] = true, ['‘'] = true, ['—'] = true, ['–'] = true,
}

local function smart_quote(open, close)
  return function()
    local p = prev_char()
    if openers[p] or p:match('^%s$') then return open end
    return close
  end
end

-- Insert mode: type the right curly quote
vim.keymap.set('i', "<M-S-'>", smart_quote('“', '”'), { expr = true })
vim.keymap.set('i', "<M-'>", smart_quote('‘', '’'), { expr = true })

-- Normal mode: curl the straight quote under the cursor in place
local function curl_under_cursor()
  local col = vim.fn.col('.')
  local c = vim.api.nvim_get_current_line():sub(col, col)
  local pairs = { ["'"] = { '‘', '’' }, ['"'] = { '“', '”' } }
  local p = pairs[c]
  if not p then return end
  vim.cmd('normal! r' .. smart_quote(p[1], p[2])())
end

vim.keymap.set('n', "<M-'>", curl_under_cursor, { desc = 'Curl straight quote under cursor' })
vim.keymap.set('n', "<M-S-'>", curl_under_cursor, { desc = 'Curl straight quote under cursor' })

