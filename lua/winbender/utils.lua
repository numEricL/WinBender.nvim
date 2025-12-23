local M = {}

function M.any(tbl, predicate)
    predicate = predicate or function(v) return v end
    for _, v in pairs(tbl) do
        if predicate(v) then
           return true
        end
    end
    return false
end

function M.count_truthy(tbl)
    local count = 0
    for _, v in pairs(tbl) do
        if v then count = count + 1 end
    end
    return count
end

function M.math_round(num)
    return num >= 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
end

function M.math_clamp(num, min, max)
    return math.min(math.max(num, min), max)
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
            metric = function(a, b) return M.math_lp_norm(a, b, 2) end
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

function M.math_area_box_intersection(box1, box2)
    -- box1 and box2 are tables with: {x, y, dx, dy} where (x,y) is top-left
    -- corner, dx is width, dy is height. Returns the area of intersection
    -- between the two boxes.

    local x1_left = box1.x
    local x1_right = box1.x + box1.dx
    local y1_top = box1.y
    local y1_bottom = box1.y + box1.dy

    local x2_left = box2.x
    local x2_right = box2.x + box2.dx
    local y2_top = box2.y
    local y2_bottom = box2.y + box2.dy

    local overlap_left = math.max(x1_left, x2_left)
    local overlap_right = math.min(x1_right, x2_right)
    local overlap_width = overlap_right - overlap_left

    local overlap_top = math.max(y1_top, y2_top)
    local overlap_bottom = math.min(y1_bottom, y2_bottom)
    local overlap_height = overlap_bottom - overlap_top

    if overlap_width <= 0 or overlap_height <= 0 then
        return 0
    end

    return overlap_width * overlap_height
end

return M
