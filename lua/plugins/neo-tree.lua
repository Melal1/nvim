return {
	"nvim-neo-tree/neo-tree.nvim",
	keys = {
		{ "<C-n>", "<cmd>Neotree float toggle<CR>" },
	},
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	opts = {
		mappings = {
			["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = false } },
		},
		close_if_last_window = false,
		filesystem = {
			bind_to_cwd = true,
			follow_current_file = { enabled = true },
			hijack_netrw_behavior = "disabled", -- don't auto open

			filtered_items = {
				visible = true,
				show_hidden_count = true,
				hide_dotfiles = true,
				hide_gitignored = false,
				hide_by_name = {
					".git",
					".DS_Store",
					"thumbs.db",
				},
				never_show = {},
			},
		},
	},

	config = function(_, opts)
		require("neo-tree").setup(opts)
	end,
}
