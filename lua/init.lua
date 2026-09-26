vim.g.mapleader = " "

-- local s = vim.uv.hrtime()
local plugins = {}
local groups = {
	require("plugins.ui"),
	require("plugins.utility"),
	require("plugins.extras"),
}

for i = 1, #groups do
	local group = groups[i]
	for i = 1, #group do
		table.insert(plugins, group[i])
	end
end

_G.Packload = require("packload")

Packload.load(plugins, { validate = false })

-- local e = vim.uv.hrtime()

require("core.set")
require("core.keymaps")
require("core.lsp")
require("config")
require("statusline")

-- local e2 = vim.uv.hrtime()
-- print("packload took " .. (e - s) / 1e6 .. " ms, whole setup took " .. (e2- s) / 1e6 .. " ms")
