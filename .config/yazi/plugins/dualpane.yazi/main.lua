--- @since 26.5.6
--- @sync entry

-- Companion to split-tabs.yazi. split-tabs draws the two panes; this decides
-- which tab each pane is and drives the file operations between them.
--
--   toggle     -- split / unsplit
--   smart_tab  -- switch panes while split, spot the hovered file otherwise
--   copy/move  -- send the selection to the other pane
--   preset     -- put a directory in each pane, splitting first if needed
--
-- split-tabs keeps its pane pair in a module-local, so nothing here can read
-- it. Instead `toggle` recomputes the same pair with the same rule and keeps
-- it in `pair` below -- see activate() in split-tabs' main.lua:201-212.

local pair = nil -- { left_tab, right_tab }, 1-based, only while split

local function warn(msg)
	ya.notify { title = "Dual pane", content = msg, timeout = 3, level = "warn" }
end

-- split-tabs is driven through the native `plugin` command, never require().
-- Yazi's require() yields to load the file and a `@sync entry` is not a
-- coroutine, so requiring it -- lazily *or* at main-chunk load -- dies with
-- "attempt to yield from outside a coroutine". The command goes on the same
-- queue as everything else here, which is what makes the ordering below work.
local function split_tabs(act) ya.emit("plugin", { "split-tabs", act }) end

-- split-tabs collapses the tab strip to zero rows while it is active. The
-- preset Tabs.height() also returns 0 for a lone tab, hence the count check.
local function is_split() return #cx.tabs >= 2 and Tabs.height() == 0 end

local function toggle()
	if is_split() then
		pair = nil
		return split_tabs("spl_toggle")
	end

	local n, cur = #cx.tabs, cx.tabs.idx
	if n < 2 then
		-- Create the partner tab here rather than letting split-tabs do it.
		-- Its activate() emits `tab_create` from inside the queued plugin call,
		-- which lands *behind* anything preset() queues next -- the cd's would
		-- then run against a tab that does not exist yet. Doing it up front also
		-- pins the pair to {1, 2}: tab_create focuses the tab it made, so hop
		-- back to tab 1 before split-tabs reads cx.tabs.idx to pick its pair.
		ya.emit("tab_create", { cx.active.current.cwd })
		ya.emit("tab_switch", { 0 })
		pair = { 1, 2 }
	else
		-- Mirrors split-tabs' own choice of second pane.
		pair = { cur, cur < n and cur + 1 or 1 }
	end

	split_tabs("spl_toggle")
end

-- <Tab> keeps doing what it always did when there is nothing to switch between.
local function smart_tab()
	if is_split() then
		split_tabs("spl_switch_tab")
	else
		ya.emit("spot", {})
	end
end

-- The focused tab and its partner, 1-based. nil if focus wandered out of the
-- pair (pressing 1-9 while split, or toggling split-tabs directly).
local function ends()
	if not is_split() or not pair then
		warn("Not split -- press \\ first")
		return
	end
	local here = cx.tabs.idx
	if here ~= pair[1] and here ~= pair[2] then
		warn("Focus is outside the pane pair")
		return
	end
	return here, here == pair[1] and pair[2] or pair[1]
end

-- `paste` has no --to, so the only way to keep Yazi's overwrite prompts and
-- task-manager progress is to go there, paste, and come back. These are native
-- commands, and emitted commands run in the order they were queued.
local function send(cut)
	local here, there = ends()
	if not here then return end

	ya.emit("yank", cut and { cut = true } or {})
	ya.emit("tab_switch", { there - 1 })
	ya.emit("paste", {})
	ya.emit("tab_switch", { here - 1 })
end

local function expand(p)
	local home = os.getenv("HOME") or ""
	if p == "~" then return home end
	return (p:gsub("^~/", home .. "/"))
end

-- Splits first if needed, so this is a one-press "these two, side by side".
--
-- Addresses the panes by absolute pair index rather than here/there: when the
-- split is being created in this same keypress, cx.tabs.idx still reads the old
-- focus, and the tab_switch queued by toggle() has not moved it yet. Pair index
-- is correct either way, and it pins `a` to the left pane and `b` to the right
-- instead of letting the result depend on which side happened to be focused.
local function preset(a, b)
	if not a or not b then return warn("preset needs two paths") end
	if not is_split() then toggle() end
	if not pair then return warn("Dual pane did not activate") end

	ya.emit("tab_switch", { pair[1] - 1 })
	ya.emit("cd", { expand(a) })
	ya.emit("tab_switch", { pair[2] - 1 })
	ya.emit("cd", { expand(b) })
	ya.emit("tab_switch", { pair[1] - 1 })
end

return {
	entry = function(_, job)
		local args = type(job) == "string" and { job } or job.args
		local act = args[1]
		ya.dbg("DUALPANE args: " .. tostring(args[1]) .. " | " .. tostring(args[2]) .. " | " .. tostring(args[3]))

		if act == "toggle" then
			toggle()
		elseif act == "smart_tab" then
			smart_tab()
		elseif act == "copy" then
			send(false)
		elseif act == "move" then
			send(true)
		elseif act == "preset" then
			preset(args[2], args[3])
		end
	end,
}
