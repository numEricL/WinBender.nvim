local M = {}

local version_has_title = nil
local version_has_footer = nil

function M.init()
    version_has_title  = pcall(vim.api.nvim_win_set_config, 0, { title = "" })
    version_has_footer = pcall(vim.api.nvim_win_set_config, 0, { footer = "" })
end

function M.has_title()
    return version_has_title
end

function M.has_footer()
    return version_has_footer
end

-- neovim 0.7.2 returns a boolean table for row/col of floating windows
function M.nvim_win_get_config(winid)
    local win_config = vim.api.nvim_win_get_config(winid)
    win_config.row = type(win_config.row) == "table" and win_config.row[false] or win_config.row
    win_config.col = type(win_config.col) == "table" and win_config.col[false] or win_config.col
    return win_config
end

function M.nvim_win_set_config(winid, win_config)
    if not version_has_title then
        win_config.title = nil
    end
    if not version_has_footer then
        win_config.footer = nil
    end
    vim.api.nvim_win_set_config(winid, win_config)
end

return M
