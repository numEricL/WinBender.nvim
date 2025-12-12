local M = {}

state = {}
state.wins = {}
state.maps = {}
state.old_winid = nil
state.winid = nil

function state.wins:save(winid)
    if self[winid] == nil then
        self[winid] = vim.api.nvim_win_get_config(winid)
    end
end

function state.wins:restore(winid)
    if self[winid] == nil then
        return
    end
    vim.api.nvim_win_set_config(winid, self[winid])
end

local function validate_floating_window() end

function reposition_floating_window(winid, x_delta, y_delta)
    -- validate_floating_window(winid)
    state.wins:save(winid)

    local config = vim.api.nvim_win_get_config(winid)
    config.col = config.col + x_delta
    config.row = config.row + y_delta
    vim.api.nvim_win_set_config(winid, config)
end

function resize_floating_window(winid, x_delta, y_delta)
    -- validate_floating_window(winid)
    state.wins:save(winid)

    local config = vim.api.nvim_win_get_config(winid)
    config.height = math.max(config.height + y_delta, 1)
    config.width = math.max(config.width + x_delta, 1)
    vim.api.nvim_win_set_config(winid, config)
end

-- checks the current window first, then other windows in descending order by winid
function find_floating_window()
    local cur_win = vim.api.nvim_get_current_win()
    local config = vim.api.nvim_win_get_config(cur_win)
    if config.relative ~= "" then
        return cur_win
    else
        return find_next_floating_window()
    end
end

function find_next_floating_window()
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

    local n = #wins
    for i = 1, n do
        -- wrap with modulo arithmetic using representatives 1 to n
        local idx = ((cur_idx - i - 1) % n) + 1
        local winid = wins[idx]
        local config = vim.api.nvim_win_get_config(winid)
        if config.relative ~= "" then
            return winid
        end
    end

    return nil
end

function focus_window(winid)
    if vim.api.nvim_win_is_valid(winid) then
        state.winid = winid
        vim.api.nvim_set_current_win(winid)
    else
        vim.notify("Invalid window id: " .. tostring(winid), vim.log.levels.ERROR)
    end
end

function focus_next_floating_window()
    local winid = find_next_floating_window()
    if winid then
        focus_window(winid)
    else
        vim.notify("No floating windows found", vim.log.levels.INFO)
    end
end

local function validate_floating_window(winid)
    if not vim.api.nvim_win_is_valid(winid) then
        vim.notify("Invalid window id: " .. tostring(winid), vim.log.levels.ERROR)
        return false
    end
    local config = vim.api.nvim_win_get_config(winid)
    if not config.relative or config.relative == "" then
        vim.notify("Window " .. winid .. " is not a floating window", vim.log.levels.ERROR)
        return false
    end
    return true
end

local function focus_next(args)
    focus_next_floating_window()
end

local function reset_window(args)
    state.wins:restore(state.winid)
end

local function shift_left(args)
    reposition_floating_window(state.winid, args.x_delta, args.y_delta)
end

local function shift_right(args)
    reposition_floating_window(state.winid, args.x_delta, args.y_delta)
end

local function shift_down(args)
    reposition_floating_window(state.winid, args.x_delta, args.y_delta)
end

local function shift_up(args)
    reposition_floating_window(state.winid, args.x_delta, args.y_delta)
end

local function width_increase(args)
    resize_floating_window(state.winid, args.x_delta, args.y_delta)
end

local function width_decrease(args)
    resize_floating_window(state.winid, args.x_delta, args.y_delta)
end

local function height_increase(args)
    resize_floating_window(state.winid, args.x_delta, args.y_delta)
end

local function height_decrease(args)
    resize_floating_window(state.winid, args.x_delta, args.y_delta)
end

local function get_floating_window_size(config)
    local width = config.width
    local height = config.height
    local border = config.border
    local border_width = 0
    local border_height = 0

    if border then
        if type(border) == "string" then
            border_width = 2
            border_height = 2
        elseif type(border) == "table" then
            border_height = border_height + ((border[2] ~= "" and 1) or 0)
            border_height = border_height + ((border[6] ~= "" and 1) or 0)
            border_width = border_width + ((border[4] ~= "" and 1) or 0)
            border_width = border_width + ((border[8] ~= "" and 1) or 0)
        end
    end

    return width + border_width, height + border_height
end

local function update_anchor(args)
    local config = vim.api.nvim_win_get_config(state.winid)
    local width, height = get_floating_window_size(config)

    local old_anchor = config.anchor
    local x_old = (old_anchor:sub(2,2) == 'E' and 1) or 0
    local y_old = (old_anchor:sub(1,1) == 'S' and 1) or 0

    local anchor = args.anchor
    local x_new = (anchor:sub(2,2) == 'E' and 1) or 0
    local y_new = (anchor:sub(1,1) == 'S' and 1) or 0

    config.anchor = anchor
    config.col = config.col + (x_new - x_old) * width
    config.row = config.row + (y_new - y_old) * height
    vim.api.nvim_win_set_config(state.winid, config)
end


local keymap_defaults = {
    focus_next       = { map = 'f', func = focus_next,      args = {} },
    reset_window     = { map = 'r', func = reset_window,    args = {} },
    shift_left       = { map = 'h', func = shift_left,      args = {x_delta = -1, y_delta =  0} },
    shift_right      = { map = 'l', func = shift_right,     args = {x_delta =  1, y_delta =  0} },
    shift_down       = { map = 'j', func = shift_down,      args = {x_delta =  0, y_delta =  1} },
    shift_up         = { map = 'k', func = shift_up,        args = {x_delta =  0, y_delta = -1} },
    width_increase   = { map = '>', func = width_increase,  args = {x_delta =  1, y_delta =  0} },
    width_decrease   = { map = '<', func = width_decrease,  args = {x_delta = -1, y_delta =  0} },
    height_increase  = { map = '+', func = height_increase, args = {x_delta =  0, y_delta =  1} },
    height_decrease  = { map = '-', func = height_decrease, args = {x_delta =  0, y_delta = -1} },
    anchor_NW        = { map = 'q', func = update_anchor,   args = {anchor = 'NW'} },
    anchor_NE        = { map = 'w', func = update_anchor,   args = {anchor = 'NE'} },
    anchor_SW        = { map = 'a', func = update_anchor,   args = {anchor = 'SW'} },
    anchor_SE        = { map = 's', func = update_anchor,   args = {anchor = 'SE'} },
}

function state.maps:save()
    for action, mapping in pairs(keymap_defaults) do
        local rhs = vim.fn.maparg(mapping.map, 'n', 0, 1)
        if not vim.tbl_isempty(rhs) then
            table.insert(self, rhs)
        end
    end
end

function state.maps:restore()
    for _, mapping in pairs(keymap_defaults) do
        vim.api.nvim_del_keymap('n', mapping.map)
    end
    while #self > 0 do
        local maparg = table.remove(self)
        vim.fn.mapset('n', 0, maparg)
    end
end

function set_maps()
    for action, mapping in pairs(keymap_defaults) do
        vim.keymap.set('n', mapping.map, function()
            mapping.func(mapping.args)
        end, { desc = "Winbender: " .. action })
    end
end

function create_floaters()
    local buf = vim.api.nvim_create_buf(false, true)
    local opts = {
        relative = 'editor',
        width = 40,
        height = 10,
        row = 5,
        col = 10,
        style = 'minimal'
    }
    local win = vim.api.nvim_open_win(buf, true, opts)
    opts.border = 'single'
    opts.relative = 'cursor'
    local win = vim.api.nvim_open_win(buf, true, opts)
end

M.toggle = function()
    if state.winid == nil then
        local winid = find_floating_window()
        if winid then
            state.old_winid = vim.api.nvim_get_current_win()
            state.winid = winid
            focus_window(winid)
            state.maps:save()
            set_maps()
            vim.notify("Winbender activated for window " .. tostring(winid), vim.log.levels.INFO)
        else
            vim.notify("No floating window found to activate Winbender", vim.log.levels.WARN)
        end
    else
        vim.notify("Winbender deactivated for window " .. tostring(state.winid), vim.log.levels.INFO)
        vim.api.nvim_set_current_win(state.old_winid)
        state.winid = nil
        state.old_winid = nil
        state.maps:restore()
    end
end

return M
