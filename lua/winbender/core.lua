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
    return width + border_width, height + border_height
end

local function get_pos_bound(win_config, dir)
    local anchor = win_config.anchor
    local width, height = get_win_size(win_config)
    if dir == 'N' then
        return anchor:sub(1,1) == 'N' and 0 or height
    elseif dir == 'S' then
        return vim.o.lines - vim.o.cmdheight - (anchor:sub(1,1) == 'S' and 0 or height)
    elseif dir == 'W' then
        return anchor:sub(2,2) == 'W' and 0 or width
    elseif dir == 'E' then
        return vim.o.columns - (anchor:sub(2,2) == 'E' and 0 or width)
    end
end

local function get_max_resize_deltas(win_config)
    local anchor = win_config.anchor
    local row, col = win_config.row, win_config.col
    local width, height = get_win_size(win_config)
    local width_bound  = (anchor:sub(2,2) == 'W') and (vim.o.columns - col - width) or (col - width)
    local height_bound = (anchor:sub(1,1) == 'N') and (vim.o.lines - vim.o.cmdheight - row - height) or (row - height)
    return width_bound, height_bound
end

local function reposition_in_bounds(win_config)
    win_config.row = math.max(win_config.row, get_pos_bound(win_config, 'N'))
    win_config.row = math.min(win_config.row, get_pos_bound(win_config, 'S'))
    win_config.col = math.max(win_config.col, get_pos_bound(win_config, 'W'))
    win_config.col = math.min(win_config.col, get_pos_bound(win_config, 'E'))
end

function M.get_current_floating_window()
    local cur_winid = vim.api.nvim_get_current_win()
    if state.validate_floating_window(cur_winid) then
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

function M.update_anchor(winid, anchor)
    local win_config = compat.nvim_win_get_config(winid)
    local width, height = get_win_size(win_config)

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
    local width, height = get_win_size(compat.nvim_win_get_config(winid))
    local row, col = top_left_pos[1], top_left_pos[2]
    return {row + height/2, col + width/2}
end

local function win_to_box(winid)
    local win_config = compat.nvim_win_get_config(winid)
    local coord = vim.api.nvim_win_get_position(winid)
    local width, height = get_win_size(win_config)
    return { x = coord[2], y = coord[1], dx = width, dy = height }
end

local function win_similarity(winid1, winid2)
    local box1 = win_to_box(winid1)
    local box2 = win_to_box(winid2)

    -- similarity based on intersection, normalized by box1
    local box1_area = box1.dx * box1.dy
    return 1 - utils.math_area_box_intersection(box1, box2) / box1_area
end

local function find_closest_docked_window(winid)
    local docked_wins = docked_window_list()
    return utils.math_nearest_neighbor(winid, docked_wins, win_similarity)
end

local function orientation_new_docked_window(winid_float, winid_docked)
    -- Determine orientation based on relative position of midpoints
    -- set the origin to the docked window midpoint and partition docked window
    -- by its diagonals
    local midpoint_float  = win_midpoint(winid_float)
    local midpoint_docked = win_midpoint(winid_docked)
    local width, height = get_win_size(compat.nvim_win_get_config(winid_docked))
    local slope = height / width

    local x = midpoint_float[2] - midpoint_docked[2]
    local y = midpoint_float[1] - midpoint_docked[1]
    y = -y -- reflect y for cartesian coordinate system

    if (y - slope*x) * (y + slope*x) > 0 then
        return 'horizontal'
    else
        return 'vertical'
    end
end

local function copy_win_options(src_win, dst_win)
    local win_opts = {
        "number", "relativenumber", "cursorline", "cursorcolumn", "colorcolumn",
        "foldcolumn", "foldenable", "foldlevel", "foldmethod", "linebreak",
        "list", "listchars", "scrolloff", "sidescrolloff", "signcolumn",
        "spell", "wrap", "winhl", "winblend", "statuscolumn"
    }
    for _, opt in ipairs(win_opts) do
        local ok, val = pcall(vim.api.nvim_get_option_value, opt, {win = src_win})
        if ok then
            vim.api.nvim_set_option_value(opt, val, {win = dst_win})
        end
    end
end

function M.dock_floating_window(winid)
    local closest = find_closest_docked_window(winid)

    local midpoint_float = win_midpoint(winid)
    local midpoint_closest = win_midpoint(closest)

    local bufnr = vim.api.nvim_win_get_buf(winid)
    local width, height = get_win_size(compat.nvim_win_get_config(winid))
    local new_config = {
        width = width,
        height = height,
        win = closest
    }
    local type_as_floating = (width*options.cell_pixel_ratio_w_to_h > height) and 'horizontal' or 'vertical'
    local type_as_docked = orientation_new_docked_window(winid, closest)
    if type_as_floating ~= type_as_docked then
        -- reflect window across diagonal
        new_config.width = utils.math_round(height/options.cell_pixel_ratio_w_to_h)
        new_config.height = utils.math_round(width*options.cell_pixel_ratio_w_to_h)
    end
    if type_as_docked == 'horizontal' then
        new_config.split = midpoint_float[1] < midpoint_closest[1] and "above" or "below"
    else
        new_config.split = midpoint_float[2] < midpoint_closest[2] and "left" or "right"
        new_config.vertical = true
    end
    local new_winid = vim.api.nvim_open_win(bufnr, false, new_config)
    copy_win_options(winid, new_winid)
    M.focus_window(M.find_next_floating_window('forward'))
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
    -- label = label .. "[" .. win_config.anchor .. "]"
    label = label .. "(" .. win_config.row .. "," .. win_config.col .. ")"
    win_config.footer = utils.prepend_label(footer, label)
    compat.nvim_win_set_config(winid, win_config)
end

return M
