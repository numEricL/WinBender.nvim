if vim.g.loaded_winbender then
    return
end
vim.g.loaded_winbender = true

local function enable()
    local state = require("winbender.state")
    local core = require("winbender.core")
    local keymaps = require("winbender.keymaps")

    local old_winid = vim.api.nvim_get_current_win()
    local winid = core.find_floating_window('backward')
    if winid then
        core.focus_window(winid)
        state.old_winid = old_winid
        state.winid = winid
        keymaps.save()
        keymaps.set_winbender_maps()
    else
        vim.notify("Winbender: No floating windows found", vim.log.levels.INFO)
    end
end

local function disable()
    local state = require("winbender.state")
    local core = require("winbender.core")
    local keymaps = require("winbender.keymaps")

    vim.notify("", vim.log.levels.INFO)
    vim.api.nvim_set_current_win(state.old_winid)
    state.winid = nil
    state.old_winid = nil
    keymaps.restore()
end

local function toggle()
    local state = require("winbender.state")
    if state.winid == nil then
        enable()
    else
        disable()
    end
end

vim.api.nvim_create_user_command('WinbenderToggle', function()
    toggle()
end, { desc = 'Toggle Winbender mode' })

vim.keymap.set('n', '<leader>f', toggle, { desc = "Winbender: Toggle activation" })
