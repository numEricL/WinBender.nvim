# WinBender.nvim

Manage Neovim windows - undock and manipulate as a floating window

## Features

- **Interactive** - Convert docked windows to floating windows and back again
- **Modal Keymaps** - Keymaps are only active when WinBender mode is toggled
- **Visual feedback** - Move, resize, and reposition floating windows
- **Smart anchor handling** - Resize by direction, not by anchor
- **Quick access** - Jump directly to numbered floating windows (`g1`-`g9`)
- **Mouse support** - Drag and drop floating windows with the mouse

## Requirements

- Tested on Neovim 0.11.5

## BETA NOTICE

This plugin is currently in beta. While the core functionality is stable,
some features are experimental and may undergo changes. Keymaps are not
finalized and may be adjusted or removed in future releases.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'numEricL/WinBender.nvim',
  opts = {
    -- your config (optionally) here
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

WinBender provides a modal window management interface. Toggle WinBender with 
`:WinBenderToggle` or create a keymap. There are two methods provided for 
defining a toggle keymap, either set the `toggle_key` in the `opts` config 
table, or define your own keymap:

```lua
vim.keymap.set('n', '<leader>f', '<Plug>(winbender-toggle)')
```

When activated, WinBender creates a keybinding layer for window management:
- Floating windows are numbered (`[g1]`, `[g2]`, etc.) in their titles for quick access
- Window footers display details (winid, anchor, row, col) for floating windows
- The focused window is highlighted for better visibility
- A comprehensive set of keymaps becomes available for all window manipulation operations

While active, you can:
- Navigate between any windows (floating or docked)
- Reposition floating windows
- Resize any window (floating or docked)
- Switch between docked splits using familiar vim navigation
- Set anchor points for floating windows
- Reset windows to their original configuration
- Use the mouse to drag floating windows

### Keymaps

While active, floating windows are numbered for quick access. Focused windows
are highlighted, and the following keymaps become available:

| Key           | Action                                      |
|---------------|---------------------------------------------|
| `f` / `F`     | Focus next/previous floating window         |
| `n` / `N`     | Focus next/previous docked window           |
| `gf` / `gd`   | Float/dock the current window               |
| `g1`-`g9`     | Jump to numbered floating window            |
| `h/j/k/l`     | Move floating window or change docked focus |
| `H/J/K/L`     | Expand window* in specified direction       |
| `<C-h/j/k/l>` | Shrink window* in specified direction       |
| `gh/gj/gk/gl` | Snap floating window to screen edge         |
| `>` / `<`     | Increase/decrease width relative to anchor  |
| `+` / `-`     | Increase/decrease height relative to anchor |
| `q/w/a/s`     | Set anchor to NW/NE/SW/SE (floating only)   |
| `u`           | Reset window to original configuration      |

** \* Note:** Resize operations (`H/J/K/L` and `<C-h/j/k/l>`) are not currently
implemented for docked windows.

All keymaps support count prefixes (e.g., `5j` moves down 5 steps).

**Context-aware behavior:** These keymaps adapt to the current window type:
- When focused on a **floating window**: `h/j/k/l` reposition the window in screen space
- When focused on a **docked window**: `h/j/k/l` switch to adjacent splits (like `<C-w>h/j/k/l>`)

### Docking and Floating

WinBender lets you convert between docked window splits and floating windows.
Window sizes are preserved when possible, as well as window-local options. When
docking a floating window WinBender first determines the closest docked window
based on greatest overlap, then determines the best split direction by comparing
the midpoints of the two windows. These implementation details are subject to
change in future releases.

### Snap Windows

Floating windows can be quickly snapped to screen edges. When two corners of a
floating window are matched to screen corners and it is docked, a new top-level
split is created at that position.

### Mouse Support

Floating windows may be dragged, and docked windows may be undocked via mouse
input.

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
  },
  quick_access_hl = 'WarningMsg',  -- Highlight group for quick access labels
  cell_pixel_ratio_w_to_h = 12/26, -- Cell aspect ratio for window calculations
})
```

## Integration

If [cyclops.vim](https://github.com/numEricL/cyclops.vim) is installed,
WinBender will automatically enable repeatable operations with persistent counts
for paired keymaps via the `;` and `,` keys.
