return {

	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
	},
	branch = "main",
  lazy = false ,
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")
		ts.install({ "cpp", "bash", "lua", "rust", "make" })
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("EnableTreesitterHighlighting", { clear = true }),
			desc = "Try to enable tree-sitter syntax highlighting",
			pattern = "*", -- run on *all* filetypes
			callback = function()
				pcall(function()
					vim.treesitter.start()
				end)
			end,
		})
	end,
}
