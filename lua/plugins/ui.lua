local theme = require("config.utils.theme").apply_theme()
return {
	--Indent
	{
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
	},
	--Colorizer: ccc
	{
		"uga-rosa/ccc.nvim",
		keys = {
			{ "<leader>cct", "<cmd>CccHighlighterToggle<CR>", desc = "Toggle color highlighter" },
		},
		config = function()
			require("ccc").setup({
				highlighter = {
					auto_enable = false, -- Keep disabled by default to save time
					lsp = true, -- Leverage LSP for accuracy
				},
				outputs = {
					require("ccc").output.hex, -- #RRGGBB
					require("ccc").output.css_rgb, -- rgb(255, 0, 0)
					require("ccc").output.css_rgba, -- rgba(255, 0, 0, 0.5)
				},
			})

			-- Add other keybindings after the plugin is set up
			vim.api.nvim_set_keymap("n", "<leader>cp", "<cmd>CccPick<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>cc", "<cmd>CccConvert<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("v", "<leader>cs", "<Plug>(ccc-select-color)", { noremap = true, silent = true })
		end,
	},
	--Focus: twilight
	{
		"folke/twilight.nvim",
		opts = {
			dimming = {
				alpha = 0.4, -- amount of dimming
				-- we try to get the foreground from the highlight groups or fallback color
				color = { "Normal", "#ffffff" },
				term_bg = "#000000", -- if guibg=NONE, this will be used to calculate text color
				inactive = false, -- when true, other windows will be fully dimmed (unless they contain the same buffer)
			},
			context = 10, -- amount of lines we will try to show around the current line
			treesitter = true, -- use treesitter when available for the filetype
			-- treesitter is used to automatically expand the visible text,
			-- but you can further control the types of nodes that should always be fully expanded
			expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
				"function",
				"method",
				"table",
				"if_statement",
			},
			exclude = {}, -- exclude these filetypes,
		},
		keys = { { "<leader>ltw", ":Twilight<CR>" } },
	},
	--Focus: zen
	{
		"folke/zen-mode.nvim",
		keys = { { "<leader>lz", ":ZenMode<CR>" } },
		opts = {
			window = {
				backdrop = 1, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
				-- height and width can be:
				-- * an absolute number of cells when > 1
				-- * a percentage of the width / height of the editor when <= 1
				-- * a function that returns the width or the height
				width = 1, -- width of the Zen window
				height = 1, -- height of the Zen window
				-- by default, no options are changed for the Zen window
				-- uncomment any of the options below, or add other vim.wo options you want to apply
				options = {
					-- signcolumn = "no", -- disable signcolumn
					-- number = false, -- disable number column
					-- relativenumber = false, -- disable relative numbers
					-- cursorline = false, -- disable cursorline
					-- cursorcolumn = false, -- disable cursor column
					-- foldcolumn = "0", -- disable fold column
					-- list = false, -- disable whitespace characters
				},
			},
			plugins = {
				options = {
					enabled = true,
					ruler = false, -- disables the ruler text in the cmd line area
					showcmd = false, -- disables the command in the last line of the screen
					-- you may turn on/off statusline in zen mode by setting 'laststatus'
					-- statusline will be shown only if 'laststatus' == 3
					laststatus = 0, -- turn off the statusline in zen mode
				},
				twilight = { enabled = false }, -- enable to start Twilight when zen mode opens
				gitsigns = { enabled = true }, -- disables git signs
				tmux = { enabled = false }, -- disables the tmux statusline
				todo = { enabled = true }, -- if set to "true", todo-comments.nvim highlights will be disabled
				-- this will change the font size on kitty when in zen mode
				-- to make this work, you need to set the following kitty options:
				-- - allow_remote_control socket-only
				-- - listen_on unix:/tmp/kitty
				kitty = {
					enabled = true,
					font = "+6", -- font size increment
				},
				ghostty = {
					enabled = true,
					font = "+6",
				},
			},
			on_open = function()
				vim.fn.system([[tmux set status off]])
			end,

			on_close = function()
				vim.fn.system([[tmux set status on]])
			end,
			-- callback where you can add custom code when the Zen window opens
		},
	},
	--Folds: UFO
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		event = "BufReadPost",
		config = function()
			vim.o.foldcolumn = "1"
			vim.o.foldenable = true
			vim.o.foldlevel = 99
			vim.o.foldlevelstart = 99
			vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
			require("ufo").setup({
				-- open_fold_hl_timeout = 0,
				-- close_fold_kinds_for_ft = {},
				-- enable_get_fold_virt_text = false,
				-- fold_virt_text_handler = nil,
				provider_selector = function(_, filetype, buftype)
					if buftype ~= "" or filetype == "neo-tree" then
						return "" -- Disable UFO for special/non-file buffers_color
					end
					return { "treesitter", "indent" }
				end,
			})

			vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
			vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
			vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
			vim.keymap.set("n", "zm", require("ufo").closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)

			vim.keymap.set("n", "zK", function()
				local ex = require("ufo").peekFoldedLinesUnderCursor()
				if not ex then
					vim.lsp.buf.hover()
				end
			end, { desc = "Peek fold" })
			vim.api.nvim_set_hl(0, "FoldColumn", { fg = "#aeaed1", bg = "NONE" }) -- fold column background
		end,
	},
	--Statuscolumn
	{
		"luukvbaal/statuscol.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			vim.o.numberwidth = 3
			vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#cdcdcd", bg = "NONE", bold = true })
			local builtin = require("statuscol.builtin")
			require("statuscol").setup({
				relculright = true,
				segments = {
					{
						sign = {
							name = { "Dap" },
							maxwidth = 1,
							colwidth = 1,
							auto = "",
							wrap = true,
							foldclosed = true,
						},
					},

					{
						sign = {
							namespace = { "diagnostic", "gitsigns_signs_" },
							maxwidth = 1,
							colwidth = 1,
							auto = " ",
							wrap = true,
							foldclosed = true,
						},
					},
					{
						text = {
							builtin.lnumfunc,
							" ",
						},
						condition = { true, builtin.not_empty },
					},
					{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
					{ text = { "  " } },
				},
			})
		end,
	},
	--Dashboard: Dashboard
	{
		"Melal1/dashboard-nvim",
		branch = "myPref",
		event = "VimEnter",
		enabled = false,
		config = function()
			require("dashboard").setup({
				disable_move = true,
				theme = "hyper",
				config = {
					disable_move = true,
					packages = { enable = false },
					shortcut = {},
					week_header = {
						enable = true,
					},
					footer = function()
						local stats = require("lazy").stats()
						local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
						return { "", "⚡ Startup time: " .. ms .. "ms" }
					end,
				},
			})
		end,
		dependencies = { { "nvim-tree/nvim-web-devicons" } },
	},
	--THEMES:
	{
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
	},
}
