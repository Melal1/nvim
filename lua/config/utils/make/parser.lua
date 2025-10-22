---@module "config.utils.make.parser"
local Utils = require("config.utils.make.utils")
---@class Parser
local Parser = {}

---@param Content string|nil
---@return table<string, string>
function Parser.ParseVariables(Content)
	local Variables = {}
	if not Content then
		return Variables
	end
	for Line in Content:gmatch("[^\n]+") do
		Line = Line:match("^%s*(.-)%s*$")
		if Line and Line ~= "" and not Line:match("^#") then
			local VarName, VarValue = Line:match("^([%w_]+)%s*:?=%s*(.*)$")
			if VarName and VarValue then
				Variables[VarName] = VarValue
			end
		end
	end

	return Variables
end

---@param Content string|nil
---@param MakefileVars MakefileVars
---@return boolean
function Parser.HasReqVars(Content, MakefileVars)
	if not Content then
		return false
	end
	local Variables = Parser.ParseVariables(Content)
	for VarName, _ in pairs(MakefileVars) do
		if not Variables[VarName] then
			return false
		end
	end
	return true
end

---@class MarkerInfo
---@field M_start integer|nil
---@field M_end integer|nil
---@field type string|nil

---@param Content string
---@param RelativePath string
---@param CheckStart boolean
---@param CheckEnd boolean
---@return MarkerInfo
function Parser.FindMarker(Content, RelativePath, CheckStart, CheckEnd)
	local info = { M_start = nil, M_end = nil, type = nil }
	local escapedPath = Utils.EscapePattern(RelativePath)
	local lineNumber = 0
	if not CheckStart then
		info.M_start = -1
	end
	if not CheckEnd then
		info.M_end = -1
	end

	if info.M_start == -1 and info.M_end == -1 then
		return info
	end
	for line in Content:gmatch("([^\n]*)\n?") do
		lineNumber = lineNumber + 1
		local trimmedLine = line:match("^%s*(.-)%s*$")
		if not trimmedLine:match("^%s*#") or trimmedLine == "" then
			goto continue
		end
		if not info.M_start and CheckStart then
			local markerMatch = trimmedLine:match("^%s*#%s*marker_start%s*:%s*" .. escapedPath .. "(.*)$")
			if markerMatch then
				info.M_start = lineNumber
				-- Extract type if present
				local typeAnnotation = markerMatch:match("%s+type:(%S+)")
				if typeAnnotation then
					info.type = typeAnnotation
				end
				if not CheckEnd then
					return info
				end
			end
		end
		if not info.M_end and info.M_start and CheckEnd then
			if trimmedLine:match("^%s*#%s*marker_end%s*:%s*" .. escapedPath) then
				info.M_end = lineNumber
				return info
			end
		end
		::continue::
	end
	return info
end

---@class MarkerPair
---@field path string
---@field StartLine integer
---@field EndLine integer
---@field annotatedType string|nil

---@param Content string|nil
---@return MarkerPair[]
function Parser.FindAllMarkerPairs(Content)
	local allPairs = {}
	local openMarkers = {}
	local lineNumber = 0
	if not Content then
		return allPairs
	end
	for line in Content:gmatch("([^\n]*)\n?") do
		lineNumber = lineNumber + 1
		local trimmedLine = line:match("^%s*(.-)%s*$")
		if trimmedLine:match("^%s*#") then
			local startMatch = trimmedLine:match("^%s*#%s*marker_start%s*:%s*(.*)$")
			if startMatch then
				local path = startMatch:match("^(%S+)")
				local typeAnnotation = startMatch:match("%s+type:(%S+)")
				openMarkers[path] = { line = lineNumber, type = typeAnnotation }
			end
			local endPath = trimmedLine:match("^%s*#%s*marker_end%s*:%s*(.*)$")
			if endPath then
				endPath = endPath:match("^(%S+)")
				local markerData = openMarkers[endPath]
				if markerData then
					table.insert(allPairs, {
						path = endPath,
						StartLine = markerData.line,
						EndLine = lineNumber,
						annotatedType = markerData.type,
					})
					openMarkers[endPath] = nil
				end
			end
		end
	end
	return allPairs
end

---@param Content string
---@param StartLine integer
---@param EndLine integer
---@param ReturnTable boolean?
---@return string|string[]
function Parser.ReadContentBetweenLines(Content, StartLine, EndLine, ReturnTable)
	ReturnTable = not not ReturnTable
	local contentLines = {}
	local currentLineNumber = 0
	for line in Content:gmatch("([^\n]*)\n?") do
		currentLineNumber = currentLineNumber + 1
		if currentLineNumber > StartLine and currentLineNumber < EndLine then
			table.insert(contentLines, line)
		end
	end
	if ReturnTable then
		return contentLines
	end
	return table.concat(contentLines, "\n")
end

---@param Content string
---@param RelativePath string
---@param ReturnTable boolean?
---@return string|string[]
function Parser.ReadContentBetweenMarkers(Content, RelativePath, ReturnTable)
	ReturnTable = not not ReturnTable
	local contentLines = {}
	local currentLineNumber = 0
	local markerInfo = Parser.FindMarker(Content, RelativePath, true, true)
	local StartLine = markerInfo.M_start
	local EndLine = markerInfo.M_end
	if StartLine == -1 or EndLine == -1 then
		return ""
	end
	for line in Content:gmatch("([^\n]*)\n?") do
		currentLineNumber = currentLineNumber + 1
		if currentLineNumber > StartLine and currentLineNumber < EndLine then
			table.insert(contentLines, line)
		end
	end
	if ReturnTable then
		return contentLines
	end
	return table.concat(contentLines, "\n")
end

---@param Content string|nil
---@param RelativePath string
---@return boolean
function Parser.TargetExists(Content, RelativePath)
	if not Content then
		return false
	end
	local markerInfo = Parser.FindMarker(Content, RelativePath, true, false)
	return markerInfo.M_start ~= nil
end

---@param targetLine string
---@return string[]
function Parser.ParseDependencies(targetLine)
	local dependencies = {}

	local depString = targetLine:match("^[^:]*:%s*(.*)$")
	if not depString then
		return dependencies
	end

	for dep in depString:gmatch("%S+") do
		table.insert(dependencies, dep)
	end

	return dependencies
end

---@class TargetInfo
---@field name string
---@field dependencies string[]
---@field recipe string[]
---@field found boolean

---@param sectionContent string
---@param targetName string
---@return TargetInfo
function Parser.ParseTarget(sectionContent, targetName)
	local target = {
		name = targetName,
		dependencies = {},
		recipe = {},
		found = false,
	}

	local lines = {}
	for line in sectionContent:gmatch("[^\n]+") do
		table.insert(lines, line)
	end

	local i = 1
	while i <= #lines do
		local line = lines[i]
		local trimmedLine = line:match("^%s*(.-)%s*$")

		local targetPattern = "^" .. Utils.EscapePattern(targetName) .. "%s*:"
		if trimmedLine:match(targetPattern) then
			target.found = true
			target.dependencies = Parser.ParseDependencies(trimmedLine)

			i = i + 1
			while i <= #lines do
				local nextLine = lines[i]
				if nextLine:match("^%s+") and not nextLine:match("^%s*#") then
					table.insert(target.recipe, nextLine:match("^%s*(.*)$"))
					i = i + 1
				else
					break
				end
			end
			break
		end
		i = i + 1
	end

	return target
end

---@param sectionContent string
---@param baseName string|nil
---@param annotatedType string|nil
---@return boolean hasObj
---@return boolean hasExecutable
---@return boolean hasRun
function Parser.DetectTargetTypes(sectionContent, baseName, annotatedType)
	local hasObj = false
	local hasExecutable = false
	local hasRun = false

	local searchFor = {
		obj = true,
		executable = true,
		run = true,
	}

	if annotatedType then
		searchFor = {
			obj = false,
			executable = false,
			run = false,
		}

		if annotatedType == "full" then
			searchFor.obj = true
			searchFor.executable = true
			searchFor.run = true
		elseif annotatedType == "executable" then
			searchFor.obj = true
			searchFor.executable = true
		elseif annotatedType == "obj" then
			searchFor.obj = true
		elseif annotatedType == "run" then
			searchFor.run = true
		end
	end

	for line in sectionContent:gmatch("[^\n]+") do
		local trimmedLine = line:match("^%s*(.-)%s*$")

		if trimmedLine == "" or trimmedLine:match("^#") then
			goto continue
		end

		local targetName = trimmedLine:match("^([^:]+):")
		if targetName then
			targetName = targetName:match("^%s*(.-)%s*$")

			if searchFor.obj and not hasObj then
				if targetName:match("%.o$") or targetName:match("%.o%s*$") then
					hasObj = true
				end
			end

			if searchFor.executable and not hasExecutable then
				if
					baseName
					and (targetName == baseName or targetName:match("/" .. Utils.EscapePattern(baseName) .. "$"))
				then
					hasExecutable = true
				end
			end

			if searchFor.run and not hasRun then
				if
					baseName
					and (
						targetName == "run" .. baseName
						or targetName:match("/run" .. Utils.EscapePattern(baseName) .. "$")
					)
				then
					hasRun = true
				end
			end

			if
				(not searchFor.obj or hasObj)
				and (not searchFor.executable or hasExecutable)
				and (not searchFor.run or hasRun)
			then
				break
			end
		end

		::continue::
	end

	return hasObj, hasExecutable, hasRun
end

---@class SectionAnalysis
---@field hasObj boolean
---@field hasExecutable boolean
---@field hasRun boolean
---@field type string
---@field targets TargetInfo[]
---@field valid boolean
---@field error string|nil
---@field annotatedType string|nil

---@param sectionContent string
---@param baseName string|nil
---@param annotatedType string|nil
---@return SectionAnalysis
function Parser.AnalyzeSection(sectionContent, baseName, annotatedType)
	if not sectionContent or sectionContent == "" then
		return {
			hasObj = false,
			hasExecutable = false,
			hasRun = false,
			type = "empty",
			targets = {},
			valid = true,
			error = nil,
		}
	end

	local targets = {}

	if not baseName then
		baseName = sectionContent:match("([^/]+)%.cpp") or ""
		baseName = baseName:gsub("%.cpp$", "")
	end

	for line in sectionContent:gmatch("[^\n]+") do
		local trimmedLine = line:match("^%s*(.-)%s*$")

		if trimmedLine == "" or trimmedLine:match("^#") then
			goto continue
		end

		local targetName = trimmedLine:match("^([^:]+):")
		if targetName then
			targetName = targetName:match("^%s*(.-)%s*$")

			local targetInfo = Parser.ParseTarget(sectionContent, targetName)
			if targetInfo.found then
				table.insert(targets, targetInfo)
			end
		end

		::continue::
	end

	local hasObj, hasExecutable, hasRun = Parser.DetectTargetTypes(sectionContent, baseName)

	local inferredType
	if hasObj and hasExecutable and hasRun then
		inferredType = "full"
	elseif hasObj and hasExecutable then
		inferredType = "executable"
	elseif hasObj then
		inferredType = "obj"
	elseif hasRun then
		inferredType = "run"
	else
		inferredType = "unknown"
	end

	local valid = true
	local error = nil

	if annotatedType then
		local expectedTargets = {}

		if annotatedType == "full" then
			expectedTargets = { "obj", "executable", "run" }
		elseif annotatedType == "executable" then
			expectedTargets = { "obj", "executable" }
		elseif annotatedType == "obj" then
			expectedTargets = { "obj" }
		elseif annotatedType == "run" then
			expectedTargets = { "run" }
		end

		local missingTargets = {}
		for _, expected in ipairs(expectedTargets) do
			if expected == "obj" and not hasObj then
				table.insert(missingTargets, "object file (.o)")
			elseif expected == "executable" and not hasExecutable then
				table.insert(missingTargets, "executable")
			elseif expected == "run" and not hasRun then
				table.insert(missingTargets, "run target")
			end
		end

		if #missingTargets > 0 then
			valid = false
			error = string.format(
				"Type mismatch: marker specifies type '%s' but missing: %s",
				annotatedType,
				table.concat(missingTargets, ", ")
			)
		end
	end

	return {
		hasObj = hasObj,
		hasExecutable = hasExecutable,
		hasRun = hasRun,
		type = inferredType,
		targets = targets,
		valid = valid,
		error = error,
		annotatedType = annotatedType,
	}
end

---@param Content string
---@return { path: string, baseName: string|nil, startLine: integer, endLine: integer, analysis: SectionAnalysis }[]
function Parser.AnalyzeAllSections(Content)
	local allPairs = Parser.FindAllMarkerPairs(Content)
	local sectionAnalysis = {}

	for _, pair in ipairs(allPairs) do
		local sectionContent = Parser.ReadContentBetweenMarkers(Content, pair.path)
		if type(sectionContent) == "table" then
			sectionContent = table.concat(sectionContent, "\n")
		end

		local baseName = pair.path:match("([^/]+)%.cpp$")
		if baseName then
			baseName = baseName:gsub("%.cpp$", "")
		end

		local analysis = Parser.AnalyzeSection(sectionContent, baseName, pair.annotatedType)

		if analysis.valid then
			table.insert(sectionAnalysis, {
				path = pair.path,
				baseName = baseName,
				startLine = pair.StartLine,
				endLine = pair.EndLine,
				analysis = analysis,
			})
		else
			vim.notify(string.format("ERROR in section '%s': %s", pair.path, analysis.error), vim.log.levels.ERROR)
		end
	end

	return sectionAnalysis
end

---@param Content string
---@param targetType string
---@return table[]
function Parser.GetSectionsByType(Content, targetType)
	local allSections = Parser.AnalyzeAllSections(Content)
	local filteredSections = {}

	for _, section in ipairs(allSections) do
		if section.analysis.type == targetType then
			table.insert(filteredSections, section)
		end
	end

	return filteredSections
end

---@param Content string
function Parser.PrintAnalysisSummary(Content)
	local allSections = Parser.AnalyzeAllSections(Content)

	vim.notify("Makefile Section Analysis:")
	vim.notify("=" .. string.rep("=", 50))

	for _, section in ipairs(allSections) do
		local analysis = section.analysis
		vim.notify(string.format("Path: %s", section.path))
		vim.notify(string.format("Base Name: %s", section.baseName or "N/A"))
		vim.notify(string.format("Type: %s", analysis.type))

		if analysis.annotatedType then
			vim.notify(string.format("Annotated Type: %s", analysis.annotatedType))
		end

		vim.notify(string.format("Has Object: %s", analysis.hasObj and "Yes" or "No"))
		vim.notify(string.format("Has Executable: %s", analysis.hasExecutable and "Yes" or "No"))
		vim.notify(string.format("Has Run: %s", analysis.hasRun and "Yes" or "No"))

		if #analysis.targets > 0 then
			vim.notify("Targets:")
			for _, target in ipairs(analysis.targets) do
				vim.notify(string.format("  - %s", target.name))
				if #target.dependencies > 0 then
					vim.notify(string.format("    Dependencies: %s", table.concat(target.dependencies, ", ")))
				end
				if #target.recipe > 0 then
					vim.notify("    Recipe:")
					for _, recipeLine in ipairs(target.recipe) do
						vim.notify(string.format("      %s", recipeLine))
					end
				end
			end
		end
		vim.notify(string.rep("-", 50))
	end
end

return Parser
