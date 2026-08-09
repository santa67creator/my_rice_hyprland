-- init.lua - Superfile-inspired layout for Yazi
-- Adds a bottom info row (Processes | Metadata | Clipboard) and a quick-access bar
-- (Pinned | Home / Downloads / Trash | Disk). Colors follow the existing theme.

-- Cross-instance yank: yanking in one window makes the files pasteable in every
-- other running window. Rides DDS, so the state also survives a restart.
-- Instances started before this line loads won't participate -- restart them all.
require("session"):setup { sync_yanked = true }

-- Receiver for the `<A-p>` binding in keymap.toml, which yanks and then broadcasts
-- to every other instance. The yanked list itself is already synced by `session`
-- above, so this only has to be a "now paste" nudge -- shipping the file list here
-- would just mean reassembling it on the far side for no gain.
ps.sub_remote("yank-push", function() ya.emit("paste", {}) end)

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

-- ---------------------------------------------------------------------------
-- Drag a file row onto another directory to move it, within this one window.
--
-- Yazi 26.5.6 only ships drag-and-drop with *other* applications: Current:drag
-- answers the terminal's OSC-72 "offer" by handing the selection to the system
-- drag, and Current:drop deliberately refuses a drag that yazi itself started.
-- Nothing handles a drag that begins and ends inside this window, and Parent
-- and Preview have no drag hook at all.
--
-- Legacy mouse drags arrive as Root:drag with event.type == "legacy"; OSC-72
-- drags come through the same hook as "offer"/"land"/"end". Only the legacy
-- ones are claimed below, so dragging out to a GUI app and Rail's
-- drag-to-resize both keep their existing behaviour.
--
-- Two constraints from the preset shape this code. Root:drag always dispatches
-- to the component the press *started* on, never the one under the cursor, so
-- the drop target is hit-tested here. And component tables outlive an event
-- while the userdata inside them (_folder, _tab, files) does not -- it is
-- scoped to a single event -- hence the owned Url() copies and the re-lookup
-- by _id rather than stashing the component itself.
local saved_root_click, saved_root_drag = Root.click, Root.drag

-- src: { id, url, cwd } captured on press. files: owned Urls, filled on the
-- first drag event. area/label: the drop-target highlight, nil when parked.
local drag = {}

-- A pane is any component exposing a folder: parent, current, preview when it
-- is listing a directory, and each side of the split-tabs layout (its Pane
-- wrapper delegates reflow to the inner Current, so that is what surfaces).
local function pane_at(root, event)
	local c = ya.child_at(ui.Rect { x = event.x, y = event.y }, root:reflow())
	return c and c._folder and c or nil
end

local function row_at(c, event)
	local w = c._folder.window
	return w and w[event.y - c._area.y + 1]
end

-- Where a release over `c` would put the files: the directory under the
-- cursor, else the directory the pane is listing. Returned owned, so it stays
-- valid after this event's scope closes.
local function target_at(c, event)
	local f = row_at(c, event)
	if f and f.cha.is_dir then
		return Url(tostring(f.url))
	end
	return Url(tostring(c._folder.cwd))
end

local function find_pane(root, id)
	for _, c in ipairs(root:reflow()) do
		if c._id == id and c._folder then
			return c
		end
	end
end

local function move_into(to)
	cx.tasks.behavior:reset()
	for _, from in ipairs(drag.files) do
		-- Guard the two no-ops the file tasks would otherwise act on: a file
		-- landing back in its own directory, and a directory dropped into
		-- itself or one of its own descendants.
		if tostring(from.parent) ~= tostring(to) and not to:starts_with(from) then
			local dest = to:join(from.name)
			ya.async(function() ya.task("cut", { from = from, to = dest, force = false }):spawn() end)
		end
	end
end

local function park()
	local shown = drag.area ~= nil
	drag = {}
	if shown then
		ui.render()
	end
end

function Root:click(event, up)
	if up then
		if drag.files then
			local c = pane_at(self, event)
			if c then
				move_into(target_at(c, event))
			end
		end
		park()
	elseif event.is_left then
		-- Remember the press, cheaply. The selection is read later, on the
		-- first actual drag, so a plain click costs one Url copy.
		local c = pane_at(self, event)
		local f = c and row_at(c, event)
		drag = f and { id = c._id, url = Url(tostring(f.url)), cwd = tostring(c._folder.cwd) } or {}
	end

	return saved_root_click(self, event, up)
end

function Root:drag(event)
	if event.type ~= "legacy" or not (drag.id and event.is_left) then
		return saved_root_drag(self, event) -- OSC-72 drag-out, rail resize
	end

	if not drag.files then
		local src = find_pane(self, drag.id)
		local files = {}
		-- Move the whole selection when there is one, matching yank/paste and
		-- dnd.selected_uri_list. Read from the source pane's own tab, which is
		-- not necessarily the active one while split. Iterating `selected`
		-- yields File, not Url -- same as dnd.selected_uri_list does.
		for _, f in pairs(src and src._tab.selected or {}) do
			files[#files + 1] = Url(tostring(f.url))
		end
		drag.files = #files > 0 and files or { drag.url }
	end

	local c = pane_at(self, event)
	local to = c and target_at(c, event)
	local area, label
	if to and tostring(to) ~= drag.cwd then
		area = c._area
		label = string.format("Move %d file(s) to %s", #drag.files, tostring(to.name or to))
	end

	if tostring(drag.label) ~= tostring(label) then
		drag.area, drag.label = area, label
		ui.render()
	end
end

-- Highlight for the pane the files would land in. reflow returns nothing so it
-- never becomes a hit-test target itself.
local DropTip = { _id = "drop_tip" }

function DropTip:new(area, text) return setmetatable({ _area = area, _text = text }, { __index = self }) end

function DropTip:reflow() return {} end

function DropTip:redraw() return Tip:new(self._area, self._text):redraw() end

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
	-- Backdrop must stay first: it paints the full area and everything else draws
	-- on top. It is not in Yazi 26.5.6's preset -- if this config is ever rolled
	-- back to stable, drop this line or Root:build will call a nil global.
	self._children = {
		Backdrop:new(self._area),
		Header:new(self._chunks[1], cx.active),
		Tabs:new(self._chunks[2]),
		Tab:new(self._chunks[3], cx.active),
		InfoRow:new(self._chunks[4]),
		QuickBar:new(self._chunks[5]),
		Status:new(self._chunks[6], cx.active),
		Modal:new(self._area),
	}

	-- Last, so the drop hint paints over the panes rather than under them.
	if drag.area then
		self._children[#self._children + 1] = DropTip:new(drag.area, drag.label)
	end
end
