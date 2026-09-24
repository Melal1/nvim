local state = {
	split = {
		buf = -1,
		win = -1,
		temp = -1,
	},
}

local function create_split_terminal(opts)
	opts = opts or {}
	local height = opts.height or math.floor(vim.o.lines * 0.2)

	local buf = nil
	if vim.api.nvim_buf_is_valid(opts.buf) then
		buf = opts.buf
	else
		buf = vim.api.nvim_create_buf(false, true)
	end

	vim.cmd("belowright " .. height .. "split")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)

	if vim.bo[buf].buftype ~= "terminal" then
		vim.cmd("terminal")
	end

	return { buf = buf, win = win }
end

local M = {}

function M.toggle()
	if not vim.api.nvim_win_is_valid(state.split.win) then
		state.split = create_split_terminal({ buf = state.split.buf })
	else
		vim.api.nvim_win_hide(state.split.win)
	end
end

function M.kill()
	if vim.api.nvim_win_is_valid(state.split.win) then
		vim.api.nvim_win_close(state.split.win, true)
	end
	if vim.api.nvim_buf_is_valid(state.split.buf) then
		vim.api.nvim_buf_delete(state.split.buf, { force = true })
	end
	state.split.buf = -1
	state.split.win = -1
end

function M.run_cmd(Ops)
	if not vim.api.nvim_win_is_valid(state.split.win) then
		state.split = create_split_terminal({ buf = state.split.buf })
	end

	if vim.api.nvim_buf_is_valid(state.split.buf) then
		local chan_id = vim.b[state.split.buf].terminal_job_id
		if chan_id then
			for _, op in ipairs(Ops) do
				vim.fn.chansend(chan_id, op .. "\n")
			end
		else
			vim.notify("No terminal job attached to buffer", vim.log.levels.ERROR)
		end
	end
end

local colors = {
	reset = "\27[0m",
	bold = "\27[1m",
	cyan = "\27[36m",
	pink = "\27[35m",
	green = "\27[32m",
	yellow = "\27[33m",
	blue = "\27[34m",
	bg_blue = "\27[44m",
}

---@param cmd string The command to run
---@param height number? Height in percentage (1-100)
---@param verbose boolean? If true, prints a fancy header with the command
function M.SingleShot(cmd, height, verbose)
	-- 1. Calculate Window Height
	height = height or 30
	if height < 1 or height > 100 then
		height = 30
	end
	local row_height = math.floor(vim.o.lines * (height / 100))

	-- 2. Cleanup existing temporary terminal windows
	if state.split.temp and vim.api.nvim_win_is_valid(state.split.temp) then
		vim.api.nvim_win_close(state.split.temp, true)
	end

	-- 3. Create the Split
	vim.cmd("belowright " .. row_height .. "split")
	state.split.temp = vim.api.nvim_get_current_win()

	-- 4. Construct the Command
	local final_cmd
	if verbose then
		local timestamp = os.date("%H:%M")

		local header = string.format(
			"%s%s[%s]%s %s Running:%s %s%s%s",
			colors.bold,
			colors.blue,
			timestamp,
			colors.reset,
			colors.bold,
			colors.reset,
			colors.pink,
			cmd,
			colors.reset
		)

		local sep = colors.cyan .. string.rep("━", string.len(header) -32) .. colors.reset

		-- Wrap everything in bash -c
		final_cmd = string.format([[bash -c "echo -e '%s\n%s' && %s"]], header, sep, cmd)
	else
		final_cmd = string.format([[bash -c "%s"]], cmd)
	end

	vim.cmd("terminal " .. final_cmd)

	-- Auto-scroll to bottom and enter insert mode
	vim.cmd("startinsert")
end

return M
