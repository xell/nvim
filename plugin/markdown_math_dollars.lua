-- Pandoc's tex_math_dollars rule that a query alone can't express: the
-- closing $ of inline math must not be followed by a digit, so prose like
-- "$5,000–$10,000" stays currency. Used by queries/markdown_inline/injections.scm.
vim.treesitter.query.add_predicate('dollar-math?', function(match, _, source, pred)
  local nodes = match[pred[2]]
  local node = nodes and nodes[#nodes]
  if not node then return true end
  local _, _, er, ec = node:range()
  local line
  if type(source) == 'number' then
    line = vim.api.nvim_buf_get_lines(source, er, er + 1, false)[1]
  else
    line = vim.split(source, '\n', { plain = true })[er + 1]
  end
  return not (line and line:sub(ec + 1, ec + 1):match('%d'))
end, { force = true })
