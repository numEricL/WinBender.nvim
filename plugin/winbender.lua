vim.api.nvim_create_user_command('WinBenderToggle', function()
    require('winbender').toggle()
end, { desc = 'WinBender: Toggle activation' })

vim.keymap.set('n', '<plug>(winbender-toggle)', function()
    require('winbender').toggle()
end, { desc = 'WinBender: Toggle activation' })
