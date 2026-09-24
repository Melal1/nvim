local map = vim.keymap.set

map("n", "<C-q>", "<cmd>wqa!<CR>")
map("n", "<leader><C-q>", "<cmd>qa!<CR>")
map("n", "<leader>w", "<cmd>w<CR>")

-- map("i", "jk", "<ESC>", { desc = "Exit insert mode quickly" }) -- I am lefting this for caps lock :(

-- Terminal mode
map("t", "<ESC><ESC>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map({ "t", "n" }, "<leader>tt", function()
	require("config.utils.toggleTerm").toggle()
end, { desc = "Toggle split term" })

map({ "t", "n" }, "<leader>tk", function()
	require("config.utils.toggleTerm").kill()
end, { desc = "kill split term" })

-- Search and replace
map("n", "<leader>a", [[:%s/<C-r><C-w>/<C-r><C-w>/gc<Left><Left><Left>]], {
	desc = "Search and replace word under cursor with confirmation",
})
map("v", "<leader>a", 'y:%s/<C-R>"//gc<Left><Left><Left>', {
	noremap = true,
	silent = true,
	desc = "Substitute visually selected region",
})
map(
	"n",
	"<leader>cw",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Change all occurrences of word" }
)

map("n", "<leader>eX", function()
	vim.cmd(".lua")
end, { desc = "Execute current line" })

-- Visual mode: execute the selected lines
map("v", "<leader><leader>x", function()
	-- Get the visual selection range
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end

	-- Execute the selected lines as Lua code
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local chunk = table.concat(lines, "\n")
	local f, err = loadstring(chunk)

	if not f then
		vim.notify("Error: " .. err, vim.log.levels.ERROR)
		return
	end

	local ok, runtime_err = pcall(f)
	if not ok then
		vim.notify("Runtime error: " .. runtime_err, vim.log.levels.ERROR)
	end
end, { desc = "Execute selected lines" })

-- Quickfix navigation
map("n", "<A-j>", "<cmd>cnext<CR>", { desc = "Go to next quickfix item" })
map("n", "<A-k>", "<cmd>cprev<CR>", { desc = "Go to previous quickfix item" })

-- Open nvim configs in tmux window or new tab
-- The old config-directory mappings intentionally remain disabled during the migration.
-- map("n", "<leader>Opc", ...)
-- map("n", "<leader>ops", ...)

map("n", "<leader>h", "<cmd>noh<CR>", { desc = "Clear search highlight" })

-- Delete without yanking
map("n", "x", '"_x', { desc = "Delete character without yanking" })
map("n", "dd", '"_dd', { desc = "Delete line without yanking" })
map("v", "d", '"_d', { desc = "Delete selection without yanking" })
map("n", "d", '"_d', { silent = true, desc = "Delete without yanking" })

-- Paste without overwriting default register in visual mode
map("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting default register" })

-- Clipboard mappings
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })

-- Leader + d deletes normally
map({ "n", "v" }, "<leader>d", "d", { desc = "Delete selection normally" })

-- Change working directory to current file's directory
map("n", "<leader>cd", "<cmd>lcd %:p:h<CR>", { desc = "Set local working directory to current file" })
map("n", "<leader>Cd", "<cmd>cd %:p:h<CR>", { desc = "Set Global working directory to current file" })

-- Center screen after scrolling/search
map("n", "n", "nzzzv", { desc = "Next search result and center" })
map("n", "N", "Nzzzv", { desc = "Previous search result and center" })

map("n", "<leader>pv", "<cmd>Oil<CR>", { desc = "Open file explorer" })

map("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make current file executable" })


-- Move selected lines up/down in visual mode
map("x", "<C-j>", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down", silent = true })
map("x", "<C-k>", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up", silent = true })
-- Window resizing
map("n", "<C-up>", "1<C-w>+", { silent = true, desc = "Increase window height" })
map("n", "<C-down>", "1<C-w>-", { silent = true, desc = "Decrease window height" })
map("n", "<C-right>", "1<C-w>>", { silent = true, desc = "Increase window width" })
map("n", "<C-left>", "1<C-w><", { silent = true, desc = "Decrease window width" })

map("n", "<C-c>", "<C-o><", { noremap = true, silent = true, desc = "Unmapped placeholder key" })

map("n", "+", function()
	require("config.utils.togglebool").toggleBool(true)
end, { desc = "Toggle bool" })

map("n", "<leader>+", function()
	require("config.utils.togglebool").toggleBool(false)
end, { desc = "Toggle vari" })

map("n", "<S-Tab>", "<cmd>bprev!<CR>", { silent = true, desc = "Previous buffer" })
map("n", "<Tab>", "<cmd>bnext!<CR>", { silent = true, desc = "Next buffer" })
-- map("n", "<leader>bd", "<cmd>bdelete!<CR>", { silent = true, desc = "Delete buffer" })
