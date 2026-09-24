local M = {}
local ui_ns = vim.api.nvim_create_namespace("packload")
local ui_win

---@param plugin packload.Plugin
---@param State table
---@param names table<integer, string>
---@return packload.StateName
local function state_name(plugin, State, names)
	if plugin.state == State.REGISTERED and plugin.error then
		return "failed"
	end
	return names[plugin.state]
end

---@param plugin packload.Plugin
---@param list fun(value: string|string[]|nil): string[]
---@return string[]
local function plugin_triggers(plugin, list)
	local triggers = {}
	if plugin.lazy == false then
		return triggers
	end
	for _, event in ipairs(list(plugin.event)) do
		triggers[#triggers + 1] = "event:" .. event
	end
	for _, ft in ipairs(list(plugin.ft)) do
		triggers[#triggers + 1] = "ft:" .. ft
	end
	for _, command in ipairs(list(plugin.cmd)) do
		triggers[#triggers + 1] = "cmd:" .. command
	end
	for _, key in ipairs(plugin.keys or {}) do
		triggers[#triggers + 1] = "keys:" .. key[1]
	end
	return triggers
end

---@param core table
---@param opts? packload.StatusOpts|string
---@return packload.StatusItem[]
function M.status(core, opts)
	if type(opts) == "string" then
		opts = { name = opts }
	end
	opts = opts or {}

	local private = core._private
	local plugins, State, list = private.plugins, private.State, private.list
	local state_names = {
		[State.REGISTERED] = "registered",
		[State.LOADING] = "loading",
		[State.LOADED] = "loaded",
	}

	local wanted
	if opts.state ~= nil and opts.state ~= "all" then
		wanted = {}
		for _, state in ipairs(list(opts.state)) do
			wanted[state] = true
		end
	end
	local needle = opts.match and opts.match:lower() or nil

	local names
	if opts.name then
		assert(plugins[opts.name], "unknown packload plugin: " .. opts.name)
		names = { opts.name }
	else
		names = vim.tbl_keys(plugins)
		table.sort(names)
	end

	local required_by = {}
	for name, plugin in pairs(plugins) do
		for _, dep in ipairs(plugin.after) do
			required_by[dep] = required_by[dep] or {}
			required_by[dep][#required_by[dep] + 1] = name
		end
	end

	local out = {}
	for _, name in ipairs(names) do
		local plugin = plugins[name]
		local state = state_name(plugin, State, state_names)
		local keep = (not wanted or wanted[state])
			and (not needle or name:lower():find(needle, 1, true) ~= nil)
			and (opts.eager == nil or (plugin.eager == true) == opts.eager)
		if keep then
			local dependents = required_by[name] or {}
			table.sort(dependents)
			out[#out + 1] = {
				name = name,
				state = state,
				src = plugin.src,
				version = plugin.version,
				path = plugin.path,
				eager = plugin.eager == true,
				load_time_ns = plugin.load_time_ns,
				triggers = plugin_triggers(plugin, list),
				depends_on = plugin.after,
				required_by = dependents,
				error = plugin.error,
			}
		end
	end
	return out
end

local STATE_ORDER = { failed = 1, loading = 2, registered = 3, loaded = 4 }
local STATE_ICON = { failed = "✗", loading = "◐", registered = "○", loaded = "●" }
local STATE_HL = {
	failed = "DiagnosticError",
	loading = "DiagnosticInfo",
	registered = "DiagnosticWarn",
	loaded = "DiagnosticOk",
}
local STATE_FILTERS = { "all", "failed", "registered", "loaded" }

---@param nlines integer
local function ui_geometry(nlines)
	local width = math.min(vim.o.columns - 4, 110)
	local height = math.max(3, math.min(nlines, vim.o.lines - 6))
	return {
		relative = "editor",
		width = width,
		height = height,
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
	}
end

---Open the floating status window.
---@param core table
---@param opts? packload.StatusOpts
function M.open(core, opts)
	opts = vim.deepcopy(opts or {})
	if ui_win and vim.api.nvim_win_is_valid(ui_win) then
		vim.api.nvim_win_close(ui_win, true)
	end
	local prev_win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "packload"
	local win = vim.api.nvim_open_win(
		buf,
		true,
		vim.tbl_extend("force", ui_geometry(10), {
			style = "minimal",
			border = "rounded",
			title = " packload ",
			title_pos = "center",
		})
	)
	ui_win = win
	vim.wo[win].cursorline = true
	vim.wo[win].wrap = false

	local expanded = {}
	local selected = {}
	local line_items = {}
	local header_line = {}
	local first_render = true

	local function render()
		local cursor_row = first_render and 4 or vim.api.nvim_win_get_cursor(win)[1]
		first_render = false

		local items = M.status(core, opts)
		table.sort(items, function(a, b)
			if a.state ~= b.state then
				return STATE_ORDER[a.state] < STATE_ORDER[b.state]
			end
			return a.name < b.name
		end)

		local lines, marks = {}, {}
		line_items, header_line = {}, {}

		---@param segments { [1]: string, [2]?: string }[]
		---@param item? packload.StatusItem
		local function add(segments, item)
			local text, col, lnum = "", 0, #lines
			for _, segment in ipairs(segments) do
				local chunk, hl = segment[1], segment[2]
				if hl and #chunk > 0 then
					marks[#marks + 1] = { lnum, col, col + #chunk, hl }
				end
				text = text .. chunk
				col = col + #chunk
			end
			lines[#lines + 1] = text
			if item then
				line_items[#lines] = item
			end
		end

		local selected_count = 0
		for _ in pairs(selected) do
			selected_count = selected_count + 1
		end
		local filter = opts.state and table.concat(core._private.list(opts.state), ",") or "all"
		add({
			{ " packload", "Title" },
			{
				string.format(
					"  %d plugin%s · %d selected · filter: %s",
					#items,
					#items == 1 and "" or "s",
					selected_count,
					filter
				),
				"Comment",
			},
		})
		add({
			{
				" <Space> select  A all  B build  U update  D delete  <CR> open  <Tab> details  gx url  L load  F filter  R refresh  q close",
				"Comment",
			},
		})
		add({ { "" } })

		local name_width = 0
		for _, item in ipairs(items) do
			name_width = math.max(name_width, #item.name)
		end

		for _, item in ipairs(items) do
			local trigger_text = item.eager and "eager"
				or (#item.triggers > 0 and table.concat(item.triggers, " ") or "manual")
			local selection = selected[item.name] and "[x]" or "[ ]"
			header_line[item.name] = #lines + 1
			add({
				{ " " .. selection .. " ", selected[item.name] and "DiagnosticOk" or "Comment" },
				{ " " .. STATE_ICON[item.state] .. " ", STATE_HL[item.state] },
				{ string.format("%-" .. name_width .. "s", item.name) },
				{ "  " .. string.format("%-10s", item.state), STATE_HL[item.state] },
				{ "  " .. trigger_text, "Comment" },
			}, item)

			if expanded[item.name] then
				local function detail(label, value)
					if value and value ~= "" then
						add({ { "      " .. label .. ": ", "Comment" }, { value } }, item)
					end
				end
				detail("src", item.src)
				detail("version", item.version ~= nil and tostring(item.version) or nil)
				detail("path", item.path)
				detail(
					item.eager and "startup time" or "load time",
					item.load_time_ns and string.format("%.2f ms", item.load_time_ns / 1e6) or nil
				)
				detail("after", #item.depends_on > 0 and table.concat(item.depends_on, ", ") or nil)
				detail("required by", #item.required_by > 0 and table.concat(item.required_by, ", ") or nil)
				detail("error", item.error and item.error:match("[^\n]+") or nil)
			end
		end

		if #items == 0 then
			add({ { " no plugins match", "Comment" } })
		end

		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].modifiable = false
		vim.api.nvim_buf_clear_namespace(buf, ui_ns, 0, -1)
		for _, mark in ipairs(marks) do
			vim.api.nvim_buf_set_extmark(buf, ui_ns, mark[1], mark[2], {
				end_col = mark[3],
				hl_group = mark[4],
			})
		end

		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_set_config(win, ui_geometry(#lines))
			pcall(vim.api.nvim_win_set_cursor, win, { math.min(cursor_row, #lines), 0 })
		end
	end

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	local function current_item()
		return line_items[vim.api.nvim_win_get_cursor(win)[1]]
	end

	local function target_names()
		local names = {}
		for name in pairs(selected) do
			names[#names + 1] = name
		end
		if #names == 0 then
			local item = current_item()
			if item then
				names[1] = item.name
			end
		end
		table.sort(names)
		return names
	end

	local function run_pack_action(action)
		local names = target_names()
		if #names == 0 then
			return
		end

		local ok, err = xpcall(function()
			if action == "build" then
				core.build(names)
			elseif action == "update" then
				core.update(names)
			else
				core.delete(names)
			end
		end, debug.traceback)
		if not ok then
			vim.notify("[packload] " .. action .. " failed:\n" .. err, vim.log.levels.ERROR)
			return
		end

		selected = {}
		local past_tense = { build = "built", update = "updated", delete = "deleted" }
		vim.notify("[packload] " .. past_tense[action] .. " " .. table.concat(names, ", "), vim.log.levels.INFO)
		render()
	end

	local function map(lhs, fn, desc)
		vim.keymap.set("n", lhs, fn, {
			buf = buf,
			nowait = true,
			silent = true,
			desc = "packload: " .. desc,
		})
	end

	map("q", close, "close")
	map("<Esc>", close, "close")
	map("R", render, "refresh")

	map("<Space>", function()
		local item = current_item()
		if not item then
			return
		end
		selected[item.name] = not selected[item.name] or nil
		render()
		pcall(vim.api.nvim_win_set_cursor, win, { header_line[item.name] or 1, 0 })
	end, "select plugin")

	map("A", function()
		local items = M.status(core, opts)
		local all_selected = #items > 0
		for _, item in ipairs(items) do
			if not selected[item.name] then
				all_selected = false
				break
			end
		end
		if all_selected then
			for _, item in ipairs(items) do
				selected[item.name] = nil
			end
		else
			for _, item in ipairs(items) do
				selected[item.name] = true
			end
		end
		render()
	end, "select all plugins")

	map("F", function()
		local current = type(opts.state) == "string" and opts.state or "all"
		local index = 1
		for i, state in ipairs(STATE_FILTERS) do
			if state == current then
				index = i
				break
			end
		end
		local next_state = STATE_FILTERS[index % #STATE_FILTERS + 1]
		opts.state = next_state ~= "all" and next_state or nil
		render()
	end, "cycle state filter")

	map("<Tab>", function()
		local item = current_item()
		if not item then
			return
		end
		expanded[item.name] = not expanded[item.name] or nil
		render()
		pcall(vim.api.nvim_win_set_cursor, win, { header_line[item.name] or 1, 0 })
	end, "toggle details")

	map("<CR>", function()
		local item = current_item()
		if not item then
			return
		end
		if not item.path then
			vim.notify("[packload] " .. item.name .. " has no install path yet", vim.log.levels.WARN)
			return
		end
		close()
		if vim.api.nvim_win_is_valid(prev_win) then
			vim.api.nvim_set_current_win(prev_win)
		end
		vim.cmd.edit(item.path)
	end, "open plugin directory")

	map("gx", function()
		local item = current_item()
		if item then
			vim.ui.open(item.src)
		end
	end, "open source URL")

	map("L", function()
		local item = current_item()
		if not item then
			return
		end
		if item.state == "loaded" then
			vim.notify("[packload] " .. item.name .. " is already loaded", vim.log.levels.INFO)
			return
		end
		core.trigger(item.name)
		render()
	end, "load plugin now")

	map("U", function()
		run_pack_action("update")
	end, "update selected plugins")

	map("B", function()
		run_pack_action("build")
	end, "build selected plugins")

	map("D", function()
		run_pack_action("delete")
	end, "delete selected plugins")

	vim.api.nvim_create_autocmd("WinLeave", {
		buffer = buf,
		once = true,
		callback = function()
			vim.schedule(close)
		end,
	})

	render()
end

return M
