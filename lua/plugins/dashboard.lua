return {
	"Melal1/dashboard-nvim",
	branch = "myPref",
	event = "VimEnter",
	enabled = false,
	config = function()
		require("dashboard").setup({
			disable_move = true,
			theme = "hyper",
			config = {
				disable_move = true,
				packages = { enable = false },
				shortcut = {},
				week_header = {
					enable = true,
				},
				footer = function()
					local stats = require("lazy").stats()
					local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
					return {'', "⚡ Startup time: " .. ms .. "ms" }
				end,
			},
		})
	end,
	dependencies = { { "nvim-tree/nvim-web-devicons" } },
}
