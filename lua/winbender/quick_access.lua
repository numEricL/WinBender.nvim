local M = {}

local state  = require("winbender.state")

local indexed_winids = {}
local reverse_lookup = {}

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
