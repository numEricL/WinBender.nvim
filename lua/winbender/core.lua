-- TODO: screen size calculations may be wrong in some places due to
-- tabline/statusline. Check places that use vim.o.lines and vim.o.cmdheight

local compat  = require("winbender.compat")
local options = require("winbender.config").options
local state   = require("winbender.state")
local utils   = require("winbender.utils")
local win     = require("winbender.win")

local M = {}

function M.focus_window(winid, silent)
    if state.validate_window(winid, silent) then
        vim.api.nvim_set_current_win(winid)
    elseif not silent then
        vim.notify("WinBender: Cannot focus invalid window " .. tostring(winid), vim.log.levels.WARN)
    end
end

function M.get_current_window()
    local cur_winid = vim.api.nvim_get_current_win()
    local silent = true
    if state.validate_floating_window(cur_winid, silent) then
        return cur_winid, 'floating'
    elseif state.validate_docked_window(cur_winid, silent) then
        return cur_winid, 'docked'
    else
        return nil, nil
    end
end

function M.get_current_docked_window()
    local cur_winid = vim.api.nvim_get_current_win()
    local silent = true
    if state.validate_docked_window(cur_winid, silent) then
        return cur_winid
    else
        return nil
    end
end

function M.get_current_floating_window()
    local cur_winid = vim.api.nvim_get_current_win()
    local silent = true
    if state.validate_floating_window(cur_winid, silent) then
        return cur_winid
    else
        return nil
    end
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

function M.reposition_in_bounds(winid)
    local cfg = compat.nvim_win_get_config(winid)
    win.reposition_in_bounds(cfg)
    compat.nvim_win_set_config(winid, cfg)
end

-- x,y is a cartesian coordinate system with y reflected and origin at top-left
function M.reposition_floating_window(winid, x_delta, y_delta)
    local cfg = compat.nvim_win_get_config(winid)
    cfg.col = cfg.col + x_delta
    cfg.row = cfg.row + y_delta
    win.reposition_in_bounds(cfg)
    compat.nvim_win_set_config(winid, cfg)
end

function M.resize_floating_window(winid, x_delta, y_delta)
    local cfg = compat.nvim_win_get_config(winid)
    local width_bound, height_bound = win.get_max_resize_deltas(cfg)
    x_delta = math.min(x_delta, width_bound)
    y_delta = math.min(y_delta, height_bound)
    cfg.height = math.max(cfg.height + y_delta, 1)
    cfg.width = math.max(cfg.width + x_delta, 1)
    compat.nvim_win_set_config(winid, cfg)
end

function M.make_square_floating_window(winid)
    local cfg = compat.nvim_win_get_config(winid)
    local ratio = options.cell_pixel_ratio_w_to_h
    local width, height = cfg.width, cfg.height
    local border_width, border_height = win.get_border_size(cfg)

    local min_dim = math.min(width + border_width, (height + border_height)/ratio)
    width  = utils.math_round(min_dim - border_width)
    height = utils.math_round(min_dim*ratio - border_height)
    cfg.width = math.max(width, 1)
    cfg.height = math.max(height, 1)
    compat.nvim_win_set_config(winid, cfg)
end

function M.update_anchor(winid, anchor)
    local cfg = compat.nvim_win_get_config(winid)
    win.set_anchor(cfg, anchor)
    compat.nvim_win_set_config(winid, cfg)
end

return M
