vim.cmd [[highlight clear]]
vim.cmd [[syntax reset]]
vim.g.colors_name = 'xell_apple_dark'

local c = {}

c.black_full = '#000000'
c.black = '#121212' -- safari reader
c.black2 = '#1e1e1e' -- notes
c.black3 = '#262627' -- notes sidebar
c.black_light = '#323233' -- safari reader

c.gray_dark = '#4a4a4d' -- safari reader
c.gray = '#a2a2a7'
c.gray_light = '#b0b0b0' -- safari reader

c.white = '#d7d7d8' -- safari reader notes #dcdcdc
c.white_light = '#e6e6e6' -- safari reader light
c.white_full = '#ffffff'

c.red = '#ff4f44'
c.orange = '#ffa914'
c.yellow = '#ffe014'
c.green = '#3ce155'
c.teal = '#44d4ed'
c.blue = '#148eff'
c.purple = '#cc65ff'
c.pink = '#ff4169'
c.brown = '#b69872'

local editor = {
    Normal = { fg = c.white, bg = c.black, },
    Comment = { fg = c.gray, italic = true, },

    Constant = { fg = c.green, },
    String = { link = 'Constant', },
    Character = { link = 'Constant', },
    Number = { fg = c.teal, },
    Boolean = { link = 'Number', },
    Float = { link = 'Number', },

    Identifier = { fg = c.orange, },
    Function = { fg = c.brown, bold = true, },

    Statement = { fg = c.yellow, },
    Conditional = { link = 'Statement', },
    Repeat = { link = 'Statement', },
    Label = { link = 'Statement', },
    Operator = { link = 'Statement', },
    Keyword = { link = 'Statement', },
    Exception = { link = 'Statement', },

    PreProc = { fg = c.brown, },
    Include = { link = 'PreProc', },
    Define = { link = 'PreProc', },
    Macro = { link = 'PreProc', },
    PreCondit = { link = 'PreProc', },

    Type = { fg = c.purple, },
}

local function set_hl(highlights)
    for group_name, group_values in pairs(highlights) do
        vim.api.nvim_set_hl(0, tostring(group_name), group_values)
    end
end

set_hl(editor)

-- Type		int, long, char, etc.
-- StorageClass	static, register, volatile, etc.
-- Structure	struct, union, enum, etc.
-- Typedef		a typedef
-- 
-- Special		any special symbol
-- SpecialChar	special character in a constant
-- Tag		you can use CTRL-] on this
-- Delimiter	character that needs attention
-- SpecialComment	special things inside a comment
-- Debug		debugging statements
-- 
-- Underlined	text that stands out, HTML links
-- 
-- Ignore		left blank, hidden  |hl-Ignore|
-- 
-- Error		any erroneous construct
-- 
-- Todo		anything that needs extra attention; mostly the keywords TODO FIXME and XXX
-- 
-- Added		added line in a diff
-- Changed		changed line in a diff
-- Removed		removed line in a diff


-- fg bg sp
-- blend: integer between 0 and 100
-- bold standout italic strikethrough
-- underline undercurl underdouble underdotted underdashed
-- reverse nocombine
-- link force
