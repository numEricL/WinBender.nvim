local M = {}

local core = require("winbender.core")
local state = require("winbender.state")
local options = require("winbender.config").options

local keymaps = {}

local function focus_next(args)
    core.focus_next_floating_window()
end

local function reset_window(args)
    state.restore_config(state.winid)
end

local function reposition(args)
    core.reposition_floating_window(state.winid, args.x_delta, args.y_delta)
end

local function resize(args)
    core.resize_floating_window(state.winid, args.x_delta, args.y_delta)
end

local function update_anchor(args)
    core.update_anchor(state.winid, args.anchor)
end

local keymap_defaults = {
    focus_next       = { map = 'f', func = focus_next,     args = {} },
    reset_window     = { map = 'r', func = reset_window,   args = {} },
    shift_left       = { map = 'h', func = reposition,     args = {x_delta = -1, y_delta =  0} },
    shift_right      = { map = 'l', func = reposition,     args = {x_delta =  1, y_delta =  0} },
    shift_down       = { map = 'j', func = reposition,     args = {x_delta =  0, y_delta =  1} },
    shift_up         = { map = 'k', func = reposition,     args = {x_delta =  0, y_delta = -1} },
    width_increase   = { map = '>', func = resize,         args = {x_delta =  1, y_delta =  0} },
    width_decrease   = { map = '<', func = resize,         args = {x_delta = -1, y_delta =  0} },
    height_increase  = { map = '+', func = resize,         args = {x_delta =  0, y_delta =  1} },
    height_decrease  = { map = '-', func = resize,         args = {x_delta =  0, y_delta = -1} },
    anchor_NW        = { map = 'q', func = update_anchor,  args = {anchor = 'NW'} },
    anchor_NE        = { map = 'w', func = update_anchor,  args = {anchor = 'NE'} },
    anchor_SW        = { map = 'a', func = update_anchor,  args = {anchor = 'SW'} },
    anchor_SE        = { map = 's', func = update_anchor,  args = {anchor = 'SE'} },
}

function M.set_winbender_maps()
    for action, mapping in pairs(keymap_defaults) do
        vim.keymap.set('n', mapping.map, function()
            mapping.func(mapping.args)
        end, { desc = "Winbender: " .. action })
    end
end

function M.save()
    for action, mapping in pairs(keymap_defaults) do
        local rhs = vim.fn.maparg(mapping.map, 'n', 0, 1)
        if not vim.tbl_isempty(rhs) then
            table.insert(keymaps, rhs)
        end
    end
end

function M.restore()
    for _, mapping in pairs(keymap_defaults) do
        vim.api.nvim_del_keymap('n', mapping.map)
    end
    while #keymaps > 0 do
        local maparg = table.remove(keymaps)
        vim.fn.mapset('n', 0, maparg)
    end
end

return M
