---@type vim.lsp.Config
return {
	name = "avalonia",
	cmd = {
		"dotnet",
		"--roll-forward",
		"Major",
		vim.fn.expand("~/.local/share/avalonia-ls/lsp/AvaloniaLanguageServer.dll"),
	},
	filetypes = { "axaml" },
	root_markers = { "*.csproj", "*.sln", ".git" },
	settings = {
		avaloniaLS = {
			parserOutputDir = vim.fn.expand("~/.local/share/avalonia-ls/solution-parser"),
			useSolutionParser = true,
		},
	},
}
