# WinBender.nvim

A Neovim plugin for manipulating floating windows

## Features

- Move, resize, and reposition floating windows in a keybinding layer
- Cycle through floating windows
- Quick access to numbered floating windows (`g1`-`g9`)
- Anchor points are adjusted quietly and automatically
- Manually specify anchor point if desired

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'numEricL/winbender.nvim'
}
```

## Usage

Press `<leader>f` to toggle WinBender mode. While active, floating windows are
numbered for quick access, and the following keymaps become available:

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
| `r`           | Reset window to original configuration      |

All keymaps support count prefixes (e.g., `5j` moves down 5 steps).

## Configuration

```lua
require('winbender').setup({
  toggle_key = '<leader>f',  -- Key to toggle Winbender mode (set to false to disable)
  keymaps = {
    -- Override default keymaps
  },
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
