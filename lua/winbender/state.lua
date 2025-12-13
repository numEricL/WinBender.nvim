local M = {}

M.winid_on_enable = nil
local quick_access_index = {}
local win_config = {}

function M.clear_win_configs()
    win_config = {}
end

function M.save_config(winid)
    if win_config[winid] == nil then
        win_config[winid] = vim.api.nvim_win_get_config(winid)
    end
end

function M.restore_config(winid)
    if win_config[winid] == nil then
        return
    end
    vim.api.nvim_win_set_config(winid, win_config[winid])
end

function M.index_floating_windows()
    quick_access_index = {}
    local i = 1
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, winid in ipairs(wins) do
        local config = vim.api.nvim_win_get_config(winid)
        if config.relative ~= "" then
            quick_access_index[i] = {winid = winid, title = config.title}
            i = i + 1
        end
    end
end

local function copy_table(t)
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function M.update_titles_with_quick_access()
    for i, win in ipairs(quick_access_index) do
        local new_title = nil
        local label = "[g" .. i .. "] "
        if type(win.title) == "table" then
            new_title = copy_table(win.title)
            table.insert(new_title, 1, {label})
        elseif type(win.title) == "string" then
            new_title = label .. win.title
        end

        local config = vim.api.nvim_win_get_config(win.winid)
        config.title = new_title
        vim.api.nvim_win_set_config(win.winid, config)
    end
end

function M.restore_titles()
    for _, win in ipairs(quick_access_index) do
        if vim.api.nvim_win_is_valid(win.winid) then
            local config = vim.api.nvim_win_get_config(win.winid)
            config.title = win.title
            vim.api.nvim_win_set_config(win.winid, config)
        end
    end
end

function M.quick_access_winid(id)
    return quick_access_index[id].winid
end

return M
