local M = {}

local compat  = require("winbender.compat")
local core    = require("winbender.core")
local display = require("winbender.display")
local state   = require("winbender.state")

local mouse_maps = {}

local drag_state = {
    active = false,
    winid = nil,
    start_mouse_row = nil,
    start_mouse_col = nil,
    start_win_row = nil,
    start_win_col = nil,
}

local function init_drag_floating_window()
    local mouse_pos = vim.fn.getmousepos()
    local winid = mouse_pos.winid

    local silent = true
    if not state.validate_floating_window(winid, silent) then
        return
    end

    local cfg = compat.nvim_win_get_config(winid)
    drag_state = {
        active = true,
        winid = winid,
        start_mouse_row = mouse_pos.screenrow,
        start_mouse_col = mouse_pos.screencol,
        start_win_row = cfg.row,
        start_win_col = cfg.col,
    }
end

local function end_drag_floating_window()
    local silent = true
    if state.validate_floating_window(drag_state.winid, silent) then
        core.reposition_in_bounds(drag_state.winid)
        display.labels(drag_state.winid)
    end
    drag_state = {
        active = false,
        winid = nil,
        start_mouse_row = nil,
        start_mouse_col = nil,
        start_win_row = nil,
        start_win_col = nil,
    }
end

local function drag_floating_window()
    if not drag_state.active then
        return
    end
    local silent = true
    if not state.validate_window(drag_state.winid, silent) then
        end_drag_floating_window()
        return
    end

    local mouse_pos = vim.fn.getmousepos()
    local row_delta = mouse_pos.screenrow - drag_state.start_mouse_row
    local col_delta = mouse_pos.screencol - drag_state.start_mouse_col

    local cfg = compat.nvim_win_get_config(drag_state.winid)
    cfg.row = drag_state.start_win_row + row_delta
    cfg.col = drag_state.start_win_col + col_delta

    compat.nvim_win_set_config(drag_state.winid, cfg)
    display.labels(drag_state.winid)
end

local function left_mouse()
    local winid = vim.fn.getmousepos().winid
    local silent = true
    core.focus_window(winid, silent)
    init_drag_floating_window()
end

function M.set_maps()
    vim.keymap.set('n', '<LeftMouse>',   left_mouse,               { desc = "WinBender: Start drag"  })
    vim.keymap.set('n', '<LeftDrag>',    drag_floating_window,     { desc = "WinBender: Drag window" })
    vim.keymap.set('n', '<LeftRelease>', end_drag_floating_window, { desc = "WinBender: End drag"    })

    vim.keymap.set('n', '<2-LeftMouse>', '<nop>', { desc = "WinBender: Disabled" })
    vim.keymap.set('n', '<3-LeftMouse>', '<nop>', { desc = "WinBender: Disabled" })
    vim.keymap.set('n', '<4-LeftMouse>', '<nop>', { desc = "WinBender: Disabled" })
end

function M.save()
    mouse_maps = {}
    local maps_to_save = {'<LeftMouse>', '<LeftDrag>', '<LeftRelease>', '<2-LeftMouse>', '<3-LeftMouse>', '<4-LeftMouse>'}

    for _, map in ipairs(maps_to_save) do
        local rhs = vim.fn.maparg(map, 'n', 0, 1)
        if not vim.tbl_isempty(rhs) then
            table.insert(mouse_maps, rhs)
        end
    end
end

function M.restore_maps()
    pcall(vim.api.nvim_del_keymap, 'n', '<LeftMouse>')
    pcall(vim.api.nvim_del_keymap, 'n', '<LeftDrag>')
    pcall(vim.api.nvim_del_keymap, 'n', '<LeftRelease>')
    pcall(vim.api.nvim_del_keymap, 'n', '<2-LeftMouse>')
    pcall(vim.api.nvim_del_keymap, 'n', '<3-LeftMouse>')
    pcall(vim.api.nvim_del_keymap, 'n', '<4-LeftMouse>')

    while #mouse_maps > 0 do
        local maparg = table.remove(mouse_maps)
        vim.fn.mapset('n', 0, maparg)
    end
end

return M
