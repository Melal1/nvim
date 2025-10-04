return {
	"m4xshen/hardtime.nvim",
	event = { "BufReadPost", "BufNewFile" },
	keys = { { "<leader>lht", "<cmd>Hardtime toggle" } },
	dependencies = { "MunifTanjim/nui.nvim" },
	opts = {},
}
