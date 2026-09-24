-- ========================================
-- functions
-- ========================================

-- random title function
-- local function get_random_title()
-- 	math.randomseed(os.time()) -- Seed the random number generator with current time
-- 	local option = math.random(1, 20) -- Random number between 1 and 2
-- 	if option == 1 then
-- 		return "NotVsCode - %t" -- First title format
-- 	else
-- 		return "Neovim - %t" -- Second title format
-- 	end
-- end
--
-- ========================================
-- general options
-- ========================================
vim.o.laststatus = 3
-- vim.g.loaded_netrw = 1 -- disable netrw plugin
-- vim.g.loaded_netrwplugin = 1 -- disable netrw plugins
vim.opt.expandtab = true -- convert tabs to spaces
vim.opt.tabstop = 2 -- tab = 2 spaces
vim.opt.softtabstop = 2 -- backspace deletes 2 spaces
vim.opt.smartindent = true
vim.opt.shiftwidth = 2 -- indent = 2 spaces
vim.opt.number = true -- show line numbers
vim.opt.relativenumber = true -- show relative numbers
-- vim.opt.cursorlineopt = "number"
vim.opt.cursorline = true
vim.opt.updatetime = 50
vim.opt.undofile = true -- persistent undo history
vim.opt.updatetime = 50 -- faster cursorhold events
vim.opt.nu = true
vim.o.shada = "'100,<50,s10,h"
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.autoread = true
vim.opt.autowrite = false
vim.opt.selection = "inclusive"
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000

-- ========================================
-- visual settings
-- ========================================
vim.opt.termguicolors = true -- true color support
-- vim.opt.fillchars = { eob = "" } -- hide end-of-buffer ~
vim.opt.wrap = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.guicursor = ""
vim.opt.cmdheight = 1
vim.cmd("autocmd BufEnter * set formatoptions-=cro")
vim.cmd("autocmd BufEnter * setlocal formatoptions-=cro")
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
	callback = function()
		vim.opt_local.cursorline = true
	end,
})

vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
	callback = function()
		vim.opt_local.cursorline = false
	end,
})
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1b1b26", bold = true }) -- example color

vim.o.foldenable = true
vim.o.foldmethod = "expr"
vim.o.foldtext = ""
vim.o.foldlevelstart = 99

vim.o.foldcolumn = "1"
vim.opt.fillchars = {
	fold = ".",
	foldopen = "󰅀",
	foldclose = "󰅂",
	foldinner = " ",
	foldsep = " ",
}
vim.api.nvim_set_hl(0, "FoldColumn", { fg = "#aeaed1", bg = "NONE", bold = true })


-- ========================================
-- Other
-- ========================================
-- Neovide

vim.g.neovide_opacity = 0.8
vim.g.neovide_refresh_rate = 400
vim.g.neovide_font = "FiraCode Nerd Font:h14"
vim.filetype.add({
	extension = {
		axaml = "axaml",
		xaml = "xaml",
	},
})

vim.treesitter.language.register("xml", "axaml")
vim.treesitter.language.register("xml", "xaml")
