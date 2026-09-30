local M = {}
local saved = {}

local function mk_lbl(args)
	return string.format("DEBUGPRINT %s:%d %s=", args.file, args.ln, args.var)
end

local supported_langs = {
	cpp = {
		comment = "//",
		fn = {
			{
				id = "println",
				label = "std::println (C++23, requires <print>)",
				fn = function(args)
					local label = mk_lbl(args):gsub("{", "{{"):gsub("}", "}}")
					return string.format("std::println(%q, %s);", label .. "{}", args.var)
				end,
			},
			{
				id = "cout",
				label = "std::cout (older C++, requires <iostream>)",
				fn = function(args)
					return string.format("std::cout << %q << (%s) << '\\n';", mk_lbl(args), args.var)
				end,
			},
		},
	},
	lua = {
		comment = "--",
		fn = function(args)
			return string.format("print(%q .. vim.inspect(%s))", mk_lbl(args), args.var)
		end,
	},
}

local function get_language()
	local ft = vim.bo.filetype
	local lang = supported_langs[ft]
	if not lang then
		vim.notify("debugprint: unsupported filetype " .. ft, vim.log.levels.WARN)
	end
	return lang
end

local function choose_formatter(key, lang, callback)
	local bufn = vim.api.nvim_get_current_buf()
	vim.ui.select(lang.fn, {
		prompt = "Debug print format:",
		format_item = function(option)
			return option.label
		end,
	}, function(option)
		if not option then
			return
		end

		saved[key] = option.fn
		if bufn ~= vim.api.nvim_get_current_buf() then
			return
		end

		callback(option.fn)
	end)
end

local function edit_debug_lines(transform)
	local lang = get_language()
	if not lang then
		return 0
	end
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local changed = 0
	for i = #lines, 1, -1 do
		local line = lines[i]
		if line:find('"DEBUGPRINT ', 1, true) or line:find("'DEBUGPRINT ", 1, true) then
			local replacement = transform(line, lang.comment)
			if changed > 0 then
				vim.cmd("undojoin")
			end
			vim.api.nvim_buf_set_lines(0, i - 1, i, false, replacement)
			changed = changed + 1
		end
	end
	return changed
end

local function add_line(fn, args, above)
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local index = row - (above and 1 or 0)
	local indent = vim.api.nvim_get_current_line():match("^%s*")
	args.ln = index + 1
	vim.api.nvim_buf_set_lines(0, index, index, false, { indent .. fn(args) })
end

local function with_formatter(callback)
	local lang = get_language()
	if not lang then
		return
	end
	local var = vim.fn.expand("<cWORD>")
	if var:match("^%s*$") then
		vim.notify("debugprint: place the cursor on an expression", vim.log.levels.WARN)
		return
	end
	local full_file_name = vim.api.nvim_buf_get_name(0)
	local args = {
		var = var,
		file = vim.fn.fnamemodify(full_file_name, ":t"),
		ln = 0,
	}
	if type(lang.fn) == "function" then
		callback(lang.fn, args)
		return
	end

	local key = full_file_name ~= "" and full_file_name or vim.api.nvim_get_current_buf()
	local fn = saved[key]
	if fn then
		callback(fn, args)
		return
	end
	choose_formatter(key, lang, function(res_fn)
		callback(res_fn, args)
	end)
end

function M.add_above()
	with_formatter(function(fn, args)
		add_line(fn, args, true)
	end)
end

function M.add_below()
	with_formatter(function(fn, args)
		add_line(fn, args, false)
	end)
end

function M.surround()
	with_formatter(function(fn, args)
		add_line(fn, args, true)
		vim.cmd("undojoin")
		add_line(fn, args, false)
	end)
end

function M.select()
	local lang = get_language()
	if not lang then
		return
	end
	if type(lang.fn) ~= "table" then
		vim.notify("debugprint: this language has only one formatter")
		return
	end
	local path = vim.api.nvim_buf_get_name(0)
	local key = path ~= "" and path or vim.api.nvim_get_current_buf()
	choose_formatter(key, lang, function() end)
end

function M.toggle()
	return edit_debug_lines(function(line, prefix)
		local indent, body = line:match("^(%s*)(.*)$")
		if body:sub(1, #prefix + 1) == prefix .. " " then
			return { indent .. body:sub(#prefix + 2) }
		end
		return { indent .. prefix .. " " .. body }
	end)
end

function M.clean()
	return edit_debug_lines(function()
		return {}
	end)
end

vim.api.nvim_create_user_command("DebugPrintSelect", M.select, {
	desc = "Choose the debug print formatter for this file",
	force = true,
})

return M
