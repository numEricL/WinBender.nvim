local M = {}

local compat = require("winbender.compat")

local init_winid = nil
local win_configs = {}

local function save_config(winid)
    if win_configs[winid] == nil then
        win_configs[winid] = compat.nvim_win_get_config(winid)
    end
end

function M.init(initial_winid)
    init_winid = initial_winid
    win_configs = {}
end

function M.active()
    return init_winid ~= nil
end

function M.initial_winid()
    return init_winid
end

function M.has_config(winid)
    return win_configs[winid] ~= nil
end

function M.get_config(winid)
    return win_configs[winid]
end

function M.validate_floating_window(winid, silent)
    if not vim.api.nvim_win_is_valid(winid) then
        if not silent then
            vim.notify("WinBender: Window " .. winid .. " is not valid", vim.log.levels.WARN)
        end
        return false
    end
    local win_config = compat.nvim_win_get_config(winid)
    if not win_config.relative or win_config.relative == "" then
        if not silent then
            vim.notify("WinBender: Window " .. winid .. " is not a floating window", vim.log.levels.WARN)
        end
        return false
    end
    save_config(winid)
    return true
end

-- TODO: save state of docked windows to allow restoring later
function M.validate_docked_window(winid, silent)
    if not vim.api.nvim_win_is_valid(winid) then
        if not silent then
            vim.notify("WinBender: Window " .. winid .. " is not valid", vim.log.levels.WARN)
        end
        return false
    end
    local win_config = compat.nvim_win_get_config(winid)
    if win_config.relative and win_config.relative ~= "" then
        if not silent then
            vim.notify("WinBender: Window " .. winid .. " is not a docked window", vim.log.levels.WARN)
        end
        return false
    end
    return true
end

function M.restore_config(winid)
    if win_configs[winid] == nil then
        return
    end
    compat.nvim_win_set_config(winid, win_configs[winid])
end

function M.exit()
    init_winid = nil
    for winid, saved_config in pairs(win_configs) do
        if vim.api.nvim_win_is_valid(winid) then
            local win_config = compat.nvim_win_get_config(winid)
            win_config.title = saved_config.title or ""
            win_config.footer = saved_config.footer or ""
            compat.nvim_win_set_config(winid, win_config)
        end
    end
end

return M
