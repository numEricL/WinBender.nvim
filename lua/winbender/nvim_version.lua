local M = {}

local version_has_title = nil
local version_has_footer = nil

function M.init()
    version_has_title  = pcall(vim.api.nvim_win_set_config, 0, { title = "" })
    version_has_footer = pcall(vim.api.nvim_win_set_config, 0, { footer = "" })
end

function M.has_title()
    return version_has_title
end

function M.has_footer()
    return version_has_footer
end

return M
