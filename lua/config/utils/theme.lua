
local M = {}
function M.read_current_theme()
	local theme_file = vim.fn.expand("~/.config/settings/current_theme.txt")
	local file = io.open(theme_file, "r")

	if not file then
		vim.notify("Could not open theme file: " .. theme_file, vim.log.levels.ERROR)
		return nil
	end

	local theme = file:read("*l")
	file:close()

	if not theme or theme == "" then
		vim.notify("Theme file is empty or invalid.", vim.log.levels.WARN)
		return nil
	end

	return theme
end

function M.apply_theme()
	local theme = M.read_current_theme()

	if theme then
		return theme
	else
		vim.notify("Failed to apply theme. Using default.", vim.log.levels.ERROR)
		return "default"
	end
end

function M.set_theme(theme)
	local theme_file = vim.fn.expand("~/.config/settings/current_theme.txt")
	local file = io.open(theme_file, "w")

	if not file then
		vim.notify("Could not open theme file: " .. theme_file, vim.log.levels.ERROR)
		return
	end

	file:write(theme)
	file:close()

	M.apply_theme()
end

return M
