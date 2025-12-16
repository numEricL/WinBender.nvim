local M = {}

local state = require("winbender.state")
local utils = require("winbender.utils")

local indexed_winids = {}
local reverse_lookup = {}

local function init_index()
    indexed_winids = {}
    reverse_lookup = {}
    local silent = true
    local i = 1
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, winid in ipairs(wins) do
        local win_config = vim.api.nvim_win_get_config(winid)
        if state.validate_floating_window(winid, silent) then
            indexed_winids[i] = winid
            reverse_lookup[winid] = i
            i = i + 1
        end
    end
end

function M.display(winid, index)
    local win_config = vim.api.nvim_win_get_config(winid)
    local title = state.get_config(winid).title
    win_config.title = utils.prepend_title(title, "[g" .. index .. "]")
    vim.api.nvim_win_set_config(winid, win_config)
end

function M.init()
    init_index()
    for index, winid in ipairs(indexed_winids) do
        M.display(winid, index)
    end
end

function M.get_winid(id)
    return indexed_winids[id]
end

function M.get_index(winid)
    return reverse_lookup[winid]
end

return M
