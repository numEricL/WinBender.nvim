local M = {}

local core         = require("winbender.core")
local compat       = require("winbender.compat")
local display      = require("winbender.display")
local dock         = require("winbender.dock")
local mouse        = require("winbender.mouse")
local options      = require("winbender.config").options
local quick_access = require("winbender.quick_access")
local state        = require("winbender.state")

local keymaps = {}

local function focus_next(args, count)
    local winid = core.find_next_floating_window(args.dir, math.max(1, count))
    if not winid then
        return
    end
    core.focus_window(winid)
end

---@diagnostic disable-next-line: unused-local
local function reset_window(args)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    state.restore_config(winid)
    core.reposition_floating_window(winid, 0, 0) -- for repositioning in bounds
    display.win_labels(winid)
end

local function move_or_reposition(args, count)
    local winid, type = core.get_current_window()
    if not winid then
        return
    end
    if type == 'floating' then
        local step = (count == 0) and args.step or count
        core.reposition_floating_window(winid, step*args.x_delta, step*args.y_delta)
        display.win_labels(winid)
    else
        local dir = (args.x_delta < 0) and 'h' or
                    (args.x_delta > 0) and 'l' or
                    (args.y_delta < 0) and 'k' or
                    (args.y_delta > 0) and 'j' or nil
        local count1 = math.max(1, count)
        if dir then
            vim.cmd('wincmd '   .. tostring(count1) .. dir)
        end
    end
end

local function update_anchor(args)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    core.update_anchor(winid, args.anchor)
    display.win_labels(winid)
end

local function resize(args, count)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    local step = (count == 0) and args.step or count
    core.resize_floating_window(winid, step*args.x_delta, step*args.y_delta)
    display.win_labels(winid)
end

local function resize_dir(args, count)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    local old_anchor = compat.nvim_win_get_config(winid).anchor
    local dir_map = {
        left = { anchor = old_anchor:sub(1,1) .. 'E', dx = 1, dy = 0 },
        right= { anchor = old_anchor:sub(1,1) .. 'W', dx = 1, dy = 0 },
        up   = { anchor = 'S' .. old_anchor:sub(2,2), dx = 0, dy = 1 },
        down = { anchor = 'N' .. old_anchor:sub(2,2), dx = 0, dy = 1 },
    }
    local d = dir_map[args.dir]

    local sign = (args.step > 0) and 1 or -1
    local step = (count == 0) and args.step or sign*count

    core.update_anchor(winid, d.anchor)
    core.resize_floating_window(winid, step*d.dx, step*d.dy)
    core.update_anchor(winid, old_anchor)
    display.win_labels(winid)
end

local function snap_dir(args)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    local max_row = vim.o.lines
    local max_col = vim.o.columns
    local dir_map = {
        left  = {dx = -max_col, dy = 0, dir1 = 'up',   dir2 = 'down',  step = max_row},
        right = {dx =  max_col, dy = 0, dir1 = 'up',   dir2 = 'down',  step = max_row},
        up    = {dx = 0, dy = -max_row, dir1 = 'left', dir2 = 'right', step = max_col},
        down  = {dx = 0, dy =  max_row, dir1 = 'left', dir2 = 'right', step = max_col},
    }

    local d = dir_map[args.dir]
    core.make_square_floating_window(winid)
    core.reposition_floating_window(winid, d.dx, d.dy)
    resize_dir({dir = d.dir1, step = d.step}, 0)
    resize_dir({dir = d.dir2, step = d.step}, 0)
end

---@diagnostic disable-next-line: unused-local
local function dock_window(args)
    local winid = core.get_current_floating_window()
    if not winid then
        return
    end
    dock.dock_floating_window(winid)
    display.win_labels(winid)
end

---@diagnostic disable-next-line: unused-local
local function float_window(args)
    local winid = core.get_current_docked_window()
    if not winid then
        return
    end
    dock.float_docked_window(winid)
    display.win_labels(winid)
end

local function get_maps()
    local keys = options.keymaps
    local p_sz = options.step_size.position
    local s_sz = options.step_size.size
    local maps = {
        focus_next   = { map = keys.focus_next,   func = focus_next,   args = {dir = 'forward' } },
        focus_prev   = { map = keys.focus_prev,   func = focus_next,   args = {dir = 'backward'} },
        reset_window = { map = keys.reset_window, func = reset_window, args = {}                 },

        move_left  = { map = keys.move_left,  func = move_or_reposition, args = {x_delta = -1, y_delta =  0, step = p_sz} },
        move_right = { map = keys.move_right, func = move_or_reposition, args = {x_delta =  1, y_delta =  0, step = p_sz} },
        move_down  = { map = keys.move_down,  func = move_or_reposition, args = {x_delta =  0, y_delta =  1, step = p_sz} },
        move_up    = { map = keys.move_up,    func = move_or_reposition, args = {x_delta =  0, y_delta = -1, step = p_sz} },

        increase_left  = { map = keys.increase_left,  func = resize_dir, args = {dir = 'left',  step = s_sz} },
        increase_right = { map = keys.increase_right, func = resize_dir, args = {dir = 'right', step = s_sz} },
        increase_down  = { map = keys.increase_down,  func = resize_dir, args = {dir = 'down',  step = s_sz} },
        increase_up    = { map = keys.increase_up,    func = resize_dir, args = {dir = 'up',    step = s_sz} },

        decrease_left  = { map = keys.decrease_left,  func = resize_dir, args = {dir = 'left',  step = -s_sz} },
        decrease_right = { map = keys.decrease_right, func = resize_dir, args = {dir = 'right', step = -s_sz} },
        decrease_down  = { map = keys.decrease_down,  func = resize_dir, args = {dir = 'down',  step = -s_sz} },
        decrease_up    = { map = keys.decrease_up,    func = resize_dir, args = {dir = 'up',    step = -s_sz} },

        snap_left = { map = keys.snap_left,  func = snap_dir, args = {dir = 'left' } },
        snap_right= { map = keys.snap_right, func = snap_dir, args = {dir = 'right'} },
        snap_up   = { map = keys.snap_up,    func = snap_dir, args = {dir = 'up'   } },
        snap_down = { map = keys.snap_down,  func = snap_dir, args = {dir = 'down' } },

        increase_width  = { map = keys.increase_width,  func = resize, args = {x_delta =  1, y_delta =  0, step = s_sz} },
        decrease_width  = { map = keys.decrease_width,  func = resize, args = {x_delta = -1, y_delta =  0, step = s_sz} },
        increase_height = { map = keys.increase_height, func = resize, args = {x_delta =  0, y_delta =  1, step = s_sz} },
        decrease_height = { map = keys.decrease_height, func = resize, args = {x_delta =  0, y_delta = -1, step = s_sz} },

        anchor_NW = { map = keys.anchor_NW, func = update_anchor,  args = {anchor = 'NW'} },
        anchor_NE = { map = keys.anchor_NE, func = update_anchor,  args = {anchor = 'NE'} },
        anchor_SW = { map = keys.anchor_SW, func = update_anchor,  args = {anchor = 'SW'} },
        anchor_SE = { map = keys.anchor_SE, func = update_anchor,  args = {anchor = 'SE'} },

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
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.focus_next, keys.focus_prev          }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.move_right, keys.move_left           }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.move_up, keys.move_down              }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_left, keys.decrease_left    }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_right, keys.decrease_right  }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_up, keys.decrease_up        }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_down, keys.decrease_down    }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_width, keys.decrease_width  }, cyclops_opts })
    pcall(vim.api.nvim_call_function, "pair#SetMap", { "nmap", { keys.increase_height, keys.decrease_height}, cyclops_opts })
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
    -- cyclops_integration()
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
