local M = {}

local options = {init = false}

local defaults = {
    init = true,
    keymaps = {
        focus_next = 'f',
        focus_prev = 'F',
        reset_window = 'r',

        shift_left = 'h',
        shift_down = 'j',
        shift_up = 'k',
        shift_right = 'l',

        increase_left = 'H',
        increase_down = 'J',
        increase_up = 'K',
        increase_right = 'L',

        decrease_left = '<c-h>',
        decrease_down = '<c-j>',
        decrease_up = '<c-k>',
        decrease_right = '<c-l>',

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


function M.setup(opts)
    options = vim.tbl_deep_extend("force", defaults, opts or {})
end

function M.get_options()
    if not options.init then
        M.setup()
    end
    return options
end

return M
