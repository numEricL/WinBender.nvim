local M = {}

local defaults = {
    toggle_key = nil,
    mouse_enabled = true,
    quick_access_hl = 'WarningMsg',
    cell_pixel_ratio_w_to_h = 12/26,
    keymaps = {
        focus_next_float = 'f',
        focus_prev_float = 'F',
        focus_next_dock  = 'n',
        focus_prev_dock  = 'N',
        reset_window     = 'u',

        move_left  = 'h',
        move_down  = 'j',
        move_up    = 'k',
        move_right = 'l',

        increase_left  = 'H',
        increase_down  = 'J',
        increase_up    = 'K',
        increase_right = 'L',

        decrease_left  = '<c-l>',
        decrease_down  = '<c-k>',
        decrease_up    = '<c-j>',
        decrease_right = '<c-h>',

        snap_left  = nil,
        snap_down  = nil,
        snap_up    = nil,
        snap_right = nil,

        anchor_NW = 'q',
        anchor_NE = 'w',
        anchor_SW = 'a',
        anchor_SE = 's',
    },
    step_size = {
        position_x = 5,
        position_y = 3,
        size_x     = 5,
        size_y     = 3,
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
