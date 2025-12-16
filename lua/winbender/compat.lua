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

-- Extract numeric values from row/col (handle both plain numbers and tables
-- that are common on older Neovim versions)
function M.win_config_row_col(win_config)
    local row_val = type(win_config.row) == "table" and win_config.row[false] or win_config.row
    local col_val = type(win_config.col) == "table" and win_config.col[false] or win_config.col
    return row_val, col_val
end

return M
