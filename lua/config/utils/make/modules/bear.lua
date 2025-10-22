local Parser = require("config.utils.make.parser")
local Utils = require("config.utils.make.utils")

---@class Bear
local M = {}
---@param cmd string commands to run
---@param success_msg? string text to show when success
local function run_bear_async(cmd, success_msg)
	vim.system({ "sh", "-c", cmd }, { text = true }, function(obj)
		if obj.code == 0 then
			vim.schedule(function()
				vim.notify(success_msg or "Bear finished successfully", vim.log.levels.INFO, { title = "Make + Bear" })
			end)
		else
			vim.schedule(function()
				vim.notify("Bear failed:\n" .. tostring(obj.stderr), vim.log.levels.ERROR, { title = "Make + Bear" })
			end)
		end
	end)
end

---Run bear for the current file
---@param Content string Makefile content
---@param Rootdir string Root directory of the project
---@return boolean success True if cmd sent ( Regarding cmd errors)
function M.CurrentFile(Content, Rootdir)
	local Vars = Parser.ParseVariables(Content)
	local BuildDir = Vars["BUILD_DIR"]
	local RelativePath = Utils.GetRelativePath(vim.fn.expand("%"), Rootdir)

	if not RelativePath then
		return false
	end

	local Targets = Parser.AnalyzeAllSections(Content)

	for _, Ent in ipairs(Targets) do
		if (Ent.analysis.type == "full" or Ent.analysis.type == "obj") and Ent.path == RelativePath then
			for _, Target in ipairs(Ent.analysis.targets) do
				if Target.name:match("^%$%(BUILD_DIR%).+%.o$") then
					local ModifiedName = Target.name:gsub("%$%(BUILD_DIR%)", BuildDir)
					local cmd = string.format(
						"cd %s && bear --append -- make -B %s",
						vim.fn.shellescape(Rootdir),
						vim.fn.shellescape(ModifiedName)
					)

					run_bear_async(cmd, "Bear finished")

					return true
				end
			end
		end
	end

	return false
end

---Run bear for specific target lines
---@param Lines string[] Target lines
---@param Rootdir string Root directory of the project
---@param BuildDir string Build directory as specified in Makefile
---@return boolean success True if cmd sent ( Regarding cmd errors)
function M.Target(Lines, Rootdir, BuildDir)
	for _, Line in ipairs(Lines) do
		-- Match object file targets
		local targetName = Line:match("^([^:]+):")
		if targetName and targetName:match("^%$%(BUILD_DIR%).+%.o$") then
			local ModifiedName = targetName:gsub("%$%(BUILD_DIR%)", BuildDir):match("^%s*(.-)%s*$")
			local cmd = string.format(
				"cd %s && bear --append -- make -B %s",
				vim.fn.shellescape(Rootdir),
				vim.fn.shellescape(ModifiedName)
			)

			run_bear_async(cmd, "Bear finished")

			return true
		end
	end

	return false
end

---@param Content string Makefile content
---@param Rootdir string Root directory of the project
---@return boolean success True if cmd sent ( Regarding cmd errors)
function M.SelectTarget(Content, Rootdir)
	print("enterd")
	local Picker = require("config.utils.pick")
	if not Picker.available then
		vim.notify("Picker is not available")
		return false
	end

	local Vars = Parser.ParseVariables(Content)
	local BuildDir = Vars["BUILD_DIR"]
	local TableOfAllTargets = Parser.AnalyzeAllSections(Content)
	local map = {}
	local PickerEnts = {}
	for _, Ent in ipairs(TableOfAllTargets) do
		if Ent.analysis.type == "full" or Ent.analysis.type == "obj" then
			table.insert(PickerEnts, {
				value = Ent.startLine,
				display = string.format("%s ( %s )", Ent.baseName, Ent.analysis.type),
				preview_text = Parser.ReadContentBetweenLines(Content, Ent.startLine, Ent.endLine, true),
			})
			map[Ent.startLine] = Ent
		end
	end

	Picker.pick_multi_with_preview(PickerEnts, function(selected)
		local BearTargets = {}
		for _, LineNum in ipairs(selected) do
			for _, Target in ipairs(map[LineNum].analysis.targets) do
				if Target.name:match("^%$%(BUILD_DIR%).+%.o$") then
					table.insert(BearTargets, Target.name:gsub("%$%(BUILD_DIR%)", BuildDir):match("^%s*(.-)%s*$"))
					break
				end
			end
		end

		local cmd = string.format(
			"cd %s && bear --append -- make -B %s",
			vim.fn.shellescape(Rootdir),
			table.concat(BearTargets, " ")
		)
		run_bear_async(cmd, "Bear finished")
	end, { prompt_title = "Select target(s) to bear!", previewer = Picker.text_per_entry_previewer("make") })
  return true
end

return M
