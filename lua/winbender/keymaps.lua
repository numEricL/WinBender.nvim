local M = {}

local core = require("winbender.core")
local state = require("winbender.state")
local config = require("winbender.config")

local keymaps = {}

local function focus_next(args, count)
    local winid = core.find_next_floating_window(args.dir, math.max(1, count))
    if not winid then
        return
    end
    core.focus_window(winid)
end

local function reset_window(args)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    state.restore_config(winid)
end

local function reposition(args, count)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    local step = (count == 0) and args.step or count
    core.reposition_floating_window(winid, step*args.x_delta, step*args.y_delta)
end

local function resize(args, count)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    local step = (count == 0) and args.step or count
    core.resize_floating_window(winid, step*args.x_delta, step*args.y_delta)
end

local function update_anchor(args)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    core.update_anchor(winid, args.anchor)
end

local function resize_dir(args, count)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    local old_anchor = core.get_anchor(winid)
    local anchor = old_anchor
    if args.dir == 'up' then
        anchor = 'S' .. anchor:sub(2,2)
    elseif args.dir == 'down' then
        anchor = 'N' .. anchor:sub(2,2)
    elseif args.dir == 'left' then
        anchor = anchor:sub(1,1) .. 'E'
    elseif args.dir == 'right' then
        anchor = anchor:sub(1,1) .. 'W'
    end
    core.update_anchor(winid, anchor)
    local step = (count == 0) and args.step or count
    core.resize_floating_window(winid, step*args.x_delta, step*args.y_delta)
    core.update_anchor(winid, old_anchor)
end

local function get_maps()
    local opts = config.get_options()
    local keys = opts.keymaps
    local p_sz = opts.step_size.position
    local s_sz = opts.step_size.size
    local maps = {
        focus_next   = { map = keys.focus_next,   func = focus_next,   args = {dir = 'forward'} },
        focus_prev   = { map = keys.focus_prev,   func = focus_next,   args = {dir = 'backward'} },
        reset_window = { map = keys.reset_window, func = reset_window, args = {} },

        shift_left  = { map = keys.shift_left,  func = reposition, args = {x_delta = -1, y_delta =  0, step = p_sz} },
        shift_right = { map = keys.shift_right, func = reposition, args = {x_delta =  1, y_delta =  0, step = p_sz} },
        shift_down  = { map = keys.shift_down,  func = reposition, args = {x_delta =  0, y_delta =  1, step = p_sz} },
        shift_up    = { map = keys.shift_up,    func = reposition, args = {x_delta =  0, y_delta = -1, step = p_sz} },

        increase_left  = { map = keys.increase_left,  func = resize_dir, args = {dir = 'left',  x_delta =  1, y_delta =  0, step = s_sz} },
        increase_right = { map = keys.increase_right, func = resize_dir, args = {dir = 'right', x_delta =  1, y_delta =  0, step = s_sz} },
        increase_down  = { map = keys.increase_down,  func = resize_dir, args = {dir = 'down',  x_delta =  0, y_delta =  1, step = s_sz} },
        increase_up    = { map = keys.increase_up,    func = resize_dir, args = {dir = 'up',    x_delta =  0, y_delta =  1, step = s_sz} },

        decrease_left  = { map = keys.decrease_left,  func = resize_dir, args = {dir = 'left',  x_delta = -1, y_delta =  0, step = s_sz} },
        decrease_right = { map = keys.decrease_right, func = resize_dir, args = {dir = 'right', x_delta = -1, y_delta =  0, step = s_sz} },
        decrease_down  = { map = keys.decrease_down,  func = resize_dir, args = {dir = 'down',  x_delta =  0, y_delta = -1, step = s_sz} },
        decrease_up    = { map = keys.decrease_up,    func = resize_dir, args = {dir = 'up',    x_delta =  0, y_delta = -1, step = s_sz} },

        increase_width  = { map = keys.increase_width,  func = resize, args = {x_delta =  1, y_delta =  0, step = s_sz} },
        decrease_width  = { map = keys.decrease_width,  func = resize, args = {x_delta = -1, y_delta =  0, step = s_sz} },
        increase_height = { map = keys.increase_height, func = resize, args = {x_delta =  0, y_delta =  1, step = s_sz} },
        decrease_height = { map = keys.decrease_height, func = resize, args = {x_delta =  0, y_delta = -1, step = s_sz} },

        anchor_NW = { map = keys.anchor_NW, func = update_anchor,  args = {anchor = 'NW'} },
        anchor_NE = { map = keys.anchor_NE, func = update_anchor,  args = {anchor = 'NE'} },
        anchor_SW = { map = keys.anchor_SW, func = update_anchor,  args = {anchor = 'SW'} },
        anchor_SE = { map = keys.anchor_SE, func = update_anchor,  args = {anchor = 'SE'} },
    }
    return maps
end

local function quick_access(id)
    local winid = state.quick_access_winid(id)
    if not winid then
        return
    end
    core.focus_window(winid)
end

function M.set_winbender_maps()
    for action, mapping in pairs(get_maps()) do
        vim.keymap.set('n', mapping.map, function()
            mapping.func(mapping.args, vim.v.count)
        end, { desc = "Winbender: " .. action })
    end
    for n = 1, 9 do
        vim.keymap.set('n', 'g' .. n, function() quick_access(n) end, { desc = 'Winbender: quick access' })
    end
end

function M.save()
    for action, mapping in pairs(get_maps()) do
        local rhs = vim.fn.maparg(mapping.map, 'n', 0, 1)
        if not vim.tbl_isempty(rhs) then
            table.insert(keymaps, rhs)
        end
    end
end

function M.restore()
    for _, mapping in pairs(get_maps()) do
        vim.api.nvim_del_keymap('n', mapping.map)
    end
    while #keymaps > 0 do
        local maparg = table.remove(keymaps)
        vim.fn.mapset('n', 0, maparg)
    end
end

return M
