local vol = vim.opt_local
vol.tabstop = 2
vol.shiftwidth = 2
vol.concealcursor = 'nc'
vol.conceallevel = 2
vol.breakindent = true
vol.linebreak = true
vol.formatoptions = 'mBlrocq'
vol.comments:append(':-')
vol.comments:remove('fb:-')
vol.formatlistpat = '^\\s*\\d\\+\\.\\s\\+\\|^\\s*[-*+]\\s\\+\\|^\\[^\\ze[^\\]]\\+\\]:\\&^.\\{4\\}'
vol.breakindentopt = "list:-2"
-- vol.breakindentopt = "shift:2"

local vks = vim.keymap.set
vks('v', '<Leader>b', [[<ESC>`>a**<ESC>`<i**<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>i', [[<ESC>`>a*<ESC>`<i*<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>t', [[<ESC>`>a}<ESC>`<i{=<ESC>`>ll]], { buffer = true })

-- fold {{{
-- TODO
vol.foldminlines = 1
vol.foldmethod = 'expr'

-- folding https://github.com/kevinhwang91/nvim-ufo
-- https://www.reddit.com/r/neovim/comments/10q2mjq/i_dont_really_get_folding/
-- refer to https://github.com/masukomi/vim-markdown-folding/blob/master/after/ftplugin/markdown/folding.vim

-- https://www.reddit.com/r/neovim/comments/193n9fx/how_to_reference_local_function_for_foldexpr/
-- ?? vim.opt.foldexpr = [[luaevel('MKDFold')()]]
-- or
-- --- e.g. config/folding.lua
-- local M = {}
-- function M.get_my_foldlevel() ... end
-- return M
-- vim.o.foldexpr = 'v:lua.require("config.folding").get_my_foldlevel()'
vol.foldexpr = 'v:lua.MKDFold()'
vol.foldtext = 'v:lua.MKDfoldText()'

-- 1->1, 3->2, 5->3
-- blank line is 0
_G.MKDFold = function ()
    local line = vim.fn.getline(vim.v.lnum)
    local level = string.find(line, '[^ ]')
    if level >= 1 then
        if string.find(line, '^ *-') then
          return ('>' .. ((level + 1) / 2))
        else
          -- this will treat mutliline item as a fold
          -- return ('' .. ((level - 1) / 2))
          -- return ('>' .. (((level - 1) / 2)) - 1)
          -- this will NOT treat mutliline item as a fold FIXME
          -- return '-1'
        end
    end
    return '='
end

_G.MKDfoldText = function ()
    local fs = vim.v.foldstart
    local fs_next = fs + 1
    local line = vim.fn.getline(fs)
    -- line = string.sub(line, 1, 50)
    -- ⊙ ○ ● ✪ ⊕ ⌾ ⊗ ⊘ ⊚
    --         󰺕 󱎕 󰧞 󰧟 󰅙      󰻃󰝦
    --   󰺕 󰻃
    if vim.fn.foldlevel(fs) < vim.fn.foldlevel(fs_next) then
      -- it's a real fold with sub items underneath
      line = string.gsub(line, '-', '●', 1)
      -- line = string.gsub(line, '-', '', 1)
    else
      -- it's only a lone, wrapped line fold by 'foldminlines'
      -- ﹥﹥
      line = string.gsub(line, '-', '◇', 1)
      -- line = string.gsub(line, '-', '⋗', 1)
      -- line = string.gsub(line, '-', '', 1)
      -- line = string.gsub(line, '-', '󰧞', 1)
      -- line = string.gsub(line, '-', '', 1)
      -- line = string.gsub(line, '-', '⊙', 1)
      -- line = string.gsub(line, '-', '󰺕', 1)
      -- line = string.gsub(line, '-', '', 1)
    end
    return line
end
-- }}}
