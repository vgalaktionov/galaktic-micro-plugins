# Galaktic LSP

Language Server Protocol client for micro.

## Commands

- `lsp start [server|cmd ...]` start a server (defaults to filetype mapping)
- `lsp stop [name]` stop one server or all servers when omitted
- `lsp goto-definition`
- `lsp goto-implementation`
- `lsp find-references`
- `lsp format` format the current buffer
- `lsp diagnostic-info` show diagnostics for the current line
- `lsp hover`
- `lsp rename [new_name]`

## Defaults

- Lua autostarts with `lua-language-server` when available.
- Default filetype mapping includes common industry standard servers.
- Formatting runs on save when the server supports it.

## Statusline

By default this plugin appends ` | lsp:$(galaktic_lsp.status)` to `statusformatl`.
Disable with `galakticlsp.statusline` = `false`.

When `galakticlsp.compactfilename` is `true`, the statusline uses
`$(galaktic_lsp.filename)` to keep the left side shorter.

## Default bindings

The plugin registers default bindings using `Alt` (terminals do not
distinguish `Ctrl-Shift` from `Ctrl`). Override by editing
`galaktic_lsp/config.lua` or set `defaultBindingsOverwrite` to `true`.
