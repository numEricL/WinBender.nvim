local M = {}

local options = require("winbender.config").options

function M.prepend_label(title, label)
    if type(title) == "table" then
        local new_title = vim.deepcopy(title)
        table.insert(new_title, 1, {' '})
        table.insert(new_title, 1, {label, options.quick_access_hl})
        return new_title
    elseif type(title) == "string" then
        return { {label, options.quick_access_hl}, {' ' .. title} }
    else
        return { {label, options.quick_access_hl} }
    end
end

function M.math_round(num)
    return num >= 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
end

return M
