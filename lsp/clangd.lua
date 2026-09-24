--@brief
---
--- https://clangd.llvm.org/installation.html
---
--- - **NOTE:** Clang >= 11 is recommended! See [#23](https://github.com/neovim/nvim-lspconfig/issues/23).
--- - If `compile_commands.json` lives in a build directory, you should
---   symlink it to the root of your source tree.
---   ```
---   ln -s /path/to/myproject/build/compile_commands.json /path/to/myproject/
---   ```
--- - clangd relies on a [JSON compilation database](https://clang.llvm.org/docs/JSONCompilationDatabase.html)
---   specified as compile_commands.json, see https://clangd.llvm.org/installation#compile_commandsjson

-- https://clangd.llvm.org/extensions.html#switch-between-sourceheader
local function switch_source_header(bufnr, client)
	local method_name = "textDocument/switchSourceHeader"
	---@diagnostic disable-next-line:param-type-mismatch
	if not client or not client:supports_method(method_name) then
		return vim.notify(
			("method %s is not supported by any servers active on the current buffer"):format(method_name)
		)
	end
	local params = vim.lsp.util.make_text_document_params(bufnr)
	---@diagnostic disable-next-line:param-type-mismatch
	client:request(method_name, params, function(err, result)
		if err then
			error(tostring(err))
		end
		if not result then
			vim.notify("corresponding file cannot be determined")
			return
		end
		vim.cmd.edit(vim.uri_to_fname(result))
	end, bufnr)
end

local function symbol_info(bufnr, client)
	local method_name = "textDocument/symbolInfo"
	---@diagnostic disable-next-line:param-type-mismatch
	if not client or not client:supports_method(method_name) then
		return vim.notify("Clangd client not found", vim.log.levels.ERROR)
	end
	local win = vim.api.nvim_get_current_win()
	local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
	---@diagnostic disable-next-line:param-type-mismatch
	client:request(method_name, params, function(err, res)
		if err or #res == 0 then
			-- Clangd always returns an error, there is no reason to parse it
			return
		end
		local container = string.format("container: %s", res[1].containerName) ---@type string
		local name = string.format("name: %s", res[1].name) ---@type string
		vim.lsp.util.open_floating_preview({ name, container }, "", {
			height = 2,
			width = math.max(string.len(name), string.len(container)),
			focusable = false,
			focus = false,
			title = "Symbol Info",
		})
	end, bufnr)
end

local function is_tidy_enabled()
	if vim.g.clangd_tidy_enabled == nil then
		vim.g.clangd_tidy_enabled = false
	end
	return vim.g.clangd_tidy_enabled
end

local last_cmd = nil

local function get_cmd()
	local cmd = {
		"clangd",
		"--background-index",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders",
    "--experimental-modules-support",
	}
	if is_tidy_enabled() then
		table.insert(cmd, "--clang-tidy")
	else
		table.insert(cmd, "--clang-tidy=false")
	end
	last_cmd = vim.deepcopy(cmd)
	return cmd
end

local function restart_clangd()
	for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
		client:stop(true)
	end
	vim.defer_fn(function()
		vim.lsp.enable("clangd", true)
	end, 200)
end

local function set_tidy(enabled)
	vim.g.clangd_tidy_enabled = enabled and true or false
	vim.notify("clang-tidy " .. (vim.g.clangd_tidy_enabled and "enabled" or "disabled"))
	restart_clangd()
end

local clang_tidy_lines = {
	"Checks: >",
	"  clang-analyzer-*,",
	"  bugprone-*,",
	"  performance-*,",
	"  portability-*,",
	"  readability-*,",
	"  modernize-*,",
	"  misc-*,",
	"  -clang-analyzer-cplusplus*,",
	"  -clang-analyzer-optin*,",
	"  -bugprone-easily-swappable-parameters,",
	"  -clang-analyzer-security.FloatLoopCounter,",
	"  -clang-analyzer-security.insecureAPI*",
	"WarningsAsErrors: ''",
}

local function get_root_dir(client)
	if client and client.config and client.config.root_dir then
		return client.config.root_dir
	end
	if client and client.workspace_folders and client.workspace_folders[1] then
		return vim.uri_to_fname(client.workspace_folders[1].uri)
	end
	return nil
end

local function create_clang_tidy(client)
	local root = get_root_dir(client)
	if not root or root == "" then
		vim.notify("clangd root dir not found", vim.log.levels.ERROR)
		return
	end
	local path = root .. "/.clang-tidy"
	if vim.uv.fs_stat(path) then
		vim.notify(".clang-tidy already exists: " .. path, vim.log.levels.WARN)
		return
	end
	local ok, err = pcall(vim.fn.writefile, clang_tidy_lines, path)
	if not ok then
		vim.notify("Failed to create .clang-tidy: " .. tostring(err), vim.log.levels.ERROR)
		return
	end
	vim.notify("Created .clang-tidy at " .. path)
end

local navic = require("nvim-navic")
local navbud = require("nvim-navbuddy")

---@class ClangdInitializeResult: lsp.InitializeResult
---@field offsetEncoding? string

---@type vim.lsp.Config
return {
	cmd = function(dispatchers, config)
		local cmd = get_cmd()
		config._last_cmd = cmd
		return vim.lsp.rpc.start(cmd, dispatchers)
	end,
	filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
	root_markers = {
		".clangd",
		".clang-tidy",
		".clang-format",
		"Makefile",
		"CMakeLists.txt",
		"compile_commands.json",
		"compile_flags.txt",
		"configure.ac", -- AutoTools
		".git",
	},
	get_language_id = function(_, ftype)
		local t = { objc = "objective-c", objcpp = "objective-cpp", cuda = "cuda-cpp" }
		return t[ftype] or ftype
	end,
	capabilities = {
		textDocument = {
			completion = {
				editsNearCursor = true,
			},
		},
		offsetEncoding = { "utf-8", "utf-16" },
	},
	---@param init_result ClangdInitializeResult
	on_init = function(client, init_result)
		if init_result.offsetEncoding then
			client.offset_encoding = init_result.offsetEncoding
		end
	end,
	on_attach = function(client, bufnr)
		-- Navic attach

		navic.attach(client, bufnr)
		navbud.attach(client, bufnr)

		vim.api.nvim_buf_create_user_command(bufnr, "LspClangdDisableTidy", function()
			set_tidy(false)
		end, { desc = "Disable clang-tidy and restart clangd" })

		vim.api.nvim_buf_create_user_command(bufnr, "LspClangdEnableTidy", function()
			set_tidy(true)
		end, { desc = "Enable clang-tidy and restart clangd" })

		vim.api.nvim_buf_create_user_command(bufnr, "LspClangdToggleTidy", function()
			set_tidy(not is_tidy_enabled())
		end, { desc = "Toggle clang-tidy and restart clangd" })

		vim.api.nvim_buf_create_user_command(bufnr, "LspClangdSwitchSourceHeader", function()
			switch_source_header(bufnr, client)
		end, { desc = "Switch between source/header" })

		vim.api.nvim_buf_create_user_command(bufnr, "LspClangdCreateTidy", function()
			create_clang_tidy(client)
		end, { desc = "Create .clang-tidy in project root" })

		vim.api.nvim_buf_create_user_command(bufnr, "LspClangdShowSymbolInfo", function()
			symbol_info(bufnr, client)
		end, { desc = "Show symbol info" })

		if client.server_capabilities.inlayHintProvider then
			vim.api.nvim_buf_create_user_command(bufnr, "LspToggleInlayHints", function()
				local enabled = vim.lsp.inlay_hint.is_enabled()
				vim.lsp.inlay_hint.enable(not enabled)
			end, { desc = "Toggle inlay hints" })
		end
	end,
}
