return {
	"alexghergh/nvim-tmux-navigation",
	keys = {
		{ "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>" },
		{ "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>" },
		{ "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>" },
		{ "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>" },
	},
	config = function()
		require("nvim-tmux-navigation").setup({})
	end,
}
