local M = {}

local state  = require("winbender.state")
local utils  = require("winbender.utils")
local compat = require("winbender.compat")

local indexed_winids = {}
local reverse_lookup = {}

function M.display(winid, index)
    local win_config = compat.nvim_win_get_config(winid)
    local title = state.get_config(winid) and state.get_config(winid).title or ""
    win_config.title = utils.prepend_label(title, "[g" .. index .. "]")
    compat.nvim_win_set_config(winid, win_config)
end

function M.init()
    indexed_winids = {}
    reverse_lookup = {}
    local silent = true
    local i = 1
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, winid in ipairs(wins) do
        if state.validate_floating_window(winid, silent) then
            indexed_winids[i] = winid
            reverse_lookup[winid] = i
            M.display(winid, i)
            i = i + 1
        end
    end
end

function M.get_winid(id)
    return indexed_winids[id]
end

function M.get_index(winid)
    return reverse_lookup[winid]
end

return M
