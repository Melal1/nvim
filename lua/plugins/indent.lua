return {
	"lukas-reineke/indent-blankline.nvim",
	event = "BufRead",
	main = "ibl",
	---@module "ibl"
	---@type ibl.config

	config = function()
		vim.cmd([[highlight IblIndent guifg=#252530 gui=nocombine]])
		vim.cmd([[highlight IblScope guifg=#c9b1ca gui=nocombine]])
		require("ibl").setup({})
	end,
}
