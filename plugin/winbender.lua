if vim.g.loaded_winbender then
    return
end
vim.g.loaded_winbender = true

function create_floaters()
    local old_winid = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    local opts = {
        relative = 'cursor',
        width = 40,
        height = 10,
        row = 5,
        col = 10,
        style = 'minimal',
        border = 'single',
    }
    local win = vim.api.nvim_open_win(buf, true, opts)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Window ID: " .. win })
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "Relative: " .. opts.relative })
    vim.api.nvim_set_current_win(old_winid)



    local buf = vim.api.nvim_create_buf(false, true)
    opts.relative = 'cursor'
    opts.border = 'bold'
    opts.col = 30
    local win = vim.api.nvim_open_win(buf, true, opts)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Window ID: " .. win })
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "Relative: " .. opts.relative })
    vim.api.nvim_set_current_win(old_winid)


    local buf = vim.api.nvim_create_buf(false, true)
    opts.relative = 'cursor'
    opts.border = 'double'
    opts.col = 90
    local win = vim.api.nvim_open_win(buf, true, opts)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Window ID: " .. win })
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "Relative: " .. opts.relative })
    vim.api.nvim_set_current_win(old_winid)
end

local function enable()
    local state = require("winbender.state")
    local core = require("winbender.core")
    local keymaps = require("winbender.keymaps")

    local winid_on_enable = vim.api.nvim_get_current_win()
    local winid = core.find_floating_window('backward')
    if winid then
        core.focus_window(winid)
        state.winid_on_enable = winid_on_enable
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
    vim.api.nvim_set_current_win(state.winid_on_enable)
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

vim.api.nvim_create_user_command('WinbenderToggle', function()
    toggle()
end, { desc = 'Toggle Winbender mode' })

vim.keymap.set('n', '<leader>f', toggle, { desc = "Winbender: Toggle activation" })
