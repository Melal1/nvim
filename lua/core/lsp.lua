vim.lsp.enable({
	"lua_ls",
	"clangd",
	"nil_ls",
})
vim.opt.winborder = "rounded"

vim.diagnostic.config({
	virtual_lines = false,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚 ",
			[vim.diagnostic.severity.WARN] = "󰀪 ",
			[vim.diagnostic.severity.INFO] = "󰋽 ",
			[vim.diagnostic.severity.HINT] = "󰌶 ",
		},
		numhl = {
			[vim.diagnostic.severity.ERROR] = "ErrorMsg",
			[vim.diagnostic.severity.WARN] = "WarningMsg",
		},
	},
})

vim.keymap.set("n", "grn", function()
	vim.ui.input({ prompt = "New name: " }, function(new_name)
		if new_name then
			require("config.utils.lsp").lspRename(new_name)
		end
	end)
end, { desc = "Lsp rename" })

vim.keymap.set("n", "gd", function()
	vim.lsp.buf.definition()
end, { desc = "Go to definition" })

vim.keymap.set("n", "td", function()
	if vim.diagnostic.is_enabled() then
		vim.diagnostic.enable(false) -- disable diagnostics
	else
		vim.diagnostic.enable(true) -- enable diagnostics
	end
end, { desc = "Toggle diagnostics" })
