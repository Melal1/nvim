return {
	"yetone/avante.nvim",
  cond = false ,
	build = "make",
	keys = {
		{
			"<leader>lav",
			function()
				vim.notify("Avante loaded")
				vim.keymap.set("n", "<leader>ta", "<cmd>AvanteAsk<CR>", { desc = "Toggle avante" })
			end,
		},
	},
	version = false,
	---@module 'avante'
	---@type avante.Config
	opts = {
		file_selector = {
			provider = "telescope",
		},

		selection = {
			hint_display = "none",
		},
		provider = "gemini",
		providers = {
			gemini = {
				model = "gemini-2.5-flash",
				timeout = 30000,
			},
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"MeanderingProgrammer/render-markdown.nvim",
	},
}
