local M = {}

function M.resolve(dir)
	assert(type(dir) == "string" and dir ~= "", "packload local plugin requires a non-empty dir")
	local path = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(dir), ":p"))
	local stat = vim.uv.fs_stat(path)
	assert(stat and stat.type == "directory", "packload local plugin directory does not exist: " .. path)
	return path
end

local function source(path, pattern)
	for _, file in ipairs(vim.fn.glob(vim.fn.escape(path, "\\*?[]{}") .. "/" .. pattern, false, true)) do
		vim.cmd.source({ file, magic = { file = false } })
	end
end

function M.load(plugin, defer)
	local path = plugin.path
	vim.opt.runtimepath:prepend(path)
	local after = path .. "/after"
	if vim.fn.isdirectory(after) == 1 then
		vim.opt.runtimepath:append(after)
	end
	if defer then
		return
	end
	source(path, "plugin/**/*.vim")
	source(path, "plugin/**/*.lua")
	if vim.g.did_load_filetypes then
		vim.cmd.augroup("filetypedetect")
		local ok, err = pcall(function()
			source(path, "ftdetect/*.vim")
			source(path, "ftdetect/*.lua")
		end)
		vim.cmd.augroup("END")
		if not ok then
			error(err)
		end
	end
	-- During startup Neovim sources after/plugin itself.
	if vim.v.vim_did_enter == 1 then
		source(after, "plugin/**/*.vim")
		source(after, "plugin/**/*.lua")
	end
end

return M
