local M = {}

local config  = require("winbender.config")

local function enable()
    local compat       = require("winbender.compat")
    local core         = require("winbender.core")
    local display      = require("winbender.display")
    local keymaps      = require("winbender.keymaps")
    local quick_access = require("winbender.quick_access")
    local state        = require("winbender.state")

    local initial_winid = vim.api.nvim_get_current_win()
    local winid = core.find_floating_window('forward')
    if winid then
        state.init(initial_winid)
        quick_access.init()

        local silent = true
        local wins = vim.api.nvim_tabpage_list_wins(0)
        for _, _winid in ipairs(wins) do
            if state.validate_floating_window(_winid, silent) then
                local win_config = compat.nvim_win_get_config(_winid)
                core.reposition_in_bounds(win_config)
                compat.nvim_win_set_config(_winid, win_config)
                display.win_labels(_winid)
            end
        end

        core.focus_window(winid)
        keymaps.save()
        keymaps.set_maps()
    else
       vim.notify("WinBender: No floating windows found", vim.log.levels.INFO)
    end
end

local function disable()
    local state   = require("winbender.state")
    local core    = require("winbender.core")
    local keymaps = require("winbender.keymaps")

    core.focus_window(state.initial_winid())
    state.exit()
    keymaps.restore_maps()
end

function M.toggle()
    local state   = require("winbender.state")
    if not state.active() then
        enable()
    else
        disable()
    end
end

function M.setup(opts)
    config.setup(opts)
    if config.options.toggle_key then
        vim.keymap.set("n", config.options.toggle_key, "<Plug>(winbender-toggle)", { desc = "WinBender: Toggle activation" })
    end
end

return M
