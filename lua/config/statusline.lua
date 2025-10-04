local M = {}

local colors = {
	bg = "#141415",
	bg_alt = "#252530",
	fg = "#cdcdcd",
	fg_dim = "#282828",

	red = "#d8647e",
	green = "#7fa563",
	yellow = "#f3be7c",
	blue = "#6e94b2",
	magenta = "#bb9dbd",
	cyan = "#aeaed1",

	red_bright = "#e08398",
	green_bright = "#99b782",
	yellow_bright = "#f5cb96",
	blue_bright = "#8ba9c1",
	magenta_bright = "#c9b1ca",
	cyan_bright = "#bebeda",
}

vim.api.nvim_set_hl(0, "StatusLineFilePath", { fg = colors.fg_dim })
vim.api.nvim_set_hl(0, "StatusLineFileName", { fg = colors.fg, bold = false })
vim.api.nvim_set_hl(0, "GitBranch", { fg = colors.cyan, bg = colors.fg_dim, bold = true })
vim.api.nvim_set_hl(0, "DapIcon", { fg = colors.magenta_bright, bold = false })
vim.api.nvim_set_hl(0, "CopilotStatus", { fg = colors.cyan_bright, bold = false })
vim.api.nvim_set_hl(0, "DiagWarn", { fg = colors.yellow_bright, bold = false })
vim.api.nvim_set_hl(0, "DiagError", { fg = colors.red_bright })
vim.api.nvim_set_hl(0, "ModeNormal", { fg = colors.bg_alt, bg = colors.cyan_bright, bold = true })
vim.api.nvim_set_hl(0, "ModeVisual", { fg = colors.bg, bg = colors.magenta, bold = true })
vim.api.nvim_set_hl(0, "ModeInsert", { fg = colors.bg, bg = colors.fg, bold = true })
vim.api.nvim_set_hl(0, "ModeReplace", { fg = colors.bg, bg = colors.red, bold = true })
vim.api.nvim_set_hl(0, "ModeCommand", { fg = colors.bg, bg = colors.yellow, bold = true })
vim.api.nvim_set_hl(0, "ModeSelect", { fg = colors.bg, bg = colors.cyan, bold = true })
vim.api.nvim_set_hl(0, "ModeTerminal", { fg = colors.bg, bg = colors.green_bright, bold = true })
vim.api.nvim_set_hl(0, "ModeOther", { fg = colors.fg, bg = colors.fg_dim, bold = true })

vim.o.showmode = false

local CTRL_V = vim.api.nvim_replace_termcodes("<C-v>", true, true, true)
local CTRL_S = vim.api.nvim_replace_termcodes("<C-s>", true, true, true)
local icons = require("nvim-web-devicons")

local modes = setmetatable({
	["n"] = { long = "NORMAL", short = "N", hl = "ModeNormal" },
	["v"] = { long = "VISUAL", short = "V", hl = "ModeVisual" },
	["V"] = { long = "V-LINE", short = "V-L", hl = "ModeVisual" },
	[CTRL_V] = { long = "V-BLOCK", short = "V-B", hl = "ModeVisual" },
	["s"] = { long = "SELECT", short = "S", hl = "ModeSelect" },
	["S"] = { long = "S-LINE", short = "S-L", hl = "ModeSelect" },
	[CTRL_S] = { long = "S-BLOCK", short = "S-B", hl = "ModeSelect" },
	["i"] = { long = "INSERT", short = "I", hl = "ModeInsert" },
	["R"] = { long = "REPLACE", short = "R", hl = "ModeReplace" },
	["c"] = { long = "COMMAND", short = "C", hl = "ModeCommand" },
	["r"] = { long = "PROMPT", short = "P", hl = "ModeOther" },
	["!"] = { long = "SHELL", short = "Sh", hl = "ModeOther" },
	["t"] = { long = "TERMINAL", short = "T", hl = "ModeTerminal" },
}, {
	__index = function()
		return { long = "UNKNOWN", short = "U", hl = "ModeOther" }
	end,
})

local is_truncated = function(trunc_width)
	local cur_width = vim.o.laststatus == 3 and vim.o.columns or vim.api.nvim_win_get_width(0)
	return cur_width < (trunc_width or -1)
end
local is_truncated100 = true

local function _spacer(n)
	return string.rep(" ", n or 1)
end

local function hl_str(hl, str)
	return string.format("%%#%s#%s%%#Normal#", hl, str)
end

local function mode_component()
	local m = modes[vim.fn.mode()]
	local text = is_truncated100 and m.short or m.long

	return hl_str(m.hl, _spacer(1) .. text .. _spacer(1))
end

function M.git_component()
	local head = vim.b.gitsigns_head
	if not head or head == "" then
		return ""
	end

	if not is_truncated100 then
		return string.format("%%#ModeOther#  %s %%#Normal#", head)
	end
	return string.format("%%#ModeOther#  %%#Normal#")
end

function M.diagnostics_component()
	local counts = { E = 0, W = 0, H = 0, I = 0 }
	for _, d in ipairs(vim.diagnostic.get(0)) do
		if d.severity == vim.diagnostic.severity.ERROR then
			counts.E = counts.E + 1
		elseif d.severity == vim.diagnostic.severity.WARN then
			counts.W = counts.W + 1
		elseif d.severity == vim.diagnostic.severity.HINT then
			counts.H = counts.H + 1
		elseif d.severity == vim.diagnostic.severity.INFO then
			counts.I = counts.I + 1
		end
	end

	local parts = {}
	if counts.E > 0 then
		table.insert(parts, "%#DiagError#E:" .. counts.E)
	end
	if counts.W > 0 then
		table.insert(parts, "%#DiagWarn#W:" .. counts.W)
	end
	if counts.H > 0 then
		table.insert(parts, "%#CopilotStatus#H:" .. counts.H)
	end
	if counts.I > 0 then
		table.insert(parts, "%#DiagnosticInfo#I:" .. counts.I)
	end

	if #parts > 0 then
		return table.concat(parts, " ") .. "%#Normal# "
	end
	return ""
end

local function get_line_col()
	local m = modes[vim.fn.mode()]
	local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- Use nvim_win_get_cursor
	local text = ""
	if is_truncated100 then
		text = string.format(" %d:%d ", row, col + 1) -- Lua API is 0-indexed for col, so add 1
	else
		text = string.format(" Ln%d,Col%d ", row, col + 1)
	end
	return hl_str(m.hl, text)
end

local LspSt = ""
local copilot_name = ""

math.randomseed(os.time())

local funny_names = {
	"Creative",
	"EasyMode",
	"Spectator",
	"Redstone",
	"!Xp",
	" ",
}

vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach", "BufEnter" }, {
	callback = function(args)
		LspSt = ""

		local event = args.event

		local client
		if args.data and args.data.client_id then
			client = vim.lsp.get_client_by_id(args.data.client_id)
		end

		if client and client.name == "copilot" then
			if event == "LspAttach" then
				if math.random(#funny_names) < #funny_names then
					copilot_name = funny_names[#funny_names]
				else
					copilot_name = funny_names[math.random(#funny_names - 1)]
				end
				copilot_name = hl_str("CopilotStatus", copilot_name)
			elseif event == "LspDetach" then
				copilot_name = ""
			end
		end

		local clients = vim.lsp.get_clients({ bufnr = args.buf })

		local icon = icons.get_icon_by_filetype(vim.bo[args.buf].filetype)
		if not icon then
			vim.cmd("redrawstatus")
			return
		end
		local non_copilot_clients = vim.tbl_filter(function(c)
			return c.name ~= "copilot"
		end, clients)

		if #non_copilot_clients > 0 then
			LspSt = icon .. _spacer(1)
		end
		if args.event ~= "BufEnter" then
			vim.cmd("redrawstatus")
		end
	end,
})

local dap = false

local function filepath()
	if is_truncated100 or dap then
		return ""
	end
	local fpath = vim.fn.expand("%:~:.:h")
	if fpath == "" or fpath == "." then
		return ""
	end

	return string.format("%%#StatusLineFilePath#%%<%s/", fpath)
end

local function file_component()
	local fname = vim.fn.expand("%:t")

	if fname == "" or dap then
		return ""
	end

	if LspSt ~= "" then
		fname = vim.fn.fnamemodify(fname, ":r")
	end

	local file_display = string.format("%%#StatusLineFileName#%s", fname)

	return file_display
end

function M.dap_component()
	if not package.loaded["dap"] or require("dap").status() == "" then
		dap = false
		return ""
	end
	dap = false
	local file_comp = vim.fn.expand("%:~:.")
	if LspSt ~= "" then
		file_comp = vim.fn.fnamemodify(file_comp, ":r")
	end
	if #file_comp > 25 then
		file_comp = file_component()
	else
		file_comp = string.format("%s%s", filepath(), file_component())
	end
	dap = true
	if is_truncated100 then
		return string.format(
			"%%#DapIcon#Debugging:%%#Normal# %%#CopilotStatus#%s%%#Normal# %%#DapIcon# %%#Normal#",
			file_comp
		)
	end
	return string.format(
		"%%#DapIcon#Debugging:%%#Normal# %%#CopilotStatus#%s%%#Normal# %%#DapIcon# %%#Normal# %%#CopilotStatus#%s%%#Normal#",
		file_comp,
		require("dap").status()
	)
end

function M.buffer_flags_component()
	local flags = {}

	if vim.bo.modified then
		table.insert(flags, " [+]")
	end

	if vim.bo.readonly then
		table.insert(flags, " [RO]")
	end

	if not vim.bo.modifiable then
		table.insert(flags, " [-]")
	end

	return table.concat(flags, "")
end

local function get_lsp_status()
	if LspSt ~= "" then
		if is_truncated100 then
			return hl_str("ModeOther", _spacer(1) .. LspSt)
		end
		return hl_str("ModeOther", _spacer(1) .. LspSt .. vim.bo.ft .. _spacer(1))
	end
	return LspSt
end

function M.render()
	is_truncated100 = is_truncated(100)
	return table.concat({
		mode_component(),
		M.git_component(),
		" ",
		M.buffer_flags_component(),
		"%=",
		M.dap_component(),
		filepath(),
		file_component(),
		"%=",
		" ",
		copilot_name,
		" ",
		M.diagnostics_component(),
		"",
		get_lsp_status(),
		get_line_col(),
	})
end

vim.o.statusline = "%!v:lua.require'config.statusline'.render()"
return M
