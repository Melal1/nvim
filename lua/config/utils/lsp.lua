M = {}

function M.lspRename(new_name)
	local old_bufs = vim.api.nvim_list_bufs()
	local old_buf_set = {}
	for _, bufnr in ipairs(old_bufs) do
		old_buf_set[bufnr] = true
	end

	vim.lsp.buf.rename(new_name)
	vim.defer_fn(function()
		vim.cmd("silent wa")

		local new_bufs = vim.api.nvim_list_bufs()

		for _, bufnr in ipairs(new_bufs) do
			if not old_buf_set[bufnr] then
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end
		end
	end, 500)
end

return M
