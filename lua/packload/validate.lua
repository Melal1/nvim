---@param value unknown
---@param field string
local function validate_string_list(value, field)
	if value == nil then
		return
	end
	if type(value) == "table" and not vim.islist(value) then
		error("packload " .. field .. " must be a list: " .. vim.inspect(value), 3)
	end

	local values = type(value) == "table" and value or { value }
	for _, item in ipairs(values) do
		if type(item) ~= "string" then
			error("packload " .. field .. " must contain only strings: " .. vim.inspect(value), 3)
		end
	end
end

---@param spec packload.PluginSpec
return function(spec)
	if type(spec) ~= "table" then
		error("packload malformed plugin spec: " .. vim.inspect(spec), 2)
	end
	if type(spec.src) ~= "string" or spec.src == "" then
		error("packload plugin spec requires a non-empty src: " .. vim.inspect(spec), 2)
	end
	if spec.name ~= nil and (type(spec.name) ~= "string" or spec.name == "") then
		error("packload plugin spec has an invalid name: " .. vim.inspect(spec), 2)
	end
	if spec.version ~= nil and type(spec.version) ~= "string" and type(spec.version) ~= "table" then
		error("packload plugin spec has an invalid version: " .. vim.inspect(spec), 2)
	end

	validate_string_list(spec.event, "plugin event")
	validate_string_list(spec.ft, "plugin filetype")
	validate_string_list(spec.cmd, "plugin command")
	validate_string_list(spec.after, "plugin dependency")

	if spec.priority ~= nil and (type(spec.priority) ~= "number" or spec.priority % 1 ~= 0) then
		error("packload plugin spec has an invalid priority: " .. vim.inspect(spec), 2)
	end
	if spec.build ~= nil and type(spec.build) ~= "string" and type(spec.build) ~= "function" then
		error("packload plugin spec has an invalid build: " .. vim.inspect(spec), 2)
	end
	if spec.lazy ~= nil and type(spec.lazy) ~= "boolean" then
		error("packload plugin spec has an invalid lazy flag: " .. vim.inspect(spec), 2)
	end
	if spec.event_replay ~= nil and type(spec.event_replay) ~= "boolean" then
		error("packload plugin spec has an invalid event_replay flag: " .. vim.inspect(spec), 2)
	end
	if spec.init ~= nil and type(spec.init) ~= "function" then
		error("packload plugin spec has an invalid init: " .. vim.inspect(spec), 2)
	end
	if spec.config ~= nil and type(spec.config) ~= "function" then
		error("packload plugin spec has an invalid config: " .. vim.inspect(spec), 2)
	end
	if spec.opts ~= nil and type(spec.opts) ~= "table" then
		error("packload plugin spec has invalid opts: " .. vim.inspect(spec), 2)
	end

	if spec.keys == nil then
		return
	end
	if type(spec.keys) ~= "table" or not vim.islist(spec.keys) then
		error("packload plugin spec keys must be a list: " .. vim.inspect(spec.keys), 2)
	end
	for _, key in ipairs(spec.keys) do
		if type(key) ~= "table" then
			error("packload key spec must be a table: " .. vim.inspect(key), 2)
		end
		if type(key[1]) ~= "string" then
			error("packload key spec requires a string lhs: " .. vim.inspect(key), 2)
		end
		if key[2] ~= nil and type(key[2]) ~= "function" and type(key[2]) ~= "string" then
			error("packload key spec has an invalid rhs: " .. vim.inspect(key), 2)
		end
		validate_string_list(key.mode, "key mode")
		if key.refeed ~= nil and type(key.refeed) ~= "boolean" then
			error("packload key spec has an invalid refeed flag: " .. vim.inspect(key), 2)
		end
	end
end
