# galaktic-micro-plugins

A collection of plugins for the [Micro](https://micro-editor.github.io/) text editor (>=2.0.0). Pure Lua, no build step, no external dependencies.

## Plugins

### galaktic_sidebar

A file-tree sidebar with Nerd Font icons, mouse support, and git integration.

- Nerd Font file-type icons (40+ extensions covered)
- Single-click to open files and toggle folders
- Git status indicators per file (added, modified, deleted, renamed, untracked)
- Statusline shows current branch, insertions/deletions, and untracked count
- Inline rename, create file/directory, delete, copy, cut, and paste
- Folders-first sorting, dotfile and gitignore visibility toggles
- Auto-refresh on a configurable timer
- Keyboard-driven: single-key commands when the sidebar is focused

### galaktic_lsp

A full LSP 3.17+ client with sane defaults and multi-server support.

- Go-to-definition, go-to-implementation, find references
- Inline diagnostics with gutter indicators (error, warning, info, hint)
- Hover documentation
- Autocomplete via LSP (opt-in Tab override)
- Format on save
- Symbol rename
- Incremental document sync
- Multiple servers per filetype (e.g. ruff + ty for Python)
- 25+ pre-configured language servers (see `galaktic_lsp/config.lua`)
- Statusline integration showing active server name and status

## Installation

### From the plugin repository (recommended)

Add the custom plugin repo to `~/.config/micro/settings.json`:

```json
"pluginrepos": ["https://raw.githubusercontent.com/vgalaktionov/galaktic-micro-plugins/main/repo.json"]
```

Then install:

```
micro -plugin install galaktic_sidebar
micro -plugin install galaktic_lsp
```

### Manual

Clone the repo and symlink each plugin into Micro's plugin directory:

```sh
git clone https://github.com/vgalaktionov/galaktic-micro-plugins.git
mkdir -p ~/.config/micro/plug

# Sidebar (single-file plugin, needs its own directory)
mkdir -p ~/.config/micro/plug/galaktic_sidebar
ln -s "$(pwd)/galaktic-micro-plugins/galaktic-sidebar.lua" ~/.config/micro/plug/galaktic_sidebar/
ln -s "$(pwd)/galaktic-micro-plugins/syntax.yaml" ~/.config/micro/plug/galaktic_sidebar/
ln -s "$(pwd)/galaktic-micro-plugins/repo.json" ~/.config/micro/plug/galaktic_sidebar/
ln -s "$(pwd)/galaktic-micro-plugins/help" ~/.config/micro/plug/galaktic_sidebar/help

# LSP
ln -s "$(pwd)/galaktic-micro-plugins/galaktic_lsp" ~/.config/micro/plug/galaktic_lsp
```

Restart Micro after installing.

## Usage

### Sidebar

Toggle with the `sidebar` command or bind it to a key. While focused:

| Key | Action |
| --- | --- |
| `o` / Enter / Click | Open file or toggle folder |
| `r` | Rename |
| `n` | New file |
| `m` | New directory |
| `d` | Delete |
| `c` / `x` / `v` | Copy / cut / paste |
| `f` | Refresh |

### LSP

Servers autostart for configured filetypes. Commands:

| Command | Description |
| --- | --- |
| `lsp start [server]` | Start a server |
| `lsp stop [name]` | Stop server(s) |
| `lsp goto-definition` | Jump to definition |
| `lsp goto-implementation` | Jump to implementation |
| `lsp find-references` | List references |
| `lsp format` | Format buffer |
| `lsp hover` | Show hover docs |
| `lsp rename [name]` | Rename symbol |
| `lsp diagnostic-info` | Show line diagnostics |

Default keybindings (override in `bindings.json`):

| Key | Action |
| --- | --- |
| Alt-G | Go to definition |
| Alt-I | Go to implementation |
| Alt-R | Find references |
| Alt-F | Format |
| Alt-D | Diagnostic info |

## Configuration

See the help files for full option lists:

- `help galaktic-sidebar` in Micro
- `help galaktic-lsp` in Micro

## Contributing

Edit the Lua files and test by symlinking into `~/.config/micro/plug/` as described above. There is no build step, linter, or test suite — just load the plugin in Micro and verify.

When adding a new language server, add its definition to `galaktic_lsp/config.lua` in the `languageServer` table and optionally wire it into `settings.autostart` or `settings.defaultLanguageServer`.

## Credits

The LSP plugin is based on [mlsp](https://github.com/Andriamanitra/mlsp) by Andriamanitra. galaktic_lsp extends it with format-on-save, statusline integration, default keybindings, and additional server configurations.

JSON encoding/decoding uses [json.lua](https://github.com/rxi/json.lua) by rxi (MIT license).

## License

MIT
