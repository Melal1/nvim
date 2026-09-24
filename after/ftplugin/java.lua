local home = vim.uv.os_homedir()
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

local workspace_data_dir = home .. "/.local/share/nvim/workspace_data/" .. project_name

local config = {
	name = "jdtls",
	cmd = {
		"jdtls",
		"--jvm-arg=--add-modules=jdk.incubator.vector",
		"--jvm-arg=-XX:+IgnoreUnrecognizedVMOptions",
		"-data",
		workspace_data_dir,
	},
	-- This looks for your project root markers
	root_dir = vim.fs.root(0, { "gradlew", ".git", "mvnw", "build.gradle.kts" }),

	settings = {
		java = {
			signatureHelp = { enabled = true },
			contentProvider = { preferred = "fernflower" },
		},
	},
}

require("jdtls").start_or_attach(config)

vim.api.nvim_create_user_command("JavaFile", function()
	local filename = vim.fn.expand("%:t:r")

	if filename == "" then
		filename = "Main"
	end

	local content = {
		"public class " .. filename .. " {",
		"",
		"    public static void main(String[] args) {",
		"        ",
		"    }",
		"}",
	}

	-- Insert content into the current buffer
	vim.api.nvim_buf_set_lines(0, 0, -1, false, content)

	-- Move cursor to the middle of the main method (line 4)
	vim.api.nvim_win_set_cursor(0, { 4, 8 })
end, {})

local function run_in_tmux(cmd_str)
	if not os.getenv("TMUX") then
		vim.notify("This command must be used inside tmux", vim.log.levels.WARN)
		return
	end
	local shell_cmd = string.format("clear; %s; echo -e '\\n[Finished] Press Enter to close...'; read", cmd_str)
	vim.system({ "tmux", "split-window", "-v", "-l", "15", shell_cmd }, { detach = true })
end

local function get_project_build_file()
	local file_path = vim.api.nvim_buf_get_name(0)
	local search_path = file_path ~= "" and vim.fs.dirname(file_path) or vim.uv.cwd()
	local gradle_files = vim.fs.find({ "build.gradle", "settings.gradle", "build.gradle.kts" }, {
		upward = true,
		limit = 1,
		path = search_path,
		stop = vim.uv.os_homedir(),
	})

	return #gradle_files > 0 and gradle_files[1] or nil
end

local function get_smart_run_cmd(task, extra_args)
	local build_file = get_project_build_file()
	local file_path = vim.api.nvim_buf_get_name(0)
	extra_args = extra_args and extra_args ~= "" and (" " .. extra_args) or ""

	if build_file then
		local project_dir = vim.fs.dirname(build_file)
		local env_cmd = ""
		local envrc_files =
			vim.fs.find(".envrc", { upward = true, path = project_dir, limit = 1, stop = vim.uv.os_homedir() })
		if #envrc_files > 0 and vim.fn.executable("direnv") == 1 then
			local envrc_dir = vim.fs.dirname(envrc_files[1])
			env_cmd = string.format("direnv exec %s ", vim.fn.shellescape(envrc_dir))
		end
		return string
			.format("cd %s && %sgradle %s%s", vim.fn.shellescape(project_dir), env_cmd, task, extra_args)
			:gsub("%s+$", "")
	elseif vim.bo.filetype == "java" and file_path ~= "" then
		local cwd = vim.fs.dirname(file_path)
		local env_cmd = ""
		local envrc_files = vim.fs.find(".envrc", { upward = true, path = cwd, limit = 1, stop = vim.uv.os_homedir() })
		if #envrc_files > 0 and vim.fn.executable("direnv") == 1 then
			local envrc_dir = vim.fs.dirname(envrc_files[1])
			env_cmd = string.format("direnv exec %s ", vim.fn.shellescape(envrc_dir))
		end
		return string.format("%sjava %s%s", env_cmd, file_path, extra_args):gsub("%s+$", "")
	else
		vim.notify("Not in a Gradle project and not a Java file.", vim.log.levels.WARN)
		return nil
	end
end

-- Package Utilities
local function get_java_src_dir()
	local build_file = get_project_build_file()
	if not build_file then
		return nil
	end
	local root = vim.fs.dirname(build_file)
	local src_dir = root .. "/src/main/java"
	local stat = vim.uv.fs_stat(src_dir)
	if stat and stat.type == "directory" then
		return src_dir
	end
	return nil
end

local function get_deepest_package(src_dir)
	-- Traverse directories to find the deepest package structure
	local current_dir = src_dir
	local current_pkg = {}

	while true do
		local fd = vim.uv.fs_scandir(current_dir)
		if not fd then
			break
		end

		local dirs = {}
		local files = {}
		while true do
			local name, type = vim.uv.fs_scandir_next(fd)
			if not name then
				break
			end
			if type == "directory" then
				table.insert(dirs, name)
			elseif type == "file" then
				table.insert(files, name)
			end
		end

		-- If we have exactly one directory and no files, it's highly likely part of a package chain
		if #dirs == 1 and #files == 0 then
			table.insert(current_pkg, dirs[1])
			current_dir = current_dir .. "/" .. dirs[1]
		elseif #dirs > 0 then
			-- We might have reached a package with multiple sub-packages, or a package with classes and sub-packages.
			-- In both cases, the common package path ends here for our auto-detection purposes.
			break
		else
			break
		end
	end

	return current_dir, table.concat(current_pkg, ".")
end

local function get_current_pkg_dir_and_name(src_dir)
	local current_file = vim.api.nvim_buf_get_name(0)
	if current_file ~= "" and current_file:match("%.java$") then
		local file_dir = vim.fs.dirname(current_file)
		if file_dir:sub(1, #src_dir) == src_dir then
			local rel_path = file_dir:sub(#src_dir + 2)
			if rel_path and rel_path ~= "" then
				local pkg_name = rel_path:gsub("/", ".")
				return file_dir, pkg_name
			else
				return src_dir, ""
			end
		end
	end
	return get_deepest_package(src_dir)
end

-- --- HANDLERS ---

local setup_handlers = {
	["in"] = function()
		local build_file = get_project_build_file()
		if not build_file or not build_file:match("build%.gradle%.kts$") then
			vim.notify("No build.gradle.kts found! Did init finish?", vim.log.levels.ERROR)
			return
		end

		local content = vim.fn.readfile(build_file)
		for _, line in ipairs(content) do
			if line:match("standardInput") then
				vim.notify("Interactive mode is already enabled.", vim.log.levels.INFO)
				return
			end
		end

		local append_block = {
			"",
			'tasks.named<JavaExec>("run") {',
			"    standardInput = System.`in`",
			"}",
		}
		vim.fn.writefile(append_block, build_file, "a")
		vim.notify("Appended interactive mode to " .. vim.fs.basename(build_file), vim.log.levels.INFO)
	end,

	["pkg"] = function()
		local src_dir = get_java_src_dir()
		if not src_dir then
			vim.notify("Could not find src/main/java directory.", vim.log.levels.ERROR)
			return
		end

		-- Always fallback to the deepest package for renaming the project package if we aren't in a specific java file.
		-- But if we are in a java file, it will suggest that file's package structure.
		local _, current_pkg_name = get_current_pkg_dir_and_name(src_dir)
		if current_pkg_name == "" then
			vim.notify("No package structure found in src/main/java", vim.log.levels.WARN)
			return
		end

		vim.ui.input(
			{ prompt = "Rename package (current: " .. current_pkg_name .. "): ", default = current_pkg_name },
			function(new_pkg_name)
				if not new_pkg_name or new_pkg_name == "" or new_pkg_name == current_pkg_name then
					return -- Cancelled or unchanged
				end

				local new_pkg_parts = vim.split(new_pkg_name, "%.")
				local new_pkg_dir = src_dir .. "/" .. table.concat(new_pkg_parts, "/")

				-- Create new directory structure
				vim.fn.mkdir(new_pkg_dir, "p")

				-- Find all .java files in the old package dir
				local java_files = vim.fs.find(function(name, path)
					return name:match("%.java$")
				end, { path = src_dir, type = "file", limit = math.huge })

				local moved_count = 0
				for _, file_path in ipairs(java_files) do
					local content = vim.fn.readfile(file_path)
					local updated = false
					for i, line in ipairs(content) do
						if line:match("^%s*package%s+" .. vim.pesc(current_pkg_name) .. "%s*;") then
							content[i] = "package " .. new_pkg_name .. ";"
							updated = true
							break
						end
					end

					if updated then
						local rel_path = file_path:sub(#src_dir + 2) -- e.g., com/old/Main.java
						local old_pkg_path = current_pkg_name:gsub("%.", "/")
						local new_pkg_path = new_pkg_name:gsub("%.", "/")

						if rel_path:sub(1, #old_pkg_path) == old_pkg_path then
							local new_rel_path = new_pkg_path .. rel_path:sub(#old_pkg_path + 1)
							local new_file_path = src_dir .. "/" .. new_rel_path

							-- Ensure target dir exists (for subpackages)
							vim.fn.mkdir(vim.fs.dirname(new_file_path), "p")

							-- Write updated content to new file
							vim.fn.writefile(content, new_file_path)

							-- Delete old file
							vim.fn.delete(file_path)
							moved_count = moved_count + 1
						end
					end
				end

				-- Clean up old empty directories
				local old_pkg_parts = vim.split(current_pkg_name, "%.")
				local dir_to_check = src_dir
				for i = 1, #old_pkg_parts do
					dir_to_check = dir_to_check .. "/" .. old_pkg_parts[i]
				end

				-- Try to delete directories upwards until they are not empty
				while dir_to_check and #dir_to_check > #src_dir do
					local success = vim.uv.fs_rmdir(dir_to_check)
					if not success then
						break
					end
					dir_to_check = vim.fs.dirname(dir_to_check)
				end

				-- Update build.gradle.kts or build.gradle if necessary
				local build_file = get_project_build_file()
				if build_file then
					local build_content = vim.fn.readfile(build_file)
					local build_updated = false
					for i, line in ipairs(build_content) do
						if line:match("mainClass") or line:match("mainClassName") or line:match("group") then
							-- Replacing exact old package string with new one in lines matching mainClass or group
							local new_line, matches = line:gsub(vim.pesc(current_pkg_name), new_pkg_name)
							if matches > 0 then
								build_content[i] = new_line
								build_updated = true
							end
						end
					end
					if build_updated then
						vim.fn.writefile(build_content, build_file)
						vim.notify("Updated package references in " .. vim.fs.basename(build_file), vim.log.levels.INFO)
					end
				end

				vim.notify(
					"Successfully renamed package to " .. new_pkg_name .. " and moved " .. moved_count .. " files.",
					vim.log.levels.INFO
				)
			end
		)
	end,

	["jdtls"] = function(args)
		if args[2] == "jdtls" and args[3] == "refresh" then
			-- 1. Wipe the workspace data directory
			os.execute("rm -rf " .. workspace_data_dir)

			-- 2. Stop the current JDTLS client using the global API
			local clients = vim.lsp.get_clients({ name = "jdtls" })

			for _, client in ipairs(clients) do
				-- This is the "safe" way that doesn't trigger type mismatch errors
				client.stop(client, true)
			end

			-- 3. Restart the server
			vim.defer_fn(function()
				require("jdtls").start_or_attach(config)
				vim.notify("JDTLS: Workspace reset and server restarted", vim.log.levels.INFO)
			end, 500)
		else
			vim.notify("Usage: Java set jdtls refresh", vim.log.levels.WARN)
		end
	end,

	["dep"] = function(args)
		local dep = args and args[3]
		if dep == "javafx" then
			local build_file = get_project_build_file()
			if not build_file then
				vim.notify("No build file found to add dependencies.", vim.log.levels.ERROR)
				return
			end

			local is_kts = build_file:match("%.kts$") ~= nil
			local content = vim.fn.readfile(build_file)
			local new_content = {}
			local in_plugins = false
			local plugins_added = false

			for _, line in ipairs(content) do
				if not plugins_added and line:match("^%s*plugins%s*{") then
					in_plugins = true
					table.insert(new_content, line)
				elseif in_plugins and line:match("^%s*}") then
					in_plugins = false
					if is_kts then
						table.insert(new_content, '    id("org.openjfx.javafxplugin") version "0.1.0"')
					else
						table.insert(new_content, '    id "org.openjfx.javafxplugin" version "0.1.0"')
					end
					table.insert(new_content, line)
					table.insert(new_content, "")
					table.insert(new_content, "javafx {")
					if is_kts then
						table.insert(
							new_content,
							'    version = "21" // Use a version that matches your JDK (21 is stable)'
						)
						table.insert(new_content, '    modules("javafx.controls", "javafx.fxml")')
					else
						table.insert(
							new_content,
							"    version = '21' // Use a version that matches your JDK (21 is stable)"
						)
						table.insert(new_content, "    modules = [ 'javafx.controls', 'javafx.fxml' ]")
					end
					table.insert(new_content, "}")
					plugins_added = true
				else
					table.insert(new_content, line)
				end
			end

			if not plugins_added then
				vim.notify("Could not find plugins block in build file.", vim.log.levels.ERROR)
				return
			end

			vim.fn.writefile(new_content, build_file)
			vim.notify("Added JavaFX plugin and configuration to " .. vim.fs.basename(build_file), vim.log.levels.INFO)
			os.execute("rm -rf ~/.local/share/nvim/workspace_data/gui")
		else
			vim.notify("Unknown dependency: " .. (dep or "nil"), vim.log.levels.ERROR)
		end
	end,
}

-- --- USER COMMAND ---

vim.api.nvim_create_user_command("Java", function(opts)
	local args = opts.fargs
	if #args == 0 then
		vim.notify("Requires an argument: run, init, set, or new", vim.log.levels.ERROR)
		return
	end

	local cmd_type = args[1]

	if cmd_type == "run" then
		local task = "run"
		local offset = 2
		if args[2] == "build" or args[2] == "clean" or args[2] == "test" then
			task = args[2]
			offset = 3
		end
		local extra_args = table.concat(args, " ", offset)
		local run_cmd = get_smart_run_cmd(task, extra_args)
		if run_cmd then
			run_in_tmux(run_cmd)
		end
	elseif cmd_type == "new" then
		local class_name = args[2]
		local class_type = args[3] or "class"
		if not class_name then
			vim.notify("Class name is required: Java new <ClassName> [type]", vim.log.levels.ERROR)
			return
		end

		local src_dir = get_java_src_dir()
		if not src_dir then
			vim.notify("Could not find src/main/java directory. Are you in a valid Java project?", vim.log.levels.ERROR)
			return
		end

		-- Try to find the package from current file, fallback to deepest package
		local _, pkg_name = get_current_pkg_dir_and_name(src_dir)

		-- If no package found, default to default package (no package statement)
		local target_dir = src_dir
		if pkg_name ~= "" then
			target_dir = src_dir .. "/" .. pkg_name:gsub("%.", "/")
		end

		local file_path = target_dir .. "/" .. class_name .. ".java"

		-- Check if file already exists
		local stat = vim.uv.fs_stat(file_path)
		if stat then
			vim.notify("File already exists: " .. file_path, vim.log.levels.ERROR)
			return
		end

		-- Create directory if it doesn't exist
		vim.fn.mkdir(target_dir, "p")

		-- Generate boilerplate
		local lines = {}
		if pkg_name ~= "" then
			table.insert(lines, "package " .. pkg_name .. ";")
			table.insert(lines, "")
		end
		table.insert(lines, "public " .. class_type .. " " .. class_name .. " {")
		table.insert(lines, "    ")
		table.insert(lines, "}")

		vim.fn.writefile(lines, file_path)
		vim.cmd("edit " .. vim.fn.fnameescape(file_path))

		-- Move cursor inside the class body
		vim.api.nvim_win_set_cursor(0, { #lines - 1, 4 })
		vim.notify(
			"Created " .. class_name .. ".java in " .. (pkg_name == "" and "default package" or pkg_name),
			vim.log.levels.INFO
		)
	elseif cmd_type == "init" then
		local extra_args = {}
		local settings_to_apply = {}

		for i = 2, #args do
			if setup_handlers[args[i]] then
				table.insert(settings_to_apply, args[i])
			else
				table.insert(extra_args, args[i])
			end
		end

		local gradle_args_str = table.concat(extra_args, " ")
		local shell_cmd = string.format("gradle init %s", gradle_args_str):gsub("%s+$", "")

		if #settings_to_apply > 0 then
			local server = vim.v.servername
			for _, setting in ipairs(settings_to_apply) do
				local nvim_callback =
					string.format("nvim --server %s --remote-send '<Cmd>Runner set %s<CR>'", server, setting)
				shell_cmd = shell_cmd .. " && " .. nvim_callback
			end
		end
		run_in_tmux(shell_cmd)
	elseif cmd_type == "set" then
		local setting = args[2]

		if setting and setup_handlers[setting] then
			setup_handlers[setting](args)
		else
			local available = table.concat(vim.tbl_keys(setup_handlers), ", ")
			vim.notify(string.format("Invalid setting. Available options: %s", available), vim.log.levels.ERROR)
		end
	else
		vim.notify("Invalid argument. Use 'run', 'init', 'set', or 'new'.", vim.log.levels.ERROR)
	end
end, {
	nargs = "+",
	complete = function(ArgLead, CmdLine)
		local parts = vim.split(CmdLine, "%s+", { trimempty = true })

		if #parts == 1 or (#parts == 2 and not CmdLine:match("%s$")) then
			return vim.tbl_filter(function(v)
				return v:match("^" .. ArgLead)
			end, { "run", "init", "set", "new" })
		end

		if
			(parts[2] == "set" or parts[2] == "init") and (#parts == 2 or (#parts == 3 and not CmdLine:match("%s$")))
		then
			local available_settings = vim.tbl_keys(setup_handlers)
			return vim.tbl_filter(function(v)
				return v:match("^" .. ArgLead)
			end, available_settings)
		elseif parts[2] == "set" and parts[3] == "jdtls" then
			return vim.tbl_filter(function(v)
				return v:match("^" .. ArgLead)
			end, { "refresh" })
		elseif parts[2] == "set" and parts[3] == "dep" then
			return vim.tbl_filter(function(v)
				return v:match("^" .. ArgLead)
			end, { "javafx" })
		elseif parts[2] == "run" then
			if #parts == 2 or (#parts == 3 and not CmdLine:match("%s$")) then
				return vim.tbl_filter(function(v)
					return v:match("^" .. ArgLead)
				end, { "build", "clean", "test" })
			end
		elseif parts[2] == "new" and #parts == 3 then
			return vim.tbl_filter(function(v)
				return v:match("^" .. ArgLead)
			end, { "class", "interface", "record", "enum" })
		end
	end,
	desc = "Generic Java Project Util (run, init, set, new)",
})

vim.keymap.set("n", "<leader>rf", function()
	if vim.bo.filetype ~= "java" then
		return
	end
	local run_cmd = get_smart_run_cmd("run", "")
	if run_cmd then
		run_in_tmux(run_cmd)
	end
end, { desc = "Run Java (Gradle or Single File) in tmux" })
