if vim.g.loaded_winbender then
    return
end
vim.g.loaded_winbender = true

function create_floaters()
    local old_winid = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    local opts = {
        relative = 'editor',
        width = 40,
        height = 10,
        row = 5,
        col = 10,
        style = 'minimal',
        border = 'single',
    }
    local win = vim.api.nvim_open_win(buf, true, opts)
    opts.border = 'bold'
    opts.col = 60
    local win = vim.api.nvim_open_win(buf, true, opts)
    opts.border = 'double'
    opts.relative = 'cursor'
    local win = vim.api.nvim_open_win(buf, true, opts)
    vim.api.nvim_set_current_win(old_winid)
end


local function toggle()
    local core = require("winbender.core")
    local keymaps = require("winbender.keymaps")
    local state = require("winbender.state")
    if state.winid == nil then
        local old_winid = vim.api.nvim_get_current_win()
        local winid = core.focus_floating_window('backward')
        if winid then
            state.old_winid = old_winid
            state.winid = winid
            keymaps.save()
            keymaps.set_winbender_maps()
        else
            vim.notify("Winbender: No floating windows found", vim.log.levels.INFO)
        end
    else
        vim.notify("", vim.log.levels.INFO)
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
