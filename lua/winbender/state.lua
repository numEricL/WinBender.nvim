local M = {}

local compat    = require("winbender.compat")

local init_winid = nil
local win_configs = {}
local win_highlights = {}

local function save_config(winid)
    if win_configs[winid] == nil then
        win_configs[winid] = compat.nvim_win_get_config(winid)
    end
    if win_highlights[winid] == nil then
        win_highlights[winid] = vim.wo[winid].winhighlight
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

function M.get_all_configs()
    return win_configs
end

function M.get_highlight(winid)
    return win_highlights[winid]
end

function M.get_all_highlights()
    return win_highlights
end

function M.clear_all_highlights()
    win_highlights = {}
end

function M.validate_floating_window(winid, silent)
    if not winid then
        if not silent then
            vim.notify("WinBender: Window ID is nil", vim.log.levels.WARN)
        end
        return false
    end
    if not vim.api.nvim_win_is_valid(winid) then
        if not silent then
            vim.notify("WinBender: Window " .. winid .. " is not valid", vim.log.levels.WARN)
        end
        return false
    end
    local cfg = compat.nvim_win_get_config(winid)
    if not cfg.relative or cfg.relative == "" then
        if not silent then
            vim.notify("WinBender: Window " .. winid .. " is not a floating window", vim.log.levels.WARN)
        end
        return false
    end
    save_config(winid)
    return true
end

function M.validate_docked_window(winid, silent)
    if not winid then
        if not silent then
            vim.notify("WinBender: Window ID is nil", vim.log.levels.WARN)
        end
        return false
    end
    if not vim.api.nvim_win_is_valid(winid) then
        if not silent then
            vim.notify("WinBender: Window " .. winid .. " is not valid", vim.log.levels.WARN)
        end
        return false
    end
    local cfg = compat.nvim_win_get_config(winid)
    if cfg.relative and cfg.relative ~= "" then
        if not silent then
            vim.notify("WinBender: Window " .. winid .. " is not a docked window", vim.log.levels.WARN)
        end
        return false
    end
    save_config(winid)
    return true
end

function M.validate_window(winid, silent)
    if not winid then
        if not silent then
            vim.notify("WinBender: Window ID is nil", vim.log.levels.WARN)
        end
        return false
    end
    if not vim.api.nvim_win_is_valid(winid) then
        if not silent then
            vim.notify("WinBender: Window " .. winid .. " is not valid", vim.log.levels.WARN)
        end
        return false
    end
    save_config(winid)
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
    local silent = true
    for winid, saved_cfg in pairs(win_configs) do
        if vim.api.nvim_win_is_valid(winid) then
            if M.validate_floating_window(winid, silent) then
                local cfg  = {
                    title = saved_cfg.title or "",
                    footer = saved_cfg.footer or "",
                }
                compat.nvim_win_set_config(winid, cfg)
            end
        end
    end
end

return M
