local function cursor_path()
  local word = vim.fn["netrw#Call"]("NetrwGetWord")
  local path

  if vim.w.netrw_liststyle == 3 then
    -- Tree mode: rebuild the path from the indentation.
    -- NetrwTreePath returns the containing dir for a file,
    -- or the dir itself for a directory line.
    local dir = vim.fn["netrw#Call"]("NetrwTreePath", vim.w.netrw_treetop)
    path = word:sub(-1) == "/" and dir or dir .. word
  else
    path = vim.b.netrw_curdir .. "/" .. word
  end

  if path:match("^%a+://") then return path end  -- leave remote URLs alone
  return vim.fn.fnamemodify(path, ":p")
end

vim.keymap.set("n", "cc", function()
  local p = cursor_path()
  vim.fn.setreg("+", p)
  vim.notify("Copied: " .. p)
end, { buffer = 0, desc = "Copy absolute path" })

vim.keymap.set("n", "cf", function()
  local p = vim.fn.fnamemodify(cursor_path(), ":.")
  vim.fn.setreg("+", p)
  vim.notify("Copied: " .. p)
end, { buffer = 0, desc = "Copy relative path" })
