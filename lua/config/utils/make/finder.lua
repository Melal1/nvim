---@class RootInfo
---@field Path string           # Absolute path to the detected project root
---@field Marker string         # The marker that determined the root (e.g. ".git", "Makefile")
---@field Level integer         # How many levels up the search went

local Finder = {}

---Finds the root directory of a project by searching upward from a starting point
---for known root markers (e.g. `.git`, `Makefile`).
---
---@param StartingPoint? string  # Directory to start the search from (defaults to current buffer's directory)
---@param MaxSearchLevels? integer # Maximum number of parent directories to search
---@param RootMarkers? string[]  # List of marker names to look for
---@return RootInfo|nil, string? # Returns root info table if found, otherwise nil and an error message
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

---Finds the directory containing a header file with the given basename, relative to the project root.
---For example, if `Basename` is `"utils"`, it will search for `"utils.h"`.
---
---@param Basename string # Base name of the header file (without extension)
---@param RootPath string # Root directory to start the search
---@return string|nil     # Relative or absolute path to the header's directory, or nil if not found
function Finder.FindHeaderDirectory(Basename, RootPath)
	local HeaderName = Basename .. ".h"

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

	local HeaderPath = vim.trim(vim.split(FindResult, "\n")[1])
	local HeaderDir = vim.fn.fnamemodify(HeaderPath, ":h")

	local RelativeHeaderDir, _ = Utils.GetRelativePath(HeaderDir, RootPath)
	if RelativeHeaderDir then
		return RelativeHeaderDir
	end

	return HeaderDir
end

return Finder
