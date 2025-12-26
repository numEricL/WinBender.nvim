local M = {}

local options = require("winbender.config").options
local utils   = require("winbender.utils")

-- screen size is defined by where floating windows can be placed, it includes
-- the tabline and statusline, but not the command line
function M.get_screen_size()
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

function M.get_border_size(win_config)
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

function M.get_win_size(win_config)
    local width = win_config.width
    local height = win_config.height
    local border_width, border_height = M.get_border_size(win_config)
    local win_size = {
        width = width + border_width,
        height = height + border_height
    }
    return win_size
end

local function get_max_resize_deltas(win_config)
    local anchor = win_config.anchor
    local row, col = win_config.row, win_config.col
    local win_size = M.get_win_size(win_config)
    local width_bound  = (anchor:sub(2,2) == 'W') and (vim.o.columns - col - win_size['width']) or (col - win_size['width'])
    local height_bound = (anchor:sub(1,1) == 'N') and (vim.o.lines - vim.o.cmdheight - row - win_size['height']) or (row - win_size['height'])
    return width_bound, height_bound
end

local function get_pos_bound(win_config, dir)
    local anchor = win_config.anchor
    local win_size = M.get_win_size(win_config)
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

function M.resize_anchored_floating_window(win_config, x_delta, y_delta)
    local width_bound, height_bound = get_max_resize_deltas(win_config)
    x_delta = math.min(x_delta, width_bound)
    y_delta = math.min(y_delta, height_bound)
    win_config.height = math.max(win_config.height + y_delta, 1)
    win_config.width = math.max(win_config.width + x_delta, 1)
end

function M.reposition_in_bounds(win_config)
    win_config.row = math.max(win_config.row, get_pos_bound(win_config, 'N'))
    win_config.row = math.min(win_config.row, get_pos_bound(win_config, 'S'))
    win_config.col = math.max(win_config.col, get_pos_bound(win_config, 'W'))
    win_config.col = math.min(win_config.col, get_pos_bound(win_config, 'E'))
end

function M.set_anchor(win_config, anchor)
    local win_size = M.get_win_size(win_config)

    local old_anchor = win_config.anchor
    local x_old = (old_anchor:sub(2,2) == 'E' and 1) or 0
    local y_old = (old_anchor:sub(1,1) == 'S' and 1) or 0

    local x_new = (anchor:sub(2,2) == 'E' and 1) or 0
    local y_new = (anchor:sub(1,1) == 'S' and 1) or 0

    win_config.anchor = anchor
    win_config.col = win_config.col + (x_new - x_old) * win_size['width']
    win_config.row = win_config.row + (y_new - y_old) * win_size['height']
end

function M.pixel_orientation(win_config)
    local win_size = M.get_win_size(win_config)
    return (win_size.width*options.cell_pixel_ratio_w_to_h > win_size.height) and 'horizontal' or 'vertical'
end

function M.pixel_transpose(win_config)
    local width = win_config.width
    local height = win_config.height
    win_config.width = utils.math_round(height/options.cell_pixel_ratio_w_to_h)
    win_config.height = utils.math_round(width*options.cell_pixel_ratio_w_to_h)
end

local function get_options(winid)
    local win_opts = {}
    local wo = vim.wo[winid]
    local all_opts = vim.api.nvim_get_all_options_info()
    for opt, metadata in pairs(all_opts) do
        if metadata.scope == "win" then
            win_opts[opt] = wo[opt]
        end
    end
    return win_opts
end

local function set_options(winid, win_opts)
    local wo = vim.wo[winid]
    for opt, val in pairs(win_opts) do
        pcall(function() wo[opt] = val end)
    end
end

function M.copy_options(src_winid, dst_winid)
    local src_opts = get_options(src_winid)
    set_options(dst_winid, src_opts)
end

return M
