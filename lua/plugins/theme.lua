local theme = require("config.utils.theme").apply_theme()
return {
	{
		"catppuccin/nvim",
		-- lazy = true,
		name = "catppuccin",
		priority = 1000,
		enabled = false,
		config = function()
			require("catppuccin").setup({
				transparent_background = true,
				show_end_of_buffer = true, -- shows the '~' characters after the end of buffers
				term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
				dim_inactive = {
					enabled = false, -- dims the background color of inactive window
					shade = "dark",
					percentage = 0.15, -- percentage of the shade to apply to the inactive window
				},
				no_italic = false, -- Force no italic
				no_bold = false, -- Force no bold
				no_underline = false, -- Force no underline
				styles = {
					comments = { "italic" },
					conditionals = { "italic", "bold" },
					loops = { "bold" },

					functions = { "bold" },
					keywords = { "bold" },
					variables = { "bold" },
					numbers = { "bold" },
					booleans = { "italic" },
					properties = { "bold" },
					types = { "bold" },
					operators = { "bold" },
				},
				color_overrides = {},
				custom_highlights = {},
				default_integrations = true,
				integrations = {
					flash = true,
					gitsigns = true,
					neotree = true,
					native_lsp = { enabled = true, inlay_hints = { background = true } },
					telescope = {
						enabled = true,
					},
					treesitter = true,
					ufo = true,
					indent_blankline = {
						enabled = true,
						scope_color = "", -- catppuccin color (eg. `lavender`) Default: text
						colored_indent_levels = false,
					},
					alpha = true,
				},
			})
			vim.cmd.colorscheme(theme)
		end,
	},
	{
		"folke/tokyonight.nvim",
		lazy = true,
		priority = 1000,
		config = function()
			require("tokyonight").setup({
				transparent = true,
			})
		end,
	},
	{
		"rebelot/kanagawa.nvim",
		lazy = true,
		priority = 1000,
		config = function()
			require("kanagawa").setup({
				compile = false,
				undercurl = true, -- enable undercurls
				commentStyle = { italic = true },
				functionStyle = { bold = true },
				keywordStyle = { bold = true },
				statementStyle = { bold = true },
				typeStyle = { bold = true },
				transparent = true, -- do not set background color
				dimInactive = true, -- dim inactive window `:h hl-NormalNC`
				terminalColors = true, -- define vim.g.terminal_color_{0,17}
			})
		end,
	},

	{
		"EdenEast/nightfox.nvim",
		lazy = true,
		priority = 1000,
		config = function()
			require("nightfox").setup({
				options = {
					transparent = true,
					styles = { -- Style to be applied to different syntax groups
						comments = "italic", -- Value is any valid attr-list value `:help attr-list`
						conditionals = "bold",
						constants = "bold",
						functions = "bold",
						keywords = "NONE",
						numbers = "NONE",
						operators = "NONE",
						strings = "NONE",
						types = "italic, bold",
						variables = "bold",
					},
				},
			})
		end,
	},
	{
		"vague2k/vague.nvim",
		lazy = false, -- make sure we load this during startup if it is your main colorscheme
		priority = 1000, -- make sure to load this before all the other plugins
		config = function()
			require("vague").setup({
				transparent = true,
				bold = true,
				italic = true,
				style = {
					-- "none" is the same thing as default. But "italic" and "bold" are also valid options
					boolean = "italic",
					number = "bold",
					float = "bold",
					error = "bold",
					comments = "italic",
					conditionals = "bold",
					functions = "bold",
					headings = "bold",
					operators = "none",
					strings = "italic",
					variables = "bold",

					-- keywords
					keywords = "none",
					keyword_return = "italic",
					keywords_loop = "bold",
					keywords_label = "bold",
					keywords_exception = "bold",

					-- builtin
					builtin_constants = "bold",
					builtin_functions = "italic",
					builtin_types = "bold",
					builtin_variables = "italic",
				},

				plugins = {
					cmp = {
						match = "bold",
						match_fuzzy = "bold",
					},
					lsp = {
						diagnostic_error = "bold",
						diagnostic_hint = "none",
						diagnostic_info = "italic",
						diagnostic_ok = "none",
						diagnostic_warn = "bold",
					},
					telescope = {
						match = "bold",
					},
				},
			})

			vim.cmd("colorscheme vague")
		end,
	},
}
