local M = {}

local defaults = {
    toggle_key = '<leader>f',
    keymaps = {
        focus_next   = 'f',
        focus_prev   = 'F',
        reset_window = 'r',

        shift_left  = 'h',
        shift_down  = 'j',
        shift_up    = 'k',
        shift_right = 'l',

        increase_left  = 'H',
        increase_down  = 'J',
        increase_up    = 'K',
        increase_right = 'L',

        decrease_left  = '<c-l>',
        decrease_down  = '<c-k>',
        decrease_up    = '<c-j>',
        decrease_right = '<c-h>',

        increase_width  = '>',
        decrease_width  = '<',
        increase_height = '+',
        decrease_height = '-',

        anchor_NW = 'q',
        anchor_NE = 'w',
        anchor_SW = 'a',
        anchor_SE = 's',
    },
    step_size = {
        position = 5,
        size     = 5,
    },
    cyclops_opts = {
        accepts_count      = 1,
        accepts_register   = 0,
        accepts_input      = 0,
        persistent_count   = 1,
        absolute_direction = 0,
    },
}

M.options = defaults

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", defaults, opts or {})
end

return M
