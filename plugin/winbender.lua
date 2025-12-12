vim.keymap.set('n', '<leader>f', function()
    require("winbender.core").toggle()
end, { desc = "Winbender: Toggle activation" })
