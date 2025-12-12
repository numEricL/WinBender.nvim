local M = {}

M.winid_on_enable = nil
local win_config = {}

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

return M
