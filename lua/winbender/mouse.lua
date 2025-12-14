local M = {}

local core = require("winbender.core")
local state = require("winbender.state")

local mouse_maps = {}

local drag_state = {
    active = false,
    winid = nil,
    start_mouse_row = nil,
    start_mouse_col = nil,
    start_win_row = nil,
    start_win_col = nil,
}

local function get_mouse_position()
    local mouse_pos = vim.fn.getmousepos()
    return mouse_pos.screenrow, mouse_pos.screencol
end

function M.start_drag()
    local winid = vim.fn.getmousepos().winid
    
    if winid == 0 then
        return
    end
    
    if not core.validate_floating_window(winid) then
        return
    end
    
    local win_config = vim.api.nvim_win_get_config(winid)
    local mouse_row, mouse_col = get_mouse_position()
    
    -- Extract numeric values from row/col (handle both plain numbers and tables)
    local row_val = type(win_config.row) == "table" and win_config.row[false] or win_config.row
    local col_val = type(win_config.col) == "table" and win_config.col[false] or win_config.col
    
    drag_state.active = true
    drag_state.winid = winid
    drag_state.start_mouse_row = mouse_row
    drag_state.start_mouse_col = mouse_col
    drag_state.start_win_row = row_val
    drag_state.start_win_col = col_val
    
    core.focus_window(winid)
    vim.o.mouse = 'a'
end

function M.drag()
    if not drag_state.active then
        return
    end
    
    if not vim.api.nvim_win_is_valid(drag_state.winid) then
        M.end_drag()
        return
    end
    
    local mouse_row, mouse_col = get_mouse_position()
    local row_delta = mouse_row - drag_state.start_mouse_row
    local col_delta = mouse_col - drag_state.start_mouse_col
    
    local win_config = vim.api.nvim_win_get_config(drag_state.winid)
    win_config.row = drag_state.start_win_row + row_delta
    win_config.col = drag_state.start_win_col + col_delta
    
    vim.api.nvim_win_set_config(drag_state.winid, win_config)
end

function M.end_drag()
    drag_state.active = false
    drag_state.winid = nil
    drag_state.start_mouse_row = nil
    drag_state.start_mouse_col = nil
    drag_state.start_win_row = nil
    drag_state.start_win_col = nil
end

function M.is_dragging()
    return drag_state.active
end

function M.save()
    mouse_maps = {}
    local maps_to_save = {'<LeftMouse>', '<LeftDrag>', '<LeftRelease>'}
    
    for _, map in ipairs(maps_to_save) do
        local rhs = vim.fn.maparg(map, 'n', 0, 1)
        if not vim.tbl_isempty(rhs) then
            table.insert(mouse_maps, rhs)
        end
    end
end

function M.set_maps()
    vim.keymap.set('n', '<LeftMouse>', function()
        local winid = vim.fn.getmousepos().winid
        if winid ~= 0 then
            local win_config = vim.api.nvim_win_get_config(winid)
            if win_config.relative and win_config.relative ~= "" then
                M.start_drag()
                return
            end
        end
        -- Default behavior if not a floating window
        vim.cmd('normal! <LeftMouse>')
    end, { desc = "WinBender: Start drag" })
    
    vim.keymap.set('n', '<LeftDrag>', function()
        if M.is_dragging() then
            M.drag()
        else
            vim.cmd('normal! <LeftDrag>')
        end
    end, { desc = "WinBender: Drag window" })
    
    vim.keymap.set('n', '<LeftRelease>', function()
        if M.is_dragging() then
            M.end_drag()
        else
            vim.cmd('normal! <LeftRelease>')
        end
    end, { desc = "WinBender: End drag" })
end

function M.restore_maps()
    pcall(vim.api.nvim_del_keymap, 'n', '<LeftMouse>')
    pcall(vim.api.nvim_del_keymap, 'n', '<LeftDrag>')
    pcall(vim.api.nvim_del_keymap, 'n', '<LeftRelease>')
    
    while #mouse_maps > 0 do
        local maparg = table.remove(mouse_maps)
        vim.fn.mapset('n', 0, maparg)
    end
end

return M
