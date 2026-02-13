VERSION = "0.1.0"

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local os = import("os")
local filepath = import("path/filepath")
local ioutil = import("ioutil")
local fmt = import("fmt")
local time = import("time")

local sidebar_view = nil
local root_dir = os.Getwd()
local expanded = {}
local line_to_entry = {}
local path_to_line = {}
local last_editor_pane = nil
local last_rendered_lines = 0
local precmd_dir = nil
local set_statusline
local open_file
local refresh_view
local list_start_y = 2
local list_end_y = 2
local refresh_timer_started = false
local sidebar_focused = false

local icons = {
	folder = "\239\132\148",
	folder_open = "\239\132\149",
	file = "\239\128\150",
	ext = {
		lua = "\239\134\134",
		go = "\238\152\167",
		js = "\238\152\140",
		ts = "\238\152\168",
		json = "\238\152\139",
		md = "\238\152\137",
		yml = "\238\152\149",
		yaml = "\238\152\149",
		toml = "\238\152\149",
		rs = "\238\158\168",
		py = "\238\152\134",
		sh = "\238\158\149",
		zsh = "\238\158\149",
		bash = "\238\158\149",
		html = "\238\152\142",
		css = "\238\152\148",
		scss = "\238\152\131",
		c = "\238\152\158",
		h = "\238\152\158",
		cpp = "\238\152\157",
		hpp = "\238\152\157",
		txt = "\239\131\182",
	}
}

local function home_dir()
	local ok, home = pcall(function()
		return os.UserHomeDir()
	end)
	if ok and home ~= nil and home ~= "" then
		return home
	end
	local env = os.Getenv("HOME")
	if env ~= nil and env ~= "" then
		return env
	end
	return nil
end

local function shorten_home(path)
	local home = home_dir()
	if home == nil or home == "" then
		return path
	end
	if path == home then
		return "~"
	end
	if string.sub(path, 1, #home + 1) == home .. "/" then
		return "~" .. string.sub(path, #home + 1)
	end
	return path
end

local function trim(str)
	if str == nil then
		return ""
	end
	return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
end

local function read_file(path)
	local data, err = ioutil.ReadFile(path)
	if err ~= nil or data == nil then
		return nil
	end
	return fmt.Sprintf("%s", data)
end

local function file_exists(path)
	local info, err = os.Stat(path)
	if err ~= nil or info == nil then
		return false
	end
	return true
end

local function dir_exists(path)
	local info, err = os.Stat(path)
	if err ~= nil or info == nil then
		return false
	end
	return info:IsDir()
end

local function find_git_root(start_dir)
	local dir = start_dir
	while dir ~= "" do
		local git_path = filepath.Join(dir, ".git")
		if file_exists(git_path) then
			return dir
		end
		local parent = filepath.Dir(dir)
		if parent == dir then
			break
		end
		dir = parent
	end
	return nil
end

local function git_dir_from_root(root)
	local git_path = filepath.Join(root, ".git")
	if dir_exists(git_path) then
		return git_path
	end
	if file_exists(git_path) then
		local content = read_file(git_path)
		if content ~= nil then
			local target = trim(string.match(content, "gitdir:%s*(.+)"))
			if target ~= "" then
				if not filepath.IsAbs(target) then
					target = filepath.Join(root, target)
				end
				return target
			end
		end
	end
	return nil
end

local function git_root(dir)
	local out, err = shell.ExecCommand("git", "-C", dir, "rev-parse", "--show-toplevel")
	if err ~= nil or out == nil then
		return find_git_root(dir)
	end
	local root = trim(out)
	if root == "" then
		return find_git_root(dir)
	end
	return root
end

local function git_branch(dir)
	local out, err = shell.ExecCommand("git", "-C", dir, "rev-parse", "--abbrev-ref", "HEAD")
	if err ~= nil then
		local root = find_git_root(dir)
		if root == nil then
			return ""
		end
		local git_dir = git_dir_from_root(root)
		if git_dir == nil then
			return ""
		end
		local head = read_file(filepath.Join(git_dir, "HEAD"))
		if head == nil then
			return ""
		end
		local ref = string.match(head, "ref:%s*(.+)")
		if ref ~= nil then
			return filepath.Base(trim(ref))
		end
		return trim(string.sub(head, 1, 7))
	end
	local branch = trim(out or "")
	if branch == "HEAD" then
		local hash, err2 = shell.ExecCommand("git", "-C", dir, "rev-parse", "--short", "HEAD")
		if err2 == nil then
			branch = trim(hash or "")
		end
	end
	return branch
end

local function git_has_commit(dir)
	local out, err = shell.ExecCommand("git", "-C", dir, "rev-parse", "--verify", "HEAD")
	if err ~= nil then
		return false
	end
	local trimmed = trim(out or "")
	if trimmed == "" then
		return false
	end
	if string.match(trimmed, "^fatal:") or string.find(trimmed, "Needed a single revision", 1, true) then
		return false
	end
	return true
end

local function git_untracked_count(dir)
	local out, err = shell.ExecCommand("git", "-C", dir, "status", "--porcelain")
	if err ~= nil then
		return 0
	end
	local text = out or ""
	if string.match(text, "^fatal:") or string.find(text, "not found", 1, true) then
		return 0
	end
	local count = 0
	for line in string.gmatch(text, "([^\r\n]+)") do
		if string.sub(line, 1, 2) == "??" then
			count = count + 1
		end
	end
	if count == 0 then
		local other, err2 = shell.ExecCommand("git", "-C", dir, "ls-files", "--others", "--exclude-standard")
		if err2 == nil then
			for _ in string.gmatch(other or "", "([^\r\n]+)") do
				count = count + 1
			end
		end
	end
	return count
end

local function parse_shortstat(text)
	local add = tonumber(string.match(text, "([0-9]+) insertion") or "") or 0
	local del = tonumber(string.match(text, "([0-9]+) deletion") or "") or 0
	return add, del
end

local function git_diff_stats(dir)
	local work, err1 = shell.ExecCommand("git", "-C", dir, "diff", "--shortstat", "--no-ext-diff")
	local staged, err2 = shell.ExecCommand("git", "-C", dir, "diff", "--shortstat", "--no-ext-diff", "--cached")
	local add1, del1 = 0, 0
	local add2, del2 = 0, 0
	if err1 == nil and work ~= nil then
		add1, del1 = parse_shortstat(work or "")
	end
	if err2 == nil and staged ~= nil then
		add2, del2 = parse_shortstat(staged or "")
	end
	return add1 + add2, del1 + del2
end

local function git_status_map(root)
	local out, err = shell.ExecCommand("git", "-C", root, "status", "--porcelain")
	if err ~= nil or out == nil then
		return {}
	end
	local map = {}
	for line in string.gmatch(out, "([^\r\n]+)") do
		local code = string.sub(line, 1, 2)
		local path = string.sub(line, 4)
		if string.match(path, " -> ") then
			path = string.match(path, " -> (.+)$") or path
		end
		code = trim(code)
		if code == "" then
			code = "?"
		end
		map[path] = code
		local dir = filepath.Dir(path)
		while dir ~= "." and dir ~= "/" do
			if map[dir] == nil then
				map[dir] = "M"
			end
			dir = filepath.Dir(dir)
		end
	end
	return map
end

local function status_icon(code)
	if code == nil or code == "" then
		return " "
	end
	if string.match(code, "A") then
		return "A"
	end
	if string.match(code, "D") then
		return "D"
	end
	if string.match(code, "R") then
		return "R"
	end
	if string.match(code, "M") then
		return "M"
	end
	if string.match(code, "%?%?") or string.match(code, "%?") then
		return "?"
	end
	return " "
end

local function update_statusline()
	if sidebar_view == nil then
		return
	end
	local label = ""
	local name = filepath.Base(root_dir)
	if name == "" or name == "." then
		name = shorten_home(root_dir)
	end
	local status = label .. " " .. name
	local root = git_root(root_dir)
	if root ~= nil then
		local branch = git_branch(root)
		local add, del = git_diff_stats(root)
		if branch ~= "" then
			status = " " .. branch
		else
			status = " " .. name
		end
		local untracked = git_untracked_count(root)
		if untracked > 0 then
			status = status .. " ?" .. tostring(untracked)
		end
		if add > 0 or del > 0 then
			status = status .. " +" .. tostring(add) .. " -" .. tostring(del)
		end
	end
	set_statusline(status)
end

local function repeat_str(str, len)
	local string_table = {}
	for i = 1, len do
		string_table[i] = str
	end
	return table.concat(string_table)
end


local function is_dir(path)
	local file_info, _ = os.Stat(path)
	if file_info == nil then
		return false
	end
	return file_info:IsDir()
end

local function is_dotfile(name)
	return string.sub(name, 1, 1) == "."
end

local function get_ignored_files(dir)
	local git_rp_results = shell.ExecCommand('git -C "' .. dir .. '" rev-parse --is-inside-work-tree')
	if not git_rp_results or not git_rp_results:match("^true%s*$") then
		return {}
	end
	local ignored = {}
	local results = shell.ExecCommand('git -C "' ..
		dir .. '" ls-files . --ignored --exclude-standard --others --directory')
	for line in string.gmatch(results or "", "([^\r\n]+)") do
		local cleaned = line
		if string.sub(cleaned, -1) == "/" then
			cleaned = string.sub(cleaned, 1, -2)
		end
		ignored[cleaned] = true
	end
	return ignored
end

local function read_dir(dir)
	local list, err = ioutil.ReadDir(dir)
	if list == nil then
		return {}, err
	end
	return list, nil
end

local function sort_entries(entries)
	if not config.GetGlobalOption("galakticsidebar.foldersfirst") then
		return entries
	end
	local dirs = {}
	local files = {}
	for i = 1, #entries do
		if entries[i].is_dir then
			dirs[#dirs + 1] = entries[i]
		else
			files[#files + 1] = entries[i]
		end
	end
	for i = 1, #files do
		dirs[#dirs + 1] = files[i]
	end
	return dirs
end

local function icon_for(name, entry_is_dir, entry_expanded)
	if not config.GetGlobalOption("galakticsidebar.icons") then
		return ""
	end
	if entry_is_dir then
		return entry_expanded and icons.folder_open or icons.folder
	end
	local ext = string.match(string.lower(name), "%.([^.]+)$")
	if ext and icons.ext[ext] then
		return icons.ext[ext]
	end
	return icons.file
end

local function format_entry(entry)
	local prefix = repeat_str("  ", entry.depth)
	local marker = " "
	if entry.is_dir then
		marker = expanded[entry.path] and "v" or ">"
	end
	local icon = icon_for(entry.name, entry.is_dir, expanded[entry.path])
	local git = entry.status or " "
	local suffix = entry.is_dir and "/" or ""
	if icon ~= "" then
		return prefix .. marker .. " " .. git .. " " .. icon .. " " .. entry.name .. suffix
	end
	return prefix .. marker .. " " .. git .. " " .. entry.name .. suffix
end

local function build_entries()
	line_to_entry = {}
	path_to_line = {}
	local lines = {}

	lines[#lines + 1] = shorten_home(root_dir)
	lines[#lines + 1] = repeat_str("-", sidebar_view:GetView().Width)
	list_start_y = #lines

	local root = git_root(root_dir)
	local status_map = {}
	if root ~= nil then
		status_map = git_status_map(root)
	end

	local show_dotfiles = config.GetGlobalOption("galakticsidebar.showdotfiles")
	local show_ignored = config.GetGlobalOption("galakticsidebar.showignored")

	local function append_dir(dir, depth)
		local ignored = {}
		if not show_ignored then
			ignored = get_ignored_files(dir)
		end
		local list, err = read_dir(dir)
		if err ~= nil then
			micro.InfoBar():Error("Sidebar read error: ", err)
			return
		end

		local entries = {}
		for i = 1, #list do
			local name = list[i]:Name()
			if (show_dotfiles or not is_dotfile(name)) and not ignored[name] then
				local path = filepath.Join(dir, name)
				local rel = path
				if root ~= nil then
					local relpath, relerr = filepath.Rel(root, path)
					if relerr == nil then
						rel = relpath
					end
				end
				entries[#entries + 1] = {
					name = name,
					path = path,
					is_dir = list[i]:IsDir(),
					depth = depth,
					status = status_icon(status_map[rel]),
				}
			end
		end

		entries = sort_entries(entries)

		for i = 1, #entries do
			local entry = entries[i]
			lines[#lines + 1] = format_entry(entry)
			local y = #lines - 1
			line_to_entry[y] = entry
			path_to_line[entry.path] = y
			if entry.is_dir and expanded[entry.path] then
				append_dir(entry.path, depth + 1)
			end
		end
	end

	append_dir(root_dir, 0)
	if next(line_to_entry) == nil then
		lines[#lines + 1] = "(empty)"
		local y = #lines - 1
		line_to_entry[y] = {
			name = "(empty)",
			path = root_dir,
			is_dir = false,
			depth = 0,
			status = " ",
		}
		path_to_line[root_dir] = y
	end
	list_end_y = #lines - 1

	return lines
end

local function set_cursor(y, opts)
	if sidebar_view == nil then
		return
	end
	opts = opts or {}
	if opts.center == nil then
		opts.center = true
	end
	if y < list_start_y then
		y = list_start_y
	end
	if y > list_end_y then
		y = list_end_y
	end
	if y < list_start_y then
		y = list_start_y
	end
	sidebar_view.Cursor.Loc.X = 0
	sidebar_view.Cursor.Loc.Y = y
	if opts.relocate ~= false then
		sidebar_view.Cursor:Relocate()
	end
	if opts.center == true then
		sidebar_view:Center()
	end
	sidebar_view.Cursor:SelectLine()
end

local function selected_entry()
	if sidebar_view == nil then
		return nil
	end
	return line_to_entry[sidebar_view.Cursor.Loc.Y]
end

set_statusline = function(text)
	if sidebar_view == nil then
		return
	end
	sidebar_view.Buf:SetOptionNative("statusformatl", text)
	sidebar_view.Buf:SetOptionNative("statusformatr", "")
end

refresh_view = function(preserve_view)
	if sidebar_view == nil then
		return
	end
	local selected = selected_entry()
	local selected_path = selected and selected.path or nil

	local width = config.GetGlobalOption("galakticsidebar.width")
	if width ~= nil and width > 0 then
		sidebar_view:ResizePane(width)
	end

	local lines = build_entries()
	last_rendered_lines = #lines
	local text = table.concat(lines, "\n")

	sidebar_view.Buf.EventHandler:Remove(sidebar_view.Buf:Start(), sidebar_view.Buf:End())
	sidebar_view.Buf.EventHandler:Insert(buffer.Loc(0, 0), text)
	local view = sidebar_view:GetView()
	if view ~= nil then
		view.StartCol = 0
	end

	local restore_y = list_start_y
	if selected_path and path_to_line[selected_path] then
		restore_y = path_to_line[selected_path]
	end
	if preserve_view and not sidebar_focused then
		if sidebar_view.Cursor ~= nil then
			sidebar_view.Cursor.Loc.X = 0
			sidebar_view.Cursor.Loc.Y = restore_y
		end
		update_statusline()
		return
	end
	if preserve_view then
		set_cursor(restore_y, { relocate = false, center = false })
	else
		set_cursor(restore_y, { center = true })
	end
	update_statusline()
end

local function set_root_dir(dir)
	if dir == nil or dir == "" then
		return
	end
	if dir == root_dir then
		return
	end
	root_dir = dir
	expanded = {}
	refresh_view()
end

local function started_on_dir()
	local pane = micro.CurPane()
	if pane == nil or pane.Buf == nil then
		return false
	end
	local path = pane.Buf.AbsPath
	if path == nil or path == "" then
		path = pane.Buf.Path
	end
	if path == nil or path == "" then
		return true
	end
	return is_dir(path)
end

local function should_open_on_start()
	local opt = config.GetGlobalOption("galakticsidebar.openonstart")
	if type(opt) == "boolean" then
		return opt
	end
	if type(opt) == "number" then
		return opt ~= 0
	end
	if type(opt) == "string" then
		local lower = string.lower(opt)
		if lower == "true" or lower == "yes" or lower == "always" then
			return true
		end
		if lower == "false" or lower == "no" or lower == "never" then
			return false
		end
		if lower == "auto" or lower == "dir" or lower == "folder" then
			return started_on_dir()
		end
	end
	return false
end

local function pane_count()
	if sidebar_view == nil then
		return 0
	end
	local tab = sidebar_view:Tab()
	if tab == nil then
		return 0
	end
	local ok, count = pcall(function()
		return tab:NumPanes()
	end)
	if ok and type(count) == "number" then
		return count
	end
	local panes = tab.Panes
	if type(panes) == "table" then
		return #panes
	end
	local views = tab.Views
	if type(views) == "table" then
		return #views
	end
	return 0
end

local function tab_count()
	local tabs = micro.Tabs()
	if tabs == nil then
		return 1
	end
	local methods = { "Len", "Length", "Size", "Count" }
	for i = 1, #methods do
		local ok, count = pcall(function()
			return tabs[methods[i]](tabs)
		end)
		if ok and type(count) == "number" then
			return count
		end
	end
	if type(tabs.Tabs) == "table" then
		return #tabs.Tabs
	end
	return 1
end

open_file = function(path)
	local target = last_editor_pane
	if target == nil or target == sidebar_view then
		if sidebar_view ~= nil then
			sidebar_view:NextSplit()
			target = micro.CurPane()
		else
			target = micro.CurPane()
		end
	end

	if target == nil then
		micro.InfoBar():Error("Sidebar: no editor pane available")
		return
	end

	local buf, err = buffer.NewBufferFromFile(path)
	if err ~= nil then
		micro.InfoBar():Error("Sidebar open error: ", err)
		return
	end

	target:OpenBuffer(buf)
	target:SetActive(true)
end

local function activate_entry(y)
	local entry = line_to_entry[y]
	if entry == nil then
		return
	end
	if entry.is_dir then
		expanded[entry.path] = not expanded[entry.path]
		refresh_view()
		return
	end
	open_file(entry.path)
end

local function open_sidebar()
	if sidebar_view ~= nil then
		return
	end
	micro.CurPane():VSplitIndex(buffer.NewBuffer("", "galaktic-sidebar"), false)
	sidebar_view = micro.CurPane()

	sidebar_view.Buf.Type.Scratch = true
	sidebar_view.Buf.Type.Readonly = true
	sidebar_view.Buf:SetOptionNative("softwrap", false)
	sidebar_view.Buf:SetOptionNative("ruler", false)
	sidebar_view.Buf:SetOptionNative("scrollbar", false)
	sidebar_view.Buf:SetOptionNative("cursorline", true)
	sidebar_view.Buf:SetOptionNative("filetype", "galaktic_sidebar")

	root_dir = os.Getwd()
	refresh_view()

	if not config.GetGlobalOption("galakticsidebar.openfocus") then
		sidebar_view:NextSplit()
	end
end

local function close_sidebar()
	if sidebar_view ~= nil then
		sidebar_view:Quit()
		sidebar_view = nil
	end
end

function toggle_sidebar()
	if sidebar_view == nil then
		open_sidebar()
	else
		close_sidebar()
	end
end

function refresh_sidebar()
	refresh_view()
end

function preInsertNewline(view)
	if view == sidebar_view then
		activate_entry(view.Cursor.Loc.Y)
		return false
	end
	return true
end

function preRune(view, r)
	if view ~= sidebar_view then
		return true
	end
	return false
end

function preBackspace(view)
	if view == sidebar_view then
		return false
	end
	return true
end

function preCursorLeft(view)
	if view == sidebar_view then
		local entry = line_to_entry[view.Cursor.Loc.Y]
		if entry and entry.is_dir and expanded[entry.path] then
			expanded[entry.path] = false
			refresh_view()
		end
		return false
	end
	return true
end

function preCursorRight(view)
	if view == sidebar_view then
		local entry = line_to_entry[view.Cursor.Loc.Y]
		if entry and entry.is_dir and not expanded[entry.path] then
			expanded[entry.path] = true
			refresh_view()
		end
		return false
	end
	return true
end

function preCursorUp(view)
	if view == sidebar_view then
		if view.Cursor.Loc.Y <= list_start_y then
			return false
		end
	end
	return true
end

function onCursorUp(view)
	if view == sidebar_view then
		set_cursor(view.Cursor.Loc.Y)
	end
end

function onCursorDown(view)
	if view == sidebar_view then
		set_cursor(view.Cursor.Loc.Y)
	end
end

function onCursorPageUp(view)
	if view == sidebar_view then
		set_cursor(view.Cursor.Loc.Y)
	end
end

function onCursorPageDown(view)
	if view == sidebar_view then
		set_cursor(view.Cursor.Loc.Y)
	end
end

function onCursorStart(view)
	if view == sidebar_view then
		set_cursor(view.Cursor.Loc.Y)
	end
end

function onCursorEnd(view)
	if view == sidebar_view then
		set_cursor(view.Cursor.Loc.Y)
	end
end

function onJumpLine(view)
	if view == sidebar_view then
		set_cursor(view.Cursor.Loc.Y)
	end
end

function onNextSplit(view)
	if view == sidebar_view then
		set_cursor(view.Cursor.Loc.Y)
	end
end

function onPreviousSplit(view)
	if view == sidebar_view then
		set_cursor(view.Cursor.Loc.Y)
	end
end

function preMousePress(view, event)
	if view == sidebar_view then
		return true
	end
	return true
end

function onMousePress(view, event)
	if view == sidebar_view then
		set_cursor(view.Cursor.Loc.Y)
		activate_entry(view.Cursor.Loc.Y)
	end
end

function onSetActive(view)
	if view == sidebar_view then
		sidebar_focused = true
	else
		sidebar_focused = false
	end
	if view ~= nil and view ~= sidebar_view then
		last_editor_pane = view
	end
end

function onBufPaneOpen(view)
	if view ~= nil and view ~= sidebar_view then
		last_editor_pane = view
	end
end

function preCommandMode(view)
	precmd_dir = os.Getwd()
	return true
end

function onCommandMode(view)
	local new_dir = os.Getwd()
	if sidebar_view ~= nil and new_dir ~= precmd_dir and new_dir ~= root_dir then
		set_root_dir(new_dir)
	end
end

function preQuit(view)
	if sidebar_view ~= nil and pane_count() <= 2 and tab_count() <= 1 then
		view:QuitAll()
		return false
	end
	if view == sidebar_view then
		close_sidebar()
		return false
	end
	return true
end

function preQuitAll(view)
	close_sidebar()
	return true
end

function init()
	config.RegisterCommonOption("galakticsidebar", "showdotfiles", true)
	config.RegisterCommonOption("galakticsidebar", "showignored", true)
	config.RegisterCommonOption("galakticsidebar", "foldersfirst", true)
	config.RegisterCommonOption("galakticsidebar", "icons", true)
	config.RegisterCommonOption("galakticsidebar", "openfocus", false)
	config.RegisterCommonOption("galakticsidebar", "openonstart", "auto")
	config.RegisterCommonOption("galakticsidebar", "width", 30)
	config.RegisterCommonOption("galakticsidebar", "autorefresh", true)
	config.RegisterCommonOption("galakticsidebar", "refreshinterval", 2000)
	config.MakeCommand("sidebar", toggle_sidebar, config.NoComplete)
	config.MakeCommand("sidebar-refresh", refresh_sidebar, config.NoComplete)

	config.AddRuntimeFile("galaktic_sidebar", config.RTHelp, "help/galaktic-sidebar.md")
	config.AddRuntimeFile("galaktic_sidebar", config.RTSyntax, "syntax.yaml")

	if not refresh_timer_started then
		refresh_timer_started = true
		local function tick()
			if config.GetGlobalOption("galakticsidebar.autorefresh") then
				if sidebar_view ~= nil then
					local cwd = os.Getwd()
					if cwd ~= root_dir then
						if sidebar_focused then
							set_root_dir(cwd)
						else
							root_dir = cwd
						end
					else
						if sidebar_focused then
							refresh_view(true)
						end
					end
				end
			end
			local interval = config.GetGlobalOption("galakticsidebar.refreshinterval")
			if type(interval) ~= "number" or interval < 250 then
				interval = 2000
			end
			micro.After(time.Millisecond * interval, tick)
		end
		micro.After(time.Millisecond * 2000, tick)
	end

	if should_open_on_start() then
		if sidebar_view == nil then
			open_sidebar()
		end
	end
end
