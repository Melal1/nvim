local debug_mappings = {
	{ "a", require("config.utils.debugprint").add_above, "n", "Insert debug print above" },
	{ "b", require("config.utils.debugprint").add_below, "n", "Insert debug print below" },
	{ "s", require("config.utils.debugprint").surround, "n", "Surround with debug prints" },
	{ "d", require("config.utils.debugprint").clean, "n", "Remove all debug prints" },
	{ "t", require("config.utils.debugprint").toggle, "n", "Toggle comments on all debug prints" },
}

for _, mapping in ipairs(debug_mappings) do
	local key, callback, modes, description = unpack(mapping)
	vim.keymap.set(modes, "<leader>dp" .. key, callback, { desc = description })
end
