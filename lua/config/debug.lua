local M = {}

-- 1. The Debug Runner (from earlier, with herdr support)
function M.RunDebug(Filetype, ExecutablePath)
	local Db = {
		cpp = function()
			local Cmd = string.format('gdbserver --no-startup-with-shell :1234 "%s"', ExecutablePath)

			if os.getenv("HERDR_ENV") == "1" then
				local split_cmd = "herdr pane split --current --direction right --no-focus"
				local split_out = vim.fn.system(split_cmd)

				local ok, parsed = pcall(vim.fn.json_decode, split_out)
				if ok and parsed and parsed.result and parsed.result.pane and parsed.result.pane.pane_id then
					local pane_id = parsed.result.pane.pane_id
					local run_cmd = string.format("herdr pane run %s '%s'", pane_id, Cmd)
					vim.fn.system(run_cmd)
				else
					vim.notify("Failed to split herdr pane or parse response.", vim.log.levels.ERROR)
				end
			elseif os.getenv("TMUX") then
				vim.fn.system("tmux split-window -h -l 30 " .. Cmd)
			else
				local term = require("config.utils.toggleTerm")
				term.SingleShot(Cmd)
				return
			end
		end,
	}

	if Db[Filetype] then
		Db[Filetype]()
	else
		vim.notify("No debug configuration for filetype: " .. Filetype, vim.log.levels.WARN)
	end
end

-- 2. The New Executable Picker (Replaces your make plugin)
function M.DebugFromBuild(Filetype)
	Filetype = Filetype or "cpp"
	local cwd = vim.fn.getcwd()
	local build_dir = cwd .. "/build"

	-- Check if 'build' directory exists
	if vim.fn.isdirectory(build_dir) == 0 then
		vim.notify("No 'build' directory found in current path.", vim.log.levels.WARN)
		return
	end

	-- Find all executable files inside the 'build' directory
	-- Note: "-executable" is a GNU find extension. If you are on macOS,
	-- you may need to change this to: find %s -type f -perm -0111
	local find_cmd = string.format("find %s -type f -executable", vim.fn.shellescape(build_dir))
	local output = vim.fn.system(find_cmd)

	if vim.v.shell_error ~= 0 or output == "" or not output then
		vim.notify("No executables found in the 'build' directory.", vim.log.levels.WARN)
		return
	end

	-- Parse the terminal output into a Lua table
	local executables = {}
	for line in output:gmatch("[^\r\n]+") do
		table.insert(executables, line)
	end

	-- Use Snacks (via vim.ui.select) to pop open a fuzzy finder for the executables
	-- Make sure `ui_select = true` is enabled in your Snacks.picker config!
	Snacks.picker.select(executables, {
		prompt = "Select Executable to Debug",
		format_item = function(item)
			-- This makes the picker UI cleaner by showing relative paths
			-- (e.g., "build/my_app" instead of "/home/user/.../build/my_app")
			return vim.fn.fnamemodify(item, ":.")
		end,
	}, function(selected)
		-- This callback fires when you hit Enter on an executable
		if not selected then
			return -- The user hit Escape/aborted
		end

		-- Forward the selection to your herdr/gdb logic
		M.RunDebug(Filetype, selected)
	end)
end

return M
