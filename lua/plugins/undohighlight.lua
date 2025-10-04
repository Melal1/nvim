return {
	"tzachar/highlight-undo.nvim",
	event = { "BufReadPost" },
	opts = {
		hlgroup = "IncSearch",
		duration = 300,
		pattern = { "*" },
		ignored_filetypes = { "neo-tree", "fugitive", "TelescopePrompt", "mason", "lazy" },
	},
}
