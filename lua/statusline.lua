local M = {}

-- I tried to make this peforment as much as I could


-- Highlighting ----------------------------------------------------------------
vim.cmd("hi statusline guibg=NONE")
vim.cmd("hi StatuslineTerm guibg=NONE")

local colors = {
	bg = "#141415",
	bg_alt = "#252530",
	fg = "#cdcdcd",
	fg_dim = "#282828",
	gray = "#696461",
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

local hl = vim.api.nvim_set_hl
hl(0, "StatusLineFileName", { fg = colors.gray })
hl(0, "GitBranch", { fg = colors.fg })
hl(0, "DapIcon", { fg = colors.magenta_bright })
hl(0, "CopilotStatus", { fg = colors.cyan_bright })
hl(0, "DiagWarn", { fg = colors.yellow_bright })
hl(0, "DiagError", { fg = colors.red_bright })
hl(0, "ModeCom", { fg = colors.cyan_bright, bold = true })
hl(0, "ModeVisual", { fg = colors.magenta, bold = true })
hl(0, "ModeReplace", { fg = colors.red, bold = true })
hl(0, "ModeCommand", { fg = colors.yellow, bold = true })
hl(0, "ModeSelect", { fg = colors.cyan, bold = true })
hl(0, "ModeTerminal", { fg = colors.magenta_bright, bold = true })
hl(0, "ModeOther", { fg = colors.fg_dim, bold = true })
hl(0, "ModeComInv", { fg = colors.bg, bg = colors.cyan_bright, bold = true })
hl(0, "ModeVisualInv", { fg = colors.bg, bg = colors.magenta, bold = true })
hl(0, "ModeReplaceInv", { fg = colors.bg, bg = colors.red, bold = true })
hl(0, "ModeCommandInv", { fg = colors.bg, bg = colors.yellow, bold = true })
hl(0, "ModeSelectInv", { fg = colors.bg, bg = colors.cyan, bold = true })
hl(0, "ModeTerminalInv", { fg = colors.bg, bg = colors.magenta_bright, bold = true })
hl(0, "ModeOtherInv", { fg = colors.bg, bg = colors.fg_dim, bold = true })

-- Modes -------------------------------------------------------------------------

vim.o.showmode = false

local CTRL_V = vim.api.nvim_replace_termcodes("<C-v>", true, true, true)
local CTRL_S = vim.api.nvim_replace_termcodes("<C-s>", true, true, true)
Packload.trigger "nvim-web-devicons"
local WebDevIcons = require("nvim-web-devicons")

local modes = setmetatable({
	n = { long = " NORMAL ", short = " N ", hl = "ModeComInv" },
	v = { long = " VISUAL ", short = " V ", hl = "ModeVisualInv" },
	V = { long = " V-LINE ", short = " V-L ", hl = "ModeVisualInv" },
	[CTRL_V] = { long = " V-BLOCK ", short = " V-B ", hl = "ModeVisualInv" },
	s = { long = " SELECT ", short = " S ", hl = "ModeSelectInv" },
	S = { long = " S-LINE ", short = " S-L ", hl = "ModeSelectInv" },
	[CTRL_S] = { long = " S-BLOCK ", short = " S-B ", hl = "ModeSelectInv" },
	i = { long = " INSERT ", short = " I ", hl = "ModeComInv" },
	R = { long = " REPLACE ", short = " R ", hl = "ModeReplaceInv" },
	c = { long = " COMMAND ", short = " C ", hl = "ModeCommandInv" },
	r = { long = " PROMPT ", short = " P ", hl = "ModeOtherInv" },
	[" ! "] = { long = " SHELL ", short = "Sh", hl = "ModeOtherInv" },
	t = { long = " TERMINAL ", short = " T ", hl = "ModeTerminalInv" },
}, {
	__index = function()
		return { long = " UNKNOWN ", short = " U ", hl = "ModeOtherInv" }
	end,
})

-- Utility: wrap text with highlight ------------------------------------------
local function hl_str(hl_name, text)
	return "%#" .. hl_name .. "#" .. text .. "%#Normal#"
end

-- Window truncation detection --------------------------------------------------
M._trunc100 = true
local function is_truncated(width)
	local w = (vim.o.laststatus == 3) and vim.o.columns or vim.api.nvim_win_get_width(0)
	return w < width
end

-- MODE COMPONENT --------------------------------------------------------------
local function mode_component()
	local m = modes[vim.fn.mode()]
	-- return hl_str(m.hl, (trunc100 and m.short or m.long))
	return hl_str(m.hl, m.short)
end

-- GIT COMPONENT ----------------------------------------------------------------
function M.git_component()
	local head = vim.b.gitsigns_head
	if not head or head == "" then
		return ""
	end
	return hl_str("GitBranch", M._trunc100 and "   " or ("  " .. head .. " "))
end

-- LINE / COLUMN ----------------------------------------------------------------
local function line_col()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	if M._trunc100 then
		return hl_str("StatusLineFileName", string.format(" %d:%d ", row, col + 1))
	end
	return hl_str("StatusLineFileName", string.format(" Ln%d, Col%d ", row, col + 1))
end

-- VARIABLES UPDATED BY AUTOCOMMANDS -------------------------------------------
local copilot = ""
local file_icon = ""
local file_name = ""
local cwd_tail = ""
local diag_enabled = false

math.randomseed(os.time())
local funny = { "Creative", "EasyMode", "Spectator", "Redstone", "!Xp", " " }
local shell_name = (vim.env.SHELL and vim.fn.fnamemodify(vim.env.SHELL, ":t")) or "shell"

-- AUTOCOMMAND: LSP attach/detach ----------------------------------------------
vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
	callback = function(args)
		local buf = args.buf
		local client = args.data and args.data.client_id and vim.lsp.get_client_by_id(args.data.client_id)

		-- Handle Copilot client detection
		if client and client.name == "copilot" then
			if args.event == "LspAttach" then
				copilot = hl_str("CopilotStatus", funny[math.random(#funny)])
			else
				copilot = ""
			end
		end

		-- Diagnostics enabled if at least one LSP is attached and diags are on
		local clients = vim.lsp.get_clients({ bufnr = buf })

		diag_enabled = (#clients > 0 and copilot == "") or (#clients > 1)

	end,
})

-- AUTOCOMMAND: BufEnter --------------------------------------------------------
local function update_file_info(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then
		file_name = "[No Name]"
	else
		file_name = vim.fs.basename(name)
	end

	local ft = vim.bo[buf].filetype
	file_icon = WebDevIcons.get_icon_by_filetype(ft) or ""
end

local function update_cwd()
	local cwd = (vim.uv and vim.uv.cwd()) or vim.fn.getcwd()
	if not cwd or cwd == "" then
		cwd_tail = ""
		return
	end
	cwd_tail = vim.fs.basename(cwd)
end

vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
	callback = function()
		update_cwd()
	end,
})

update_cwd()

vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost" }, {
	callback = function(args)
		local buf = args.buf

		update_file_info(buf)

		-- Diagnostics enabled if at least one LSP is attached , it's added here so diags disappear when in oil,telescope ....etc
		local clients = vim.lsp.get_clients({ bufnr = buf })
		diag_enabled = (#clients > 0 and copilot == "") or (#clients > 1)
	end,
})

local function update_diag_counts(bufnr)
	if not bufnr or bufnr == 0 then
		bufnr = vim.api.nvim_get_current_buf()
	end
	local counts = { E = 0, W = 0, H = 0, I = 0 }
	if vim.diagnostic.count then
		local c = vim.diagnostic.count(bufnr)
		counts.E = c[vim.diagnostic.severity.ERROR] or 0
		counts.W = c[vim.diagnostic.severity.WARN] or 0
		counts.H = c[vim.diagnostic.severity.HINT] or 0
		counts.I = c[vim.diagnostic.severity.INFO] or 0
	else
		for _, d in ipairs(vim.diagnostic.get(bufnr)) do
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
	end
	vim.b[bufnr].statusline_diag_counts = counts
end

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
	callback = function(args)
		update_diag_counts(args.buf)
	end,
})

-- DIAGNOSTICS COMPONENT --------------------------------------------------------
function M.diagnostics_component()
	if not diag_enabled or not vim.diagnostic.is_enabled() then
		return ""
	end
	local counts = vim.b.statusline_diag_counts
	if not counts then
		update_diag_counts(0)
		counts = vim.b.statusline_diag_counts
	end
	if not counts then
		return ""
	end
	local parts = {}
	if counts.E > 0 then
		table.insert(parts, "%#DiagError# " .. counts.E)
	else
		table.insert(parts, "%#StatusLineFileName# " .. counts.E)
	end
	if counts.W > 0 then
		table.insert(parts, "%#DiagWarn# " .. counts.W)
	else
		table.insert(parts, "%#StatusLineFileName# " .. counts.W)
	end
	if counts.H > 0 then
		table.insert(parts, "%#CopilotStatus#H:" .. counts.H)
	end
	if counts.I > 0 then
		table.insert(parts, "%#DiagnosticInfo#I:" .. counts.I)
	end
	return " " .. table.concat(parts, " ") .. "%#Normal# "
end

-- DAP COMPONENT ----------------------------------------------------------------
_G.DAP_IS_ACTIVE = false

function M.dap_component()
	if not _G.DAP_IS_ACTIVE then
		return ""
	end

	local dap = require("dap")

	local name = file_name ~= "" and file_name or "[No Name]"

	if M._trunc100 then
		return string.format(
			"%%#DapIcon#Debugging:%%#Normal# %%#CopilotStatus#%s%%#Normal# %%#DapIcon# %%#Normal#",
			name
		)
	end

	return string.format(
		"%%#DapIcon#Debugging:%%#Normal# %%#CopilotStatus#%s%%#Normal# %%#DapIcon# %%#Normal# %%#CopilotStatus#%s%%#Normal#",
		name,
		dap.status()
	)
end

-- BUFFER FLAGS -----------------------------------------------------------------
function M.buffer_flags_component()
	local b = vim.bo
	local out = {}
	if b.modified then
		out[#out + 1] = " [+]"
	end
	if b.readonly then
		out[#out + 1] = " [RO]"
	end
	if not b.modifiable then
		out[#out + 1] = " [-]"
	end
	return table.concat(out)
end

-- CURRENT WORKING DIRECTORY ----------------------------------------------------
M.cwd = function()
	if vim.o.columns > 85 and cwd_tail ~= "" then
		return "%#ModeCom#  " .. cwd_tail .. " "
	end
	return ""
end

-- BREADCRUMB / WINBAR ----------------------------------------------------------
local breadcrumb_on = true
local ignore = {
	["dap-view"] = true,
	["dap-view-term"] = true,
	["dap-view-help"] = true,
	["dap-view-hover"] = true,
}


-- RENDER -----------------------------------------------------------------------
function M.render()
	M._trunc100 = is_truncated(100)
	local ft = vim.bo.filetype
	return table.concat({
		mode_component(),
		" ",

		(_G.DAP_IS_ACTIVE and "")
			or (vim.bo.buftype == "terminal" and ("%#StatusLineFileName# " .. shell_name))
			or ("%#StatusLineFileName#" .. (file_icon or "") .. " " .. (file_name ~= "" and file_name or "[No Name]")),

		" ",
		M.diagnostics_component(),
		" ",
		"%=",
		M.dap_component(),
		"%=",
		"                  ",
		copilot,
		M.buffer_flags_component(),
		M.git_component(),
		M.cwd(),
		line_col(),
	})
end

vim.o.statusline = "%!v:lua.require'statusline'.render()"
return M

