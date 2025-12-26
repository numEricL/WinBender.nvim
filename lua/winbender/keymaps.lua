local M = {}

local core         = require("winbender.core")
local compat       = require("winbender.compat")
local display      = require("winbender.display")
local dock         = require("winbender.dock")
local highlight    = require("winbender.highlight")
local mouse        = require("winbender.mouse")
local options      = require("winbender.config").options
local quick_access = require("winbender.quick_access")
local state        = require("winbender.state")

local keymaps = {}

local function focus_next_float(args, count)
    local winid = core.find_next_floating_window(args.dir, math.max(1, count))
    if not winid then
        return
    end
    core.focus_window(winid)
    display.labels(winid)
end

local function focus_next_dock(args, count)
    local winid = core.find_next_docked_window(args.dir, math.max(1, count))
    if not winid then
        return
    end
    core.focus_window(winid)
    display.labels(winid)
end

---@diagnostic disable-next-line: unused-local
local function reset_window(args)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    state.restore_config(winid)
    core.reposition_floating_window(winid, 0, 0) -- for repositioning in bounds
    display.labels(winid)
end

local function move_or_reposition(args, count)
    local winid, type = core.get_current_window()
    if not winid then
        return
    end
    if type == 'floating' then
        local step = (count == 0) and args.step or count
        core.reposition_floating_window(winid, step*args.x_delta, step*args.y_delta)
        display.labels(winid)
    else
        local dir = (args.x_delta < 0) and 'h' or
                    (args.x_delta > 0) and 'l' or
                    (args.y_delta < 0) and 'k' or
                    (args.y_delta > 0) and 'j' or nil
        local count1 = math.max(1, count)
        if dir then
            vim.cmd('wincmd ' .. tostring(count1) .. dir)
        end
    end
end

local function update_anchor(args)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    core.update_anchor(winid, args.anchor)
    display.labels(winid)
end

local function resize_edge(args, count)
    local winid = core.get_current_window()
    local sign = (args.step > 0) and 1 or -1
    local step = (count == 0) and args.step or sign*count
    local silent = true
    if state.validate_docked_window(winid, true) then
        core.resize_docked_window(winid, args.edge, step)
    elseif state.validate_floating_window(winid, true) then
        core.resize_floating_window(winid, args.edge, step)
    else
        return
    end
    display.labels(winid)
end

local function snap(args)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    local max_row = vim.o.lines
    local max_col = vim.o.columns
    local edge_map = {
        left  = {dx = -max_col, dy = 0, edge1 = 'up',   edge2 = 'down',  step = max_row},
        right = {dx =  max_col, dy = 0, edge1 = 'up',   edge2 = 'down',  step = max_row},
        up    = {dx = 0, dy = -max_row, edge1 = 'left', edge2 = 'right', step = max_col},
        down  = {dx = 0, dy =  max_row, edge1 = 'left', edge2 = 'right', step = max_col},
    }

    local d = edge_map[args.edge]
    core.make_square_floating_window(winid)
    core.reposition_floating_window(winid, d.dx, d.dy)
    resize_edge({edge = d.edge1, step = d.step}, 0)
    resize_edge({edge = d.edge2, step = d.step}, 0)
end

---@diagnostic disable-next-line: unused-local
local function dock_window(args)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    display.clear_labels(winid)
    highlight.restore(winid)
    local new_winid = dock.dock_floating_window(winid)
    local next_focus = core.find_next_floating_window('forward')
    next_focus = next_focus or new_winid
    core.focus_window(next_focus)
    display.labels(new_winid)
end

---@diagnostic disable-next-line: unused-local
local function float_window(args)
    local winid = core.get_current_docked_window()
    if not winid then
        return
    end
    display.clear_labels(winid)
    highlight.restore(winid)
    local new_winid = dock.float_docked_window(winid)
    core.focus_window(new_winid)
    display.labels(new_winid)
end

local function get_maps()
    local keys = options.keymaps
    local p_sz = { x = options.step_size.position_x, y = options.step_size.position_y }
    local s_sz = { x = options.step_size.size_x,     y = options.step_size.size_y     }
    local maps = {
        focus_next_float = { map = keys.focus_next_float, func = focus_next_float, args = {dir = 'forward' } },
        focus_prev_float = { map = keys.focus_prev_float, func = focus_next_float, args = {dir = 'backward'} },
        focus_next_dock  = { map = keys.focus_next_dock,  func = focus_next_dock,  args = {dir = 'forward' } },
        focus_prev_dock  = { map = keys.focus_prev_dock,  func = focus_next_dock,  args = {dir = 'backward'} },

        reset_window = { map = keys.reset_window, func = reset_window, args = {} },

        move_left  = { map = keys.move_left,  func = move_or_reposition, args = {x_delta = -1, y_delta =  0, step = p_sz.x} },
        move_right = { map = keys.move_right, func = move_or_reposition, args = {x_delta =  1, y_delta =  0, step = p_sz.x} },
        move_down  = { map = keys.move_down,  func = move_or_reposition, args = {x_delta =  0, y_delta =  1, step = p_sz.y} },
        move_up    = { map = keys.move_up,    func = move_or_reposition, args = {x_delta =  0, y_delta = -1, step = p_sz.y} },

        increase_left  = { map = keys.increase_left,  func = resize_edge, args = {edge = 'left',   step = s_sz.x} },
        increase_right = { map = keys.increase_right, func = resize_edge, args = {edge = 'right',  step = s_sz.x} },
        increase_down  = { map = keys.increase_down,  func = resize_edge, args = {edge = 'bottom', step = s_sz.y} },
        increase_up    = { map = keys.increase_up,    func = resize_edge, args = {edge = 'top',    step = s_sz.y} },

        decrease_left  = { map = keys.decrease_left,  func = resize_edge, args = {edge = 'left',   step = -s_sz.x} },
        decrease_right = { map = keys.decrease_right, func = resize_edge, args = {edge = 'right',  step = -s_sz.x} },
        decrease_down  = { map = keys.decrease_down,  func = resize_edge, args = {edge = 'bottom', step = -s_sz.y} },
        decrease_up    = { map = keys.decrease_up,    func = resize_edge, args = {edge = 'top',    step = -s_sz.y} },

        snap_left = { map = keys.snap_left,  func = snap, args = {edge = 'left'  } },
        snap_right= { map = keys.snap_right, func = snap, args = {edge = 'right' } },
        snap_up   = { map = keys.snap_up,    func = snap, args = {edge = 'top'   } },
        snap_down = { map = keys.snap_down,  func = snap, args = {edge = 'bottom'} },

        anchor_NW = { map = keys.anchor_NW, func = update_anchor, args = {anchor = 'NW'} },
        anchor_NE = { map = keys.anchor_NE, func = update_anchor, args = {anchor = 'NE'} },
        anchor_SW = { map = keys.anchor_SW, func = update_anchor, args = {anchor = 'SW'} },
        anchor_SE = { map = keys.anchor_SE, func = update_anchor, args = {anchor = 'SE'} },

        dock_window  = { map = keys.dock_window,  func = dock_window,  args = {} },
        float_window = { map = keys.float_window, func = float_window, args = {} },
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

local function cyclops_integration()
    local keys = options.keymaps
    local cyclops_opts = options.cyclops_opts
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.focus_next_float, keys.focus_prev_float }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.focus_next_dock, keys.focus_prev_dock   }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.move_right, keys.move_left              }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.move_up, keys.move_down                 }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_left, keys.decrease_left       }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_right, keys.decrease_right     }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_up, keys.decrease_up           }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_down, keys.decrease_down       }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_width, keys.decrease_width     }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_height, keys.decrease_height   }, cyclops_opts })
end

function M.set_maps()
    for action, mapping in pairs(get_maps()) do
        if mapping.map then
            vim.keymap.set('n', mapping.map, function()
                mapping.func(mapping.args, vim.v.count)
            end, { desc = "WinBender: " .. action })
        end
    end
    for n = 1, 9 do
        vim.keymap.set('n', 'g' .. n, function() focus_quick_access(n) end, { desc = 'WinBender: quick access' })
    end
    if options.mouse_enabled then
        mouse.set_maps()
    end
    cyclops_integration()
end

function M.save()
    for _, mapping in pairs(get_maps()) do
        local rhs = vim.fn.maparg(mapping.map, 'n', 0, 1)
        if not vim.tbl_isempty(rhs) then
            table.insert(keymaps, rhs)
        end
    end
    if options.mouse_enabled then
        mouse.save()
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
    if options.mouse_enabled then
        mouse.restore_maps()
    end
end

return M
