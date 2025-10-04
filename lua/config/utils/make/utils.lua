local Utils = {}

function Utils.ReadFile(FilePath)
	local File, Err = io.open(FilePath, "r")
	if not File then
		return nil, "Could not open file: " .. FilePath .. " (" .. (Err or "unknown error") .. ")"
	end

	local Content = File:read("*a")
	File:close()

	if not Content then
		return nil, "Could not read file content: " .. FilePath
	end

	return Content
end

function Utils.WriteFile(FilePath, Content)
	local BackupPath = FilePath .. ".bak"
	local OriginalContent = Utils.ReadFile(FilePath)
	if OriginalContent then
		local BackupFile = io.open(BackupPath, "w")
		if BackupFile then
			BackupFile:write(OriginalContent)
			BackupFile:close()
		end
	end

	local File, Err = io.open(FilePath, "w")
	if not File then
		return false, "Could not open file for writing: " .. FilePath .. " (" .. (Err or "unknown error") .. ")"
	end

	local Success, WriteErr = File:write(Content)
	File:close()

	if not Success then
		return false, "Could not write to file: " .. FilePath .. " (" .. (WriteErr or "unknown error") .. ")"
	end

	return true
end

function Utils.AppendToFile(FilePath, Lines)
	local File, Err = io.open(FilePath, "a")
	if not File then
		return false, "Could not open file for appending: " .. FilePath .. " (" .. (Err or "unknown error") .. ")"
	end

	for _, Line in ipairs(Lines) do
		File:write(Line .. "\n")
	end
	File:close()
	return true
end

function Utils.IsValidSourceFile(FilePath, SourceExtensions)
	local Ext = vim.fn.fnamemodify(FilePath, ":e")
	for _, ValidExt in ipairs(SourceExtensions) do
		if "." .. Ext == ValidExt then
			return true
		end
	end
	return false
end

function Utils.EscapePattern(Str)
	return Str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

function Utils.GetRelativePath(FilePath, RootPath)
	local AbsFilePath = vim.fn.fnamemodify(FilePath, ":p")
	local AbsRoot = vim.fn.fnamemodify(RootPath, ":p")

	if AbsRoot:sub(-1) ~= "/" then
		AbsRoot = AbsRoot .. "/"
	end

	if AbsFilePath:sub(1, #AbsRoot) == AbsRoot then
		return "./" .. AbsFilePath:sub(#AbsRoot + 1)
	else
		return nil, "File is outside the project root"
	end
end

return Utils
