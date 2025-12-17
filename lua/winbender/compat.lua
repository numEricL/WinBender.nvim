local M = {}

local initialized = false
local compat_has = {
    title = nil,
    footer = nil,
}

function M.init()
    if initialized then
        return
    else
        initialized = true
    end
    if vim.fn.has("nvim-0.10.0") == 1 then
        compat_has.title = true
        compat_has.footer = true
    else
        compat_has.title  = pcall(vim.api.nvim_win_set_config, 0, { title = "" })
        compat_has.footer = pcall(vim.api.nvim_win_set_config, 0, { footer = "" })
    end
end

local function has_title()
    M.init()
    return compat_has.title
end

local function has_footer()
    M.init()
    return compat_has.footer
end

-- neovim 0.7.2 returns a boolean table for row/col of floating windows
function M.nvim_win_get_config(winid)
    local win_config = vim.api.nvim_win_get_config(winid)
    win_config.row = type(win_config.row) == "table" and win_config.row[false] or win_config.row
    win_config.col = type(win_config.col) == "table" and win_config.col[false] or win_config.col
    return win_config
end

function M.nvim_win_set_config(winid, win_config)
    if not has_title() then
        win_config.title = nil
    end
    if not has_footer() then
        win_config.footer = nil
    end
    vim.api.nvim_win_set_config(winid, win_config)
end

return M
