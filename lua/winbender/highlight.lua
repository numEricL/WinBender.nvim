local core   = require("winbender.core")
local compat = require("winbender.compat")
local utils  = require("winbender.utils")
local state  = require("winbender.state")

local M = {}
local highlight_factor = 0.25

local augroup_name = "WinBenderHighlight"

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

local function update_window_highlight(winid)
    local silent = true
    if not state.validate_window(winid, silent) then
        return
    end

    local is_focused = (winid == core.get_current_window())

    if is_focused then
        local normal_hl = compat.nvim_get_hl(0, { name = "Normal" })
        local normal_bg = {
            gui = adjust_color_hex(string.format("#%06x", normal_hl.bg), highlight_factor),
            cterm = adjust_color_cterm(normal_hl.ctermbg, highlight_factor),
        }
        vim.api.nvim_set_hl(0, "WinBenderFocusedNormal", {
            bg = normal_bg.gui,
            ctermbg = normal_bg.cterm,
        })
        vim.wo[winid].winhighlight = "Normal:WinBenderFocusedNormal"
    else
        vim.wo[winid].winhighlight = state.get_highlight(winid)
    end
end

local function update_all_windows()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, winid in ipairs(wins) do
        update_window_highlight(winid)
    end
end

function M.restore(winid)
    local silent = true
    if not state.validate_window(winid, silent) then
        return
    end

    vim.wo[winid].winhighlight = state.get_highlight(winid)
end

function M.enable()
    update_window_highlight(core.get_current_window())

    local augroup = vim.api.nvim_create_augroup(augroup_name, { clear = true })
    vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
        group = augroup,
        callback = function()
            update_all_windows()
        end,
        desc = "WinBender: Update window highlights on focus change"
    })
end

function M.disable()
    vim.api.nvim_del_augroup_by_name(augroup_name)

    for winid, original_hl in pairs(state.get_all_highlights()) do
        local silent = true
        if  state.validate_window(winid, silent) then
            vim.wo[winid].winhighlight = original_hl
        end
    end
    state.clear_all_highlights()
end

return M
