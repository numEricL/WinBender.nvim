local M = {}

M.winid = nil
M.old_winid = nil
local win_configs = {}

function M.save_config(winid)
    if win_configs[winid] == nil then
        win_configs[winid] = vim.api.nvim_win_get_config(winid)
    end
end

function M.restore_config(winid)
    if win_configs[winid] == nil then
        return
    end
    vim.api.nvim_win_set_config(winid, win_configs[winid])
end

return M
