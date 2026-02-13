# Micro Cross-Platform Control Scheme (macOS + Windows)

This scheme is identical across platforms; only the modifier changes:

- Mod = Option (Alt) on macOS
- Mod = Ctrl on Windows

The goal is to match familiar Sublime Text / VS Code muscle memory while
covering micro's native functionality.

## File and App

| Key | Action |
| --- | --- |
| Mod+N | New buffer |
| Mod+O | Open file |
| Mod+P | Quick open (files/buffers) |
| Mod+S | Save |
| Mod+Shift+S | Save as |
| Mod+W | Close buffer |
| Mod+Shift+W | Close all buffers |
| Mod+Q | Quit micro |
| Mod+, | Settings file or keybindings |
| Mod+Shift+P | Command bar |
| F1 | Help |

## Editing

| Key | Action |
| --- | --- |
| Mod+Z | Undo |
| Mod+Shift+Z | Redo |
| Mod+X | Cut |
| Mod+C | Copy |
| Mod+V | Paste |
| Mod+A | Select all |
| Mod+L | Select line |
| Mod+D | Add cursor to next match |
| Mod+Shift+L | Add cursors to all matches |
| Mod+/ | Toggle comment |
| Mod+] | Indent |
| Mod+[ | Outdent |
| Mod+Shift+D | Duplicate line/selection |
| Mod+Shift+K | Delete line |
| Mod+J | Join lines |
| Mod+Shift+Up | Move line up |
| Mod+Shift+Down | Move line down |

## Navigation and Selection

| Key | Action |
| --- | --- |
| Mod+Left | Jump word left |
| Mod+Right | Jump word right |
| Mod+Up | Scroll up |
| Mod+Down | Scroll down |
| Home | Start of line |
| End | End of line |
| Mod+Home | Start of file |
| Mod+End | End of file |
| Mod+G | Go to line |
| Mod+M | Jump to matching bracket |
| Shift+Arrow | Extend selection |
| Mod+Shift+Left | Select word left |
| Mod+Shift+Right | Select word right |

## Search and Replace

| Key | Action |
| --- | --- |
| Mod+F | Find |
| Mod+Shift+F | Find in files |
| Mod+H | Replace |
| F3 | Find next |
| Shift+F3 | Find previous |

## Tabs and Splits

| Key | Action |
| --- | --- |
| Mod+T | New tab |
| Mod+Shift+T | Reopen tab |
| Mod+Tab | Next tab |
| Mod+Shift+Tab | Previous tab |
| Mod+1 | Focus pane 1 |
| Mod+2 | Focus pane 2 |
| Mod+3 | Focus pane 3 |
| Mod+\\ | Split vertical |
| Mod+Shift+\\ | Split horizontal |
| Mod+Shift+Enter | Zoom pane |
| Mod+Shift+W | Close pane |

## View and Utilities

| Key | Action |
| --- | --- |
| Mod+B | Buffer list |
| Mod+Shift+B | Toggle statusline |
| Mod+Shift+N | Toggle line numbers |
| Mod+Shift+R | Toggle ruler |
| Mod+Shift+Space | Toggle soft wrap |

## Notes

- If a command is missing in your build, bind the action to a nearby key and
  keep the same intent (e.g., map find-in-files to a grep-like command).
- For plugins, prefer using the same Mod-based scheme so key shapes are shared
  across platforms.
