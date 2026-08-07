-- init.lua - Superfile-inspired layout for Yazi 26.5.6
-- Adds a bottom info row (Processes | Metadata | Clipboard) and a quick-access bar
-- (Pinned | Home / Downloads / Trash | Disk). Colors follow the existing theme.

local ACCENT = "#89b4fa"
local LABEL = "#a6adc8"
local VALUE = "#cdd6f4"
local MUTED = "#6b7089"
local GREEN = "#a6e3a1"
local RED = "#f38ba8"

-- Pinned directories shown in the quick bar. Edit to taste; each entry has a
-- matching `g`-prefixed jump in keymap.toml.
local HOME = os.getenv("HOME") or ""
local PINNED = {
	{ icon = "", name = "Config", path = HOME .. "/.config" },       -- g c
	{ icon = "", name = "Yazi", path = HOME .. "/.config/yazi" },    -- g y
	{ icon = "", name = "Dotfiles", path = HOME .. "/dotfiles" },    -- g D
}

-- Disk usage is polled at most once every N seconds; df is a subprocess and
-- redraw runs on every keystroke.
local disk_cache = { at = 0, text = nil }

local function disk_usage()
	local now = os.time()
	if disk_cache.text and now - disk_cache.at < 30 then
		return disk_cache.text
	end

	local home = os.getenv("HOME") or "/"
	local handle = io.popen("df -h '" .. home .. "' 2>/dev/null | tail -1")
	if not handle then
		return nil
	end
	local out = handle:read("*a") or ""
	handle:close()

	-- df -h: Filesystem Size Used Avail Use% Mounted-on
	local size, used, avail, pct = out:match("%S+%s+(%S+)%s+(%S+)%s+(%S+)%s+(%d+)%%")
	if not size then
		return nil
	end

	disk_cache.at = now
	disk_cache.text = { used = used, avail = avail, pct = tonumber(pct) }
	return disk_cache.text
end

local function processes_line()
	local summary = cx.tasks.summary
	if summary.total == 0 then
		return ui.Line { ui.Span("idle"):fg(MUTED) }
	end

	local spans = {
		ui.Span(tostring(summary.total)):fg(ACCENT),
		ui.Span(" running"):fg(LABEL),
	}
	if summary.success > 0 then
		spans[#spans + 1] = ui.Span("  " .. summary.success .. " done"):fg(GREEN)
	end
	if summary.failed > 0 then
		spans[#spans + 1] = ui.Span("  " .. summary.failed .. " failed"):fg(RED)
	end
	return ui.Line(spans)
end

local function metadata_line()
	local h = cx.active.current.hovered
	if not h then
		return ui.Line { ui.Span("no selection"):fg(MUTED) }
	end

	local spans = {}
	if h.cha.is_dir then
		local folder = cx.active:history(h.url)
		spans[#spans + 1] = ui.Span("dir"):fg(LABEL)
		if folder then
			spans[#spans + 1] = ui.Span("  " .. #folder.files .. " items"):fg(VALUE)
		end
	else
		spans[#spans + 1] = ui.Span(ya.readable_size(h.cha.len or 0)):fg(VALUE)
	end

	local mtime = math.floor(h.cha.mtime or 0)
	if mtime > 0 then
		spans[#spans + 1] = ui.Span("  " .. os.date("%Y-%m-%d %H:%M", mtime)):fg(LABEL)
	end

	local perm = h.cha:perm()
	if perm then
		spans[#spans + 1] = ui.Span("  " .. perm):fg(MUTED)
	end
	return ui.Line(spans)
end

local function clipboard_line()
	local selected = #cx.active.selected
	local yanked = #cx.yanked

	if yanked > 0 then
		local cut = cx.yanked.is_cut
		return ui.Line {
			ui.Span(tostring(yanked)):fg(cut and RED or GREEN),
			ui.Span(cut and " cut" or " copied"):fg(LABEL),
		}
	elseif selected > 0 then
		return ui.Line {
			ui.Span(tostring(selected)):fg(ACCENT),
			ui.Span(" selected"):fg(LABEL),
		}
	end
	return ui.Line { ui.Span("empty"):fg(MUTED) }
end

-- One panel: a title line, a body line, and an optional left divider.
-- The divider starts one row below the top border so it doesn't punch a hole in it.
local function panel(area, icon, title, body, with_divider)
	local els = {
		ui.Text({
			ui.Line { ui.Span(icon .. " " .. title):fg(ACCENT) },
			body,
		}):area(area:pad(ui.Pad(1, 1, 0, 2))),
	}
	if with_divider and area.h > 1 then
		els[#els + 1] = ui.Bar(ui.Edge.LEFT)
			:area(ui.Rect { x = area.x, y = area.y + 1, w = area.w, h = area.h - 1 })
			:symbol("│")
			:style(ui.Style():fg(MUTED))
	end
	return els
end

local InfoRow = { _id = "info_row" }

function InfoRow:new(area) return setmetatable({ _area = area }, { __index = self }) end

function InfoRow:reflow() return { self } end

function InfoRow:redraw()
	local chunks = ui.Layout()
		:direction(ui.Layout.HORIZONTAL)
		:constraints({
			ui.Constraint.Ratio(1, 3),
			ui.Constraint.Ratio(1, 3),
			ui.Constraint.Ratio(1, 3),
		})
		:split(self._area)

	local els = {
		ui.Bar(ui.Edge.TOP):area(self._area):symbol("─"):style(ui.Style():fg(MUTED)),
	}
	local function append(t)
		for _, e in ipairs(t) do
			els[#els + 1] = e
		end
	end

	append(panel(chunks[1], "󱎫", "Processes", processes_line(), false))
	append(panel(chunks[2], "", "Metadata", metadata_line(), true))
	append(panel(chunks[3], "󰅌", "Clipboard", clipboard_line(), true))
	return els
end

local QuickBar = { _id = "quick_bar" }

function QuickBar:new(area) return setmetatable({ _area = area }, { __index = self }) end

function QuickBar:reflow() return { self } end

function QuickBar:redraw()
	local cwd = tostring(cx.active.current.cwd)
	local home = HOME

	-- A shortcut renders highlighted when the cwd is currently inside it.
	local function shortcut(icon, name, path)
		local active = path ~= "" and (cwd == path or cwd:sub(1, #path + 1) == path .. "/")
		return {
			ui.Span(" " .. icon .. " "):fg(active and ACCENT or LABEL),
			ui.Span(name):fg(active and VALUE or MUTED),
		}
	end

	local left = { ui.Span(" 󰐃 Pinned"):fg(ACCENT), ui.Span(" │"):fg(MUTED) }
	local function append(t)
		for _, s in ipairs(t) do
			left[#left + 1] = s
		end
	end

	for _, p in ipairs(PINNED) do
		append(shortcut(p.icon, p.name, p.path))
	end
	left[#left + 1] = ui.Span("  │"):fg(MUTED)
	append(shortcut("", "Home", home))
	append(shortcut("", "Downloads", home .. "/Downloads"))
	append(shortcut("󰩹", "Trash", home .. "/.local/share/Trash/files"))

	local right
	local disk = disk_usage()
	if disk then
		local tone = disk.pct >= 90 and RED or (disk.pct >= 75 and "#f9e2af" or GREEN)
		right = ui.Line {
			ui.Span("󰋊 "):fg(ACCENT),
			ui.Span(disk.used):fg(VALUE),
			ui.Span(" used  "):fg(LABEL),
			ui.Span(disk.avail):fg(VALUE),
			ui.Span(" free  "):fg(LABEL),
			ui.Span(disk.pct .. "% "):fg(tone),
		}
	else
		right = ui.Line { ui.Span("󰋊 n/a "):fg(MUTED) }
	end

	return {
		ui.Line(left):area(self._area),
		right:area(self._area):align(ui.Align.RIGHT),
	}
end

-- Root override: insert the info row and quick bar above the status line.
function Root:layout()
	self._chunks = ui.Layout()
		:direction(ui.Layout.VERTICAL)
		:constraints({
			ui.Constraint.Length(1),             -- Header
			ui.Constraint.Length(Tabs.height()), -- Tabs
			ui.Constraint.Fill(1),               -- Tab (parent | current | preview)
			ui.Constraint.Length(3),             -- Info row
			ui.Constraint.Length(1),             -- Quick bar
			ui.Constraint.Length(1),             -- Status
		})
		:split(self._area)
end

function Root:build()
	self._children = {
		Header:new(self._chunks[1], cx.active),
		Tabs:new(self._chunks[2]),
		Tab:new(self._chunks[3], cx.active),
		InfoRow:new(self._chunks[4]),
		QuickBar:new(self._chunks[5]),
		Status:new(self._chunks[6], cx.active),
		Modal:new(self._area),
	}
end
