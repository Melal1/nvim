-- <C-h/j/k/l> can only belong to one split navigator: herdr-splits inside a
-- herdr session, nvim-tmux-navigation inside tmux. Registering both let the
-- later spec silently shadow the earlier one, so gate the keys by environment.
local in_herdr = os.getenv("HERDR_ENV") == "1"

local herdr_keys = {
	{ "<C-h>", function() require("herdr-splits").move_cursor_left() end, desc = "Navigate left" },
	{ "<C-j>", function() require("herdr-splits").move_cursor_down() end, desc = "Navigate down" },
	{ "<C-k>", function() require("herdr-splits").move_cursor_up() end, desc = "Navigate up" },
	{ "<C-l>", function() require("herdr-splits").move_cursor_right() end, desc = "Navigate right" },
	{ "<M-h>", function() require("herdr-splits").resize_left() end, desc = "Resize left" },
	{ "<M-j>", function() require("herdr-splits").resize_down() end, desc = "Resize down" },
	{ "<M-k>", function() require("herdr-splits").resize_up() end, desc = "Resize up" },
	{ "<M-l>", function() require("herdr-splits").resize_right() end, desc = "Resize right" },
}

local tmux_keys = {
	{ "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>" },
	{ "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>" },
	{ "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>" },
	{ "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>" },
}

math.randomseed(os.time()) 

return {
	{
		src = "https://github.com/lmilojevicc/herdr-splits.nvim",
		lazy = true,
		keys = in_herdr and herdr_keys or nil,
	},

	{
		src = "https://github.com/alexghergh/nvim-tmux-navigation",
		lazy = true,
		keys = (not in_herdr) and tmux_keys or nil,
		config = function()
			require("nvim-tmux-navigation").setup({})
		end,
	},

	{
		src = "https://github.com/dstein64/vim-startuptime",
		cmd = { "StartupTime" },
	},

	{
		src = "https://github.com/vyfor/cord.nvim",
		build = ":Cord update",
		opts = {
			display = {
				theme = (math.random(0, 1) == 0) and "minecraft" or "classic",
				flavor = "dark",
			},
			editor = {
				tooltip = "Snowflake",
			},
		},
		config = function()
			require("cord").setup()
		end,
	},
}
