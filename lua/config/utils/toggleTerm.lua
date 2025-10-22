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

---@param cmd string cmd to run
---@param height number? Hight in percentage range 1-100
function M.SingleShot(cmd, height)
  height = height or -1
	if height < 1 or height > 100 then
		height = 30
	end
	height = math.floor(vim.o.lines * (height / 100))
	vim.cmd("belowright " .. height .. "split")
	if vim.api.nvim_win_is_valid(state.split.win) then
		vim.api.nvim_win_hide(state.split.win)
	end
	if vim.api.nvim_win_is_valid(state.split.temp) then
		vim.api.nvim_win_close(state.split.temp, true)
	end
	state.split.temp = vim.api.nvim_get_current_win()
	vim.cmd("terminal " .. cmd)
end

return M
