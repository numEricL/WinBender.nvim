local M = {}

local config  = require("winbender.config")

local function enable()
    local state   = require("winbender.state")
    local core    = require("winbender.core")
    local keymaps = require("winbender.keymaps")
    local mouse   = require("winbender.mouse")

    local winid_on_enable = vim.api.nvim_get_current_win()
    local winid = core.find_floating_window('forward')
    if winid then
        state.clear_win_configs()
        state.index_floating_windows()
        state.update_titles_with_quick_access()
        core.focus_window(winid)
        state.winid_on_enable = winid_on_enable
        keymaps.save()
        keymaps.set_maps()
        if config.options.mouse_enabled then
            mouse.save()
            mouse.set_maps()
        end
    else
        vim.notify("WinBender: No floating windows found", vim.log.levels.INFO)
    end
end

local function disable()
    local state   = require("winbender.state")
    local core    = require("winbender.core")
    local keymaps = require("winbender.keymaps")
    local mouse   = require("winbender.mouse")

    core.focus_window(state.winid_on_enable)
    state.restore_titles()
    state.winid_on_enable = nil
    keymaps.restore_maps()
    if config.options.mouse_enabled then
        mouse.restore_maps()
    end
end

function M.toggle()
    local state   = require("winbender.state")

    if state.winid_on_enable == nil then
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
