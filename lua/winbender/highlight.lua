local core   = require("winbender.core")
local compat = require("winbender.compat")
local utils  = require("winbender.utils")
local state  = require("winbender.state")

local M = {}
local highlight_factor = 0.25
local augroup_name = "WinBenderHighlight"
local winhighlights = {}
local adjusted_winhighlights = {}

local function rgb_to_hex(r, g, b)
    return string.format("#%02x%02x%02x", r, g, b)
end

local function hex_to_rgb(hex)
    hex = hex:gsub("#", "")
    return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function is_light_rgb(r, g, b)
    -- assume r, g, b are in 0-255 range
    local luminance = 0.299 * r + 0.587 * g + 0.114 * b
    return luminance > 127.5
end

local function is_light_cterm(color)
    if color >= 0 and color < 16 then
        return color >= 8
    elseif color >= 16 and color < 232 then
        local idx = color - 16
        local r = math.floor(idx / 36)
        local g = math.floor((idx % 36) / 6)
        local b = idx % 6
        -- Map 0–5 to 0, 95, 135, 175, 215, 255
        local function level(n)
            return n == 0 and 0 or 95 + 40 * (n - 1)
        end
        return is_light_rgb(level(r), level(g), level(b))
    elseif color >= 232 and color < 256 then
        return (color - 232) > 11.5
    end
end

local function adjust_color_hex(hex, factor)
    local r, g, b = hex_to_rgb(hex)

    if is_light_rgb(r, g, b) then
        r = math.max(0, math.floor(r * (1 - factor)))
        g = math.max(0, math.floor(g * (1 - factor)))
        b = math.max(0, math.floor(b * (1 - factor)))
    else
        r = math.min(255, math.floor(r + (255 - r) * factor))
        g = math.min(255, math.floor(g + (255 - g) * factor))
        b = math.min(255, math.floor(b + (255 - b) * factor))
    end

    return rgb_to_hex(r, g, b)
end

local function adjust_ansi_color(color_num)
    return (color_num + 8) % 16
end

local function adjust_greyscale_color(color_num, factor)
    -- assumed between 232 and 255 (24 shades of grey)
    local grey_index = color_num - 232
    local is_light = grey_index > 11.5
    local sign = is_light and -1 or 1
    local factor_index = sign*math.max(1, utils.math_round(factor*24))
    local adjusted_index = utils.math_clamp(grey_index + factor_index, 0, 23)
    return 232 + adjusted_index
end

local function adjust_256_color(color_num, factor)
    local base_index = color_num - 16
    local b_index = base_index % 6
    local g_index = math.floor((base_index / 6) % 6)
    local r_index = math.floor(base_index / 36)

    local is_light = is_light_cterm(color_num)
    local sign = is_light and -1 or 1
    local factor_index = sign*math.max(1, utils.math_round(factor*6))
    local adjust_b_index = utils.math_clamp(b_index + factor_index, 0, 5)
    local adjust_g_index = utils.math_clamp(g_index + factor_index, 0, 5)
    local adjust_r_index = utils.math_clamp(r_index + factor_index, 0, 5)
    return 16 + adjust_r_index * 36 + adjust_g_index * 6 + adjust_b_index
end

local function adjust_color_cterm(color_num, factor)
    if color_num >= 0 and color_num <= 15 then
        return adjust_ansi_color(color_num)
    elseif color_num >= 232 and color_num <= 255 then
        return adjust_greyscale_color(color_num, factor)
    elseif color_num >= 16 and color_num <= 231 then
        return adjust_256_color(color_num, factor)
    end
    return color_num
end

local function adjust_highlight_group(group_name, factor)
    local hl = compat.nvim_get_hl(0, { name = group_name })
    if not hl.bg then
        return {}
    end

    local adjusted_bg = {
        gui = adjust_color_hex(string.format("#%06x", hl.bg), factor),
        cterm = adjust_color_cterm(hl.ctermbg, factor),
    }

    return {
        bg = adjusted_bg.gui,
        ctermbg = adjusted_bg.cterm,
    }
end

local function get_local_highlight_groups(winid)
    local hl_dict = {
        ColorColumn  = "ColorColumn",
        CursorLine   = "CursorLine",
        CursorLineNr = "CursorLineNr",
        EndOfBuffer  = "EndOfBuffer",
        FoldColumn   = "FoldColumn",
        LineNr       = "LineNr",
        NonText      = "NonText",
        Normal       = "Normal",
        SignColumn   = "SignColumn",
    }

    local pairs = vim.split(vim.wo[winid].winhighlight, ",")
    for _, pair in ipairs(pairs) do
        local parts = vim.split(pair, ":")
        if hl_dict[parts[1]] then
            hl_dict[parts[1]] = parts[2]
        end
    end
    return hl_dict
end

local function concat_winhighlight_dict(hl_dict)
    local winhighlight = {}
    for hl_from, hl_to in pairs(hl_dict) do
        table.insert(winhighlight, hl_from .. ":" .. hl_to)
    end
    return table.concat(winhighlight, ",")
end

local function register_adjusted_hl_group(hl_group)
    if vim.fn.hlexists("WinBender" .. hl_group) == 0 then
        local adjusted_hl = adjust_highlight_group(hl_group, highlight_factor)
        vim.api.nvim_set_hl(0, "WinBender" .. hl_group, adjusted_hl)
    end
    return "WinBender" .. hl_group
end

local function store_winhighlight(winid)
    if not winhighlights[winid] then
        winhighlights[winid] = vim.wo[winid].winhighlight
    end
end

local function get_stored_winhighlight(winid)
    store_winhighlight(winid)
    return winhighlights[winid]
end

local function get_adjusted_winhighlight(winid)
    if adjusted_winhighlights[winid] then
        return adjusted_winhighlights[winid]
    end

    local hl_groups = get_local_highlight_groups(winid)
    for hl_from, hl_to in pairs(hl_groups) do
        hl_groups[hl_from] = register_adjusted_hl_group(hl_to)
    end
    adjusted_winhighlights[winid] = concat_winhighlight_dict(hl_groups)
    return adjusted_winhighlights[winid]
end

local function update_window_highlight(winid)
    local silent = true
    if not state.validate_window(winid, silent) then
        return
    end
    store_winhighlight(winid)

    local is_focused = (winid == core.get_current_window())
    if is_focused then
        vim.wo[winid].winhighlight = get_adjusted_winhighlight(winid)
    else
        vim.wo[winid].winhighlight = get_stored_winhighlight(winid)
    end
end

function M.restore(winid)
    local silent = true
    if not state.validate_window(winid, silent) then
        return
    end

    vim.wo[winid].winhighlight = get_stored_winhighlight(winid)
end

function M.enable()
    update_window_highlight(core.get_current_window())

    local augroup = vim.api.nvim_create_augroup(augroup_name, { clear = true })
    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        group = augroup,
        callback = function()
            local old_winid = vim.fn.win_getid(vim.fn.winnr("#"))
            local new_winid = vim.api.nvim_get_current_win()
            update_window_highlight(old_winid)
            update_window_highlight(new_winid)
        end,
        desc = "WinBender: Update window highlights on focus change"
    })
    vim.api.nvim_create_autocmd({ "WinNew" }, {
        group = augroup,
        callback = function()
            local new_winid = vim.api.nvim_get_current_win()
            local old_winid = vim.fn.win_getid(vim.fn.winnr("#"))
            vim.wo[new_winid].winhighlight = get_stored_winhighlight(old_winid)
        end,
        desc = "WinBender: Don't highlight new windows"
    })
end

function M.disable()
    vim.api.nvim_del_augroup_by_name(augroup_name)

    for winid, original_hl in pairs(winhighlights) do
        local silent = true
        if  state.validate_window(winid, silent) then
            vim.wo[winid].winhighlight = original_hl
        end
    end
    winhighlights = {}
    adjusted_winhighlights = {}
end

return M
