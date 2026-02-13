# AGENTS.md

Guidance for building Micro plugins in this repo, based on the galaktic_sidebar work.

## Plugin naming and loading
- Plugin folder and name must match `^[_A-Za-z0-9]+$`. Hyphens break plugin loading.
- `repo.json` must have a non-empty `Website`; otherwise the loader can fall back to the folder name and reject it.
- Use `config.AddRuntimeFile("galaktic_sidebar", ...)` with the plugin name, not the folder name.

## Micro Lua API realities
- `shell.ExecCommand` expects `ExecCommand(name, arg1, arg2, ...)`, not a single string.
- Some builds lack `BufPane.GetMouseClickLocation` and `EventMouse:Position()`; use `onMousePress` and the cursor location instead of manual mouse mapping.
- Forward-declare functions used inside nested callbacks (e.g., `refresh_view`, `open_file`) to avoid nil calls.
- `micro.InfoBar():Prompt` may be unavailable; prefer a local input mode inside the sidebar for name entry.

## Sidebar UX decisions
- Keep `softwrap` disabled for the sidebar to avoid wrapped lines and misaligned clicks.
- Hide parent navigation (`..`) to prevent exiting the root.
- Sidebar statusline should be informative (git branch, untracked counts, +/- counts).
- If git commands fail inside micro, fallback to reading `.git/HEAD` for the branch.

## Git integration details
- Statusline counts use `git status --porcelain`, `git diff --shortstat`, `git diff --cached`.
- New repos (no commits) still need untracked counts; do not gate on `rev-parse --verify HEAD`.
- File status indicators are derived from `git status --porcelain` and mapped to letters (A/M/D/R/?).

## Key handling
- Sidebar-only single-key commands should be implemented via `preRune` and guarded by `view == sidebar_view`.
- For inline input mode, intercept `preRune`, `preBackspace`, `preEscape`, and `preInsertNewline`.
- Avoid global keybindings for sidebar actions; keep them scoped to the sidebar pane.

## Auto-refresh
- Prefer a timer-based refresh (e.g., `micro.After(time.Millisecond * interval, tick)`).
- Preserve expanded/collapsed state by keeping the `expanded` table intact on refresh.
- Refresh should be skipped while in inline input mode.

## Syntax highlighting
- `syntax.yaml` must be valid micro syntax format; YAML mistakes will block micro startup.
- Highlight icons and status glyphs only, not full lines, to avoid over-coloring.

## Known limitations
- Split border styling is controlled by micro; avoid fake separators inside the sidebar.
