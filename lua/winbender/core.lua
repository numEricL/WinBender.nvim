local M = {}

local state        = require("winbender.state")
local utils        = require("winbender.utils")
local quick_access = require("winbender.quick_access")
local compat       = require("winbender.compat")

function M.get_current_floating_window()
    local cur_winid = vim.api.nvim_get_current_win()
    if state.validate_floating_window(cur_winid) then
        return cur_winid
    else
        return nil
    end
end

function M.reposition_floating_window(winid, x_delta, y_delta)
    local win_config = compat.nvim_win_get_config(winid)
    win_config.col = win_config.col + x_delta
    win_config.row = win_config.row + y_delta
    compat.nvim_win_set_config(winid, win_config)
end

function M.resize_floating_window(winid, x_delta, y_delta)
    local win_config = compat.nvim_win_get_config(winid)
    win_config.height = math.max(win_config.height + y_delta, 1)
    win_config.width = math.max(win_config.width + x_delta, 1)
    compat.nvim_win_set_config(winid, win_config)
end

function M.find_next_floating_window(dir, count)
    local count1 = count or 1

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

    -- wrap with modulo arithmetic using representatives 1 to n
    local function wrap_index(index, n)
        return ((index - 1) % n) + 1
    end

    local silent = true
    local counter = 0
    local i = 1
    while counter < count1 do
        local idx = dir == 'forward' and (cur_idx + i) or (cur_idx - i)
        idx = wrap_index(idx, #wins)
        local winid = wins[idx]
        local win_config = compat.nvim_win_get_config(winid)
        if state.validate_floating_window(winid, silent) then
            counter = counter + 1
            if counter == count1 then
                return winid
            end
        end
        if counter == 0 and i >= #wins then
            return nil -- no floating windows found
        end
        i = i + 1
    end
end

-- checks the current window first, then other windows in descending order by winid
function M.find_floating_window(dir)
    local winid = vim.api.nvim_get_current_win()
    local silent = true
    if state.validate_floating_window(winid, silent) then
        return winid
    else
        return M.find_next_floating_window(dir)
    end
end

function M.focus_window(winid, silent)
    if winid and vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_set_current_win(winid)
    elseif not silent then
        vim.notify("WinBender: Cannot focus invalid window " .. tostring(winid), vim.log.levels.WARN)
    end
end

local function get_floating_window_size(win_config)
    local width = win_config.width
    local height = win_config.height
    local border = win_config.border
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
    local win_config = compat.nvim_win_get_config(winid)
    local width, height = get_floating_window_size(win_config)

    local old_anchor = win_config.anchor
    local x_old = (old_anchor:sub(2,2) == 'E' and 1) or 0
    local y_old = (old_anchor:sub(1,1) == 'S' and 1) or 0

    local x_new = (anchor:sub(2,2) == 'E' and 1) or 0
    local y_new = (anchor:sub(1,1) == 'S' and 1) or 0

    win_config.anchor = anchor
    win_config.col = win_config.col + (x_new - x_old) * width
    win_config.row = win_config.row + (y_new - y_old) * height
    compat.nvim_win_set_config(winid, win_config)
end

function M.get_anchor(winid)
    local win_config = compat.nvim_win_get_config(winid)
    return win_config.anchor
end

function M.display_info(winid)
    local qa_index = quick_access.get_index(winid)
    if qa_index then
        quick_access.display(winid, qa_index)
    end

    local win_config = compat.nvim_win_get_config(winid)
    local footer = state.get_config(winid).footer
    local label = "[" .. winid .. "]"
    local label = label .. "[" .. win_config.anchor .. "]"
    local label = label .. "(" .. win_config.row .. "," .. win_config.col .. ")"
    win_config.footer = utils.prepend_title(footer, label)
    compat.nvim_win_set_config(winid, win_config)
end

function M.init_display_info()
    local silent = true
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, winid in ipairs(wins) do
        local win_config = compat.nvim_win_get_config(winid)
        if state.validate_floating_window(winid, silent) then
            M.display_info(winid)
        end
    end
end

return M
