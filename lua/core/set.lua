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
vim.opt.cursorlineopt = "number"
vim.opt.cursorline = true
vim.opt.updatetime = 50
vim.opt.undofile = true -- persistent undo history
vim.opt.updatetime = 50 -- faster cursorhold events
vim.opt.nu = true
vim.o.shada = "'100,<50,s10,h"

-- ========================================
-- visual settings
-- ========================================
vim.opt.termguicolors = true -- true color support
-- vim.opt.fillchars = { eob = "" } -- hide end-of-buffer ~
vim.opt.wrap = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.guicursor = ""
vim.cmd('autocmd BufEnter * set formatoptions-=cro')
vim.cmd('autocmd BufEnter * setlocal formatoptions-=cro')
-- vim.api.nvim_set_hl(0, "LineNr", { fg = "#4e4e4e", bold = false }) -- Normal line numbers

-- ========================================
-- Other
-- ========================================
vim.cmd(":hi statusline guibg=NONE")
