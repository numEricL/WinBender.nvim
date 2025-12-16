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

return M
