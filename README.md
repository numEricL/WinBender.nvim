# WinBender.nvim

A Neovim plugin for manipulating floating windows

## Features

- Move, resize, and reposition floating windows in a keybinding layer
- Drag and drop floating windows with the mouse
- Cycle through floating windows
- Quick access to numbered floating windows (`g1`-`g9`)
- Anchor points are adjusted quietly and automatically
- Manually specify anchor point if desired

## Requirements

- Neovim 0.7.2 or later (with partial compatibility)
- Neovim 0.10.0 or later recommended for full feature support (title/footer labels)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'numEricL/WinBender.nvim',
  opts = {
    -- your config here
  }
}
```

**Note:** The `opts` table is optional. If omitted, default settings will be
used. See the Configuration section below or the documentation for details.


Using [Plug](https://github.com/junegunn/vim-plug):

```vim
call plug#begin()
Plug 'numEricL/WinBender.nvim'
call plug#end()
```

## Usage

Toggle WinBender with `:WinBenderToggle` or create a keymap. There are two
methods provided for defining a toggle keymap, either set the `toggle_key` in
the `opts` config table, or define your own keymap:

```lua
vim.keymap.set('n', '<leader>f', '<Plug>(winbender-toggle)')
```

While active, floating windows are numbered for quick access, display details
(winid, anchor, row, col) in the footer, and the following keymaps become
available:

| Key           | Action                                      |
|---------------|---------------------------------------------|
| `f` / `F`     | Focus next/previous floating window         |
| `g1`-`g9`     | Jump to numbered floating window            |
| `h/j/k/l`     | Reposition window                           |
| `H/J/K/L`     | Expand window in specified direction        |
| `<C-h/j/k/l>` | Shrink window in specified direction        |
| `>` / `<`     | Increase/decrease width relative to anchor  |
| `+` / `-`     | Increase/decrease height relative to anchor |
| `q/w/a/s`     | Set anchor to NW/NE/SW/SE                   |
| `u`           | Reset window to original configuration      |

All keymaps support count prefixes (e.g., `5j` moves down 5 steps).

### Experimental Snap Feature

WinBender includes an experimental snap feature that allows windows to be
quickly snapped to screen edges. This feature is disabled by default and must
be explicitly enabled via keymaps configuration. It may have breaking changes in
the future.

To enable snap keymaps, add them to your setup:

```lua
require("winbender").setup{
  keymaps = {
    snap_left  = "gh",
    snap_down  = "gj",
    snap_up    = "gk",
    snap_right = "gl"
  }
}
```

### Mouse Support

Floating windows may be dragged while WinBender is active.

## Configuration

```lua
require('winbender').setup({
  toggle_key = '<leader>f',  -- Key to toggle WinBender mode (default: nil)
  keymaps = {
    -- Override default keymaps
  },
  mouse_enabled = true,      -- Enable mouse drag and drop (default: true)
  step_size = {
    position = 5,  -- Step size for position changes
    size = 5,      -- Step size for resize operations
  }
})
```

## Integration

If [cyclops.vim](https://github.com/numEricL/cyclops.vim) is installed,
WinBender will automatically enable repeatable operations with persistent counts
for paired keymaps via the `;` and `,` keys.
