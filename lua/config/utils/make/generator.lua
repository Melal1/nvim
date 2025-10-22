---@module "config.utils.make.generator"

local Utils = require("config.utils.make.utils")
local Parser = require("config.utils.make.parser")
local Finder = require("config.utils.make.finder")

local Generator = {}

---Generate lines for required Makefile variables.
---@param MakefileVars MakefileVars
---@return string[]
function Generator.GenerateMakefileVariables(MakefileVars)
	local Lines = {}

	for VarName, VarValue in pairs(MakefileVars) do
		table.insert(Lines, VarName .. " = " .. VarValue)
	end

	table.insert(Lines, "$(shell mkdir -p $(BUILD_DIR))")
	table.insert(Lines, "")

	return Lines
end

---Generate an object target rule for a single source file.
---@param Basename string           Basename without extension
---@param RelativePath string       Relative path to the source file
---@param MakefileVars MakefileVars Makefile variables table
---@return string[]
function Generator.ObjectTarget(Basename, RelativePath, MakefileVars)
	local ObjName = "$(BUILD_DIR)/" .. Basename .. ".o"
	local CompilerVar = MakefileVars.CC and "$(CC)" or "$(CXX)"
	local FlagsVar = MakefileVars.CFLAGS and "$(CFLAGS)" or "$(CXXFLAGS)"

	return {
		"",
		"# marker_start: " .. RelativePath .. " type:obj",
		ObjName .. ": " .. RelativePath,
		"\t" .. CompilerVar .. " " .. FlagsVar .. " -c $< -o $@",
		"# marker_end: " .. RelativePath,
	}
end

---Generate full compilation & linking rule for an executable target.
---@param Basename string                 Basename of the source file
---@param RelativePath string             Relative path to the source file
---@param Dependencies string[]|nil       Optional list of header dependencies
---@param MakefileVars MakefileVars       Makefile variables table
---@param RootPath string                 Root search path for includes
---@return string[] lines_or_missing
---@return boolean success                Whether generation succeeded
function Generator.ExecutableTarget(Basename, RelativePath, Dependencies, MakefileVars, RootPath)
	Dependencies = Dependencies or {}
	local ObjName = "$(BUILD_DIR)/" .. Basename .. ".o"
	local ExeName = "$(BUILD_DIR)/" .. Basename
	local CompilerVar = MakefileVars.CC and "$(CC)" or "$(CXX)"
	local FlagsVar = MakefileVars.CFLAGS and "$(CFLAGS)" or "$(CXXFLAGS)"

	local LinkDeps = {}
	local Include = {}
	local UnFoundIncludePath = {}

	for _, Dep in ipairs(Dependencies) do
		table.insert(LinkDeps, Dep)
		local IncludePath = Finder.FindHeaderDirectory(vim.fn.fnamemodify(Dep, ":t:r"), RootPath)
		if IncludePath then
			table.insert(Include, "-I" .. IncludePath)
		else
			table.insert(UnFoundIncludePath, Dep)
		end
	end

	if #UnFoundIncludePath > 0 then
		-- return `nil` second value (list of missing includes)
		return UnFoundIncludePath,false
	end

	local IncludeStr = table.concat(Include, " ")
	local LinkDepsStr = table.concat(LinkDeps, " ")

	return {
		"",
		"# marker_start: " .. RelativePath .. " type:full",
		ObjName .. ": " .. RelativePath,
		"\t" .. CompilerVar .. " " .. FlagsVar .. " " .. IncludeStr .. " -c $< -o $@",
		"",
		ExeName .. ": " .. ObjName .. (LinkDepsStr ~= "" and " " .. LinkDepsStr or ""),
		"\t" .. CompilerVar .. " $^ -o $@",
		"",
		"run" .. Basename .. ": " .. ExeName,
		"\t" .. ExeName,
		"# marker_end: " .. RelativePath,
	},
		true
end

---Ensure the required Makefile variables are present in the file content.
---@param MakefilePath string
---@param Content string|nil
---@param MakefileVars MakefileVars
---@return boolean success
---@return string|nil new_content_or_error
function Generator.EnsureMakefileVariables(MakefilePath, Content, MakefileVars)
	if not Parser.HasReqVars(Content, MakefileVars) then
		local VarLines = Generator.GenerateMakefileVariables(MakefileVars)
		local NewContent = table.concat(VarLines, "\n") .. (Content or "")

		local Success, WriteErr = Utils.WriteFile(MakefilePath, NewContent)
		if not Success then
			return false, "Failed to add variables to Makefile: " .. WriteErr
		end

		local VarNames = {}
		for VarName, _ in pairs(MakefileVars) do
			table.insert(VarNames, VarName)
		end
		table.sort(VarNames)

		vim.notify("Added Makefile variables (" .. table.concat(VarNames, ", ") .. ")", vim.log.levels.INFO)
		return true, NewContent
	end

	return true, Content
end

return Generator
