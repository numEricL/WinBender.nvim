local compat = require("winbender.compat")
local state  = require("winbender.state")
local win    = require("winbender.win")

local M = {}

function M.swap_floating_windows(winid1, winid2)
    local cfg1 = compat.nvim_win_get_config(winid1)
    local cfg2 = compat.nvim_win_get_config(winid2)

    -- swaps anchor, position, and size
    local anchor1 = cfg1.anchor
    local row1, col1 = cfg1.row, cfg1.col
    local width1, height1 = cfg1.width, cfg1.height

    cfg1.anchor = cfg2.anchor
    cfg1.row, cfg1.col = cfg2.row, cfg2.col
    cfg1.width, cfg1.height = cfg2.width, cfg2.height

    cfg2.anchor = anchor1
    cfg2.width, cfg2.height = width1, height1
    cfg2.row, cfg2.col = row1, col1

    compat.nvim_win_set_config(winid1, cfg1)
    compat.nvim_win_set_config(winid2, cfg2)
end

-- node = {
    --     type = "row" | "col" | "leaf",
    --     winid = number, -- only for leaf
    --     parent = node | nil,
    --     index = number | nil, -- index in parent's children
    --     [1] = node,
    --     [2] = node,
    --     ...
    -- }
local function build_layout_tree(layout)
    local function recurse(parent)
        local node = { type = parent[1], winid = nil, parent = nil, index = nil, children = nil }

        if node.type == "leaf" then
            node.winid = parent[2]
        else
            node.children = {}
            for i, child in ipairs(parent[2]) do
                node.children[i] = recurse(child)
                node.children[i].parent = node
                node.children[i].index = i
            end
        end
        return node
    end

    return recurse(layout)
end

local function find_leaf(node, winid)
    if node.type == "leaf" then
        return (node.winid == winid) and node or nil
    end
    for _, child in ipairs(node.children) do
        local result = find_leaf(child, winid)
        if result then
            return result
        end
    end
end

function M.swap_docked_windows(winid1, winid2)
    local tree = build_layout_tree(vim.fn.winlayout())

    local node1 = find_leaf(tree, winid1)
    local node2 = find_leaf(tree, winid2)

    local function type(node)
        return node.parent and node.parent.type or "row"
    end

    local temp_split = vim.api.nvim_open_win(0, false, {
        win = winid1,
        split = type(node1) == "row" and "below" or "right",
        width=1,
        height=1,
    })

    vim.fn.win_splitmove(winid1, winid2, {
        vertical = type(node2) == "col",
        rightbelow = true,
    })
    vim.fn.win_splitmove(winid2, temp_split, {
        vertical = type(node1) == "col",
        rightbelow = true,
    })
    vim.api.nvim_win_close(temp_split, true)
end

local function swap_windows_fallback(winid1, winid2)
    local buf1 = vim.api.nvim_win_get_buf(winid1)
    local opt1 = win.get_options(winid1)
    local var1 = win.get_variables(winid1)
    local view1 = win.get_view(winid1)

    local buf2 = vim.api.nvim_win_get_buf(winid2)
    local opt2 = win.get_options(winid2)
    local var2 = win.get_variables(winid2)
    local view2 = win.get_view(winid2)

    vim.api.nvim_win_set_buf(winid1, buf2)
    win.set_options(winid1, opt2)
    win.set_variables(winid1, var2)
    win.set_view(winid1, view2)

    vim.api.nvim_win_set_buf(winid2, buf1)
    win.set_options(winid2, opt1)
    win.set_variables(winid2, var1)
    win.set_view(winid2, view1)
end

function swap_windows(winid1, winid2)
    local silent = true
    if state.validate_floating_window(winid1, silent) and
      state.validate_floating_window(winid2, silent) then
       M.swap_floating_windows(winid1, winid2)
    elseif state.validate_docked_window(winid1, silent) and
          state.validate_docked_window(winid2, silent) then
       M.swap_docked_windows(winid1, winid2)
    else
        swap_windows_fallback(winid1, winid2)
    end
end

return M
