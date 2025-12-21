---@diagnostic disable: unused-function, unused-local

-- TODO: screen size calculations may be wrong in some places due to
-- tabline/statusline. Check places that use vim.o.lines and vim.o.cmdheight

local M = {}

local state        = require("winbender.state")
local utils        = require("winbender.utils")
local quick_access = require("winbender.quick_access")
local compat       = require("winbender.compat")
local options      = require("winbender.config").options

local function get_border_size(win_config)
    local border = win_config.border
    local width = 0
    local height = 0
    if border then
        if type(border) == "string" then
            width = 2
            height = 2
        elseif type(border) == "table" then
            height = height + ((border[2] ~= "" and 1) or 0)
            height = height + ((border[6] ~= "" and 1) or 0)
            width  = width  + ((border[4] ~= "" and 1) or 0)
            width  = width  + ((border[8] ~= "" and 1) or 0)
        end
    end
    return width, height
end

local function get_win_size(win_config)
    local width = win_config.width
    local height = win_config.height
    local border_width, border_height = get_border_size(win_config)
    local win_size = {
        width = width + border_width,
        height = height + border_height
    }
    return win_size
end

-- screen size is defined by where floating windows can be placed, it includes
-- the tabline and statusline, but not the command line
function get_screen_size()
    local tabline_height = 0
    if vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1 then
        tabline_height = 1
    elseif vim.o.showtabline == 2 then
        tabline_height = 1
    end

    local statusline_height = 0
    if vim.o.laststatus == 1 and #vim.api.nvim_tabpage_list_wins(0) > 1 then
        statusline_height = 1
    elseif vim.o.laststatus == 2 or vim.o.laststatus == 3 then
        statusline_height = 1
    end

    local screen = {
        height = vim.o.lines - vim.o.cmdheight,
        width = vim.o.columns,
        tabline = tabline_height,
        statusline = statusline_height,
    }
    return screen
end

local function get_pos_bound(win_config, dir)
    local anchor = win_config.anchor
    local win_size = get_win_size(win_config)
    if dir == 'N' then
        return anchor:sub(1,1) == 'N' and 0 or win_size['height']
    elseif dir == 'S' then
        return vim.o.lines - vim.o.cmdheight - (anchor:sub(1,1) == 'S' and 0 or win_size['height'])
    elseif dir == 'W' then
        return anchor:sub(2,2) == 'W' and 0 or win_size['width']
    elseif dir == 'E' then
        return vim.o.columns - (anchor:sub(2,2) == 'E' and 0 or win_size['width'])
    end
end

local function get_max_resize_deltas(win_config)
    local anchor = win_config.anchor
    local row, col = win_config.row, win_config.col
    local win_size = get_win_size(win_config)
    local width_bound  = (anchor:sub(2,2) == 'W') and (vim.o.columns - col - win_size['width']) or (col - win_size['width'])
    local height_bound = (anchor:sub(1,1) == 'N') and (vim.o.lines - vim.o.cmdheight - row - win_size['height']) or (row - win_size['height'])
    return width_bound, height_bound
end

local function reposition_in_bounds(win_config)
    win_config.row = math.max(win_config.row, get_pos_bound(win_config, 'N'))
    win_config.row = math.min(win_config.row, get_pos_bound(win_config, 'S'))
    win_config.col = math.max(win_config.col, get_pos_bound(win_config, 'W'))
    win_config.col = math.min(win_config.col, get_pos_bound(win_config, 'E'))
end

function M.get_current_window()
    local cur_winid = vim.api.nvim_get_current_win()
    if state.validate_floating_window(cur_winid) then
        return cur_winid, 'floating'
    elseif state.validate_docked_window(cur_winid) then
        return cur_winid, 'docked'
    else
        return nil, nil
    end
end

function M.get_current_floating_window()
    local cur_winid = vim.api.nvim_get_current_win()
    if state.validate_floating_window(cur_winid) then
        return cur_winid
    else
        return nil
    end
end

function M.get_current_docked_window()
    local cur_winid = vim.api.nvim_get_current_win()
    if state.validate_docked_window(cur_winid) then
        return cur_winid
    else
        return nil
    end
end

-- x,y is a cartesian coordinate system with y reflected and origin at top-left
function M.reposition_floating_window(winid, x_delta, y_delta)
    local win_config = compat.nvim_win_get_config(winid)
    win_config.col = win_config.col + x_delta
    win_config.row = win_config.row + y_delta
    reposition_in_bounds(win_config)
    compat.nvim_win_set_config(winid, win_config)
end

function M.resize_floating_window(winid, x_delta, y_delta)
    local win_config = compat.nvim_win_get_config(winid)
    local width_bound, height_bound = get_max_resize_deltas(win_config)
    x_delta = math.min(x_delta, width_bound)
    y_delta = math.min(y_delta, height_bound)
    win_config.height = math.max(win_config.height + y_delta, 1)
    win_config.width = math.max(win_config.width + x_delta, 1)
    compat.nvim_win_set_config(winid, win_config)
end

function M.make_square_floating_window(winid)
    local win_config = compat.nvim_win_get_config(winid)
    local ratio = options.cell_pixel_ratio_w_to_h
    local width, height = win_config.width, win_config.height
    local border_width, border_height = get_border_size(win_config)

    local min_dim = math.min(width + border_width, (height + border_height)/ratio)
    win_config.width  = utils.math_round(min_dim - border_width)
    win_config.height = utils.math_round(min_dim*ratio - border_height)
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

local function change_anchor(win_config, anchor)
    local win_size = get_win_size(win_config)

    local old_anchor = win_config.anchor
    local x_old = (old_anchor:sub(2,2) == 'E' and 1) or 0
    local y_old = (old_anchor:sub(1,1) == 'S' and 1) or 0

    local x_new = (anchor:sub(2,2) == 'E' and 1) or 0
    local y_new = (anchor:sub(1,1) == 'S' and 1) or 0

    win_config.anchor = anchor
    win_config.col = win_config.col + (x_new - x_old) * win_size['width']
    win_config.row = win_config.row + (y_new - y_old) * win_size['height']
end

function M.update_anchor(winid, anchor)
    local win_config = compat.nvim_win_get_config(winid)
    change_anchor(win_config, anchor)
    compat.nvim_win_set_config(winid, win_config)
end

function M.get_anchor(winid)
    local win_config = compat.nvim_win_get_config(winid)
    return win_config.anchor
end

function M.init_floating_windows()
    local silent = true
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, winid in ipairs(wins) do
        if state.validate_floating_window(winid, silent) then
            local win_config = compat.nvim_win_get_config(winid)
            reposition_in_bounds(win_config)
            compat.nvim_win_set_config(winid, win_config)
            M.display_info(winid)
        end
    end
end

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

local function win_midpoint(winid)
    local top_left_pos = vim.api.nvim_win_get_position(winid)
    local win_size = get_win_size(compat.nvim_win_get_config(winid))
    local row, col = top_left_pos[1], top_left_pos[2]
    return {row + win_size['height']/2, col + win_size['width']/2}
end

local function win_to_box(winid)
    local win_config = compat.nvim_win_get_config(winid)
    local coord = vim.api.nvim_win_get_position(winid)
    local win_size = get_win_size(compat.nvim_win_get_config(winid))
    return { x = coord[2], y = coord[1], dx = win_size['width'], dy = win_size['height'] }
end

local function win_similarity(winid1, winid2)
    local box1 = win_to_box(winid1)
    local box2 = win_to_box(winid2)

    -- similarity based on intersection, normalized by box1
    local box1_area = box1.dx * box1.dy
    return 1 - utils.math_area_box_intersection(box1, box2) / box1_area
end

local function edge_check(winid)
    local top_left_pos = vim.api.nvim_win_get_position(winid)
    local row = top_left_pos[1]
    local col = top_left_pos[2]
    local win_size = get_win_size(compat.nvim_win_get_config(winid))
    local screen = get_screen_size()
    local top_offset = 0
    local bot_offset = 0
    if state.validate_docked_window(winid) then
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

local function edge_match(edge1, edge2)
    for key, val in pairs(edge1) do
        if val and edge2[key] then
            return true
        end
    end
    return false
end

local function find_closest_docked_window(winid)
    return utils.math_nearest_neighbor(winid, docked_window_list(), win_similarity)
end

local function orientation_new_docked_window(winid_float, winid_docked)
    -- Determine orientation based on relative position of midpoints.
    -- Set the origin to the docked window midpoint, and partition the docked
    -- window by its diagonals.
    local midpoint_float  = win_midpoint(winid_float)
    local midpoint_docked = win_midpoint(winid_docked)
    local win_size = get_win_size(compat.nvim_win_get_config(winid_docked))
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

local function get_win_options(winid)
    local win_opts = {}
    local wo = vim.wo[winid]
    local all_opts = vim.api.nvim_get_all_options_info()
    for opt, metadata in pairs(all_opts) do
        if metadata.global_local == false and metadata.scope == "win" then
            win_opts[opt] = wo[opt]
        end
    end
    return win_opts
end

local function set_win_options(winid, win_opts)
    local wo = vim.wo[winid]
    for opt, val in pairs(win_opts) do
        wo[opt] = val
    end
end

local function copy_win_options(src_win, dst_win)
    set_win_options(dst_win, get_win_options(src_win))
end

local function pixel_orientation(win_config)
    local win_size = get_win_size(win_config)
    return (win_size.width*options.cell_pixel_ratio_w_to_h > win_size.height) and 'horizontal' or 'vertical'
end

local function make_relative_orientation_config(winid, current_orientation, new_orientation)
    local win_config = compat.nvim_win_get_config(winid)

    local new_config = {}
    if current_orientation ~= new_orientation then
        -- reflect window across diagonal
        new_config.width = utils.math_round(win_config.height/options.cell_pixel_ratio_w_to_h)
        new_config.height = utils.math_round(win_config.width*options.cell_pixel_ratio_w_to_h)
    else
        new_config.width = win_config.width
        new_config.height = win_config.height
    end
    return new_config
end

local function count_truthy(tbl)
    local count = 0
    for _, v in pairs(tbl) do
        if v then count = count + 1 end
    end
    return count
end

local function orientation_new_edge_docked_window(winid, edge)
    local win_config = compat.nvim_win_get_config(winid)
    if count_truthy(edge) == 1 then
        if edge.top or edge.bottom then
            return 'horizontal'
        else
            return 'vertical'
        end
    else
        pixel_orientation(win_config)
    end
end

local function edge_dock_floating_window(winid, edge)
    local docked_orientation = orientation_new_edge_docked_window(winid, edge)
    local current_orientation = pixel_orientation(compat.nvim_win_get_config(winid))
    local new_config = make_relative_orientation_config(winid, current_orientation, docked_orientation)
    new_config.win = -1

    local count = count_truthy(edge)
    if count == 1 then
        if edge.top then
            new_config.split = "above"
        elseif edge.bottom then
            new_config.split = "below"
        elseif edge.left then
            new_config.split = "left"
        elseif edge.right then
            new_config.split = "right"
        end
    elseif count == 2 then
        if edge.top and edge.left then
            new_config.split = (current_orientation == 'horizontal') and "above" or "left"
        elseif edge.top and edge.right then
            new_config.split = (current_orientation == 'horizontal') and "above" or "right"
        elseif edge.bottom and edge.left then
            new_config.split = (current_orientation == 'horizontal') and "below" or "left"
        elseif edge.bottom and edge.right then
            new_config.split = (current_orientation == 'horizontal') and "below" or "right"
        elseif edge.left and edge.right then
            -- shouldn't happen
            new_config.split = (current_orientation == 'horizontal') and "above" or "left"
        elseif edge.top and edge.bottom then
            -- shouldn't happen
            new_config.split = (current_orientation == 'horizontal') and "above" or "left"
        end
    else
        -- shouldn't happen
        new_config.split = (current_orientation == 'horizontal') and "above" or "left"
    end

    local bufnr = vim.api.nvim_win_get_buf(winid)
    local new_winid = vim.api.nvim_open_win(bufnr, false, new_config)
    copy_win_options(winid, new_winid)
    vim.api.nvim_win_close(winid, false)
    local next_focus = M.find_next_floating_window('forward')
    next_focus = next_focus or new_winid
    M.focus_window(next_focus)
end

local function edge_or_corner(edge)
    local count = count_truthy(edge)
    if count == 0 then
        return false
    elseif count == 1 then
        return true
    elseif count == 2 then
        return not ((edge.top and edge.bottom) or (edge.left and edge.right))
    else
        return false
    end
end

function M.dock_floating_window(winid)
    -- local edge = edge_check(winid)
    -- if edge_or_corner(edge) then
    --     return edge_dock_floating_window(winid, edge)
    -- end
    local closest = find_closest_docked_window(winid)
    local current_orientation = pixel_orientation(compat.nvim_win_get_config(winid))
    local docked_orientation = orientation_new_docked_window(winid, closest)
    local new_config = make_relative_orientation_config(winid, current_orientation, docked_orientation)
    new_config.win = closest

    local midpoint_float = win_midpoint(winid)
    local midpoint_closest = win_midpoint(closest)
    if docked_orientation == 'horizontal' then
        new_config.split = midpoint_float[1] < midpoint_closest[1] and "above" or "below"
    else
        new_config.split = midpoint_float[2] < midpoint_closest[2] and "left" or "right"
    end

    local bufnr = vim.api.nvim_win_get_buf(winid)
    local new_winid = vim.api.nvim_open_win(bufnr, false, new_config)
    copy_win_options(winid, new_winid)
    vim.api.nvim_win_close(winid, false)
    local next_focus = M.find_next_floating_window('forward')
    next_focus = next_focus or new_winid
    M.focus_window(next_focus)
end

function M.float_docked_window(winid)
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local pos = vim.api.nvim_win_get_position(winid)
    local win_config = compat.nvim_win_get_config(winid)
    local new_config = {
        relative = "editor",
        width = win_config.width,
        height = win_config.height,
        row = pos[1],
        col = pos[2],
        anchor = "NW",
    }
    local new_winid = vim.api.nvim_open_win(bufnr, false, new_config)
    copy_win_options(winid, new_winid)
    M.focus_window(new_winid)
    vim.api.nvim_win_close(winid, false)
end

function M.display_info(winid)
    local qa_index = quick_access.get_index(winid)
    if qa_index then
        quick_access.display(winid, qa_index)
    end

    local win_config = compat.nvim_win_get_config(winid)
    local footer = state.get_config(winid) and state.get_config(winid).footer or ""
    local label = ""
    -- label = "[" .. winid .. "]"

    local winid_closest = find_closest_docked_window(winid)
    local orientation = orientation_new_docked_window(winid, winid_closest)
    label = "[" .. winid_closest .. "]"
    label = label .. "[" .. orientation:sub(1,1) .. "]"
    label = label .. "[" .. win_config.anchor .. "]"
    label = label .. "(" .. win_config.row .. "," .. win_config.col .. ")"
    win_config.footer = utils.prepend_label(footer, label)
    compat.nvim_win_set_config(winid, win_config)
end

return M
