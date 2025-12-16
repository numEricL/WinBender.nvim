local M = {}

local core         = require("winbender.core")
local state        = require("winbender.state")
local quick_access = require("winbender.quick_access")
local options      = require("winbender.config").options

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
    core.display_info(winid)
end

local function reposition(args, count)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    local step = (count == 0) and args.step or count
    core.reposition_floating_window(winid, step*args.x_delta, step*args.y_delta)
    core.display_info(winid)
end

local function resize(args, count)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    local step = (count == 0) and args.step or count
    core.resize_floating_window(winid, step*args.x_delta, step*args.y_delta)
    core.display_info(winid)
end

local function update_anchor(args)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    core.update_anchor(winid, args.anchor)
    core.display_info(winid)
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
    core.display_info(winid)
end

local function get_maps()
    local keys = options.keymaps
    local p_sz = options.step_size.position
    local s_sz = options.step_size.size
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

local function focus_quick_access(id)
    local winid = quick_access.get_winid(id)
    if not winid then
        return
    end
    core.focus_window(winid)
end

function M.set_maps()
    for action, mapping in pairs(get_maps()) do
        vim.keymap.set('n', mapping.map, function()
            mapping.func(mapping.args, vim.v.count)
        end, { desc = "WinBender: " .. action })
    end
    for n = 1, 9 do
        vim.keymap.set('n', 'g' .. n, function() focus_quick_access(n) end, { desc = 'WinBender: quick access' })
    end
    local keys = options.keymaps
    local cyclops_opts = options.cyclops_opts
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.focus_next, keys.focus_prev          }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.shift_right, keys.shift_left         }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.shift_up, keys.shift_down            }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_left, keys.decrease_left    }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_right, keys.decrease_right  }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_up, keys.decrease_up        }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_down, keys.decrease_down    }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_width, keys.decrease_width  }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_height, keys.decrease_height}, cyclops_opts })
end

function M.save()
    for action, mapping in pairs(get_maps()) do
        local rhs = vim.fn.maparg(mapping.map, 'n', 0, 1)
        if not vim.tbl_isempty(rhs) then
            table.insert(keymaps, rhs)
        end
    end
end

function M.restore_maps()
    for _, mapping in pairs(get_maps()) do
        pcall(vim.api.nvim_del_keymap, 'n', mapping.map)
    end
    while #keymaps > 0 do
        local maparg = table.remove(keymaps)
        vim.fn.mapset('n', 0, maparg)
    end
end

return M
