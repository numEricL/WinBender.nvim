local M = {}

local defaults = {
    keymaps = {
        focus_next = 'f',
        reset_window = 'r',
        shift_left = 'h',
        shift_right = 'l',
        shift_down = 'j',
        shift_up = 'k',
        increase_width = '>',
        decrease_width = '<',
        increase_height = '+',
        decrease_height = '-',
        anchor_NW = 'q',
        anchor_NE = 'w',
        anchor_SW = 'a',
        anchor_SE = 's',
    },
    step_size = {
        position = 1,
        size = 1,
    },
}

M.options = {}

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", defaults, opts or {})
end

return M
