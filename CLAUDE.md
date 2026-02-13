# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A collection of plugins for the **Micro text editor** (>=2.0.0), written in pure Lua. No build step, no external dependencies, no test infrastructure. The two plugins are:

- **galaktic_sidebar** (`galaktic-sidebar.lua`) — File tree sidebar with Nerd Font icons, mouse support, git status indicators, and inline file operations (rename/create/delete).
- **galaktic_lsp** (`galaktic_lsp/`) — Full LSP 3.17+ client with diagnostics, completion, go-to-definition, formatting, rename, references, hover, and 24+ pre-configured language servers.

## Repository Structure

```
galaktic-sidebar.lua        # Sidebar plugin (single file, ~1400 lines)
galaktic_lsp/
  main.lua                  # LSP client implementation (~1900 lines)
  config.lua                # Language server definitions and autostart mappings
  json.lua                  # JSON encoder/decoder (vendored rxi library)
repo.json                   # Micro plugin registry manifest
syntax.yaml                 # Micro syntax highlighting rules for sidebar
help/                       # Micro help files (.md)
AGENTS.md                   # Plugin development guidelines (read this before modifying code)
```

## Development Notes

There is no build, lint, or test command. Development is done by editing Lua files and loading them in Micro.

To test changes: copy/symlink the plugin into `~/.config/micro/plug/` and restart Micro, or use `micro -plugin install` with a local path.

## Architecture

### Plugin loading model
Micro loads plugins by folder name matching `^[_A-Za-z0-9]+$`. Hyphens in folder names break loading. `repo.json` must have a non-empty `Website` field. Each plugin registers commands, keybindings, and event hooks at load time.

### Sidebar (galaktic-sidebar.lua)
- All state is module-level (expanded folders table, file-to-line mappings, input mode, etc.)
- Timer-based auto-refresh via `micro.After()` preserves expand/collapse state
- Git integration: primary via `shell.ExecCommand("git", ...)`, fallback to `.git/HEAD` parsing
- Sidebar-scoped keybindings via `preRune` guarded by `view == sidebar_view`
- Inline input mode (rename/create) intercepts `preRune`, `preBackspace`, `preEscape`, `preInsertNewline`

### LSP (galaktic_lsp/main.lua)
- `LSPClient` class (metatable-based) manages per-server state, request/response tracking, and message buffering
- JSON-RPC over stdin/stdout with streaming message parsing (Content-Length headers)
- Document sync modes: Full, Incremental, or None — negotiated during initialization
- Async callbacks: requests store callbacks keyed by request ID; responses dispatch to them
- `config.lua` defines server commands, init options, autostart rules, and filetype mappings
- Event hooks: `onBufferOpen`, `onSave`, `onBeforeTextEvent`, `onUndo`/`onRedo`, `preAutocomplete`

## Key Conventions

- **Lua 5.1 compatible** — no 5.2+ features
- Forward-declare functions used in nested callbacks to avoid nil references
- Use `pcall()` for optional Go APIs that may be missing in some Micro builds
- `shell.ExecCommand(name, arg1, arg2, ...)` — variadic args, not a single string
- `syntax.yaml` must be valid Micro syntax format; YAML errors block Micro startup
- Sidebar keeps `softwrap` disabled to prevent wrapped lines and misaligned clicks
- Plugin keybindings use Alt-based modifiers (Alt-G, Alt-F, etc.) to avoid conflicts with editor defaults
