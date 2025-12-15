# WinBender.nvim

A Neovim plugin for manipulating floating windows

## Features

- Move, resize, and reposition floating windows in a keybinding layer
- Drag and drop floating windows with the mouse
- Cycle through floating windows
- Quick access to numbered floating windows (`g1`-`g9`)
- Anchor points are adjusted quietly and automatically
- Manually specify anchor point if desired

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

Using [Plug](https://github.com/junegunn/vim-plug):

```vim
call plug#begin()
Plug 'numEricL/WinBender.nvim'
call plug#end()

" Call setup to enable the toggle keymap
lua require('winbender').setup()
```

**Note:** The `opts` table is optional. If omitted, default settings will be
used. See the documentation for full details.

```lua
require('winbender').setup({
  toggle_key = '<leader>f',  -- Define a toggle key
  step_size = {
    position = 10,
    size = 10,
  }
})
```

## Usage

Toggle WinBender with `:WinBenderToggle` or setup a keymap. There are two
options provided for defining a toggle keymap, either set the `toggle_key`
option in the setup configuration or define your own keymap to the plugmap:

```lua
vim.keymap.set('n', '<leader>f', '<plug>(winbender-toggle)')
```

While active, floating windows are numbered for quick access and the following
keymaps become available:

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
