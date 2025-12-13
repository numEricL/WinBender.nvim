# WinBender.nvim

A Neovim plugin for manipulating floating windows

## Features

- Move, resize, and reposition floating windows in a keybinding layer
- Cycle through floating windows with quick navigation
- Quick access to numbered floating windows (`g1`-`g9`)
- Reset windows to their original configuration
- Change window anchor points dynamically

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'numericl/winbender.nvim',
  config = function()
    require('winbender').setup()
  end
}
```

## Usage

Press `<leader>f` to toggle WinBender mode. While active, floating windows are
numbered for quick access, and the following keymaps become available:

| Key | Action |
|-----|--------|
| `f` / `F` | Focus next/previous floating window |
| `h/j/k/l` | Move window |
| `H/J/K/L` | Expand window in direction |
| `<C-h/j/k/l>` | Shrink window in direction |
| `>` / `<` | Increase/decrease width |
| `+` / `-` | Increase/decrease height |
| `q/w/a/s` | Set anchor to NW/NE/SW/SE |
| `r` | Reset window to original configuration |
| `g1`-`g9` | Jump to numbered floating window |

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

If [cyclops.vim](https://github.com/numeric-larson/cyclops.vim) is installed,
WinBender will use it to enable repeatable operations with persistent counts for
paired keymaps via the `;` and `,` keys.
