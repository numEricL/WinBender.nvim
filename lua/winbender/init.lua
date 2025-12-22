local M = {}

local config = require("winbender.config")

local function enable()
    local core         = require("winbender.core")
    local display      = require("winbender.display")
    local keymaps      = require("winbender.keymaps")
    local quick_access = require("winbender.quick_access")
    local state        = require("winbender.state")
    local highlight    = require("winbender.highlight")

    local initial_winid = vim.api.nvim_get_current_win()
    local winid = core.find_floating_window('forward')
    state.init(initial_winid)
    quick_access.init()

    local silent = true
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, _winid in ipairs(wins) do
        display.labels(_winid)
        if state.validate_floating_window(_winid, silent) then
            core.reposition_in_bounds(_winid)
        end
    end

    core.focus_window(winid, silent)
    keymaps.save()
    keymaps.set_maps()
    highlight.enable()
end

local function disable()
    local state     = require("winbender.state")
    local core      = require("winbender.core")
    local display   = require("winbender.display")
    local keymaps   = require("winbender.keymaps")
    local highlight = require("winbender.highlight")

    highlight.disable()
    keymaps.restore_maps()
    display.clear_all_labels()
    core.focus_window(state.initial_winid())
    state.exit()
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
