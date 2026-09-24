---@class packload.KeyOpts: vim.keymap.set.Opts
---@field buf? integer Buffer-local mapping target. `0` means the current buffer.

---@class packload.KeySpec: packload.KeyOpts
---@field [1] string Left-hand side of the mapping.
---@field [2]? fun()|string Right-hand side, run after the plugin has loaded.
---@field mode? string|string[] Mapping mode. Defaults to normal mode.
---@field refeed? boolean Re-feed the lhs after loading when no rhs is given.

---@class packload.PluginSpec
---@field src string Git source accepted by vim.pack.add().
---@field name? string Package name. Defaults to the final component of src.
---@field version? string|vim.VersionRange Version accepted by vim.pack.add().
---@field event? string|string[] Autocmd event(s) that load the plugin.
---@field ft? string|string[] Filetype(s) that load the plugin.
---@field cmd? string|string[] User command(s) that load the plugin.
---@field keys? packload.KeySpec[] Keymaps that load the plugin.
---@field after? string|string[] Dependencies that must load before this plugin.
---@field priority? integer Eager plugin load order.
---@field build? string|fun(path: string) Hook run after installation or update.
---@field lazy? boolean Skip eager loading when true.
---@field event_replay? boolean Replay the triggering event. Defaults to true.
---@field init? fun() Runs at registration time.
---@field opts? table Options passed to config(opts).
---@field config? fun(opts: table|nil) Runs after the plugin is loaded.

---@class packload.Plugin: packload.PluginSpec
---@field name string
---@field after string[]
---@field seq integer
---@field state integer
---@field autocmds integer[]
---@field commands string[]
---@field keymaps { mode: string, lhs: string, temporary: boolean, buf?: integer }[]
---@field path? string
---@field eager? boolean
---@field load_time_ns? integer Time spent in packadd and config.
---@field error? string

---@enum packload.State
local State = {
	REGISTERED = 0,
	LOADING = 1,
	LOADED = 2,
}

---@class packload.LoadOpts
---@field validate? boolean Validate every spec before registering. Defaults to false.

---@alias packload.StateName "registered"|"loading"|"loaded"|"failed"

---@class packload.StatusItem
---@field name string
---@field state packload.StateName
---@field src string
---@field version? string|vim.VersionRange
---@field path? string
---@field eager boolean
---@field load_time_ns? integer Time spent in packadd and config.
---@field triggers string[]
---@field depends_on string[]
---@field required_by string[]
---@field error? string

---@class packload.StatusOpts
---@field name? string Only this plugin.
---@field match? string Only plugins whose name contains this text.
---@field state? packload.StateName|packload.StateName[] Filter by state. "all" disables filtering.
---@field eager? boolean Filter eager or lazy plugins.

return { State = State }
