return {
	{
		src = "https://github.com/folke/todo-comments.nvim",
		after = { "plenary.nvim" },
		keys = {
			{ "<leader>ltd", desc = "Todo comments" },
		},
		config = function()
			require("todo-comments").setup({
				highlight = {
					comments_only = false,
				},
			})
		end,
	},

	{
		src = "https://github.com/rachartier/tiny-inline-diagnostic.nvim",
		event = "BufRead",
		priority = 1000,
		config = function()
			require("tiny-inline-diagnostic").setup({
				hi = {
					error = "DiagnosticError", -- Highlight for error diagnostics
					warn = "DiagnosticWarn", -- Highlight for warning diagnostics
					info = "DiagnosticInfo", -- Highlight for info diagnostics
					hint = "DiagnosticHint", -- Highlight for hint diagnostics
					arrow = "EndOfBuffer", -- Highlight for the arrow pointing to diagnostic
					background = "NONE", -- Background highlight for diagnostics
					mixing_color = "Normal", -- Color to blend background with (or "None")
				},

				transparent_cursorline = false,
				transparent_bg = false,
				options = {
					set_arrow_to_diag_color = false,
					add_messages = {
						display_count = true,
					},
					multilines = {
						enabled = true,
					},
					show_source = {
						if_many = true, -- Only show source if multiple sources exist for the same diagnostic
					},
				},
			})
		end,
	},
	--CursorWord
	{
		src = "https://github.com/nvim-mini/mini.cursorword",
		config = function()
			vim.g.minicursorword_disable = true
			require("mini.cursorword").setup()
		end,
		keys = {
			{
				"<leader>enw",
				function()
					vim.g.minicursorword_disable = not vim.g.minicursorword_disable
				end,
				desc = "Toggle cursor word highlight",
			},
		},
	},

	{
		src = "https://github.com/luukvbaal/statuscol.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			vim.o.numberwidth = 3
			vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#cdcdcd", bg = "#1b1b26", bold = true })
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
							auto = "",
							wrap = true,
							foldclosed = true,
						},
					},
					{
						text = {
							builtin.lnumfunc,
							" ",
						},
						Condition = { true, builtin.not_empty },
					},
					{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
					{ text = { " " } },
				},
			})
		end,
	},

	--- Gitsigns
	{
		src = "https://github.com/lewis6991/gitsigns.nvim",
		keys = {
			{ "<leader>lgt", desc = "Gitsigns toggle" },
		},
		opts = {
			signs = {
				add = { text = "┃" },
				change = { text = "┃" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},
			signs_staged = {
				add = { text = "┃" },
				change = { text = "┃" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},
			signs_staged_enable = true,
			signcolumn = true,
			numhl = false,
			linehl = false,
			word_diff = false,
			watch_gitdir = {
				follow_files = true,
			},
			auto_attach = true,
			attach_to_untracked = false,
			current_line_blame = false,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol",
				delay = 100,
				ignore_whitespace = false,
				virt_text_priority = 100,
				use_focus = true,
			},
			current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
			sign_priority = 6,
			update_debounce = 100,
			status_formatter = nil,
			max_file_length = 40000,
			preview_config = {
				border = "single",
				style = "minimal",
				relative = "cursor",
				row = 0,
				col = 1,
			},
			on_attach = function(bufnr)
				local gitsigns = require("gitsigns")

				local function map(mode, lhs, rhs, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, lhs, rhs, opts)
				end

				-- Navigation
				map("n", "]c", function()
					if vim.wo.diff then
						vim.cmd("normal! ]c")
					else
						gitsigns.next_hunk()
					end
				end)

				map("n", "[c", function()
					if vim.wo.diff then
						vim.cmd("normal! [c")
					else
						gitsigns.prev_hunk()
					end
				end)

				-- Actions
				map("n", "<leader>hs", gitsigns.stage_hunk)
				map("n", "<leader>hr", gitsigns.reset_hunk)
				map("v", "<leader>hs", function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end)
				map("v", "<leader>hr", function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end)
				map("n", "<leader>hS", gitsigns.stage_buffer)
				map("n", "<leader>hu", gitsigns.undo_stage_hunk)
				map("n", "<leader>hR", gitsigns.reset_buffer)
				map("n", "<leader>hp", gitsigns.preview_hunk)
				map("n", "<leader>hb", function()
					gitsigns.blame_line({ full = true })
				end)
				map("n", "<leader>tb", gitsigns.toggle_current_line_blame)
				map("n", "<leader>hd", gitsigns.diffthis)
				map("n", "<leader>hD", function()
					gitsigns.diffthis("~")
				end)
				map("n", "<leader>td", gitsigns.toggle_deleted)
			end,
		},
		config = function(opts)
			require("gitsigns").setup(opts)
		end,
	},
	--- Focus
	{
		src = "https://github.com/folke/twilight.nvim",
		opts = {
			dimming = {
				alpha = 0.7, -- amount of dimming
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
			exclude = { "oil" }, -- exclude these filetypes,
		},
		config = function(opts)
			require("twilight").setup(opts)
		end,
		keys = { { "<leader>ltw", ":Twilight<CR>" } },
	},

	{
		src = "https://github.com/tzachar/highlight-undo.nvim",
		config = function()
			require("highlight-undo").setup({
				hlgroup = "IncSearch",
				duration = 300,
				pattern = { "*" },
				ignored_filetypes = { "neo-tree", "fugitive", "TelescopePrompt", "mason", "lazy" },
			})
		end,
	},

	{
		src = "https://github.com/karb94/neoscroll.nvim",
		config = function()
			require("neoscroll").setup({ duration_multiplier = 0.15 })
		end,
	},

	{
		src = "https://github.com/nvim-mini/mini.indentscope",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			-- symbol = "▏",
			symbol = "│",
			options = { try_as_border = true },
		},
		config = function(opts)
			require("mini.indentscope").setup(opts)
		end,
	},

	{
		src = "https://github.com/vague2k/vague.nvim",
		priority = 1000,
		opts = {
			transparent = true,
			style = {
				boolean = "bold",
				number = "bold",
				float = "bold",
				error = "bold",
				comments = "italic",
				conditionals = "bold",
				functions = "bold",
				headings = "bold",
				operators = "none",
				variables = "bold",

				keywords = "none",
				keyword_return = "italic",
				keywords_loop = "bold",
				keywords_label = "bold",
				keywords_exception = "bold",

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
		},
		config = function(opts)
			require("vague").setup(opts)
			vim.cmd("colorscheme vague")
		end,
	},
	--- Colorizer
	{
		src = "https://github.com/catgoose/nvim-colorizer.lua",
		keys = { { "<leader>CL", "<cmd>ColorizerToggle<CR>" } },
		config = function()
			require("colorizer").setup()
		end,
	},

	{
		src = "https://github.com/nvim-tree/nvim-web-devicons",
		lazy = true,
		config = function()
			require("nvim-web-devicons").setup()
		end,
	},
}
