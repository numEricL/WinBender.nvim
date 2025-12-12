if vim.g.loaded_winbender then
    return
end
vim.g.loaded_winbender = true

local function toggle()
    local core = require("winbender.core")
    local keymaps = require("winbender.keymaps")
    local state = require("winbender.state")
    if state.winid == nil then
        local winid = core.find_floating_window()
        if winid then
            state.old_winid = vim.api.nvim_get_current_win()
            state.winid = winid
            core.focus_window(winid)
            keymaps.save()
            keymaps.set_winbender_maps()
            vim.notify("Winbender activated for window " .. tostring(winid), vim.log.levels.INFO)
        else
            vim.notify("No floating window found to activate Winbender", vim.log.levels.WARN)
        end
    else
        vim.notify("Winbender deactivated for window " .. tostring(state.winid), vim.log.levels.INFO)
        vim.api.nvim_set_current_win(state.old_winid)
        state.winid = nil
        state.old_winid = nil
        keymaps.restore()
    end
end

vim.api.nvim_create_user_command('WinbenderToggle', function()
    toggle()
end, { desc = 'Toggle Winbender mode' })

vim.keymap.set('n', '<leader>f', toggle, { desc = "Winbender: Toggle activation" })
