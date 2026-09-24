return {

	{
		src = "https://github.com/zbirenbaum/copilot.lua",
		cmd = { "Copilot" },
		keys = {
			{ "<leader>tc", "<cmd>Copilot enable | Copilot toggle<CR>", desc = "Toggle Copilot" },
			{ "<leader>tC", "<cmd>Copilot disable<CR>", desc = "Toggle Copilot" },
		},
		opts = {
			suggestion = { enabled = false },
			panel = { enabled = false },
			filetypes = {
				markdown = true,
				help = true,
			},
		},

		config = function(opts)
			require("copilot").setup(opts)
		end,
	},

	{
		src = "https://github.com/folke/snacks.nvim",
		config = function()
			require("snacks").setup({})
		end,
		keys = {
			{
				"<leader>ft",
				function()
					Snacks.terminal(nil, { win = { position = "float" } })
				end,
				desc = "Toggle floating term",
			},
			{
				"<leader><space>",
				function()
					Snacks.picker.smart()
				end,
				desc = "Smart Find Files",
			},
			{
				"<leader>,",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>/",
				function()
					Snacks.picker.grep()
				end,
				desc = "Grep",
			},
			{
				"<leader>:",
				function()
					Snacks.picker.command_history()
				end,
				desc = "Command History",
			},
			{
				"<leader>fb",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>fc",
				function()
					Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "Find Config File",
			},
			{
				"<leader>ff",
				function()
					Snacks.picker.files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>fg",
				function()
					Snacks.picker.git_files()
				end,
				desc = "Find Git Files",
			},
			{
				"<leader>fp",
				function()
					Snacks.picker.projects()
				end,
				desc = "Projects",
			},
			{
				"<leader>frr",
				function()
					Snacks.picker.recent()
				end,
				desc = "Recent",
			},
			{
				"<leader>gs",
				function()
					Snacks.picker.git_status()
				end,
				desc = "Git Status",
			},
			{
				"<leader>gd",
				function()
					Snacks.picker.git_diff()
				end,
				desc = "Git Diff (Hunks)",
			},
			{
				"<leader>b/",
				function()
					Snacks.picker.lines()
				end,
				desc = "Buffer Lines",
			},
			{
				"<leader>B/",
				function()
					Snacks.picker.grep_buffers()
				end,
				desc = "Grep Open Buffers",
			},
			{
				"<leader>w/",
				function()
					Snacks.picker.grep_word()
				end,
				desc = "Visual selection or word",
				mode = { "n", "x" },
			},
			{
				'<leader>rg"',
				function()
					Snacks.picker.registers()
				end,
				desc = "Registers",
			},
			{
				"<leader>shis",
				function()
					Snacks.picker.search_history()
				end,
				desc = "Search History",
			},
			{
				"<leader>sa",
				function()
					Snacks.picker.autocmds()
				end,
				desc = "Autocmds",
			},
			{
				"<leader>sC",
				function()
					Snacks.picker.commands()
				end,
				desc = "Commands",
			},
			{
				"<leader>sd",
				function()
					Snacks.picker.diagnostics()
				end,
				desc = "Diagnostics",
			},
			{
				"<leader>sD",
				function()
					Snacks.picker.diagnostics_buffer()
				end,
				desc = "Buffer Diagnostics",
			},
			{
				"<leader>sh",
				function()
					Snacks.picker.help()
				end,
				desc = "Help Pages",
			},
			{
				"<leader>sH",
				function()
					Snacks.picker.highlights()
				end,
				desc = "Highlights",
			},
			{
				"<leader>si",
				function()
					Snacks.picker.icons()
				end,
				desc = "Icons",
			},
			{
				"<leader>sj",
				function()
					Snacks.picker.jumps()
				end,
				desc = "Jumps",
			},
			{
				"<leader>sk",
				function()
					Snacks.picker.keymaps()
				end,
				desc = "Keymaps",
			},
			{
				"<leader>sm",
				function()
					Snacks.picker.marks()
				end,
				desc = "Marks",
			},
			{
				"<leader>sM",
				function()
					Snacks.picker.man()
				end,
				desc = "Man Pages",
			},
			{
				"<leader>sp",
				function()
					Snacks.picker.lazy()
				end,
				desc = "Search for Plugin Spec",
			},
			{
				"<leader>sq",
				function()
					Snacks.picker.qflist()
				end,
				desc = "Quickfix List",
			},
			{
				"<leader>sR",
				function()
					Snacks.picker.resume()
				end,
				desc = "Resume",
			},
			{
				"<leader>su",
				function()
					Snacks.picker.undo()
				end,
				desc = "Undo History",
			},
			{
				"<leader>suC",
				function()
					Snacks.picker.colorschemes()
				end,
				desc = "Colorschemes",
			},
			{
				"gd",
				function()
					Snacks.picker.lsp_definitions()
				end,
				desc = "Goto Definition",
			},
			{
				"gD",
				function()
					Snacks.picker.lsp_declarations()
				end,
				desc = "Goto Declaration",
			},
			{
				"gr",
				function()
					Snacks.picker.lsp_references()
				end,
				desc = "References",
			},
			{
				"gI",
				function()
					Snacks.picker.lsp_implementations()
				end,
				desc = "Goto Implementation",
			},
			{
				"gy",
				function()
					Snacks.picker.lsp_type_definitions()
				end,
				desc = "Goto T[y]pe Definition",
			},
			{
				"gai",
				function()
					Snacks.picker.lsp_incoming_calls()
				end,
				desc = "C[a]lls Incoming",
			},
			{
				"gao",
				function()
					Snacks.picker.lsp_outgoing_calls()
				end,
				desc = "C[a]lls Outgoing",
			},
			{
				"<leader>ss",
				function()
					Snacks.picker.lsp_symbols()
				end,
				desc = "LSP Symbols",
			},
			{
				"<leader>sS",
				function()
					Snacks.picker.lsp_workspace_symbols()
				end,
				desc = "LSP Workspace Symbols",
			},
		},
	},

	--- Better Search and replace
	{
		src = "https://github.com/nvim-pack/nvim-spectre",
		after = { "plenary.nvim" },
		cmd = { "Spectre" },
		config = function()
			require("spectre").setup()
		end,
	},
	--- Better undo
	{
		src = "https://github.com/mbbill/undotree",
		cmd = { "UndotreeToggle" },
		keys = {
			{
				"<leader>lut",
				"<cmd>UndotreeToggle<CR>",
				desc = "Toggle Undotree",
			},
		},
		config = function()
			vim.g.undotree_WindowLayout = 3
		end,
	},

	--- Better quickfix list
	{
		src = "https://github.com/folke/trouble.nvim",
		cmd = { "Trouble" },
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>xs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>xl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xq",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
		config = function()
			require("trouble").setup({})
		end,
	},

	--- BD
	{
		src = "https://github.com/nvim-mini/mini.bufremove",
		keys = {
			{
				"<leader>bd",
				function()
					MiniBufremove.delete(0, false)
				end,
				desc = "Delete Buffer",
			},
			{
				"<leader>bD",
				function()
					MiniBufremove.delete(0, true)
				end,
				desc = "Force Delete Buffer",
			},
		},
		config = function()
			require("mini.bufremove").setup()
		end,
	},

	--- Tabout
	{
		src = "https://github.com/kawre/neotab.nvim",
		event = "InsertEnter",
		opts = {
			tabkey = "<Tab>",
			reverse_key = "<S-Tab>",
			act_as_tab = true,
			behavior = "nested",
			pairs = { ---@type ntab.pair[]
				{ open = "(", close = ")" },
				{ open = "[", close = "]" },
				{ open = "{", close = "}" },
				{ open = "'", close = "'" },
				{ open = '"', close = '"' },
				{ open = "`", close = "`" },
				{ open = "<", close = ">" },
			},
			exclude = {},
			smart_punctuators = {
				enabled = true,
				semicolon = {
					enabled = true,
					ft = { "cs", "c", "cpp", "java" },
				},
				escape = {
					enabled = true,
					triggers = { ---@type table<string, ntab.trigger>
						[","] = {
							pairs = {
								{ open = "'", close = "'" },
								{ open = '"', close = '"' },
							},
							format = "%s ", -- ", "
						},
					},
				},
			},
		},
		config = function(opts)
			require("neotab").setup(opts)
		end,
	},

	{
		src = "https://github.com/stevearc/conform.nvim",
		keys = {
			{
				"<leader>frm",
				function()
					require("conform").format({ lsp_format = "fallback" }, function(err, _)
						if err then
							return
						end

						if vim.bo.ft ~= "axaml" then
							return
						end

						local bufnr = vim.api.nvim_get_current_buf()
						local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
						if #lines == 0 then
							return
						end

						-- Check the first 3 bytes for the UTF-8 BOM
						if lines[1]:sub(1, 3) == "\xEF\xBB\xBF" then
							local new_line = lines[1]:sub(4)
							vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { new_line })
						end
					end)
				end,
				desc = "Trigger formatting",
			},
		},
		opts = {
			formatters_by_ft = {
				python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
				xml = { "xmllint" },
				axaml = { "xstyler", "xmllint", stop_after_first = true },
				lua = { "stylua" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				cpp = { "clang_format" },
				nix = { "nixpkgs_fmt" },
			},
			formatters = {
				xstyler = {
					command = "xaml-styler",
					args = { "-f", "$FILENAME" },
					stdin = false,
				},
				clang_format = {
					prepend_args = {
						"--style={ \
            BasedOnStyle: LLVM, \
            IndentWidth: 2, \
            UseTab: Never, \
            ColumnLimit: 120, \
            BreakBeforeBraces: Allman, \
            AlignArrayOfStructures: None, \
            SeparateDefinitionBlocks: Always, \
            EmptyLineBeforeAccessModifier: LogicalBlock, \
            AllowShortFunctionsOnASingleLine: None, \
            BinPackArguments: false, \
            BinPackParameters: false, \
            AlignAfterOpenBracket: AlwaysBreak, \
            AllowAllArgumentsOnNextLine: true, \
            AllowAllParametersOfDeclarationOnNextLine: true, \
          }",
					},
				},
			},

			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				return { timeout_ms = 500, lsp_format = "fallback" }
			end,
		},
		config = function(opts)
			require("conform").setup(opts)
		end,
	},

	{ src = "https://github.com/saghen/blink.lib", name = "blink.lib", lazy = true },
	{ src = "https://github.com/fang2hou/blink-copilot", name = "blink-copilot", lazy = true },
	{ src = "https://github.com/rafamadriz/friendly-snippets", name = "friendly-snippets", lazy = true },
	{
		src = "https://github.com/folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
		config = function(opts)
			require("lazydev").setup(opts)
		end,
	},

	{
		src = "https://github.com/saghen/blink.cmp",
		event = { "BufReadPost", "BufNewFile" },
		after = { "blink.lib", "blink-copilot", "friendly-snippets", "nvim-web-devicons", "lazydev.nvim" },

		build = function()
			require("blink.cmp").build():pwait()
		end,

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		config = function()
			local icons = require("nvim-web-devicons")
			require("blink.cmp").setup({
				keymap = {

					preset = "default",
					["<C-s>"] = { "show" },
					["<C-y>"] = { "hide" },
					["<C-e>"] = { "select_and_accept" },
					["<C-l>"] = { "snippet_forward", "fallback" },
					["<C-h>"] = { "snippet_backward", "fallback" },
					["<UP>"] = {
						function(cmp)
							cmp.show({ providers = { "snippets" } })
						end,
					},
					["<DOWN>"] = {
						function(cmp)
							cmp.show({ providers = { "lsp" } })
						end,
					},
					["<Tab>"] = false,
					["<S-Tab>"] = false,
				},
				signature = { enabled = true },

				appearance = {
					nerd_font_variant = "normal",
				},

				cmdline = {
					completion = {
						ghost_text = { enabled = false },
					},
					keymap = {
						preset = "default",
						["<C-y>"] = { "cancel" },
						["<C-e>"] = { "select_and_accept" },
					},
				},

				completion = {
					accept = {
						create_undo_point = true,
						auto_brackets = {
							-- Whether to auto-insert brackets for functions
							enabled = true,
						},
					},
					ghost_text = {
						enabled = true,
						show_with_menu = true,
					},
					menu = {
						auto_show_delay_ms = 500,
						scrollbar = true,
						auto_show = true,
						border = "single",
						draw = {
							-- padding = { 1, 1 },
							components = {
								kind_icon = {
									highlight = function(ctx)
										return ctx.kind
									end,
									-- text = function(ctx)
									-- 	local icon = (icons[ctx.kind] or "󰈚")
									-- 	return icon
									-- end,
								},

								kind = {
									highlight = function(ctx)
										return ctx.kind
									end,
								},
								label = {
									width = { fill = true, max = 60 },
									text = function(ctx)
										return ctx.label .. ctx.label_detail
									end,
									highlight = function(ctx)
										-- label and label details
										local highlights = {
											{
												0,
												#ctx.label,
												group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
											},
										}
										if ctx.label_detail then
											table.insert(highlights, {
												#ctx.label,
												#ctx.label + #ctx.label_detail,
												group = "BlinkCmpLabelDetail",
											})
										end

										-- characters matched on the label by the fuzzy matcher
										for _, idx in ipairs(ctx.label_matched_indices) do
											table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
										end

										return highlights
									end,
								},
							},
							-- gap = 2,
							columns = {
								{ "kind_icon" },
								{ "label" },
								{ "kind" },
							},
						},
					},
					documentation = {
						auto_show = false,
					},
				},

				sources = {
					default = { "lazydev", "snippets", "lsp", "path", "buffer", "copilot" },

					providers = {
						copilot = {
							name = "copilot",
							module = "blink-copilot",
							score_offset = 9999,
							async = true,
						},
						lazydev = {
							name = "LazyDev",
							module = "lazydev.integrations.blink",
							score_offset = 100,
						},
						buffer = {
							score_offset = 7,
						},
						lsp = {
							score_offset = 1000,
						},
						snippets = {
							score_offset = 10,
						},
					},
				},
				fuzzy = {
					sorts = {
						"exact",
						"score",
						"sort_text",
					},
					-- Use Rust when its native matcher has been built, but keep completion
					-- available on fresh installs and systems without that binary.
					implementation = "prefer_rust",
				},
			})
		end,
	},

	{
		src = "https://github.com/saghen/blink.pairs",
		event = { "BufReadPost", "BufNewFile" },

		after = { "blink.lib" },
		-- vim.pack accepts an exact tag, branch, or commit; unlike lazy.nvim it
		-- does not support the "*" version range.  Omit a revision to track main.
		build = function()
			require("blink.pairs").build():pwait(60000)
		end,

		--- @module 'blink.pairs'
		--- @type blink.pairs.Config
		config = function()
			require("blink.pairs").setup({
				mappings = {
					-- you can call require("blink.pairs.mappings").enable()
					-- and require("blink.pairs.mappings").disable()
					-- to enable/disable mappings at runtime
					enabled = true,
					cmdline = true,
					-- or disable with `vim.g.pairs = false` (global) and `vim.b.pairs = false` (per-buffer)
					-- and/or with `vim.g.blink_pairs = false` and `vim.b.blink_pairs = false`
					disabled_filetypes = {},
					-- see the defaults:
					-- https://github.com/Saghen/blink.pairs/blob/main/lua/blink/pairs/config/mappings.lua#L14
					pairs = {},
				},
				highlights = {
					enabled = true,
					-- requires require('vim._extui').enable({}), otherwise has no effect
					cmdline = true,
					groups = {
						-- "BlinkPairsOrange",
						-- "BlinkPairsPurple",
						-- "BlinkPairsBlue",
						"@lsp.type.parameter",
						"@lsp.type.enum",
						"@keyword.exepction",
					},
					unmatched_group = "BlinkPairsUnmatched",

					-- highlights matching pairs under the cursor
					matchparen = {
						enabled = true,
						-- known issue where typing won't update matchparen highlight, disabled by default
						cmdline = false,
						-- also include pairs not on top of the cursor, but surrounding the cursor
						include_surrounding = false,
						group = "BlinkPairsMatchParen",
						priority = 250,
					},
				},
				debug = false,
			})
		end,
	},

	{
		src = "https://github.com/stevearc/oil.nvim",
		after = { "nvim-web-devicons" },
		cmd = { "Oil" },
		lazy = false,
		keys = {
			{ "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
		},
		opts = {
			default_file_explorer = true,
			delete_to_trash = true,
			skip_confirm_for_simple_edits = true,
			view_options = {
				show_hidden = true,
				natural_order = true,
				is_always_hidden = function(name, _)
					return name == ".." or name == ".git"
				end,
			},
			win_options = {
				wrap = true,
			},
		},
		config = function(opts)
			require("oil").setup(opts)
		end,
	},

	--- Sql things:
	{
		src = "https://github.com/NicholasMata/sqlserver.nvim",
		cmd = { "SQLServer" },
		opts = {
			keymap_prefix = "<leader>D",
		},
		config = function(opts)
			require("sqlserver").setup(opts)
		end,
	},

	--- C sharp
	{
		src = "https://github.com/GustavEikaas/easy-dotnet.nvim",
		after = { "plenary.nvim", "snacks.nvim" },
		ft = { "cs", "axaml" },
		opts = {
			external_terminal = {
				command = "kitty",
				args = { "--hold", "--" },
			},
			lsp = {
				enabled = false,
			},
			debugger = {
				bin_path = "netcoredbg",
				console = "externalTerminal",
				apply_value_converters = true,
				auto_register_dap = true,
				mappings = {
					open_variable_viewer = { lhs = "T", desc = "open variable viewer" },
				},
			},
		},
		config = function(opts)
			local dotnet = require("easy-dotnet")
			dotnet.setup(opts)

			-- Run / watch (primary entrypoints from `:Dotnet run` family)
			vim.keymap.set("n", "<leader>nr", dotnet.run, { desc = "dotnet: run (picker)" })
			vim.keymap.set("n", "<leader>nR", dotnet.run_default, { desc = "dotnet: run default project" })
			vim.keymap.set("n", "<leader>np", dotnet.run_profile, { desc = "dotnet: run --launch-profile" })
			vim.keymap.set("n", "<leader>nP", dotnet.run_profile_default, { desc = "dotnet: run default with profile" })
			vim.keymap.set("n", "<leader>nw", dotnet.watch, { desc = "dotnet: watch (picker)" })
			vim.keymap.set("n", "<leader>nW", dotnet.watch_default, { desc = "dotnet: watch default project" })

			-- Build / test / clean
			vim.keymap.set("n", "<leader>nb", dotnet.build, { desc = "dotnet: build (picker)" })
			vim.keymap.set("n", "<leader>nt", dotnet.test, { desc = "dotnet: test (picker)" })
			vim.keymap.set("n", "<leader>nc", dotnet.clean, { desc = "dotnet: clean" })

			-- Debug (bundled netcoredbg via DAP)
			vim.keymap.set("n", "<leader>nd", dotnet.debug, { desc = "dotnet: debug (picker)" })
			vim.keymap.set("n", "<leader>nD", dotnet.debug_default, { desc = "dotnet: debug default" })

			-- Toggle the Rider-like test runner window
			vim.keymap.set("n", "<leader>no", dotnet.testrunner, { desc = "dotnet: toggle test runner" })

			require("config.utils.dotnet.avalonia").setup({ notify = false, confirm = false })
		end,
	},
	{
		src = "https://github.com/khoido2003/roslyn-filewatch.nvim",
		build = "nvim -l build.lua --",
		lazy = true,
		opts = {
			watch_extensions = {
				".cs",
				".csproj",
				".sln",
				".slnx",
				".slnf",
				".props",
				".targets",
				".razor",
				".cshtml",
				".xaml",
				".axaml",
			},
		},
		config = function(opts)
			require("roslyn_filewatch").setup(opts)
		end,
	},
	{
		src = "https://github.com/seblyng/roslyn.nvim",
		after = { "roslyn-filewatch.nvim" },
		ft = { "cs", "axaml" },
		config = function()
			require("roslyn").setup({
				filewatching = "off",
			})
		end,
	},

	--- Java
	{
		src = "https://github.com/mfussenegger/nvim-jdtls",
		lazy = true,
	},
	--- Debugging
	{
		src = "https://github.com/jbyuki/one-small-step-for-vimkind",
		lazy = true,
	},
	{
		src = "https://github.com/igorlfs/nvim-dap-view",
		after = { "nvim-dap" },
		keys = {
			{
				"<leader>du",
				"<cmd>DapViewToggle<CR>",
				desc = "Start Ui",
			},
		},
		config = function()
			require("dap-view").setup({
				winbar = {
					sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "console" },
					default_section = "scopes",
				},
			})
		end,
	},
	{
		src = "https://github.com/theHamsta/nvim-dap-virtual-text",
		lazy = true,
	},
	{
		src = "https://github.com/mfussenegger/nvim-dap",
		after = { "one-small-step-for-vimkind", "nvim-dap-virtual-text" },
		keys = {
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Breakpoint Condition",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle Breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Run/Continue",
			},
			{
				"<leader>dC",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Run to Cursor",
			},
			{
				"<leader>dg",
				function()
					require("dap").goto_()
				end,
				desc = "Go to Line (No Execute)",
			},
			{
				"<Right>",
				function()
					require("dap").step_into()
				end,
				desc = "Step Into",
			},
			{
				"<leader>dj",
				function()
					require("dap").down()
				end,
				desc = "Down",
			},
			{
				"<leader>dk",
				function()
					require("dap").up()
				end,
				desc = "Up",
			},
			{
				"<leader>dl",
				function()
					require("dap").run_last()
				end,
				desc = "Run Last",
			},
			{
				"<Up>",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
			{
				"<Down>",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<leader>dP",
				function()
					require("dap").pause()
				end,
				desc = "Pause",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.toggle()
				end,
				desc = "Toggle REPL",
			},
			{
				"<leader>ds",
				function()
					require("dap").session()
				end,
				desc = "Session",
			},
			{
				"<leader>dw",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "Widgets",
			},
			{ "<leader>daw", "<cmd>DapViewWatch<CR>", desc = "Add under cursor to watch list" },
			{
				"<leader>dfr",
				function()
					local w = require("dap.ui.widgets")
					w.sidebar(w.frames).open()
				end,
				desc = "Call stack",
			},
			{
				"<leader>dNV",
				function()
					require("osv").launch({ port = 8086 })
				end,
				desc = "Launch OSV",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
					_G.DAP_IS_ACTIVE = false
					require("nvim-dap-virtual-text").disable()
					pcall(function()
						require("statusline").refresh_winbar()
					end)
				end,
				desc = "Terminate",
			},
		},
		config = function()
			local dap = require("dap")
			require("nvim-dap-virtual-text").setup({
				only_first_definition = false,
			})
			local debuggerPath = os.getenv("CODELLDB_PATH")

			dap.adapters.cppdbg = {
				id = "cppdbg",
				type = "executable",
				command = debuggerPath,
			}
			dap.configurations.cpp = {
				{
					name = "Attach to gdbserver :1234 ( Snacks + Herdr )",
					type = "cppdbg",
					request = "launch",
					MIMode = "gdb",
					miDebuggerServerAddress = "localhost:1234",
					miDebuggerPath = "/run/current-system/sw/bin/gdb",
					cwd = "${workspaceFolder}",
					program = function()
						return coroutine.create(function(dap_run_co)
							local cwd = vim.fn.getcwd()
							local build_dir = cwd .. "/build"

							if vim.fn.isdirectory(build_dir) == 0 then
								vim.notify("No 'build' directory found.", vim.log.levels.WARN)
								return
							end

							local find_cmd = string.format("find %s -type f -executable", vim.fn.shellescape(build_dir))
							local output = vim.fn.system(find_cmd)

							if vim.v.shell_error ~= 0 or output == "" or not output then
								vim.notify("No executables found in 'build'.", vim.log.levels.WARN)
								return
							end

							local executables = {}
							for line in output:gmatch("[^\r\n]+") do
								table.insert(executables, line)
							end

							Snacks.picker.select(executables, {
								prompt = "Select Executable to Debug",
								format_item = function(item)
									return vim.fn.fnamemodify(item, ":.")
								end,
							}, function(selected)
								if not selected then
									return
								end

								require("config.debug").RunDebug("cpp", selected)

								vim.defer_fn(function()
									coroutine.resume(dap_run_co, selected)
								end, 200)
							end)
						end)
					end,
					stopAtEntry = false,
					setupCommands = {
						{
							text = "-enable-pretty-printing",
							description = "enable pretty printing",
							ignoreFailures = false,
						},
					},
				},
				{
					name = "Launch file locally (No gdbserver)",
					type = "cppdbg",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopAtEntry = false,
					setupCommands = {
						{
							text = "-enable-pretty-printing",
							description = "enable pretty printing",
							ignoreFailures = false,
						},
					},
				},
			}
			dap.configurations.lua = {
				{
					type = "nlua",
					request = "attach",
					name = "Attach to running Neovim instance",
				},
			}

			dap.adapters.nlua = function(callback, config)
				callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
			end

			dap.listeners.before.attach.st = function()
				_G.DAP_IS_ACTIVE = true
				require("nvim-dap-virtual-text").enable()
				pcall(function()
					require("statusline").refresh_winbar()
				end)
			end
			dap.listeners.before.launch.st = function()
				_G.DAP_IS_ACTIVE = true
				require("nvim-dap-virtual-text").enable()
				pcall(function()
					require("statusline").refresh_winbar()
				end)
			end
			dap.listeners.before.event_terminated.st = function()
				_G.DAP_IS_ACTIVE = false
				require("nvim-dap-virtual-text").disable()
				pcall(function()
					require("statusline").refresh_winbar()
				end)
			end
			dap.listeners.before.event_exited.st = function()
				_G.DAP_IS_ACTIVE = false
				require("nvim-dap-virtual-text").disable()
				pcall(function()
					require("statusline").refresh_winbar()
				end)
			end
		end,
	},

	--- Split join
	{
		src = "https://github.com/nvim-mini/mini.splitjoin",
		config = function()
			require("mini.splitjoin").setup()
		end,
		keys = {
			{
				"<leader>tj",
				function()
					require("mini.splitjoin").toggle()
				end,
				desc = "Toggle Split/Join",
			},
		},
	},
	--- Improved txt obj
	{
		src = "https://github.com/echasnovski/mini.ai",
		event = "InsertEnter",
		config = function()
			require("mini.ai").setup()
		end,
	},

	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		after = { "nvim-treesitter-textobjects" },
		version = "main",
		-- event = { "BufRead", "BufNew" },
		build = ":TSUpdate",
		config = function()
			vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
			local ts = require("nvim-treesitter")
			ts.install({ "c_sharp", "python", "cpp", "bash", "lua", "rust", "make", "java", "cmake", "qmljs" })
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(details)
					vim.defer_fn(function()
						local bufnr = details.buf
						if not pcall(vim.treesitter.start, bufnr) then
							return -- Exit if treesitter was unable to start
						end
						vim.bo[bufnr].syntax = "on" -- fallback syntax highlighting
						-- vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- treesitter indentation
					end, 50) -- delay in milliseconds
				end,
			})
		end,
	},
	--- Fast Movement
	{
		src = "https://github.com/folke/flash.nvim",
		keys = {
			{
				"S",
				function()
					require("flash").jump()
				end,
				mode = { "n", "x", "o" },
				desc = "Flash",
			},
			{
				"r",
				function()
					require("flash").remote()
				end,
				mode = "o",
				desc = "Remote Flash",
			},
			{
				"R",
				function()
					require("flash").treesitter_search()
				end,
				mode = { "o", "x" },
				desc = "Treesitter Search",
			},
			{
				"<c-s>",
				function()
					require("flash").toggle()
				end,
				mode = { "c" },
				desc = "Toggle Flash Search",
			},
		},
	},

	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		version = "main",
		opts = {
			select = {
				-- Automatically jump forward to textobj, similar to targets.vim
				lookahead = true,
				-- You can choose the select mode (default is charwise 'v')
				--
				-- Can also be a function which gets passed a table with the keys
				-- * query_string: eg '@function.inner'
				-- * method: eg 'v' or 'o'
				-- and should return the mode ('v', 'V', or '<c-v>') or a table
				-- mapping query_strings to modes.
				selection_modes = {
					["@parameter.outer"] = "v", -- charwise
					["@function.outer"] = "V", -- linewise
					["@class.outer"] = "<c-v>", -- blockwise
				},
				-- If you set this to `true` (default is `false`) then any textobject is
				-- extended to include preceding or succeeding whitespace. Succeeding
				-- whitespace has priority in order to act similarly to eg the built-in
				-- `ap`.
				--
				-- Can also be a function which gets passed a table with the keys
				-- * query_string: eg '@function.inner'
				-- * selection_mode: eg 'v'
				-- and should return true of false
				include_surrounding_whitespace = false,
			},
			move = {
				-- whether to set jumps in the jumplist
				set_jumps = true,
			},
		},
		config = function(opts)
			require("nvim-treesitter-textobjects").setup(opts)

			-- Select
			vim.keymap.set({ "x", "o" }, "ar", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@return.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ir", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@return.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "in", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@number.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ao", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@loop.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "io", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@loop.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "i=", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@assignment.rhs", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "i-", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@assignment.lhs", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "a=", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@assignment.rhs", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "a-", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@assignment.lhs", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "am", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@call.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "im", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@call.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ai", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@conditional.outer")
			end)
			vim.keymap.set({ "x", "o" }, "ii", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@conditional.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "af", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "if", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ac", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ic", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "as", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
			end)
			vim.keymap.set({ "o", "x" }, "aA", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer")
			end)
			vim.keymap.set({ "o", "x" }, "aa", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner")
			end)

			-- Swap
			vim.keymap.set("n", "<leader>=a", function()
				require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
			end)
			vim.keymap.set("n", "<leader>=f", function()
				require("nvim-treesitter-textobjects.swap").swap_next("@function.outer")
			end)
			vim.keymap.set("n", "<leader>=A", function()
				require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.inner")
			end)
			vim.keymap.set("n", "<leader>=F", function()
				require("nvim-treesitter-textobjects.swap").swap_previous("@function.outer")
			end)

			-- Move
			vim.keymap.set({ "n", "x", "o" }, "]m", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]]", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
			end)
			-- You can also pass a list to group multiple queries.
			vim.keymap.set({ "n", "x", "o" }, "]l", function()
				require("nvim-treesitter-textobjects.move").goto_next_start(
					{ "@loop.inner", "@loop.outer" },
					"textobjects"
				)
			end)
			vim.keymap.set({ "n", "x", "o" }, "[l", function()
				require("nvim-treesitter-textobjects.move").goto_next_start(
					{ "@loop.inner", "@loop.outer" },
					"textobjects"
				)
			end)
			-- You can also use captures from other query groups like `locals.scm` or `folds.scm`
			vim.keymap.set({ "n", "x", "o" }, "]s", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@local.scope", "locals")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]z", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@fold", "folds")
			end)

			vim.keymap.set({ "n", "x", "o" }, "]M", function()
				require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "][", function()
				require("nvim-treesitter-textobjects.move").goto_next_end("@class.outer", "textobjects")
			end)

			vim.keymap.set({ "n", "x", "o" }, "[m", function()
				require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[[", function()
				require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
			end)

			vim.keymap.set({ "n", "x", "o" }, "[M", function()
				require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[]", function()
				require("nvim-treesitter-textobjects.move").goto_previous_end("@class.outer", "textobjects")
			end)

			vim.keymap.set({ "n", "x", "o" }, "]i", function()
				require("nvim-treesitter-textobjects.move").goto_next("@conditional.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[i", function()
				require("nvim-treesitter-textobjects.move").goto_previous("@conditional.outer", "textobjects")
			end)

			local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
			vim.keymap.set({ "n", "x", "o" }, "<leader>;", ts_repeat_move.repeat_last_move)
			vim.keymap.set({ "n", "x", "o" }, "<leader>,", ts_repeat_move.repeat_last_move_opposite)
		end,
	},

	{
		src = "https://github.com/windwp/nvim-ts-autotag",
		ft = { "xaml", "axaml" },
		opts = {
			opts = {
				enable_close = true, -- Auto close tags (e.g., <Button> -> <Button></Button>)
				enable_rename = true, -- Auto rename paired tags when editing
				enable_close_on_slash = true, -- Auto close on trailing </
			},
			aliases = {
				["axaml"] = "html",
				["xaml"] = "html",
			},
		},
		config = function(opts)
			require("nvim-ts-autotag").setup(opts)
		end,
	},
	{
		src = "https://github.com/nvim-lua/plenary.nvim",
		lazy = true,
	},

	{
		src = "https://github.com/nvimtools/none-ls.nvim",
		after = { "plenary.nvim" },
		ft = { "py" },
		config = function()
			local null_ls = require("null-ls")

			null_ls.setup({
				sources = {
					null_ls.builtins.diagnostics.mypy,
				},
			})
		end,
	},
}
