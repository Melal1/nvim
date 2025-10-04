local Finder = {}

function Finder.FindRoot(StartingPoint, MaxSearchLevels, RootMarkers)
	StartingPoint = StartingPoint or vim.fn.expand("%:p:h")

	if not StartingPoint or StartingPoint == "" then
		return nil, "Invalid starting location"
	end

	if not vim.fn.isdirectory(StartingPoint) then
		return nil, "Starting point is not a directory: " .. StartingPoint
	end

	MaxSearchLevels = MaxSearchLevels or 5
	RootMarkers = RootMarkers or { ".git", "src", "include", "build", "Makefile" }

	local CurrentPath = StartingPoint
	for i = 1, MaxSearchLevels do
		for _, Marker in ipairs(RootMarkers) do
			local MarkerPath = CurrentPath .. "/" .. Marker
			local Stat = vim.loop.fs_stat(MarkerPath)
			if Stat then
				return {
					Path = CurrentPath,
					Marker = Marker,
					Level = i,
				}
			end
		end

		local ParentPath = vim.fn.fnamemodify(CurrentPath, ":h")
		if ParentPath == CurrentPath then
			break
		end
		CurrentPath = ParentPath
	end

	return nil, "No project root found within " .. MaxSearchLevels .. " levels"
end

function Finder.FindHeaderDirectory(Basename, RootPath)
	local HeaderName = Basename .. ".h"

	-- Search recursively from root directory for the header file
	local Utils = require("config.utils.make.utils")
	local SearchCmd = "find "
		.. vim.fn.shellescape(RootPath)
		.. " -name "
		.. vim.fn.shellescape(HeaderName)
		.. " -type f"
	local FindResult = vim.fn.system(SearchCmd)

	if vim.v.shell_error ~= 0 or FindResult == "" then
		return nil
	end

	-- Take the first match if multiple headers found
	local HeaderPath = vim.trim(vim.split(FindResult, "\n")[1])
	local HeaderDir = vim.fn.fnamemodify(HeaderPath, ":h")

	-- Convert to relative path from root
	local RelativeHeaderDir, _ = Utils.GetRelativePath(HeaderDir, RootPath)
	if RelativeHeaderDir then
		return RelativeHeaderDir
	end

	return HeaderDir
end

return Finder
