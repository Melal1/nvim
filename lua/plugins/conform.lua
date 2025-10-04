return {
	"stevearc/conform.nvim",
	keys = {
		{
			"<leader>frm",
			function()
				require("conform").format({ lsp_format = "fallback" })
			end,
			desc = "Trigger formating",
		},
	},
	opts = {},
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				cpp = { "clang_format" },
				nix = { "nixpkgs_fmt" },
			},
			formatters = {
				clang_format = {
					prepend_args = {
						"--style={BasedOnStyle: LLVM, \
            IndentWidth: 2, \
            UseTab: Never, \
            ColumnLimit: 9999,\
            BreakBeforeBraces: Allman, \
            AlignArrayOfStructures: None,\
            SeparateDefinitionBlocks: Always,\
            EmptyLineBeforeAccessModifier: LogicalBlock,\
            AllowShortFunctionsOnASingleLine: None}",
					},
				},
			},
		})
	end,
}
