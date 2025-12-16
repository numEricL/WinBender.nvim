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

return M
