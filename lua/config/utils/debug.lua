local M = {}

function ExeFiles(FilePath)
	local MakeRoot = require("config.utils.make.finder")
	local Root = MakeRoot.FindRoot(FilePath, 4, { "build", "Build", "bin" })
	if not Root then
		vim.notify("Could not find project root", vim.log.levels.ERROR)
		return nil, -1
	end

	local BuildDir = Root.Path .. "/" .. Root.Marker
	local FsScandir = vim.loop.fs_scandir(BuildDir)
	if not FsScandir then
		vim.notify("Could not open build directory: " .. BuildDir, vim.log.levels.ERROR)
		return nil, -2
	end

	local ExeFiles = {}
	while true do
		local Name, Type = vim.loop.fs_scandir_next(FsScandir)
		if not Name then
			break
		end
		if Type == "file" and vim.fn.fnamemodify(Name, ":e") == "" then
			table.insert(ExeFiles, Name)
		end
	end

	if #ExeFiles == 0 then
		vim.notify("No executables found in build directory", vim.log.levels.WARN)
		return nil, 0
	end

	return ExeFiles, Root
end

function RunDebug(Filetype, ExecutablePath)
	local Db = {
		cpp = function()
			if os.getenv("TMUX") then
				local Cmd = string.format('gdbserver --no-startup-with-shell :1234 "%s"', ExecutablePath)
				vim.fn.system("tmux split-window -h -l 30 " .. Cmd)
			else
				vim.notify("To have a console make sure you are on tmux",vim.log.levels.ERROR)
        return
			end
		end,
	}

	if Db[Filetype] then
		Db[Filetype]()
	else
		vim.notify("No debug configuration for filetype: " .. Filetype, vim.log.levels.WARN)
    return
	end
end

function M.Debug()
	local FilePath = vim.fn.expand("%:p")
	local Picker = require("config.utils.pick")

	if not Picker.available then
		vim.notify("Pickers are not available", vim.log.levels.ERROR)
		return require("dap").ABORT
	end

	local Files, Root = ExeFiles(FilePath)
	if not Files then
		vim.notify("No executable files found.", vim.log.levels.WARN)
		return require("dap").ABORT
	end

	return coroutine.create(function(dap_run_co)
		Picker.pick_single(Files, function(selected)
			local ExecutablePath
			if selected then
				ExecutablePath = Root.Path .. "/" .. Root.Marker .. "/" .. selected
			else
				ExecutablePath = require("dap").ABORT
			end

			RunDebug(vim.bo.filetype, ExecutablePath)
			coroutine.resume(dap_run_co, ExecutablePath)
		end, { prompt_title = "Select executable to debug" })
	end)
end

return M
