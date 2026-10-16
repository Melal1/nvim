-- ========================================
-- functions
-- ========================================

-- Disabled helper that randomly chooses a window-title format.
-- local function get_random_title() -- Define a local function that returns a title string.
-- 	math.randomseed(os.time()) -- Seed the random number generator with current time
-- 	local option = math.random(1, 20) -- Choose an integer from 1 through 20, inclusive.
-- 	if option == 1 then -- Use the alternate title for one of the twenty possible results.
-- 		return "NotVsCode - %t" -- Return the alternate title; %t represents the file name.
-- 	else -- Use the default title for the other nineteen results.
-- 		return "Neovim - %t" -- Return the default title with the file name.
-- 	end -- Finish the conditional.
-- end -- Finish the title helper.
--
-- ========================================
-- general options
-- ========================================
vim.o.laststatus = 3 -- Show one global status line shared by all windows.
vim.opt.expandtab = true -- Insert spaces when Tab is pressed; existing tabs are unchanged.
vim.opt.tabstop = 2 -- Display existing tab characters using tab stops every two columns.
vim.opt.softtabstop = 2 -- Make Tab and Backspace work with two-column tab stops while inserting text.
vim.opt.smartindent = true -- Automatically adjust indentation for C-like code when starting a new line.
vim.opt.shiftwidth = 2 -- Use two spaces for each indentation level.
vim.opt.number = true -- Show line numbers; with relativenumber, show the absolute number on the cursor line.
vim.opt.relativenumber = true -- Show other lines' distances from the cursor line.
-- vim.opt.cursorlineopt = "number" -- If enabled, limit cursor-line highlighting to the line number.
vim.opt.cursorline = true -- Highlight the line containing the cursor.
vim.opt.updatetime = 50 -- Trigger CursorHold after 50 ms of inactivity; also controls swap-write timing.
vim.opt.undofile = true -- Save undo history to disk so it survives reopening a file.
vim.o.shada = "'100,<50,s10,h" -- Remember marks for 100 files, up to 50 lines per register, a 10 KiB item limit, and no restored search highlighting.
vim.opt.backup = false -- Do not keep a backup copy after successfully writing a file.
vim.opt.writebackup = false -- Do not create a temporary backup while writing a file.
vim.opt.swapfile = false -- Disable swap files used for crash recovery.
vim.opt.autoread = true -- Reload externally changed files when Neovim checks them, if the buffer has no unsaved edits.
vim.opt.autowrite = false -- Disable automatic saving before commands such as switching buffers or running external commands.
vim.opt.confirm = true -- Ask whether to save unsaved changes when quitting or abandoning a modified buffer.
vim.opt.splitright = true -- Open new vertical splits to the right of the current window.
vim.opt.splitbelow = true -- Open new horizontal splits below the current window.
vim.opt.selection = "inclusive" -- Include the character under the cursor in a Visual-mode selection.
vim.opt.redrawtime = 10000 -- Allow up to 10,000 ms for redraw work such as syntax and search highlighting.
vim.opt.lazyredraw = true -- Postpone screen redraws while executing macros and other non-typed commands.
vim.opt.maxmempattern = 20000

-- ========================================
-- visual settings
-- ========================================
vim.opt.termguicolors = true -- Enable 24-bit RGB colors in terminals that support them.
-- vim.opt.fillchars = { eob = "" } -- Disabled attempt to hide end-of-buffer tildes; use a space as the fill character.
vim.opt.wrap = false -- Keep long lines on one screen line and scroll horizontally to see the rest.
vim.opt.scrolloff = 8 -- Keep eight lines above and below the cursor where possible.
vim.opt.sidescrolloff = 8 -- Keep eight columns on either side of the cursor where possible.
vim.opt.list = true -- Display normally invisible whitespace using the markers below.
vim.opt.listchars = { -- Choose the visible markers for whitespace characters.
	tab = "·· ", -- Mark the start of a tab with a chevron and fill the remaining width with spaces.
	trail = "·", -- Show trailing spaces as dots.
	nbsp = "␣", -- Show non-breaking spaces with a visible marker.
} -- Finish the whitespace-marker settings.
vim.opt.hlsearch = false -- Do not leave all search matches highlighted after a search.
vim.opt.incsearch = true -- Preview the current search match while typing the search pattern.
vim.opt.ignorecase = true -- Ignore letter case in search patterns by default.
vim.opt.smartcase = true -- Match case when a search pattern contains uppercase letters.
vim.opt.inccommand = "split" -- Preview :substitute changes as you type, with extra results in a split.
-- vim.opt.guicursor = "" -- If enabled, stop Neovim from sending cursor-style changes to the terminal.
vim.opt.cmdheight = 1 -- Reserve one screen row for the command line.
vim.api.nvim_create_autocmd("BufEnter", { -- Run this handler whenever a buffer is entered.
	callback = function() -- Define the Lua function to run for this event.
		vim.opt_local.formatoptions:remove({ "c", "r", "o" }) -- Disable comment wrapping (c) and comment continuation with Enter (r) or o/O (o).
	end, -- Finish the buffer-entry callback.
}) -- Finish registering the BufEnter handler.
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, { -- Run when leaving Insert mode or entering a window.
	callback = function() -- Define the handler for both events.
		vim.opt_local.cursorline = true -- Enable cursor-line highlighting in the current window.
	end, -- Finish the highlighting callback.
}) -- Finish registering the highlight-enabling handler.

vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, { -- Run when entering Insert mode or leaving a window.
	callback = function() -- Define the handler for both events.
		vim.opt_local.cursorline = false -- Disable cursor-line highlighting in the current window.
	end, -- Finish the highlighting callback.
}) -- Finish registering the highlight-disabling handler.
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1b1b26", bold = true }) -- Set a dark background and bold text for CursorLine in the global highlight namespace (0).

vim.o.foldenable = true -- Allow folds to be opened and closed.
vim.o.foldmethod = "expr" -- Calculate fold levels using the foldexpr option, configured elsewhere.
vim.o.foldtext = "" -- Display a closed fold's first line with its normal highlighting.
vim.o.foldlevelstart = 99 -- Start newly opened buffers with folds up to level 99 expanded.

vim.o.foldcolumn = "1" -- Reserve one column beside the text for fold indicators.
vim.opt.fillchars = { -- Configure the characters used to draw folds and their indicators.
	fold = ".", -- Use dots to fill unused space in a closed fold's summary when foldtext is enabled.
	foldopen = "󰅀", -- Show a downward chevron at the start of an open fold.
	foldclose = "󰅂", -- Show a right-pointing chevron for a closed fold.
	foldinner = " ", -- Use a space instead of repeated numeric fold levels in a narrow fold column.
	foldsep = " ", -- Use a space for the vertical continuation marker of an open fold.
} -- Finish the fold-character settings.
vim.api.nvim_set_hl(0, "FoldColumn", { fg = "#aeaed1", bg = "NONE", bold = true }) -- Style the global fold column with light text, no background color, and bold text.

-- ========================================
-- Other
-- ========================================
-- Neovide

vim.g.neovide_opacity = 0.8 -- Set the Neovide GUI window to 80% opacity.
vim.g.neovide_refresh_rate = 400 -- Request a Neovide refresh rate of 400 frames per second.
vim.g.neovide_font = "FiraCode Nerd Font:h14" -- Store the font name and size 14 in a global variable named neovide_font.
vim.filetype.add({ -- Register extra rules for detecting file types.
	extension = { -- Match files by the extension after their final dot.
		axaml = "axaml", -- Assign the axaml file type to .axaml files.
		xaml = "xaml", -- Assign the xaml file type to .xaml files.
	}, -- Finish the extension-to-filetype mapping.
}) -- Finish registering the filetype rules.

vim.api.nvim_create_autocmd("FileType", { -- Run a handler when a buffer's file type is set.
	pattern = { "axaml", "xaml" }, -- Only handle buffers whose file type is axaml or xaml.
	once = true, -- Remove this handler after its first matching event.
	callback = function() -- Define the one-time language-registration callback.
		vim.treesitter.language.register("xml", { "axaml", "xaml" }) -- Map both file types to the XML Tree-sitter parser; the parser must be installed separately.
	end, -- Finish the registration callback.
}) -- Finish registering the FileType handler.
