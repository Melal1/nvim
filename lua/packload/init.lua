local M = {}

local State = {
	REGISTERED = 0,
	LOADING = 1,
	LOADED = 2,
}

---@type table<string, packload.Plugin>
local plugins = {}

local private = {
	plugins = plugins,
	State = State,
}
M._private = private

local build_autocmd
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

private.list = list

---@param src string
---@return string
local function name_from_src(src)
	local len = src:len()
	local pos = -1
	for i = 1, len do
		if src:sub(pos, pos) == "/" then
			break
		end
		pos = pos - 1
	end

	src = src:sub(pos + 1)

	if src:sub(-4) == ".git" then
		src = src:sub(1, -5)
	end

	return src
end

---@param items packload.PluginSpec|packload.PluginSpec[]
---@param result? packload.PluginSpec[]
---@param root? boolean
---@return packload.PluginSpec[]
local function flatten_specs(items, result, root)
	result = result or {}
	root = root ~= false
	if type(items) ~= "table" then
		error("packload malformed plugin spec: " .. vim.inspect(items), 2)
	end

	if items.src ~= nil then
		result[#result + 1] = items
		return result
	end

	if #items == 0 then
		if not root or next(items) ~= nil then
			error("packload malformed plugin spec: " .. vim.inspect(items), 2)
		end
		return result
	end

	for _, item in ipairs(items) do
		flatten_specs(item, result, false)
	end
	return result
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
			pcall(vim.keymap.del, keymap.mode, keymap.lhs, { buf = keymap.buf })
		else
			persistent_keymaps[#persistent_keymaps + 1] = keymap
		end
	end
	plugin.commands = {}
	plugin.keymaps = persistent_keymaps
end

---@param plugin packload.Plugin
---@param defer? boolean Use packadd! during startup.
---@return boolean loaded
local function load_plugin(plugin, defer)
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
			load_plugin(dependency, defer)
			if dependency.state ~= State.LOADED then
				missing_dep = true
			end
		else
			missing_dep = true
			vim.notify("[packload] Missing dependency '" .. dep .. "' for '" .. plugin.name .. "'", vim.log.levels.WARN)
		end
	end

	if missing_dep then
		plugin.state = State.REGISTERED
		plugin.error = "missing or failed dependency"
		vim.notify("[packload] not loading plugin " .. plugin.name .. ", check :messages", vim.log.levels.ERROR)
		return false
	end

	clear_triggers(plugin)
	local started = vim.uv.hrtime()
	local ok, err = xpcall(function()
		vim.cmd.packadd({ plugin.name, bang = defer })
		if plugin.config then
			plugin.config(plugin.opts)
		end
	end, debug.traceback)
	plugin.load_time_ns = vim.uv.hrtime() - started

	if not ok then
		plugin.state = State.REGISTERED
		plugin.error = err
		vim.notify("[packload] failed to load plugin '" .. plugin.name .. "':\n" .. err, vim.log.levels.ERROR)
		return false
	end

	plugin.state = State.LOADED
	plugin.error = nil
	return true
end

---@param plugin packload.Plugin
---@return boolean
local function run_build(plugin)
	local build = plugin.build
	local needs_runtime = type(build) == "function" or (type(build) == "string" and build:sub(1, 1) == ":")
	if needs_runtime and not load_plugin(plugin) then
		vim.notify("[packload] build skipped for '" .. plugin.name .. "': plugin did not load", vim.log.levels.ERROR)
		return false
	end

	vim.notify("[packload] running build for " .. plugin.name, vim.log.levels.INFO)
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
		vim.notify("[packload] build failed for " .. plugin.name .. ":\n" .. err, vim.log.levels.ERROR)
		return false
	end
	return true
end

local function flush_builds()
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
			local opts = { group = group, data = ev.data, modeline = false }
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
---@return boolean
local function register_autocmds(plugin)
	local has_trigger = false
	for _, event in ipairs(list(plugin.event)) do
		has_trigger = true
		plugin.autocmds[#plugin.autocmds + 1] = vim.api.nvim_create_autocmd(event, {
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
	end

	for _, ft in ipairs(list(plugin.ft)) do
		has_trigger = true
		plugin.autocmds[#plugin.autocmds + 1] = vim.api.nvim_create_autocmd("FileType", {
			pattern = ft,
			once = true,
			callback = function(ev)
				if load_plugin(plugin) and vim.api.nvim_buf_is_valid(ev.buf) then
					vim.api.nvim_exec_autocmds("FileType", { buffer = ev.buf, modeline = false })
				end
			end,
		})
	end
	return has_trigger
end

---@param plugin packload.Plugin
---@param command string
local function add_command(plugin, command)
	vim.api.nvim_create_user_command(command, function(ev)
		if not load_plugin(plugin) then
			return
		end

		local cmd = { cmd = command, bang = ev.bang, mods = ev.smods, args = ev.fargs }
		if ev.range == 1 then
			cmd.range = { ev.line1 }
		elseif ev.range == 2 then
			cmd.range = { ev.line1, ev.line2 }
		elseif ev.count >= 0 then
			cmd.count = ev.count
		end
		vim.cmd(cmd)
	end, {
		bang = true,
		nargs = "*",
		range = true,
		complete = function(_, line)
			if not load_plugin(plugin) then
				return {}
			end
			return vim.fn.getcompletion(line, "cmdline")
		end,
	})
	plugin.commands[#plugin.commands + 1] = command
end

local key_own_fields = { mode = true, refeed = true }

---@param key packload.KeySpec
---@return packload.KeyOpts
local function key_opts(key)
	local opts = { silent = true }
	for field, value in pairs(key) do
		if type(field) == "string" and not key_own_fields[field] then
			opts[field] = value
		end
	end
	return opts
end

---@param keys string
local function feed(keys)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "m", false)
end

---@param plugin packload.Plugin
---@param key packload.KeySpec
local function add_key(plugin, key)
	local lhs, run = key[1], key[2]
	local opts = key_opts(key)

	for _, mode in ipairs(list(key.mode or "n")) do
		vim.keymap.set(mode, lhs, function()
			if not load_plugin(plugin) then
				return
			end
			if type(run) == "function" then
				return run()
			elseif run then
				feed(run)
			elseif key.refeed ~= false then
				feed(lhs)
			end
		end, opts)
		plugin.keymaps[#plugin.keymaps + 1] = {
			mode = mode,
			lhs = lhs,
			temporary = run == nil,
			buf = opts.buf,
		}
	end
end

---@param key packload.KeySpec
local function map_key(key)
	local opts = key_opts(key)
	for _, mode in ipairs(list(key.mode or "n")) do
		vim.keymap.set(mode, key[1], key[2], opts)
	end
end

---@param plugin packload.Plugin
---@return boolean
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
	else
		for _, key in ipairs(plugin.keys or {}) do
			if key[2] ~= nil then
				map_key(key)
			end
		end
	end
	return has_trigger
end

---@param input? packload.PluginSpec|packload.PluginSpec[]
---@param opts? packload.LoadOpts
function M.load(input, opts)
	opts = opts or {}
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

	local validate = opts.validate and require("packload.validate")
	local resolved, batch_names = {}, {}
	for _, spec in ipairs(specs) do
		if validate then
			validate(spec)
		end
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
		registration_seq = registration_seq + 1
		---@type packload.Plugin
		local plugin = vim.tbl_extend("force", spec, {
			name = name,
			after = list(spec.after),
			seq = registration_seq,
			state = State.REGISTERED,
			autocmds = {},
			commands = {},
			keymaps = {},
		})
		plugins[name] = plugin

		if plugin.init then
			local ok, err = xpcall(plugin.init, debug.traceback)
			if not ok then
				vim.notify("[packload] init failed for '" .. name .. "':\n" .. err, vim.log.levels.ERROR)
			end
		end

		pack_specs[#pack_specs + 1] = {
			src = plugin.src,
			name = name,
			version = plugin.version,
		}
	end

	create_build_autocmd()
	local function load_callback(data)
		local plugin = plugins[data.spec.name]
		plugin.path = data.path
		if not register(plugin) then
			plugin.eager = true
			eager_plugins[#eager_plugins + 1] = plugin
		end
	end

	local ok, err = xpcall(function()
		vim.pack.add(pack_specs, { load = load_callback, confirm = false })
	end, debug.traceback)
	if not ok then
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

	local defer = vim.v.vim_did_enter == 0
	for _, plugin in ipairs(eager_plugins) do
		load_plugin(plugin, defer)
	end
end

---@param name string
---@return boolean loaded
function M.trigger(name)
	local plugin = assert(plugins[name], "unknown packload plugin: " .. name)
	return load_plugin(plugin)
end

---@param names string[]
function M.update(names)
	vim.pack.update(names, { force = true })
end

---@param names string[]
function M.build(names)
	for _, name in ipairs(names) do
		local plugin = assert(plugins[name], "unknown packload plugin: " .. name)
		if plugin.build then
			run_build(plugin)
		else
			vim.notify("[packload] plugin '" .. name .. "' has no build hook", vim.log.levels.ERROR)
		end
	end
end

---@param names string[]
function M.delete(names)
	vim.pack.del(names, { force = true })
	for _, name in ipairs(names) do
		local plugin = plugins[name]
		if plugin then
			clear_triggers(plugin)
			plugins[name] = nil
		end
	end
end

function M.status(opts)
	return require("packload.status").status(M, opts)
end

function M.open(opts)
	return require("packload.status").open(M, opts)
end

vim.api.nvim_create_user_command("Packload", function(cmd)
	M.open({ state = #cmd.fargs > 0 and cmd.fargs or nil })
end, {
	nargs = "*",
	desc = "Show packload plugin status (optionally only the given states)",
	complete = function(lead)
		return vim.tbl_filter(function(state)
			return vim.startswith(state, lead)
		end, { "failed", "loading", "registered", "loaded" })
	end,
})

return M
