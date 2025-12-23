local compat = require("winbender.compat")
local core   = require("winbender.core")
local state  = require("winbender.state")
local utils  = require("winbender.utils")
local win    = require("winbender.win")

local M = {}

local function win_midpoint(winid)
    local top_left_pos = vim.api.nvim_win_get_position(winid)
    local win_size = win.get_win_size(compat.nvim_win_get_config(winid))
    local row, col = top_left_pos[1], top_left_pos[2]
    return {row + win_size['height']/2, col + win_size['width']/2}
end

local function win_to_box(winid)
    local coord = vim.api.nvim_win_get_position(winid)
    local win_size = win.get_win_size(compat.nvim_win_get_config(winid))
    return { x = coord[2], y = coord[1], dx = win_size['width'], dy = win_size['height'] }
end

local function win_similarity(winid1, winid2)
    local box1 = win_to_box(winid1)
    local box2 = win_to_box(winid2)

    -- similarity based on intersection, normalized by box1
    local box1_area = box1.dx * box1.dy
    return 1 - utils.math_area_box_intersection(box1, box2) / box1_area
end

local function get_edge_info(winid)
    local top_left_pos = vim.api.nvim_win_get_position(winid)
    local row = top_left_pos[1]
    local col = top_left_pos[2]
    local win_size = win.get_win_size(compat.nvim_win_get_config(winid))
    local screen = win.get_screen_size()
    local top_offset = 0
    local bot_offset = 0
    local silent = true
    if state.validate_docked_window(winid, silent) then
        -- docked windows do not overlap tabline/statusline
        top_offset = screen.tabline
        bot_offset = screen.statusline
    end

    local edge = {
        top = row == top_offset,
        left = col == 0,
        bottom = row + win_size['height'] == screen['height'] - bot_offset,
        right = col + win_size['width']  == screen['width'],
    }

    return edge
end

local function get_top_level_split(winid)
    local edge = get_edge_info(winid)
    local split = ''
    if utils.count_truthy(edge) == 3 then
        split = not edge.bottom and 'above' or split
        split = not edge.top    and 'below' or split
        split = not edge.right  and 'left'  or split
        split = not edge.left   and 'right' or split
        return split
    end
end

-- local function edge_match(edge1, edge2)
--     for key, val in pairs(edge1) do
--         if val and edge2[key] then
--             return true
--         end
--     end
--     return false
-- end

local function docked_window_list()
    local docked_wins = {}
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, winid in ipairs(wins) do
        local cfg = compat.nvim_win_get_config(winid)
        if not cfg.relative or cfg.relative == "" then
            table.insert(docked_wins, winid)
        end
    end
    return docked_wins
end

function M.find_closest_docked_window(winid)
    local docked_wins = docked_window_list()
    return utils.math_nearest_neighbor(winid, docked_wins, win_similarity)
end

function M.orientation_new_docked_window(winid_float, winid_docked)
    -- Determine orientation based on relative position of midpoints.
    -- Set the origin to the docked window midpoint, and partition the docked
    -- window by its diagonals.
    local midpoint_float  = win_midpoint(winid_float)
    local midpoint_docked = win_midpoint(winid_docked)
    local win_size = win.get_win_size(compat.nvim_win_get_config(winid_docked))
    local slope = win_size['height'] / win_size['width']

    local x = midpoint_float[2] - midpoint_docked[2]
    local y = midpoint_float[1] - midpoint_docked[1]
    y = -y -- reflect y for cartesian coordinate system

    if (y - slope*x) * (y + slope*x) > 0 then
        return 'horizontal'
    else
        return 'vertical'
    end
end

function M.dock_floating_window(winid)
    local cfg = compat.nvim_win_get_config(winid)
    local new_cfg = { width = cfg.width, height = cfg.height }

    local top_level_split = get_top_level_split(winid)
    if top_level_split then
        new_cfg.win = -1
        new_cfg.split = top_level_split
    else
        local closest = M.find_closest_docked_window(winid)
        local current_orientation = win.pixel_orientation(compat.nvim_win_get_config(winid))
        local docked_orientation = M.orientation_new_docked_window(winid, closest)

        -- if current_orientation ~= docked_orientation then
        --     win.pixel_transpose(new_cfg)
        -- end
        new_cfg.win = closest

        local midpoint_float = win_midpoint(winid)
        local midpoint_closest = win_midpoint(closest)
        if docked_orientation == 'horizontal' then
            new_cfg.split = midpoint_float[1] < midpoint_closest[1] and "above" or "below"
        else
            new_cfg.split = midpoint_float[2] < midpoint_closest[2] and "left" or "right"
        end
    end

    local bufnr = vim.api.nvim_win_get_buf(winid)
    local new_winid = vim.api.nvim_open_win(bufnr, false, new_cfg)
    win.copy_options(winid, new_winid)
    vim.api.nvim_win_close(winid, false)
    return new_winid
end

local function count_docked_windows()
    local count = 0
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local silent = true
    for _, winid in ipairs(wins) do
        if state.validate_docked_window(winid, silent) then
            count = count + 1
        end
    end
    return count
end

function M.float_docked_window(winid)
    if count_docked_windows() == 1 then
        vim.notify("WinBender: Cannot float the last docked window", vim.log.levels.WARN)
        return nil
    end
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local pos = vim.api.nvim_win_get_position(winid)
    local cfg = compat.nvim_win_get_config(winid)
    local new_config = {
        relative = "editor",
        width = cfg.width,
        height = cfg.height,
        row = pos[1],
        col = pos[2],
        anchor = "NW",
    }
    local new_winid = vim.api.nvim_open_win(bufnr, false, new_config)
    win.copy_options(winid, new_winid)
    vim.api.nvim_win_close(winid, false)
    return new_winid
end

return M

-- local function make_relative_orientation_config(winid, current_orientation, new_orientation)
--     local cfg = compat.nvim_win_get_config(winid)
-- 
--     local new_cfg = {}
--     if current_orientation ~= new_orientation then
--         -- reflect window across diagonal
--         new_cfg.width = utils.math_round(cfg.height/options.cell_pixel_ratio_w_to_h)
--         new_cfg.height = utils.math_round(cfg.width*options.cell_pixel_ratio_w_to_h)
--     else
--         new_cfg.width = cfg.width
--         new_cfg.height = cfg.height
--     end
--     return new_cfg
-- end
-- 
-- 
-- local function orientation_new_edge_docked_window(winid, edge)
--     local cfg = compat.nvim_win_get_config(winid)
--     if count_truthy(edge) == 1 then
--         if edge.top or edge.bottom then
--             return 'horizontal'
--         else
--             return 'vertical'
--         end
--     else
--         win.pixel_orientation(cfg)
--     end
-- end
-- 
-- local function edge_dock_floating_window_old(winid, edge)
--     local docked_orientation = orientation_new_edge_docked_window(winid, edge)
--     local current_orientation = win.pixel_orientation(compat.nvim_win_get_config(winid))
--     local new_config = make_relative_orientation_config(winid, current_orientation, docked_orientation)
--     new_config.win = -1
-- 
--     local count = count_truthy(edge)
--     if count == 1 then
--         if edge.top then
--             new_config.split = "above"
--         elseif edge.bottom then
--             new_config.split = "below"
--         elseif edge.left then
--             new_config.split = "left"
--         elseif edge.right then
--             new_config.split = "right"
--         end
--     elseif count == 2 then
--         if edge.top and edge.left then
--             new_config.split = (current_orientation == 'horizontal') and "above" or "left"
--         elseif edge.top and edge.right then
--             new_config.split = (current_orientation == 'horizontal') and "above" or "right"
--         elseif edge.bottom and edge.left then
--             new_config.split = (current_orientation == 'horizontal') and "below" or "left"
--         elseif edge.bottom and edge.right then
--             new_config.split = (current_orientation == 'horizontal') and "below" or "right"
--         elseif edge.left and edge.right then
--             -- shouldn't happen
--             new_config.split = (current_orientation == 'horizontal') and "above" or "left"
--         elseif edge.top and edge.bottom then
--             -- shouldn't happen
--             new_config.split = (current_orientation == 'horizontal') and "above" or "left"
--         end
--     else
--         -- shouldn't happen
--         new_config.split = (current_orientation == 'horizontal') and "above" or "left"
--     end
-- 
--     local bufnr = vim.api.nvim_win_get_buf(winid)
--     local new_winid = vim.api.nvim_open_win(bufnr, false, new_config)
--     copy_win_options(winid, new_winid)
--     vim.api.nvim_win_close(winid, false)
--     local next_focus = core.find_next_floating_window('forward')
--     next_focus = next_focus or new_winid
--     core.focus_window(next_focus)
-- end
-- 
-- local function edge_or_corner(edge)
--     local count = count_truthy(edge)
--     if count == 0 then
--         return false
--     elseif count == 1 then
--         return true
--     elseif count == 2 then
--         return not ((edge.top and edge.bottom) or (edge.left and edge.right))
--     else
--         return false
--     end
-- end
-- 
-- local function is_corner(edge)
--     if count_truthy(edge) == 2 then
--         return not ((edge.top and edge.bottom) or (edge.left and edge.right))
--     end
--     return false
-- end
