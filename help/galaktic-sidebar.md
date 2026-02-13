# Galaktic Sidebar

A fast, lightweight file sidebar for micro with Nerd Font icons, mouse support, and clean pane switching.

## Commands

- `sidebar` toggle the sidebar
- `sidebar-refresh` rebuild the tree
- `sidebar-open` open file or toggle folder
- `sidebar-rename [name]` rename selected item
- `sidebar-newfile [name]` create file in selected directory
- `sidebar-newdir [name]` create directory in selected directory
- `sidebar-delete` delete selected item

## Keybindings

- Up/Down move selection
- Left/Right collapse or expand folders
- Enter open file or toggle folder
- Mouse click open file or toggle folder
- `o` open file or toggle folder
- `r` rename selected item
- `n` create file
- `m` create directory
- `d` delete selected item
- `f` refresh tree
- `c` copy selected item
- `x` cut selected item
- `v` paste into selected directory

## Options

- `galakticsidebar.showdotfiles` (bool, default `true`)
- `galakticsidebar.showignored` (bool, default `true`)
- `galakticsidebar.foldersfirst` (bool, default `true`)
- `galakticsidebar.icons` (bool, default `true`)
- `galakticsidebar.openfocus` (bool, default `false`) keeps focus on sidebar when opened
- `galakticsidebar.openonstart` (string, default `auto`) opens when micro starts in a directory; accepts `auto`, `true`, or `false`
- `galakticsidebar.width` (int, default `30`)
- `galakticsidebar.autorefresh` (bool, default `true`)
- `galakticsidebar.refreshinterval` (int, default `2000`) milliseconds

## Notes

- The divider line uses syntax highlighting; make sure the sidebar buffer `filetype` is `galaktic_sidebar`.
- The statusline shows the repo branch and total added/deleted lines when the root is a Git repo.
