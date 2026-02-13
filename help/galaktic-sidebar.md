# Galaktic Sidebar

A fast, lightweight file sidebar for micro with Nerd Font icons, mouse support, and clean pane switching.

## Commands

- `sidebar` toggle the sidebar
- `sidebar-refresh` rebuild the tree

## Keybindings

- Up/Down move selection
- Left/Right collapse or expand folders
- Enter open file or toggle folder
- Mouse click open file or toggle folder

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
