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
  'numEricL/WinBender.nvim',
  opts = {
    -- your config here
  }
}
```

**Note:** You must call `setup()` (either via `opts` with lazy.nvim or
explicitly) to enable the toggle keymap. Without calling `setup()`, only
the `:WinBenderToggle` command will be available.

Using [Plug](https://github.com/junegunn/vim-plug):

```vim
call plug#begin()
Plug 'numEricL/WinBender.nvim'
call plug#end()

" Call setup to enable the toggle keymap
lua require('winbender').setup()
```

Or with custom configuration:

```lua
require('winbender').setup({
  toggle_key = '<leader>w',  -- Change the toggle key
  step_size = {
    position = 10,
    size = 10,
  }
})
```

## Usage

Toggle WinBender with `:WinBenderToggle` or use the keymap (default: `<leader>f`)
if you've called `setup()`.

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
| `r`           | Reset window to original configuration      |

All keymaps support count prefixes (e.g., `5j` moves down 5 steps).

## Configuration

```lua
require('winbender').setup({
  toggle_key = '<leader>f',  -- Key to toggle Winbender mode (set to nil to disable)
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
