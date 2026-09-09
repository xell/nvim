vim.cmd [[highlight clear]]
vim.cmd [[syntax reset]]
vim.g.colors_name = 'xell_apple_light'

local highlights = {
    Normal = { fg = '#001122', bg = '#f3f3e7', },
    Statement = { fg = '#ff1122', bg = 'bg', sp = '#03283a', underdashed = true, italic = true, },
}

for group_name, group_values in pairs(highlights) do
    vim.api.nvim_set_hl(0, tostring(group_name), group_values)
end

-- vim.api.nvim_set_hl(0, 'Normal', {
--     fg = '#001122',
--     bg = '#f3f3e7',
-- })
--
-- vim.api.nvim_set_hl(0, 'Statement', {
--     fg = '#ff1122',
--     bg = '#f3f3e7',
--     sp = '#03283a',
--     underdashed = true,
--     italic = true,
-- })

-- fg bg sp
-- blend: integer between 0 and 100
-- bold standout italic
-- underline undercurl underdouble underdotted underdashed
-- strikethrough
-- reverse
-- nocombine
-- link: name of another highlight group to link to, see `:hi-link`.
-- force: if true force update the highlight group when it exists.
