return {
	{
		src = "https://github.com/lmilojevicc/herdr-splits.nvim",
		keys = {
			{
				"<C-h>",
				function()
					require("herdr-splits").move_cursor_left()
				end,
				desc = "Navigate left",
			},
			{
				"<C-j>",
				function()
					require("herdr-splits").move_cursor_down()
				end,
				desc = "Navigate down",
			},
			{
				"<C-k>",
				function()
					require("herdr-splits").move_cursor_up()
				end,
				desc = "Navigate up",
			},
			{
				"<C-l>",
				function()
					require("herdr-splits").move_cursor_right()
				end,
				desc = "Navigate right",
			},
			{
				"<M-h>",
				function()
					require("herdr-splits").resize_left()
				end,
				desc = "Resize left",
			},
			{
				"<M-j>",
				function()
					require("herdr-splits").resize_down()
				end,
				desc = "Resize down",
			},
			{
				"<M-k>",
				function()
					require("herdr-splits").resize_up()
				end,
				desc = "Resize up",
			},
			{
				"<M-l>",
				function()
					require("herdr-splits").resize_right()
				end,
				desc = "Resize right",
			},
		},
	},

	{
		src = "https://github.com/alexghergh/nvim-tmux-navigation",
		keys = {
			{ "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>" },
		},
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
