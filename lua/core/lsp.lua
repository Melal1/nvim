local function setup_lsp()
	vim.lsp.enable({
		"emmylua_ls",
		"cmake",
		"pyright",
		"ruff",
		"nil_ls",
		"jsonls",
		-- "qmlls",
		"avalonia",
		"clangd",
		"qmlgolsp",
		-- "harper_ls",
	})

	vim.diagnostic.config({
		virtual_lines = false,
		virtual_text = false,
		underline = true,
		update_in_insert = false,
		severity_sort = true,
		-- float = {
		-- 	border = "rounded",
		-- 	source = true,
		-- },
		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = "●",
				[vim.diagnostic.severity.WARN] = "●",
				[vim.diagnostic.severity.INFO] = "●",
				[vim.diagnostic.severity.HINT] = "●",
			},
			numhl = {
				[vim.diagnostic.severity.ERROR] = "ErrorMsg",
				[vim.diagnostic.severity.WARN] = "WarningMsg",
			},
		},
	})
end

-- Initialize before filetype plugins run, or when an unnamed buffer gets a type.
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile", "FileType" }, {
	group = vim.api.nvim_create_augroup("core_lsp_start", { clear = true }),
	callback = function(args)
		if vim.bo[args.buf].buftype ~= "" then
			return
		end
		setup_lsp()
		return true -- Remove this handler after the first file buffer.
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp_attach_custom_capabilities", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client == nil then
			return
		end
		if client.name == "ruff" then
			-- Disable hover in favor of Pyright
			client.server_capabilities.hoverProvider = false
		end
	end,
	desc = "LSP: Disable hover capability from Ruff",
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "lua",
	callback = function(args)
		vim.keymap.set("n", "<leader>lua", function()
			vim.lsp.enable({ "lua_ls" })
		end, { buffer = args.buf, desc = "Start lua_ls for this buffer" })
	end,
	desc = "add a buffer-local keymap to start lua_ls on lua ft",
})
vim.opt.winborder = "rounded"

vim.keymap.set("n", "<leader>grn", function()
	vim.ui.input({ prompt = "New name: " }, function(new_name)
		if new_name then
			require("config.utils.lsp").lspRename(new_name)
		end
	end)
end, { desc = "Lsp rename" })

vim.keymap.set("n", "gD", function()
	vim.lsp.buf.declaration()
end, { desc = "Go to declaration " })

vim.keymap.set("n", "gd", function()
	vim.lsp.buf.definition()
end, { desc = "Go to definition" })

vim.keymap.set("n", "gm", function()
	vim.lsp.buf.implementation()
end, { desc = "Go to implementation" })

vim.keymap.set("n", "td", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled()) -- disable diagnostics
	vim.cmd("redrawstatus")
end, { desc = "Toggle diagnostics" })

vim.keymap.set("n", "<leader>ga", function()
	local clients = vim.lsp.get_clients()
	for _, c in ipairs(clients) do
		vim.notify(vim.inspect(c.name))
	end
end, { desc = "Show active LSP clients" })
