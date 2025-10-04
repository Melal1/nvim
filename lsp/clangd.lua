---@brief

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

local disable_tidy = true

local clang_tidy_checks =
	"clang-analyzer-*,bugprone-*,performance-*,portability-*,readability-*,modernize-*,misc-*,-clang-analyzer-cplusplus*,-clang-analyzer-optin*,-bugprone-easily-swappable-parameters,-clang-analyzer-security.FloatLoopCounter,-clang-analyzer-security.insecureAPI*"

local function get_cmd()
	-- vim.notify("Called get_cmd")
	if disable_tidy then
		return { "clangd", "--background-index", "--clang-tidy=false" }
	else
		return { "clangd", "--background-index", "--clang-tidy", "--clang-tidy-checks=" .. clang_tidy_checks }
	end
end

local function reuse_client(client, config)
	return not disable_tidy and client.name == "clangd"
end

---@class ClangdInitializeResult: lsp.InitializeResult
---@field offsetEncoding? string
return {
	cmd = function(dispatchers)
		local cmd = get_cmd()
		return vim.lsp.rpc.start(cmd, dispatchers)
	end,
	filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
	reuse_client = reuse_client,

	root_markers = {
		".clangd",
		".clang-tidy",
		".clang-format",
		"compile_commands.json",
		"compile_flags.txt",
		"configure.ac", -- AutoTools
		".git",
	},

	capabilities = {
		textDocument = {
			completion = {
				editsNearCursor = true,
			},
		},
		offsetEncoding = { "utf-8", "utf-16" },
	},
	---@param client vim.lsp.Client
	---@param bufnr integer
	on_attach = function(client, bufnr)
		vim.api.nvim_buf_create_user_command(bufnr, "LspClangdSwitchSourceHeader", function()
			switch_source_header(bufnr, client)
		end, { desc = "Switch between source/header" })

		vim.api.nvim_buf_create_user_command(bufnr, "LspClangdShowSymbolInfo", function()
			symbol_info(bufnr, client)
		end, { desc = "Show symbol info" })

		if client.server_capabilities.inlayHintProvider then
			vim.api.nvim_buf_create_user_command(bufnr, "ToggleInlayHints", function()
				local enabled = vim.lsp.inlay_hint.is_enabled()
				vim.lsp.inlay_hint.enable(not enabled)
			end, { desc = "Toggle inlay hints" })
		end

		vim.api.nvim_buf_create_user_command(bufnr, "ToggelTidy", function()
			if disable_tidy then
				vim.notify("Enabling clang-tidy")
			else
				vim.notify("Disabling clang-tidy")
			end
			disable_tidy = not disable_tidy
			vim.notify("Toggled clangd cmd, restarting LSP...")
			if client.name == "clangd" then
				client.stop(client, true)
			end
      vim.defer_fn(function()
        vim.cmd("update | e!")
      end, 500)
		end, { desc = "Toggle clangd cmd and restart LSP" })
	end,
}
