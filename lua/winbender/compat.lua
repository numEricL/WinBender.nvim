-- compatibility for nvim 0.7.2 is a WIP
local M = {}

local initialized = false
local compat_has = {
    title = nil,
    footer = nil,
}

local function init()
    if initialized then
        return
    else
        initialized = true
    end
    if vim.fn.has("nvim-0.10.0") == 1 then
        compat_has.title = true
        compat_has.footer = true
    else
        compat_has.title  = pcall(vim.api.nvim_win_set_config, 0, { title = "" })
        compat_has.footer = pcall(vim.api.nvim_win_set_config, 0, { footer = "" })
    end
end

local function has_title()
    init()
    return compat_has.title
end

local function has_footer()
    init()
    return compat_has.footer
end

-- neovim 0.7.2 returns a boolean table for row/col of floating windows
function M.nvim_win_get_config(winid)
    local cfg = vim.api.nvim_win_get_config(winid)
    cfg.row = type(cfg.row) == "table" and cfg.row[false] or cfg.row
    cfg.col = type(cfg.col) == "table" and cfg.col[false] or cfg.col
    return cfg
end

function M.nvim_win_set_config(winid, cfg)
    if not has_title() then
        cfg.title = nil
        cfg.title_pos = nil
    end
    if not has_footer() then
        cfg.footer = nil
        cfg.footer_pos = nil
    end
    vim.api.nvim_win_set_config(winid, cfg)
end

-- neovim 0.7.2 compat
function M.nvim_get_hl(ns_id, opts)
    local ok, result = pcall(vim.api.nvim_get_hl, ns_id, opts)
    if ok then
        return result
    else
        local cterm_hl = vim.api.nvim_get_hl_by_name('normal', false)
        local gui_hl = vim.api.nvim_get_hl_by_name('normal', true)
        return { 
            bg = gui_hl.background,
            fg = gui_hl.foreground,
            ctermbg = cterm_hl.background,
            ctermfg = cterm_hl.foreground,
        }
    end
end

return M
