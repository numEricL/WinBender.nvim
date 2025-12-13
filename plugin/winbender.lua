if vim.g.loaded_winbender then
    return
end
vim.g.loaded_winbender = true

local function enable()
    local state = require("winbender.state")
    local core = require("winbender.core")
    local keymaps = require("winbender.keymaps")

    local winid_on_enable = vim.api.nvim_get_current_win()
    local winid = core.find_floating_window('forward')
    if winid then
        state.clear_win_configs()
        state.index_floating_windows()
        state.update_titles_with_quick_access()
        core.focus_window(winid)
        state.winid_on_enable = winid_on_enable
        keymaps.save()
        keymaps.set_winbender_maps()
    else
        vim.notify("WinBender: No floating windows found", vim.log.levels.INFO)
    end
end

local function disable()
    local state = require("winbender.state")
    local core = require("winbender.core")
    local keymaps = require("winbender.keymaps")

    vim.api.nvim_set_current_win(state.winid_on_enable)
    state.restore_titles()
    state.winid_on_enable = nil
    keymaps.restore()
end

local function toggle()
    local state = require("winbender.state")
    if state.winid_on_enable == nil then
        enable()
    else
        disable()
    end
end

vim.api.nvim_create_user_command('WinBenderToggle', function()
    toggle()
end, { desc = 'WinBender: Toggle activation' })

local config = require("winbender.config")
local opts = config.get_options()
if opts.toggle_key then
    vim.keymap.set('n', opts.toggle_key, toggle, { desc = "WinBender: Toggle activation" })
end
