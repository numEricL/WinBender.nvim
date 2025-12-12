local M = {}

local state  = require("winbender.state")

local function validate_floating_window(winid)
    if not vim.api.nvim_win_is_valid(winid) then
        vim.notify("Invalid window id: " .. tostring(winid), vim.log.levels.ERROR)
        return false
    end
    local config = vim.api.nvim_win_get_config(winid)
    if not config.relative or config.relative == "" then
        vim.notify("Window " .. winid .. " is not a floating window", vim.log.levels.ERROR)
        return false
    end
    return true
end

function M.reposition_floating_window(winid, x_delta, y_delta)
    if not validate_floating_window(winid) then
        return
    end
    state.save_config(winid)
    local config = vim.api.nvim_win_get_config(winid)
    config.col = config.col + x_delta
    config.row = config.row + y_delta
    vim.api.nvim_win_set_config(winid, config)
end

function M.resize_floating_window(winid, x_delta, y_delta)
    if not validate_floating_window(winid) then
        return
    end
    state.save_config(winid)

    local config = vim.api.nvim_win_get_config(winid)
    config.height = math.max(config.height + y_delta, 1)
    config.width = math.max(config.width + x_delta, 1)
    vim.api.nvim_win_set_config(winid, config)
end

local function find_next_floating_window()
    local cur_winid = vim.api.nvim_get_current_win()
    local wins = vim.api.nvim_tabpage_list_wins(0)

    -- Find the index of the current window
    local cur_idx
    for i, winid in ipairs(wins) do
        if winid == cur_winid then
            cur_idx = i
            break
        end
    end

    local n = #wins
    for i = 1, n do
        -- wrap with modulo arithmetic using representatives 1 to n
        local idx = ((cur_idx - i - 1) % n) + 1
        local winid = wins[idx]
        local config = vim.api.nvim_win_get_config(winid)
        if config.relative ~= "" then
            return winid
        end
    end

    return nil
end

-- checks the current window first, then other windows in descending order by winid
function M.find_floating_window()
    local cur_win = vim.api.nvim_get_current_win()
    local config = vim.api.nvim_win_get_config(cur_win)
    if config.relative ~= "" then
        return cur_win
    else
        return find_next_floating_window()
    end
end

function M.focus_window(winid)
    if not validate_floating_window(winid) then
        return
    end
    state.winid = winid
    vim.api.nvim_set_current_win(winid)
end

function M.focus_next_floating_window()
    local winid = find_next_floating_window()
    if winid then
        focus_window(winid)
    else
        vim.notify("No floating windows found", vim.log.levels.INFO)
    end
end

local function get_floating_window_size(config)
    local width = config.width
    local height = config.height
    local border = config.border
    local border_width = 0
    local border_height = 0

    if border then
        if type(border) == "string" then
            border_width = 2
            border_height = 2
        elseif type(border) == "table" then
            border_height = border_height + ((border[2] ~= "" and 1) or 0)
            border_height = border_height + ((border[6] ~= "" and 1) or 0)
            border_width = border_width + ((border[4] ~= "" and 1) or 0)
            border_width = border_width + ((border[8] ~= "" and 1) or 0)
        end
    end

    return width + border_width, height + border_height
end

function M.update_anchor(winid, anchor)
    if not validate_floating_window(winid) then
        return
    end
    local config = vim.api.nvim_win_get_config(winid)
    local width, height = get_floating_window_size(config)

    local old_anchor = config.anchor
    local x_old = (old_anchor:sub(2,2) == 'E' and 1) or 0
    local y_old = (old_anchor:sub(1,1) == 'S' and 1) or 0

    local x_new = (anchor:sub(2,2) == 'E' and 1) or 0
    local y_new = (anchor:sub(1,1) == 'S' and 1) or 0

    config.anchor = anchor
    config.col = config.col + (x_new - x_old) * width
    config.row = config.row + (y_new - y_old) * height
    vim.api.nvim_win_set_config(winid, config)
end

function create_floaters()
    local buf = vim.api.nvim_create_buf(false, true)
    local opts = {
        relative = 'editor',
        width = 40,
        height = 10,
        row = 5,
        col = 10,
        style = 'minimal'
    }
    local win = vim.api.nvim_open_win(buf, true, opts)
    opts.border = 'single'
    opts.relative = 'cursor'
    local win = vim.api.nvim_open_win(buf, true, opts)
end

return M
