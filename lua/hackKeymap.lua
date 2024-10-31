-- vim script 中的 cursorMove 不支持 select 参数
-- 所以这里通过lua脚本，同样调用 cursorMove，但是可以传递 select 参数
-- !但仍然存在问题：
-- 1. cursorMove 会破坏 visual line 模式，所以 visual line 模式只会保留一次，然后就会变成 visual 模式
-- 2. 文档中存在有中文时，移动过程中，col 会出现偏移，导致选区不准确
-- local vim_api = vim.api
-- 行内移动
local function moveInLine(d)
    require('vscode-neovim').action('cursorMove', {
        args = {{
            to = d == 'end' and 'wrappedLineEnd' or 'wrappedLineStart',
            by = 'wrappedLine',
            -- by = 'line',
            -- value = vim.v.count1,
            -- value = vim.v.count,
            value = 0,
            select = true
        }}
    })
    return '<Ignore>'
end

-- 行间移动
local function moveLine(d)
    -- local current_mode = vim.api.nvim_get_mode().mode
    require('vscode-neovim').action('cursorMove', {
        args = {{
            to = d == 'j' and 'down' or 'up',
            by = 'wrappedLine',
            -- by = 'line',
            value = vim.v.count1,
            -- value = vim.v.count,
            select = true
        }}
        -- not work
        -- callback = function()
        --     -- cb()
        --     if current_mode == 'V' then
        --         vim.schedule(function()
        --             vim_api.nvim_input('V')
        --         end)
        --         -- vim_api.nvim_input('V')
        --         -- vim_api.nvim_feedkeys('V', 'x', false)
        --         -- vim_api.nvim_feedkeys('V', 'v', true)
        --         -- debug.debug()
        --         -- return 'V'
        --     end
        --     -- return '<Ignore>'
        -- end
    })
    return '<Ignore>'
end

local function move(d)
    return function()
        -- 获取当前编辑模式
        local current_mode = vim.api.nvim_get_mode().mode
        -- Only works in charwise visual and visual line mode
        -- if current_mode ~= 'v' and current_mode ~= 'V' then
        --     return 'g' .. d
        -- end

        -- 因为 moveCursor 会破坏 visual line 模式，所以 visual line 模式只会保留一次，然后就会变成 visual 模式
        -- 因此这段逻辑在一次选区的动作中只会执行一次
        if current_mode == 'V' then
            moveLine(d)
            if d == 'j' then
                moveInLine('end')
            else
                moveInLine('start')
            end
        else
            -- 获取当前选区的标记的位置（<）
            local start_pos = vim.api.nvim_buf_get_mark(0, "<")
            local end_pos = vim.api.nvim_buf_get_mark(0, ">")
            -- 提取列号 和 行号
            local start_line = start_pos[1]
            local start_col = start_pos[2]
            local end_line = end_pos[1]
            local end_col = end_pos[2]

            -- 获取光标当前列号
            local cursor_col = vim.fn.col('.')
            -- 获取当前行最大列号
            local line_end_col = vim.fn.col('$')
            -- 获取选区的结束行文本内容
            local selected_end_line_text = vim.fn.getline(end_line)
            -- 获取当前光标位置的行号和列号
            -- 参数 0 表示当前窗口
            local cursor = vim.api.nvim_win_get_cursor(0)
            -- 提取行号
            local current_line = cursor[1]

            -- 如果选区只有一行，而且整行内容都已被选中
            -- 那么在执行完行间移动后，就将新行的光标移动到行首或行尾
            -- 实现模拟 visual line 的效果
            -- 最后直接返回，不再执行下面的逻辑
            if start_col == 0 and end_col + 1 == #selected_end_line_text and start_line == end_line then
                moveLine(d)
                if d == 'j' then
                    moveInLine('end')
                else
                    moveInLine('start')
                end
                return '<Ignore>'
            end

            -- 其他情况
            moveLine(d)

            -- k方向，向上移动
            -- 如果选区的结束行行内容被全选中，那么在执行完行间移动后，就将新行的光标移动到行尾
            -- 实现模拟 visual line 的效果
            if end_col + 1 == #selected_end_line_text and current_line < end_line then
                moveInLine('start')
                -- return 'V'
            end
            -- j方向，向下移动
            -- 如果选区的开始行行内容被全选中，那么在执行完行间移动后，就将新行的光标移动到行首
            -- 实现模拟 visual line 的效果
            if start_col == 0 and current_line > start_line then
                moveInLine('end')
                -- return 'V'
            end
        end
        return '<Ignore>'
    end
end

vim.keymap.set('v', 'gj', move('j'), {
    expr = true,
    noremap = true,
    silent = true
})
vim.keymap.set('v', 'gk', move('k'), {
    expr = true,
    noremap = true,
    silent = true
})

local function moveCursor(d)
    return function()
        -- 当 v.count 为 0 时，表示没有使用数字修饰符，此时可以执行自定义的移动
        -- 否则，执行原生的移动，如 10j
        if (vim.v.count == 0 and vim.fn.reg_recording() == '' and vim.fn.reg_executing() == '') then
            return 'g' .. d
        else
            return d
        end
    end
end

-- 依赖于 gj 和 gk 的定义，所以要放在 gj 和 gk 的后面
vim.keymap.set('', 'k', moveCursor('k'), {
    expr = true,
    remap = true,
    silent = true
})
vim.keymap.set('', 'j', moveCursor('j'), {
    expr = true,
    remap = true,
    silent = true
})

vim.g.testfoldkey = 1
