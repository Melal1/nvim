local M = {}

-- ----------------------------------------------------------------------
-- Module constants
-- ----------------------------------------------------------------------
local avalonia_dir = vim.fn.expand("~/.local/share/avalonia-ls")

M.PREVIEW_DLL = avalonia_dir .. "/avalonia-preview/AvaloniaPreview.dll"
M.PARSER_DLL = avalonia_dir .. "/solution-parser/SolutionParser.dll"

-- ----------------------------------------------------------------------
-- .csproj detection helpers
-- ----------------------------------------------------------------------

---@param start string?
---@return string? csproj_path
local function find_csproj(start)
	start = start or vim.fn.expand("%:p:h")
	local found = vim.fs.find(function(name, _)
		return vim.fs.ext(name) == "csproj"
	end, {
		path = start,
		upward = true,
		type = "file",
	})
	return found[1]
end
-- Add this to the bottom of your avalonia.lua

---Rewrites every `=""` in `text` to a numbered `"$N"` snippet placeholder.
---Returns the input unchanged when there is no `=""` literal or when the text
---already contains LSP snippet placeholders (`$N`).
---@param text string?
---@return string? rewritten
local function rewrite_empty_attrs(text)
	if not text or not text:find('=""', 1, true) then
		return text
	end
	if text:find("$%d") then
		return text
	end
	local n = 0
	local out = text:gsub('=""', function()
		n = n + 1
		return ('="$%d"'):format(n)
	end)
	return out
end

local function enable_axaml_snippet_transform()
	local ok, blink_config = pcall(require, "blink.cmp.config")
	if not ok or not blink_config then
		return
	end

	local original_transform = blink_config.sources.transform_items

	blink_config.sources.transform_items = function(ctx, items)
		if original_transform then
			items = original_transform(ctx, items)
		end

		if vim.bo[(ctx and ctx.bufnr) or 0].filetype ~= "axaml" then
			return items
		end

		for i = 1, #items do
			local item = items[i]
			local before

			if item.textEdit and item.textEdit.newText then
				before = item.textEdit.newText
				local after = rewrite_empty_attrs(before)
				if after ~= before then
					item.textEdit.newText = after
					item.insertTextFormat = 2
				end
			elseif item.textEditText then
				before = item.textEditText
				local after = rewrite_empty_attrs(before)
				if after ~= before then
					item.textEditText = after
					item.insertTextFormat = 2
				end
			elseif item.insertText then
				before = item.insertText
				local after = rewrite_empty_attrs(before)
				if after ~= before then
					item.insertText = after
					item.insertTextFormat = 2
				end
			end
		end

		return items
	end
end

---@param path string
---@return string? version
local function detect_avalonia_version(path)
	local file = io.open(path, "rb")
	if not file then
		return nil
	end
	local version
	for line in file:lines() do
		---@cast line string
		version =
			line:match("^%s*<%s*PackageReference%s+Include%s*=%s*['\"]Avalonia['\"]%s+Version%s*=%s*['\"](.-)['\"]")
		if version then
			break
		end
	end
	file:close()
	return version
end

-- ----------------------------------------------------------------------
-- Formatter setup
-- ----------------------------------------------------------------------
local function setup_formatter()
	if vim.fn.executable(vim.fn.expand("~/.dotnet/tools/xstyler")) == 0 then
		local answer =
			vim.fn.confirm("Xstyler is not installed on your system do you want to install it?", "&Yes\n&No", 2)
		if answer ~= 1 then
			return
		end
		vim.notify("Installing Xstyler via dotnet tool install -g xstyler", vim.log.levels.INFO)
		vim.system({ "dotnet", "tool", "install", "-g", "XamlStyler.Console" }, { text = true }, function(obj)
			vim.schedule(function()
				if obj.code == 0 then
					vim.notify("Xstyler installed successfully.", vim.log.levels.INFO)
				else
					vim.notify(
						"Xstyler installation failed (Code: " .. obj.code .. ")\n" .. (obj.stderr or ""),
						vim.log.levels.ERROR
					)
				end
			end)
		end)
	end
end

-- ----------------------------------------------------------------------
-- Code-behind navigation helpers
-- ----------------------------------------------------------------------

--- Returns the content of the quoted string at/around the cursor, else the
--- next quoted string forward, else nil. Matching quotes enforced via
--- backreference.
---@return string?
local function quoted_word_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1

	local first_forward
	local start = 1
	while true do
		local s, e, _, content = line:find("([\"'])(.-)%1", start)
		if not s then
			break
		end
		if col >= s and col <= e then
			return content
		end
		if s >= col and not first_forward then
			first_forward = content
		end
		start = e + 1
	end
	return first_forward
end

---@return string?
local function target_method_name()
	return quoted_word_under_cursor() or vim.fn.expand("<cword>")
end

---@param xaml_path string
---@return string?
local function resolve_codebehind(xaml_path)
	local base = xaml_path:gsub("%.axaml$", ""):gsub("%.xaml$", "")
	for _, ext in ipairs({ ".axaml.cs", ".xaml.cs", ".cs" }) do
		local p = base .. ext
		if vim.fn.filereadable(p) == 1 then
			return p
		end
	end
end

---@param cs_path string
---@return string?
local function resolve_xaml(cs_path)
	local base = cs_path:gsub("%.axaml%.cs$", ""):gsub("%.xaml%.cs$", ""):gsub("%.cs$", "")
	for _, ext in ipairs({ ".axaml", ".xaml" }) do
		local p = base .. ext
		if vim.fn.filereadable(p) == 1 then
			return p
		end
	end
end

--- Returns the 1-based line index of a method declaration matching `method`,
--- or nil. Requires a return-type-ish run before the name to avoid matching
--- calls (e.g. `foo.OnClick(`).
---@param lines string[]
---@param method string
---@return integer?
local function find_method_line(lines, method)
	local escaped = method:gsub("([^%w])", "%%%1")
	local pat = "^%s*[%a_][%w%s<>,.?]*%s+" .. escaped .. "%s*%("
	for i, line in ipairs(lines) do
		if line:match(pat) then
			return i
		end
	end
end

---@param lines string[]
---@return integer
local function find_class_close(lines)
	for i = #lines, 1, -1 do
		if lines[i]:match("^%s*}%s*$") then
			return i
		end
	end
	return #lines
end

-- ----------------------------------------------------------------------
-- Event-handler insertion helpers
-- ----------------------------------------------------------------------

---@param buf integer
---@param usings string[]
local function ensure_usings(buf, usings)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local have = {}
	for _, line in ipairs(lines) do
		local m = line:match("^%s*using%s+([^;]+);")
		if m then
			have[vim.trim(m)] = true
		end
	end
	local to_add = {}
	for _, u in ipairs(usings) do
		if not have[u] then
			to_add[#to_add + 1] = string.format("using %s;", u)
		end
	end
	if #to_add == 0 then
		return
	end

	local insert_at = 1
	for i, line in ipairs(lines) do
		if line:match("^%s*using%s+") then
			insert_at = i
			break
		elseif line:match("^%s*namespace%s+") then
			insert_at = i
			break
		end
	end
	vim.api.nvim_buf_set_lines(buf, insert_at - 1, insert_at - 1, false, to_add)
end

local HANDLER_USINGS = { "Avalonia.Interactivity" }

--- Inserts a new event handler before the class closing brace and ensures
--- the required `using` directives. Returns the 1-based line index of the new
--- method's signature.
---@param buf integer
---@param method string
---@return integer
local function insert_handler(buf, method)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local close_idx = find_class_close(lines)
	local template = {
		"",
		string.format("    public void %s(object? sender, RoutedEventArgs e)", method),
		"    {",
		"        // TODO: Implement event handler",
		"    }",
	}
	vim.api.nvim_buf_set_lines(buf, close_idx - 1, close_idx - 1, false, template)
	ensure_usings(buf, HANDLER_USINGS)
	return close_idx + 1
end

-- ----------------------------------------------------------------------
-- Public API
-- ----------------------------------------------------------------------

--- Find the Avalonia package version declared in the nearest .csproj.
---@param start string?
---@return string? version
function M.detect(start)
	local csproj = find_csproj(start)
	if not csproj then
		return nil
	end
	return detect_avalonia_version(csproj)
end

---@param root string
function M.parse(root)
	-- Resolve to a .sln file path when possible so SolutionParser writes the
	-- JSON to /tmp/{slnBasename}.json — the path the AvaloniaLanguageServer
	-- looks up (see Workspace.BuildCompletionMetadata in the LSP source).
	local target = root
	if vim.fn.isdirectory(root) == 1 then
		local sln = vim.fn.glob(root .. "/*.sln", false, true)
		if #sln > 0 then
			target = sln[1]
		end
	end

	local cmd = string.format("dotnet --roll-forward Major %s '%s'", M.PARSER_DLL, target)
	vim.fn.jobstart(cmd, {
		on_exit = function(_, code)
			if code == 0 then
				vim.notify("Solution Parser completed successfully.", vim.log.levels.INFO)
			else
				vim.notify("Solution Parser failed (Code: " .. code .. ")", vim.log.levels.ERROR)
			end
		end,
	})
end

---@param current_file string
function M.preview(current_file)
	if not current_file:match("%.axaml$") then
		vim.notify("Avalonia Preview only works on .axaml files!", vim.log.levels.WARN)
		return
	end

	local cwd = vim.fn.fnamemodify(current_file, ":h")
	local label = "Preview: " .. vim.fn.fnamemodify(current_file, ":t")
	local cmd = string.format("dotnet --roll-forward Major %s --file '%s'", M.PREVIEW_DLL, current_file)

	vim.notify("Launching Previewer for " .. vim.fn.fnamemodify(current_file, ":t"), vim.log.levels.INFO)

	local used_herdr = false
	if os.getenv("HERDR_ENV") == "1" then
		local create_out = vim.fn.system(
			string.format(
				"herdr tab create --cwd %s --label %s --no-focus",
				vim.fn.shellescape(cwd),
				vim.fn.shellescape(label)
			)
		)
		local ok, parsed = pcall(vim.fn.json_decode, create_out)
		if ok and parsed and parsed.result and parsed.result.root_pane and parsed.result.root_pane.pane_id then
			local pane_id = parsed.result.root_pane.pane_id
			local tab_id = parsed.result.tab.tab_id
			local shell_cmd = string.format(
				'trap "herdr tab close %s; exit 0" EXIT INT; %s || true; echo "Press Enter to close this tab (Ctrl+C also closes)..."; read',
				tab_id,
				cmd
			)
			vim.fn.system(string.format("herdr pane run %s %s", pane_id, vim.fn.shellescape(shell_cmd)))
			used_herdr = true
		else
			vim.notify("Failed to create herdr tab; falling back to tmux/toggleTerm.", vim.log.levels.ERROR)
		end
	end

	if not used_herdr then
		if os.getenv("TMUX") then
			local wrapped = string.format(
				"bash -c %s",
				vim.fn.shellescape(
					'trap "exit 0" EXIT INT; '
						.. cmd
						.. ' || true; echo "Press Enter to close this window (Ctrl+C also closes)..."; read'
				)
			)
			vim.fn.system(
				string.format(
					"tmux new-window -d -c %s -n %s %s",
					vim.fn.shellescape(cwd),
					vim.fn.shellescape(label),
					vim.fn.shellescape(wrapped)
				)
			)
		else
			local term = require("config.utils.toggleTerm")
			term.SingleShot(cmd)
		end
	end
end

--- Toggle between XAML and its code-behind. From an .axaml/.xaml buffer,
--- jump to the matching code-behind (creating an event handler template when
--- a method name is under the cursor). From a .cs buffer, jump back to the
--- sibling XAML.
function M.goto_codebehind()
	local cur = vim.api.nvim_buf_get_name(0)
	local is_xaml = cur:match("%.axaml$") ~= nil or cur:match("%.xaml$") ~= nil

	if not is_xaml then
		local xaml = resolve_xaml(cur)
		if xaml then
			vim.cmd("edit " .. vim.fn.fnameescape(xaml))
			vim.notify("XAML: " .. vim.fn.fnamemodify(xaml, ":t"), vim.log.levels.INFO)
			return
		end
		vim.notify("No sibling XAML file for this buffer", vim.log.levels.WARN)
		return
	end

	local target = resolve_codebehind(cur)
	if not target then
		vim.notify("Could not find matching code-behind file", vim.log.levels.ERROR)
		return
	end

	local method = target_method_name()
	vim.cmd("edit " .. vim.fn.fnameescape(target))

	if not method or method == "" then
		vim.notify("Opened " .. vim.fn.fnamemodify(target, ":t") .. " (no method under cursor)", vim.log.levels.INFO)
		return
	end

	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local existing = find_method_line(lines, method)

	if existing then
		vim.api.nvim_win_set_cursor(0, { existing, 0 })
		vim.cmd("normal! zz")
		vim.notify("Existing handler: " .. method .. " in " .. vim.fn.fnamemodify(target, ":t"), vim.log.levels.INFO)
		return
	end

	local sig_line = insert_handler(buf, method)
	vim.cmd("write")
	vim.api.nvim_win_set_cursor(0, { sig_line, 0 })
	vim.cmd("normal! zz")
	vim.notify("Added " .. method .. " in " .. vim.fn.fnamemodify(target, ":t"), vim.log.levels.INFO)
end

--- Insert HotAvalonia PackageReferences into the nearest .csproj immediately
--- after the existing Avalonia PackageReference line. The detected Avalonia
--- version is substituted for `$(AvaloniaVersion)`.
function M.add_hotavalonia()
	local csproj = find_csproj()
	if not csproj then
		vim.notify("No .csproj found upwards from the current file", vim.log.levels.WARN)
		return
	end

	local ver = detect_avalonia_version(csproj)
	if not ver then
		vim.notify("Could not detect Avalonia version in " .. csproj, vim.log.levels.WARN)
		return
	end

	local current_file = vim.api.nvim_buf_get_name(0)
	if current_file ~= csproj then
		vim.cmd("edit " .. vim.fn.fnameescape(csproj))
	end

	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	for _, line in ipairs(lines) do
		if line:match("HotAvalonia") then
			vim.notify("HotAvalonia is already referenced in " .. csproj, vim.log.levels.WARN)
			return
		end
	end

	local anchor
	for i, line in ipairs(lines) do
		if line:match("^%s*<%s*PackageReference%s+Include%s*=%s*['\"]Avalonia['\"]%s+Version%s*=%s*['\"](.-)['\"]") then
			anchor = i
			break
		end
	end

	if not anchor then
		vim.notify('No <PackageReference Include="Avalonia" ...> line found in ' .. csproj, vim.log.levels.WARN)
		return
	end

	local to_insert = {
		string.format(
			'    <PackageReference Include="Avalonia.Markup.Xaml.Loader" Version="%s" PrivateAssets="All" Publish="True" />',
			ver
		),
		'    <PackageReference Include="HotAvalonia" Version="3.*" PrivateAssets="All" Publish="True" />',
	}

	local answer = vim.fn.confirm(
		string.format("Add HotAvalonia PackageReferences to %s?\nDetected Avalonia version: %s", csproj, ver),
		"&Yes\n&No",
		2
	)
	if answer ~= 1 then
		return
	end

	vim.api.nvim_buf_set_lines(buf, anchor, anchor, false, to_insert)
	vim.cmd("write")
	vim.api.nvim_win_set_cursor(0, { anchor + 1, 0 })
	vim.cmd("normal! zz")
	vim.notify("Added HotAvalonia PackageReferences to " .. csproj, vim.log.levels.INFO)
end

---@param opts? { notify?: boolean, confirm?: boolean }
function M.setup(opts)
	opts = opts or {}
	local ver = M.detect()

	if not ver then
		if opts.notify then
			vim.notify("Avalonia LSP disabled: not an Avalonia project", vim.log.levels.INFO)
		end
		return
	end

	if opts.confirm then
		local answer = vim.fn.input(
			"Found Avalonia UI version " .. ver .. " in this project, do you want to load avalonia settings? (Y/n): "
		)

		if answer ~= "" and answer:lower():sub(1, 1) == "n" then
			return
		end
	end

	enable_axaml_snippet_transform()
	setup_formatter()

	local group = vim.api.nvim_create_augroup("AvaloniaConfig", { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = { "cs", "axaml" },
		callback = function(event)
			local keymap_opts = { buffer = event.buf, noremap = true, silent = true }

			vim.keymap.set("n", "<leader>sp", function()
				local root = vim.fs.root(event.buf, { ".git", "*.csproj", "*.sln" }) or vim.fn.getcwd()
				vim.notify("Running Solution Parser on root: " .. root, vim.log.levels.INFO)
				M.parse(root)
			end, vim.tbl_extend("force", keymap_opts, { desc = "Avalonia: Run Solution Parser at Root" }))

			vim.keymap.set("n", "<leader>pv", function()
				local current_file = vim.api.nvim_buf_get_name(event.buf)
				if not current_file:match("%.axaml$") then
					vim.notify("Avalonia Preview only works on .axaml files!", vim.log.levels.WARN)
					return
				end
				vim.notify("Launching Previewer for " .. vim.fn.fnamemodify(current_file, ":t"), vim.log.levels.INFO)
				M.preview(current_file)
			end, vim.tbl_extend("force", keymap_opts, { desc = "Avalonia: Preview Current File" }))

			vim.keymap.set(
				"n",
				"<leader>cg",
				M.goto_codebehind,
				vim.tbl_extend("force", keymap_opts, { desc = "Avalonia: Toggle XAML <-> Code-behind" })
			)
		end,
	})

	vim.api.nvim_create_user_command("AvaloniaAddHotAvalonia", function()
		M.add_hotavalonia()
	end, { desc = "Avalonia: Add HotAvalonia PackageReference to .csproj" })

	if opts.notify then
		vim.notify("Loaded avalonia settings", vim.log.levels.INFO)
	end
end

return M
