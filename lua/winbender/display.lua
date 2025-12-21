local M = {}

local compat       = require("winbender.compat")
local core         = require("winbender.core")
local quick_access = require("winbender.quick_access")
local state        = require("winbender.state")
local utils        = require("winbender.utils")

function M.win_labels(winid)
    local win_config = compat.nvim_win_get_config(winid)

    local qa_index = quick_access.get_index(winid)
    if qa_index then
        local title = state.has_config(winid) and state.get_config(winid).title or ""
        win_config.title = utils.prepend_label(title, "[g" .. qa_index .. "]")
    end

    local footer = state.get_config(winid) and state.get_config(winid).footer or ""
    local label = ""
    -- label = "[" .. winid .. "]"

    local winid_closest = core.find_closest_docked_window(winid)
    local orientation = core.orientation_new_docked_window(winid, winid_closest)
    label = "[" .. winid_closest .. "]"
    label = label .. "[" .. orientation:sub(1,1) .. "]"
    label = label .. "[" .. win_config.anchor .. "]"
    label = label .. "(" .. win_config.row .. "," .. win_config.col .. ")"
    win_config.footer = utils.prepend_label(footer, label)
    compat.nvim_win_set_config(winid, win_config)
end

return M
