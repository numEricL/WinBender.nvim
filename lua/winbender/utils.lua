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

function M.math_lp_norm(a, b, p)
    local sum = 0
    for i = 1, #a do
        sum = sum + math.abs(a[i] - b[i]) ^ p
    end
    return sum ^ (1 / p)
end

function M.math_nearest_neighbor(value, array, metric)
    if #array == 0 then
        return nil
    end

    if not metric then
        if type(value) == "table" then
            metric = function(a, b) return lp_norm(a, b, 2) end
        else
            metric = function(a, b) return math.abs(a - b) end
        end
    end

    local nearest = array[1]
    local min_dist = metric(value, nearest)

    for _, v in ipairs(array) do
        local dist = metric(value, v)
        if dist < min_dist then
            min_dist = dist
            nearest = v
        end
    end

    return nearest
end

return M
