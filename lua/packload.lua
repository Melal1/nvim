---@class packload.KeySpec
---@field [1] string Left-hand side of the mapping.
---@field [2]? fun()|string Callback or right-hand side to run after the plugin has loaded.
---@field mode? string|string[] Mapping mode. Defaults to normal mode.
---@field run? fun()|string Callback or right-hand side to run after the plugin has loaded.
---@field desc? string Mapping description.
---@field silent? boolean Whether to suppress command-line output.

---@class packload.PluginSpec
---@field src string Git source accepted by vim.pack.add().
---@field name? string Package name. Defaults to the final component of `src`.
---@field version? string|vim.VersionRange Version accepted by vim.pack.add().
---@field event? string|string[] Autocmd event(s) that load the plugin.
---@field ft? string|string[] Filetype(s) that load the plugin.
---@field cmd? string|string[] User command(s) that load the plugin.
---@field keys? packload.KeySpec[] Keymaps that load the plugin and invoke a callback.
---@field after? string|string[] Hard dependencies that must load before this plugin.
---@field priority? integer Eager plugin load order. Higher values load first; ties use declaration order.
---@field build? string|fun(path: string) Hook run after installation or update. Shell strings run in `path`; `:` strings and functions load the plugin first.
---@field lazy? boolean `true` skips eager loading; `false` ignores lazy triggers and loads eagerly.
---@field event_replay? boolean Replay the triggering event for newly created augroups. Defaults to true.
---@field config? fun() Runs once after the plugin is loaded.

---@class packload.Plugin: packload.PluginSpec
---@field name string
---@field after string[]
---@field seq integer Registration sequence, used to break ordering ties.
---@field state integer
---@field autocmds integer[]
---@field commands string[]
---@field keymaps { mode: string, lhs: string, temporary: boolean }[]
---@field path? string

local M = {}

---@enum packload.State
local State = {
	REGISTERED = 0,
	LOADING = 1,
	LOADED = 2,
	FAILED = 3,
}

---@type table<string, packload.Plugin>
local plugins = {}

local build_autocmd
local load_plugin
local register_autocmds
local flush_builds

---@type packload.Plugin[]
local build_queue = {}
---@type table<string, true>
local build_queued = {}
local build_flush_scheduled = false
local registration_seq = 0

---@param value string|string[]|nil
---@return string[]
local function list(value)
	if value == nil then
		return {}
	end
	return type(value) == "table" and value or { value }
end

---@param src string
---@return string
local function name_from_src(src)
	while #src > 0 and src:sub(-1) == "/" do
		src = src:sub(1, -2)
	end

	if src:sub(-4) == ".git" then
		src = src:sub(1, -5)
	end

	local i = #src
	while i > 0 do
		if src:sub(i, i) == "/" then
			src = src:sub(i + 1, -1)
			break
		end
		i = i - 1
	end

	return src
end

---@param value unknown
---@param field string
local function validate_string_list(value, field)
	if value == nil then
		return
	end
	if type(value) == "table" and not vim.islist(value) then
		error("packload " .. field .. " must be a list: " .. vim.inspect(value), 2)
	end

	local values = list(value)

	for _, item in ipairs(values) do
		if type(item) ~= "string" then
			error("packload " .. field .. " must contain only strings: " .. vim.inspect(value), 2)
		end
	end
end

---@param spec packload.PluginSpec
local function validate_spec(spec)
	if type(spec) ~= "table" then
		error("packload malformed plugin spec: " .. vim.inspect(spec), 2)
	end
	if type(spec.src) ~= "string" or spec.src == "" then
		error("packload plugin spec requires a non-empty src: " .. vim.inspect(spec), 2)
	end
	-- if spec.name ~= nil then
	-- 	if type(spec.name) ~= "string" or spec.name == "" then
	-- 		error("packload plugin spec has an invalid name: " .. vim.inspect(spec), 2)
	-- 	end
	-- end
	-- if spec.version ~= nil then
	-- 	if type(spec.version) ~= "string" and type(spec.version) ~= "table" then
	-- 		error("packload plugin spec has an invalid version: " .. vim.inspect(spec), 2)
	-- 	end
	-- end

	validate_string_list(spec.event, "plugin event")
	validate_string_list(spec.ft, "plugin filetype")
	validate_string_list(spec.cmd, "plugin command")
	validate_string_list(spec.after, "plugin dependency")

	if spec.priority ~= nil then
		if type(spec.priority) ~= "number" or spec.priority % 1 ~= 0 then
			error("packload plugin spec has an invalid priority: " .. vim.inspect(spec), 2)
		end
	end
	if spec.build ~= nil then
		if type(spec.build) ~= "string" and type(spec.build) ~= "function" then
			error("packload plugin spec has an invalid build: " .. vim.inspect(spec), 2)
		end
	end
	if spec.lazy ~= nil then
		if type(spec.lazy) ~= "boolean" then
			error("packload plugin spec has an invalid lazy flag: " .. vim.inspect(spec), 2)
		end
	end
	if spec.event_replay ~= nil then
		if type(spec.event_replay) ~= "boolean" then
			error("packload plugin spec has an invalid event_replay flag: " .. vim.inspect(spec), 2)
		end
	end
	if spec.config ~= nil then
		if type(spec.config) ~= "function" then
			error("packload plugin spec has an invalid config: " .. vim.inspect(spec), 2)
		end
	end
	if spec.keys ~= nil then
		if type(spec.keys) ~= "table" then
			error("packload plugin spec keys must be a table: " .. vim.inspect(spec), 2)
		end
		if not vim.islist(spec.keys) then
			error("packload plugin spec keys must be a list: " .. vim.inspect(spec.keys), 2)
		end
		for _, key in ipairs(spec.keys) do
			if type(key) ~= "table" then
				error("packload key spec must be a table: " .. vim.inspect(key), 2)
			end
			if type(key[1]) ~= "string" then
				error("packload key spec requires a string lhs: " .. vim.inspect(key), 2)
			end
			local run = key.run or key[2]
			if run ~= nil and type(run) ~= "function" and type(run) ~= "string" then
				error("packload key spec has an invalid run: " .. vim.inspect(key), 2)
			end
			if key.mode ~= nil then
				validate_string_list(key.mode, "key mode")
			end
			if key.desc ~= nil then
				if type(key.desc) ~= "string" then
					error("packload key spec has an invalid desc: " .. vim.inspect(key), 2)
				end
			end
			if key.silent ~= nil then
				if type(key.silent) ~= "boolean" then
					error("packload key spec has an invalid silent flag: " .. vim.inspect(key), 2)
				end
			end
		end
	end
end

---@param items packload.PluginSpec|packload.PluginSpec[]
---@param result? packload.PluginSpec[]
---@param root? boolean
---@return packload.PluginSpec[]
local function flatten_specs(items, result, root)
	result = result or {}
	if root == nil then
		root = true
	end

	if items.src ~= nil then
		result[#result + 1] = items
		return result
	end

	local length = #items

	if length == 0 then
		local truly_empty = next(items) == nil

		if not root or not truly_empty then
			error("packload malformed plugin spec: " .. vim.inspect(items), 2)
		end
	end

	for i = 1, length do
		local item = items[i]

		if type(item) == "table" then
			flatten_specs(item, result, false)
		end
	end

	return result
end

---@param plugin packload.Plugin
---@return boolean ok
local function run_build(plugin)
	local build = plugin.build

	local needs_runtime = type(build) == "function" or (type(build) == "string" and build:sub(1, 1) == ":")
	if needs_runtime and not load_plugin(plugin) then
		vim.notify("[packload] build skipped for '" .. plugin.name .. "': plugin did not load", vim.log.levels.ERROR)
		return false
	end

	local ok, err = xpcall(function()
		local path = plugin.path
		if type(build) == "function" then
			build(path)
		elseif needs_runtime then
			vim.cmd(build:sub(2))
		else
			local result = vim.system({ "sh", "-c", build }, { cwd = path }):wait()
			assert(result.code == 0, result.stderr)
		end
	end, debug.traceback)
	if not ok then
		vim.notify("[packload] build failed for" .. plugin.name .. " :\n" .. err, vim.log.levels.ERROR)
		return false
	end
	return true
end

flush_builds = function()
	build_flush_scheduled = false
	local queue = build_queue
	build_queue, build_queued = {}, {}
	table.sort(queue, function(a, b)
		return a.seq < b.seq
	end)
	for _, plugin in ipairs(queue) do
		run_build(plugin)
	end
end

---@param plugin packload.Plugin
local function queue_build(plugin)
	if build_queued[plugin.name] then
		return
	end
	build_queued[plugin.name] = true
	build_queue[#build_queue + 1] = plugin
	if not build_flush_scheduled then
		build_flush_scheduled = true
		vim.schedule(flush_builds)
	end
end

local function create_build_autocmd()
	if build_autocmd then
		return
	end
	build_autocmd = vim.api.nvim_create_autocmd("PackChanged", {
		callback = function(event)
			local data = event.data
			if not data or (data.kind ~= "install" and data.kind ~= "update") then
				return
			end
			local spec = data.spec
			local plugin = type(spec) == "table" and plugins[spec.name] or nil
			if not plugin or not plugin.build then
				return
			end
			if type(data.path) ~= "string" or data.path == "" then
				vim.notify("[packload] no path for build of '" .. plugin.name .. "'", vim.log.levels.ERROR)
				return
			end
			plugin.path = data.path
			queue_build(plugin)
		end,
	})
end

---@param plugin packload.Plugin
local function clear_autocmds(plugin)
	for _, id in ipairs(plugin.autocmds) do
		pcall(vim.api.nvim_del_autocmd, id)
	end
	plugin.autocmds = {}
end

---@param plugin packload.Plugin
local function clear_triggers(plugin)
	clear_autocmds(plugin)
	for _, name in ipairs(plugin.commands) do
		pcall(vim.api.nvim_del_user_command, name)
	end
	local persistent_keymaps = {}
	for _, keymap in ipairs(plugin.keymaps) do
		if keymap.temporary then
			pcall(vim.keymap.del, keymap.mode, keymap.lhs)
		else
			table.insert(persistent_keymaps, keymap)
		end
	end
	plugin.commands = {}
	plugin.keymaps = persistent_keymaps
end

---@param event string
---@return table<string, true>
local function autocmd_groups(event)
	local groups = {}
	for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event })) do
		if autocmd.group_name and autocmd.group_name ~= "" then
			groups[autocmd.group_name] = true
		end
	end
	return groups
end

---@param event string
---@param ev table
---@param before table<string, true>
local function replay_event(event, ev, before)
	local groups = {}
	for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event })) do
		local group = autocmd.group_name
		if group and group ~= "" and not before[group] then
			groups[group] = true
		end
	end
	local ordered_groups = vim.tbl_keys(groups)
	table.sort(ordered_groups)
	if #ordered_groups == 0 then
		return
	end
	vim.schedule(function()
		for _, group in ipairs(ordered_groups) do
			local opts = {
				group = group,
				data = ev.data,
				modeline = false,
			}
			if ev.buf and vim.api.nvim_buf_is_valid(ev.buf) then
				opts.buffer = ev.buf
			elseif ev.match then
				opts.pattern = ev.match
			end
			pcall(vim.api.nvim_exec_autocmds, event, opts)
		end
	end)
end

---@param plugin packload.Plugin
---@return boolean has_trigger
register_autocmds = function(plugin)
	local has_trigger = false
	for _, event in ipairs(list(plugin.event)) do
		has_trigger = true
		table.insert(
			plugin.autocmds,
			vim.api.nvim_create_autocmd(event, {
				once = true,
				callback = function(ev)
					if plugin.state == State.LOADED then
						return
					end
					local before = autocmd_groups(ev.event)
					if load_plugin(plugin) and plugin.event_replay ~= false then
						replay_event(ev.event, ev, before)
					end
				end,
			})
		)
	end

	for _, ft in ipairs(list(plugin.ft)) do
		has_trigger = true
		table.insert(
			plugin.autocmds,
			vim.api.nvim_create_autocmd("FileType", {
				pattern = ft,
				once = true,
				callback = function()
					load_plugin(plugin)
				end,
			})
		)
	end
	return has_trigger
end

---@param plugin packload.Plugin
---@param message string
---@param level integer
---@return boolean
local function fail_plugin(plugin, message, level)
	plugin.state = State.FAILED
	vim.notify(message, level)
	return false
end

---@param plugin packload.Plugin
---@return boolean loaded
load_plugin = function(plugin)
	if plugin.state == State.LOADED then
		return true
	end
	if plugin.state == State.LOADING then
		vim.notify("[packload] circular dependency involving " .. plugin.name, vim.log.levels.ERROR)
		return false
	end
	plugin.state = State.LOADING

	local missing_dep = false
	for _, dep in ipairs(list(plugin.after)) do
		local dependency = plugins[dep]
		if dependency then
			load_plugin(dependency)
			if dependency.state ~= State.LOADED then
				missing_dep = true
			end
		else
			missing_dep = true
			vim.notify("[packload] Missing dependency '" .. dep .. "' for '" .. plugin.name .. "'", vim.log.levels.WARN)
		end
	end

	if missing_dep then
		return fail_plugin(plugin, "[packload] not loading plugin " .. plugin.name, vim.log.levels.WARN)
	end

	clear_triggers(plugin)
	local ok, err = xpcall(function()
		vim.cmd.packadd(plugin.name)
		if plugin.config then
			plugin.config()
		end
	end, debug.traceback)

	if not ok then
		return fail_plugin(
			plugin,
			"[packload] failed to load plugin '" .. plugin.name .. "':\n" .. err,
			vim.log.levels.ERROR
		)
	end

	plugin.state = State.LOADED
	return true
end

---@param plugin packload.Plugin
---@param command string
local function add_command(plugin, command)
	vim.api.nvim_create_user_command(command, function(event)
		if not load_plugin(plugin) then
			return
		end

		local range = event.range > 0 and (event.line1 .. "," .. event.line2) or ""
		local bang = event.bang and "!" or ""
		local args = event.args ~= "" and " " .. event.args or ""
		local mods = event.mods and event.mods ~= "" and (event.mods .. " ") or ""
		vim.cmd(mods .. range .. command .. bang .. args)
	end, {
		bang = true,
		nargs = "*",
		range = true,
	})
	table.insert(plugin.commands, command)
end

---@param plugin packload.Plugin
---@param key packload.KeySpec
local function add_key(plugin, key)
	local lhs = key[1]
	local run = key.run or key[2]

	for _, mode in ipairs(list(key.mode or "n")) do
		vim.keymap.set(mode, lhs, function()
			if not load_plugin(plugin) then
				return
			end

			if run then
				if type(run) == "function" then
					run()
				else
					local keys = vim.api.nvim_replace_termcodes(run, true, false, true)
					vim.api.nvim_feedkeys(keys, "m", false)
				end
			else
				local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
				vim.api.nvim_feedkeys(keys, "m", false)
			end
		end, {
			desc = key.desc,
			silent = key.silent ~= false,
		})
		table.insert(plugin.keymaps, { mode = mode, lhs = lhs, temporary = run == nil })
	end
end

---@param plugin packload.Plugin
---@return boolean has_trigger
local function register(plugin)
	local has_trigger = plugin.lazy == true
	if plugin.lazy ~= false then
		has_trigger = register_autocmds(plugin) or has_trigger

		for _, command in ipairs(list(plugin.cmd)) do
			has_trigger = true
			add_command(plugin, command)
		end

		for _, key in ipairs(plugin.keys or {}) do
			has_trigger = true
			add_key(plugin, key)
		end
	end

	return has_trigger
end

---@param input? packload.PluginSpec|packload.PluginSpec[]
function M.load(input)
	if vim.pack == nil then
		error("[packload] requires Neovim with vim.pack (0.12+)", 2)
	end
	if input == nil then
		return
	end

	local specs = flatten_specs(input)
	if #specs == 0 then
		return
	end

	local resolved = {}
	local batch_names = {}
	for _, spec in ipairs(specs) do
		validate_spec(spec)
		local name = spec.name or name_from_src(spec.src)
		if name == "" then
			error("packload plugin spec resolves to an empty name: " .. vim.inspect(spec), 2)
		end
		assert(plugins[name] == nil, "packload plugin is already registered: " .. name)
		assert(not batch_names[name], "packload plugin is duplicated in this batch: " .. name)
		batch_names[name] = true
		resolved[#resolved + 1] = { spec = spec, name = name }
	end

	---@type vim.pack.Spec[]
	local pack_specs = {}
	---@type packload.Plugin[]
	local eager_plugins = {}
	for _, item in ipairs(resolved) do
		local spec, name = item.spec, item.name
		local after = list(spec.after)
		registration_seq = registration_seq + 1
		---@type packload.Plugin
		local plugin = vim.tbl_extend("force", spec, {
			name = name,
			after = after,
			seq = registration_seq,
			state = State.REGISTERED,
			autocmds = {},
			commands = {},
			keymaps = {},
		})
		plugins[name] = plugin
		pack_specs[#pack_specs + 1] = {
			src = plugin.src,
			name = name,
			version = plugin.version,
		}
	end

	create_build_autocmd()

	local function load_callback(data)
		local spec = data.spec
		local plugin = plugins[spec.name]
		plugin.path = data.path

		if not register(plugin) then
			eager_plugins[#eager_plugins + 1] = plugin
		end
	end

	local ok, err = xpcall(function()
		vim.pack.add(pack_specs, { load = load_callback })
	end, debug.traceback)
	if not ok then
		for _, item in ipairs(resolved) do
			local plugin = plugins[item.name]
			if plugin.state == State.REGISTERED then
				plugin.state = State.FAILED
			end
		end
		vim.notify("[packload] vim.pack.add failed:\n" .. err, vim.log.levels.ERROR)
	end
	flush_builds()

	table.sort(eager_plugins, function(a, b)
		local priority_a, priority_b = a.priority or 0, b.priority or 0
		if priority_a ~= priority_b then
			return priority_a > priority_b
		end
		return a.seq < b.seq
	end)
	for _, plugin in ipairs(eager_plugins) do
		load_plugin(plugin)
	end
end

---@param name string
---@return boolean loaded
function M.trigger(name)
	local plugin = assert(plugins[name], "unknown packload plugin: " .. name)
	return load_plugin(plugin)
end

---@param name? string
---@return table[]
function M.status(name)
	local names = name and { name } or vim.tbl_keys(plugins)
	if name then
		assert(plugins[name], "unknown packload plugin: " .. name)
	end
	table.sort(names)
	local out = {}
	for _, key in ipairs(names) do
		local plugin = assert(plugins[key], "unknown packload plugin: " .. key)
		local triggers = {}
		for _, spec in ipairs(plugin.keys or {}) do
			triggers[#triggers + 1] = "keys:" .. tostring(spec[1])
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
		out[#out + 1] = {
			name = plugin.name,
			state = plugin.state,
			path = plugin.path,
			depends_on = plugin.after,
			triggers = triggers,
		}
	end
	return out
end

return M
