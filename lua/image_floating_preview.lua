local image_floating_preview = {}

-- detect image https://www.reddit.com/r/neovim/comments/1dsqur4/comment/lb565xy/

-- when a buffer is hidden using :hide (which closes the window without deleting or wiping the buffer), its extmarks will be retained.
-- vim.api.nvim_set_current_buf(bufnr) for current window
-- nvim_win_set_buf({window}, {buffer}) is low level without side effects
-- autocommands (BufLeave, BufEnter); window view (scroll or cursor position); window and buffer local options; syntax highlighting; modeline processing; status line; current working directory ('autochdir'); jumplists

-- due to the limitation(bug) of image.nvim, closing a window (hence hiding a buffer)
-- will not clear the image. so it must use <C-l> and/or image:clear

local test = 1

function image_floating_preview.set_test(t)
    test = t
end

function image_floating_preview.get_test()
    vim.print(test)
    return test
end

-- vim.api.nvim_win_is_valid() expects a window handle, which is a different type of identifier used by Neovim's API.
-- win_handle = vim.api.nvim_get_current_win()
-- win_handle = vim.api.nvim_win_get_number(vim.fn.winnr())
-- win_handle = vim.fn.win_getid(vim.fn.winnr())
-- win_handles = vim.api.nvim_list_wins()

-- Store the window ID and buffer ID
local win_id = nil
local buf_id = nil
local image = nil

local function get_cursor_pos_to_screen()
    local current_win = vim.api.nvim_get_current_win()
    local win_pos = vim.api.nvim_win_get_cursor(current_win)
    local screen_pos = vim.fn.screenpos(current_win, win_pos[1], win_pos[2])

    return screen_pos.curscol, screen_pos.row
end

local function calculate_float_window_pos()
    local tab_width = vim.o.columns
    local tab_height = vim.o.lines

    -- Set up window options
    -- 201 x 54 or 180 x 40
    local threshold = 150
    local width = tab_width > threshold and math.floor(tab_width * 0.48) or tab_width - 6
    local height = math.floor(tab_height * 0.4)

    local cursor_col, cursor_row = get_cursor_pos_to_screen()
    local col, row = 0, 0

    -- calculate col
    if tab_width > threshold then
        if cursor_col < tab_width * 0.5 then
            col = math.floor(tab_width / 2)
        else
            col = 2
        end
    else
        col = math.floor((tab_width - width) / 2)
    end

    -- calculate row
    if tab_width > threshold then
        row = 2
    elseif cursor_row < tab_height * 0.5 then
        row = math.floor(tab_height * 0.5)
    end

    return width, height, col, row
end

local function image_display()
    -- from a file (absolute path)
    image = require('image').from_file(
        -- '/Users/xell/Downloads/WechatIMG5569.jpg',
        '/Users/xell/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes/img/iPhone-14-Pro-highlights.jpg',
        -- '/Users/xell/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes/img/别克胎压.jpeg',
        {
        id = 'img' .. win_id, -- optional, defaults to a random string
        window = win_id, -- vim.fn.win_getid()
        buffer = buf_id, -- vim.fn.bufnr()
        x = 1,
        y = 0,
        -- width = 90,
        -- height = 20000,
    })
    image:render()
    vim.print(win_id .. ':' .. buf_id)
end

local function image_clear()
    -- if image ~= nil then
    --     image:clear()
    -- end
end

-- Function to create the floating window
function image_floating_preview.create_float()
    -- Create a new buffer if it doesn't exist
    if not buf_id or not vim.api.nvim_buf_is_valid(buf_id) then
        buf_id = vim.api.nvim_create_buf(false, true)
        -- Set some buffer options
        vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf_id })
    end

    local width, height, col, row = calculate_float_window_pos()
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = 'rounded',
        focusable = false,
        -- title = {{ 'Title', 'Title' }},
        -- title_pos = 'center',
    }

    -- Create the floating window
    win_id = vim.api.nvim_open_win(buf_id, false, opts)

    -- Set window-local options
    vim.api.nvim_set_option_value('wrap', false, { win = win_id })
    -- vim.api.nvim_set_option_value('number', false, { win = win_id })

    image_display()
    vim.api.nvim_buf_set_lines(buf_id, 0, 1, true, {'aaa', 'bbb'})

    return win_id
end

local float_window_autocmd_id = nil

-- \v view: if valid image url under cursor, view it; else do nothing with warning
-- \f toggle: if not vim.t.floating_preview, warning (win_id??)
--            

-- user flow
-- - identify an image by highlight, then move cursor to the line or the exact column
-- - press keys to open the floating preview window
-- - finish viewing the image
--   - stay on the same position, and close the floating window
--   - move to the above or below to read the context, and close the floating window
-- - want to view the image again while the cursor moves to a new location
-- Function to toggle the floating window
function image_floating_preview.toggle_float()
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.cmd.normal(vim.api.nvim_replace_termcodes('<C-l>', true, true, true))
        vim.api.nvim_win_hide(win_id)
        if float_window_autocmd_id ~= nil then
            vim.api.nvim_del_autocmd(float_window_autocmd_id)
            image_clear()
        end
        win_id = nil
    else
        image_floating_preview.create_float()
        float_window_autocmd_id = vim.api.nvim_create_autocmd('CursorMoved', {
            callback = function ()
                local _, _, new_col, new_row = calculate_float_window_pos()
                ---@diagnostic disable-next-line: param-type-mismatch
                local win_config = vim.api.nvim_win_get_config(win_id)
                local fw_col, fw_row = win_config.col, win_config.row
                if new_col ~= fw_col or new_row ~= fw_row then
                    -- Update the window configuration
                    ---@diagnostic disable-next-line: param-type-mismatch
                    vim.api.nvim_win_set_config(win_id, {
                        relative = win_config.relative,
                        col = new_col,
                        row = new_row,
                    })
                    image_clear()
                    image_display()
                end
            end
        })
    end
end

return image_floating_preview
