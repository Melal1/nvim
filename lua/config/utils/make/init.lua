local M = {}

local Config = require("config.utils.make.config")
local Utils = require("config.utils.make.utils")
local Parser = require("config.utils.make.parser")
local Generator = require("config.utils.make.generator")
local RootFinder = require("config.utils.make.finder")

M.Config = Config.DefaultConfig

function M.Setup(UserConfig)
	M.Config = vim.tbl_deep_extend("force", M.Config, UserConfig or {})
end

local function TargetExists(Content, RelativePath)
	if Parser.TargetExists(Content, RelativePath) then
		return true
	end
	return false
end

local function GetObjectTargetsForPicker(Content)
	local sections = Parser.GetSectionsByType(Content, "obj")
	local names = {}

	for _, entry in ipairs(sections) do
		for _, target in ipairs(entry.analysis.targets) do
			table.insert(names, {
				value = target.name,
				display = entry.baseName .. ".o",
			})
		end
	end
	return names
end

local function GetExeTables(Content)
	local result = {}

	local full_sections = Parser.GetSectionsByType(Content, "full")
	vim.list_extend(result, full_sections)

	local exe_sections = Parser.GetSectionsByType(Content, "executable")
	vim.list_extend(result, exe_sections)

	return result
end

local function GetAllTargetsForDisplay(Content)
	local allSections = Parser.AnalyzeAllSections(Content)
	local targets = {}

	for _, section in ipairs(allSections) do
		for _, target in ipairs(section.analysis.targets) do
			local targetType = "(unknown)"
			if target.name:match("%.o$") then
				targetType = "(obj)"
			elseif target.name:match("^run") then
				targetType = "(run)"
			else
				targetType = "(exe)"
			end

			table.insert(targets, {
				name = target.name,
				displayName = target.name .. " " .. targetType,
				type = targetType,
			})
		end
	end

	return targets
end

function M.AddToMakefile(MakefilePath, FilePath, RootPath, Content)
	if not Utils.IsValidSourceFile(FilePath, M.Config.SourceExtensions) then
		vim.notify("File is not a valid source file: " .. vim.fn.fnamemodify(FilePath, ":e"), vim.log.levels.WARN)
		return false
	end

	local Success, UpdatedContent = Generator.EnsureMakefileVariables(MakefilePath, Content, M.Config.MakefileVars)
	if not Success then
		vim.notify(UpdatedContent or "Failed to ensure Makefile variables", vim.log.levels.ERROR)
		return false
	end
	Content = UpdatedContent

	local RelativePath, Err = Utils.GetRelativePath(FilePath, RootPath)
	if not RelativePath then
		vim.notify(Err or "Failed to get relative path", vim.log.levels.WARN)
		return false
	end

	local Basename = vim.fn.fnamemodify(FilePath, ":t:r")

	local TargetType = vim.fn.input("Target type - [o]bject file or [e]xecutable? [o/e]:\n")
	if TargetType ~= "o" and TargetType ~= "e" then
		vim.notify("\nInvalid choice. Must be 'o ( Object )' or 'e ( Execuatble )'.", vim.log.levels.WARN)
		return false
	end

	if TargetType == "o" then
		local ObjName = Basename .. ".o"
		if TargetExists(Content, RelativePath) then
			vim.notify("\nObject target '" .. ObjName .. "' already exists.", vim.log.levels.INFO)
			return false
		end

		local Lines = Generator.ObjectTarget(Basename, RelativePath, M.Config.MakefileVars)
		local AppendSuccess, WriteErr = Utils.AppendToFile(MakefilePath, Lines)
		if not AppendSuccess then
			vim.notify("\nFailed to write to Makefile: " .. WriteErr, vim.log.levels.ERROR)
			return false
		end

		vim.notify("\nAdded object target: " .. ObjName, vim.log.levels.INFO)
		return true
	else
		if TargetExists(Content, RelativePath) then
			vim.notify("\nExecutable target '" .. Basename .. "' already exists.", vim.log.levels.INFO)
			return false
		end

		local ObjectFiles = GetObjectTargetsForPicker(Content)

		if #ObjectFiles > 0 then
			local picker = require("config.utils.pick")
			if not picker.available then
				vim.notify("\nNeed Telescope for file selection", vim.log.levels.ERROR)
				return false
			end
			picker.pick_checklist(ObjectFiles, function(Selected)
				local status, Lines =
					Generator.ExecutableTarget(Basename, RelativePath, Selected, M.Config.MakefileVars, RootPath)
				if not status then
					vim.notify(
						"\nFailed to generate executable target. Missing include paths for: " .. table.concat(Lines, ", "),
						vim.log.levels.ERROR
					)
					return
				end
				local AppendSuccess, WriteErr = Utils.AppendToFile(MakefilePath, Lines)
				if not AppendSuccess then
					vim.notify("\nFailed to write to Makefile: " .. WriteErr, vim.log.levels.ERROR)
					return
				end
				vim.notify(
					"\nAdded executable target: " .. Basename .. " with " .. #Selected .. " dependencies",
					vim.log.levels.INFO
				)
			end, { prompt_title = "Select object file dependencies" })
		else
			local _, Lines = Generator.ExecutableTarget(Basename, RelativePath, {}, M.Config.MakefileVars, RootPath)
			local AppendSuccess, WriteErr = Utils.AppendToFile(MakefilePath, Lines)
			if not AppendSuccess then
				vim.notify("\nFailed to write to Makefile: " .. WriteErr, vim.log.levels.ERROR)
				return false
			end
			vim.notify("\nAdded standalone executable target: " .. Basename, vim.log.levels.INFO)
		end
		return true
	end
end

function M.RunTargetInSpilt(MakefilePath, RelativePath, Content)
	local ok, term = pcall(require, "config.utils.toggleTerm")
	if not ok then
		vim.notify("toggleTerm module not found", vim.log.levels.WARN)
		return
	end

	local Targets = GetExeTables(Content)
	if not Targets or #Targets == 0 then
		vim.notify("No executable targets found in Makefile", vim.log.levels.WARN)
		return false
	end

	local RunTargetName
	for _, Entry in ipairs(Targets) do
		if Entry.path == RelativePath then
			RunTargetName = "run" .. Entry.baseName
			break
		end
	end

	if not RunTargetName then
		vim.notify("No matching run target for " .. RelativePath, vim.log.levels.WARN)
		return false
	end

	local MakefileDir = vim.fn.fnamemodify(MakefilePath, ":h")
	local Cmd = { "cd " .. vim.fn.shellescape(MakefileDir) .. " && clear", " make " .. RunTargetName }

	term.run_cmd(Cmd)
	return true
end

function M.PickAndRunTargets(makefile_content)
	local targets = GetAllTargetsForDisplay(makefile_content)
	local display_labels = {}
	local real_names = {}

	local picker = require("config.utils.pick")
	if not picker.available then
		vim.notify("Need Telescope for file selection", vim.log.levels.ERROR)
		return false
	end

	for _, target in ipairs(targets) do
		table.insert(display_labels, target.displayName)
		table.insert(real_names, target.name)
	end

	table.sort(display_labels)

	picker.pick_checklist(display_labels, function(selected_labels)
		if not selected_labels or #selected_labels == 0 then
			vim.notify("No targets selected", vim.log.levels.WARN)
			return
		end

		local selected_targets = {}
		for _, label in ipairs(selected_labels) do
			for i, dl in ipairs(display_labels) do
				if dl == label then
					table.insert(selected_targets, real_names[i])
					break
				end
			end
		end

		local makefile_dir = vim.fn.getcwd()
		local cmd = "cd " .. vim.fn.shellescape(makefile_dir) .. " && make " .. table.concat(selected_targets, " ")

		vim.cmd("terminal " .. cmd)
		vim.notify("Running targets: " .. table.concat(selected_targets, ", "), vim.log.levels.INFO)
	end, {
		prompt_title = "Select Makefile target(s) ",
	})
end

function M.EditTarget(MakefilePath, FilePath, RootPath, Content, Entries, callback)
	local Basename = vim.fn.fnamemodify(FilePath, ":t:r")
	ReturnNewContent = ReturnNewContent == true

	local RelativePath, Err = Utils.GetRelativePath(FilePath, RootPath)
	if not RelativePath then
		vim.notify(Err or "Failed to get relative path", vim.log.levels.ERROR)
		if callback then
			callback(false)
		end
		return
	end

	if not Entries or #Entries == 0 then
		Entries = GetExeTables(Content)
		if not Entries or #Entries == 0 then
			vim.notify("No executable targets found in Makefile", vim.log.levels.WARN)
			if callback then
				callback(false)
			end
			return
		end
	end

	local ExsistingDeps = {}
	for _, Entry in ipairs(Entries) do
		if Entry.path == RelativePath then
			for _, target in ipairs(Entry.analysis.targets) do
				if target.name == Basename then
					ExsistingDeps = target.dependencies
				end
			end
		end
	end

	local ObjectFiles = GetObjectTargetsForPicker(Content)
	if not ObjectFiles or #ObjectFiles == 0 then
		vim.notify("No object files available for dependency selection", vim.log.levels.WARN)
		if callback then
			callback(false)
		end
		return
	end

	local picker = require("config.utils.pick")
	if not picker.available then
		vim.notify("Telescope is required for editing targets", vim.log.levels.ERROR)
		if callback then
			callback(false)
		end
		return
	end

	picker.pick_checklist(ObjectFiles, function(selected)
		local markerInfo = Parser.FindMarker(Content, RelativePath, true, true)

		if markerInfo.M_start == -1 then
			vim.notify("Marker start not found for: " .. RelativePath, vim.log.levels.ERROR)
			if callback then
				callback(false)
			end
			return
		end

		if markerInfo.M_end == -1 then
			vim.notify("Marker end not found for: " .. RelativePath, vim.log.levels.ERROR)
			if callback then
				callback(false)
			end
			return
		end

		local Lines = vim.split(Content, "\n", { plain = true })
		local NewLines = {}
		for i = 1, markerInfo.M_start - 1 do
			table.insert(NewLines, Lines[i])
		end
		for i = markerInfo.M_end + 1, #Lines do
			table.insert(NewLines, Lines[i])
		end

		Content = table.concat(NewLines, "\n")

		local status, GenLines =
			Generator.ExecutableTarget(Basename, RelativePath, selected, M.Config.MakefileVars, RootPath)
		if not status then
			vim.notify(
				"Failed to regenerate target. Missing include paths for: " .. table.concat(GenLines, ", "),
				vim.log.levels.ERROR
			)
			if callback then
				callback(false)
			end
			return
		end

		Content = Content .. table.concat(GenLines, "\n")
		local Success, WriteErr = Utils.WriteFile(MakefilePath, Content)
		if not Success then
			vim.notify("Failed to write Makefile: " .. WriteErr, vim.log.levels.ERROR)
			if callback then
				callback(false)
			end
			return
		end

		vim.notify("Edited target: " .. Basename .. " with " .. #selected .. " dependencies", vim.log.levels.INFO)
	end, { prompt_title = "Select new dependencies for " .. Basename, preselected_items = ExsistingDeps })
end

function M.EditAllTargets(MakefilePath, RootPath, Content)
	local Entries = GetExeTables(Content)
	if not Entries or #Entries == 0 then
		vim.notify("No executable targets found in Makefile", vim.log.levels.WARN)
		return
	end

	local picker = require("config.utils.pick")
	if not picker.available then
		vim.notify("Telescope is required for editing targets", vim.log.levels.ERROR)
		return
	end

	local pick_entries = {}
	local entry_map = {}
	for _, ent in ipairs(Entries) do
		table.insert(pick_entries, { value = ent.baseName, display = ent.baseName })
		entry_map[ent.baseName] = ent
	end

	picker.pick_single(pick_entries, function(selected)
		if #selected == 0 then
			vim.notify("Nothing selected")
			return
		end

		M.EditTarget(MakefilePath, entry_map[selected].path, RootPath, Content, entry_map[selected])
	end, { prompt_title = " Selcet target to edit" })
end

function M.Remove(MakefilePath, Content)
	local Entries = Parser.AnalyzeAllSections(Content)

	local map = {}
	local PickerEntries = {}

	local picker = require("config.utils.pick")
	if not picker.available then
		vim.notify("Telescope is required for editing targets", vim.log.levels.ERROR)
		return
	end

	for _, Entry in ipairs(Entries) do
		table.insert(PickerEntries, {
			value = Entry.startLine,
			display = Entry.baseName .. " ( " .. Entry.analysis.type .. " )",
			preview_text = Parser.ReadContentBetweenLines(Content, Entry.startLine, Entry.endLine, true),
		})
		map[Entry.startLine] = Entry
	end

	picker.pick_multi_with_preview(PickerEntries, function(selected)
		if #selected == 0 then
			vim.notify("Nothing selected", vim.log.levels.WARN)
			return
		end

		local Lines = {}
		for text, nl in Content:gmatch("([^\n]*)(\n?)") do
			if text ~= "" then
				if nl ~= "" then
					text = text .. nl
				end
				table.insert(Lines, text)
			else
				if nl ~= "" then
					table.insert(Lines, nl)
				end
			end
		end

		local function RemoveEntry(StartLine, Endline, LinesTable)
			local NewLines = {}
			for i = 1, StartLine - 1 do
				table.insert(NewLines, LinesTable[i])
			end
			if LinesTable[StartLine - 1] == "\n" then
				table.remove(NewLines, StartLine - 1)
				table.insert(NewLines, "--DELETEME")
			end
			for _ = StartLine, Endline do
				table.insert(NewLines, "--DELETEME")
			end
			for i = Endline + 1, #LinesTable do
				table.insert(NewLines, LinesTable[i])
			end

			return NewLines
		end

		for _, LineNum in ipairs(selected) do
			Lines = RemoveEntry(LineNum, map[LineNum].endLine, Lines)
		end

		for i = #Lines, 1, -1 do
			if Lines[i] == "--DELETEME" then
				table.remove(Lines, i)
			end
		end

		Content = table.concat(Lines)

		local Success, WriteErr = Utils.WriteFile(MakefilePath, Content)
		if not Success then
			vim.notify("Failed to write Makefile: " .. WriteErr, vim.log.levels.ERROR)
			return
		end
	end, { ptrompt_title = "Select target(s) to remove", previewer = picker.text_per_entry_previewer("make") })
end

function M.Make(Fargs)
  if #Fargs > 2 then
    vim.notify("Too many arguments. Use: add, edit, run, ...", vim.log.levels.WARN)
    return false
  end
	Arg = Fargs[1] or "run"
  Arg = Arg:lower()

	local Root, Err = RootFinder.FindRoot(nil, M.Config.MaxSearchLevels, M.Config.RootMarkers)

	if not Root then
		vim.notify("No project root found: " .. (Err or "unknown error"), vim.log.levels.WARN)
		return false
	end

	local MakefilePath = Root.Path .. "/Makefile"

	if Arg == "open" then
		if vim.loop.fs_stat(MakefilePath) then
			vim.cmd("edit " .. vim.fn.fnameescape(MakefilePath))
			vim.notify("Opened Makefile", vim.log.levels.INFO)
			return true
		else
			vim.notify("Makefile not found at " .. MakefilePath, vim.log.levels.WARN)
			return false
		end
	end

	local MakefileContent, _ = Utils.ReadFile(MakefilePath)
	if not MakefileContent then
		local VarLines = Generator.GenerateMakefileVariables(M.Config.MakefileVars)
		MakefileContent = table.concat(VarLines, "\n")
		local Success, WriteErr = Utils.WriteFile(MakefilePath, MakefileContent)
		if not Success then
			vim.notify("Could not create Makefile: " .. WriteErr, vim.log.levels.ERROR)
			return false
		end
		vim.notify("Created new Makefile with default variables", vim.log.levels.INFO)
	end

	local CurrentFile = vim.fn.expand("%:p")
	if CurrentFile == "" then
		vim.notify("No file currently open", vim.log.levels.WARN)
		return false
	end
	if #Fargs == 2 and Arg == "run" then
		Fargs[2] = Fargs[2]:lower()
		if Fargs[2] == "split" then
			M.RunTargetInSpilt(MakefilePath, CurrentFile, MakefileContent)
			return
		elseif Fargs[2] == "float" then
			M.RunTargetInSpilt(MakefilePath, CurrentFile, MakefileContent)
			return
		elseif Fargs[2] == "tab" then
			M.RunTargetInSpilt(MakefilePath, CurrentFile, MakefileContent)
			return
		end
	end

	if Arg == "add" then
		M.AddToMakefile(MakefilePath, CurrentFile, Root.Path, MakefileContent)
	elseif Arg == "run" then
		local RelativePath, _ = Utils.GetRelativePath(CurrentFile, Root.Path)
		M.RunTargetInSpilt(MakefilePath, RelativePath, MakefileContent)
	elseif Arg == "edit" then
		M.EditTarget(MakefilePath, CurrentFile, Root.Path, MakefileContent)
	elseif Arg == "tasks" then
		M.PickAndRunTargets(MakefileContent)
	elseif Arg == "edit_all" then
		M.EditAllTargets(MakefilePath, Root.Path, MakefileContent)
	elseif Arg == "remove" then
		M.Remove(MakefilePath, MakefileContent)
	elseif Arg == "analysis" then
		Parser.PrintAnalysisSummary(MakefileContent)
	else
		vim.notify("Unknown command", vim.log.levels.WARN)
	end
end

return M
