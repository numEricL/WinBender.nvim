local compat       = require("winbender.compat")
local dock         = require("winbender.dock")
local options      = require("winbender.config").options
local quick_access = require("winbender.quick_access")
local state        = require("winbender.state")

local M = {}

local ns_id = vim.api.nvim_create_namespace("winbender_display")

-- zero indexed
local function win_line(winid, expr)
    return vim.api.nvim_win_call(winid, function()
        return vim.fn.line(expr) - 1
    end)
end

local function has_top_border(win_config)
    local border = win_config.border
    if border then
        if type(border) == "string" then
            return true
        elseif type(border) == "table" then
            return border[2] ~= ""
        end
    end
    return false
end

local function has_bottom_border(win_config)
    local border = win_config.border
    if border then
        if type(border) == "string" then
            return true
        elseif type(border) == "table" then
            return border[6] ~= ""
        end
    end
    return false
end

local function prepend_border_label(title, label)
    if type(title) == "table" then
        local new_title = vim.deepcopy(title)
        table.insert(new_title, 1, {' '})
        table.insert(new_title, 1, {label, options.quick_access_hl})
        return new_title
    elseif type(title) == "string" then
        return { {label, options.quick_access_hl}, {' ' .. title} }
    else
        return { {label, options.quick_access_hl} }
    end
end

local function set_title(winid, title)
    local cfg = compat.nvim_win_get_config(winid)
    if has_top_border(cfg) then
        local stored_title = state.has_config(winid) and state.get_config(winid).title or ""
        cfg.title = prepend_border_label(stored_title, title)
        compat.nvim_win_set_config(winid, cfg)
    else
        -- virtual text fallback
        local topline = win_line(winid, 'w0')
        local bufnr = vim.api.nvim_win_get_buf(winid)
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, topline, 0, {
            virt_text = {{ title, options.quick_access_hl }},
            virt_text_pos = "overlay",
        })
    end
end

local function set_footer(winid, footer)
    local cfg = compat.nvim_win_get_config(winid)
    if has_bottom_border(cfg) then
        local stored_footer = state.get_config(winid) and state.get_config(winid).footer or ""
        cfg.footer = prepend_border_label(stored_footer, footer)
        compat.nvim_win_set_config(winid, cfg)
    else
        -- virtual text fallback
        local topline = win_line(winid, 'w0')
        local botline = win_line(winid, 'w$')

        local num_filler_lines = vim.api.nvim_win_get_height(winid) - (botline - topline + 1)
        local virt_filler_lines = {}
        local last_line_filler = ""
        if num_filler_lines > 0 then
            for _ = 1, num_filler_lines do
                table.insert(virt_filler_lines, {{""}})
            end
            last_line_filler = string.rep(" ", vim.api.nvim_win_get_width(winid))
        end

        local bufnr = vim.api.nvim_win_get_buf(winid)
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, botline, 0, {
            virt_text = {{ footer, options.quick_access_hl }, {last_line_filler}},
            virt_text_pos = "overlay",
            virt_lines = virt_filler_lines,
            virt_lines_above = true,
        })
    end
end

local function clear_virtual_text(winid)
    local silent = true
    if not state.validate_window(winid, silent) then
        return
    end
    local bufnr = vim.api.nvim_win_get_buf(winid)
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

function M.clear_labels(winid)
    clear_virtual_text(winid)
end

function M.clear_all_labels()
    for winid, _ in pairs(state.get_all_configs()) do
        M.clear_labels(winid)
    end
end

function M.labels(winid)
    if not state.validate_window(winid) then
        return
    end

    local title = ""
    local qa_index = quick_access.get_index(winid)
    if qa_index then
        title = "[g" .. qa_index .. "]"
    end
    title = title .. "[" .. winid .. "]"
    local footer = ""

    local silent = true
    if state.validate_floating_window(winid, silent) then
        local cfg = compat.nvim_win_get_config(winid)
        local winid_closest = dock.find_closest_docked_window(winid)
        local orientation = dock.orientation_new_docked_window(winid, winid_closest)
        footer = "[" .. winid_closest .. "]"
        footer = footer .. "[" .. string.upper(orientation:sub(1,1)) .. "]"
        footer = footer .. "[" .. cfg.anchor .. "]"
        footer = footer .. "(" .. cfg.row .. "," .. cfg.col .. ")"
    end

    M.clear_labels(winid)
    set_title(winid, title)
    set_footer(winid, footer)
end

return M
