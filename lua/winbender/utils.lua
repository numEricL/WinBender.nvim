local M = {}

local options = require("winbender.config").options

local function copy_table(t)
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function M.prepend_title(title, label)
    if type(title) == "table" then
        local new_title = copy_table(title)
        table.insert(new_title, 1, {' '})
        table.insert(new_title, 1, {label,options.quick_access_hl})
        return new_title
    elseif type(title) == "string" then
        return { {label, options.quick_access_hl}, {' ' .. title} }
    else
        return { {label, options.quick_access_hl} }
    end
end

-- Extract numeric values from row/col (handle both plain numbers and tables
-- that are common on older Neovim versions)
function M.win_config_row_col(win_config)
    local row_val = type(win_config.row) == "table" and win_config.row[false] or win_config.row
    local col_val = type(win_config.col) == "table" and win_config.col[false] or win_config.col
    return row_val, col_val
end

return M
