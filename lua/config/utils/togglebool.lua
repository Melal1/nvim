local M = {}
local toggles = {
	["1"] = "0",
	["0"] = "1",
	["true"] = "false",
	["false"] = "true",
	["on"] = "off",
	["off"] = "on",
	["yes"] = "no",
	["no"] = "yes",
	["enable"] = "disable",
	["disable"] = "enable",
	["enabled"] = "disabled",
	["disabled"] = "enabled",
	["&&"] = "||",
	["||"] = "&&",
	[">>"] = "<<",
	["<<"] = ">>",
	["++"] = "--",
	["--"] = "++",
	["=="] = "!=",
	["!="] = "==",
}

local variants = {
	["true"] = "1",
	["1"] = "true",
	["false"] = "0",
	["0"] = "false",
	["yes"] = "1",
	["no"] = "0",
	["enable"] = "1",
	["disable"] = "0",
}

local function lookup(word, mode)
	word = word:lower()
	if mode then
		return toggles[word]
	else
		return variants[word]
	end
end

function M.toggleBool(mode)
	local word = vim.fn.expand("<cWORD>")
	local replacement = lookup(word, mode)
	if not replacement then
		word = vim.fn.expand("<cword>")
		replacement = lookup(word, mode)
	end

	if replacement then
		vim.cmd("normal! ciw" .. replacement)
	else
		vim.notify("No toggle or variant available for '" .. word .. "' :) ")
	end
end
return M
