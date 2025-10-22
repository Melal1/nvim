return {
	--Debugging: DAP
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{
				"igorlfs/nvim-dap-view",
				---@module 'dap-view'
				---@type dapview.Config
				keys = {
					{
						"<leader>dc",
						"<cmd>DapViewToggle<CR>",
						desc = "Start Ui",
					},
				},
				opts = {
					winbar = {
						sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "console" },
						default_section = "scopes",
						controls = {
							enabled = true,
							position = "right",
						},
					},
				},
			},
			{
				"theHamsta/nvim-dap-virtual-text",
			},
		},
		keys = {
			{
				"[f",
				function()
					require("dap").up()
				end,
				desc = "DAP Up",
			},
			{
				"]f",
				function()
					require("dap").down()
				end,
				desc = "DAP Down",
			},
			{
				"<F1>",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "DAP Hover",
			},
			{
				"<F4>",
				function()
					require("dap").terminate({ hierarchy = true })
				end,
				desc = "DAP Terminate",
			},
			{
				"<leader>db",
				function()
					require("dap").continue()
				end,
				desc = "DAP Continue",
			},
			{
				"<F9>",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle Breakpoint",
			},
			{
				"<F10>",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<F11>",
				function()
					require("dap").step_into()
				end,
				desc = "Step Into",
			},
			{
				"<F12>",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
			{
				"<F17>",
				function()
					require("dap").run_last()
				end,
				desc = "Run Last",
			},
			{
				"<F18>",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Run to Cursor",
			},
		},
		config = function()
			local dap = require("dap")
			vim.keymap.set("n", "<leader>daw", "<cmd>DapViewWatch<CR>", { desc = "Add under cursor to watch list" })
			require("nvim-dap-virtual-text").setup({
				only_first_definition = false,
			})
			local debuggerPath = os.getenv("CODELLDB_PATH")

			dap.adapters.cppdbg = {
				id = "cppdbg",
				type = "executable",
				command = debuggerPath,
			}

			-- CPP

			dap.configurations.cpp = {
				{
					name = "Launch file",
					type = "cppdbg",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopAtEntry = true,
				},
				{
					name = "Attach to gdbserver :1234",
					type = "cppdbg",
					request = "launch",
					MIMode = "gdb",
					miDebuggerServerAddress = "localhost:1234",
					miDebuggerPath = "/run/current-system/sw/bin/gdb",
					cwd = "${workspaceFolder}",
					program = function()
						local msg = require("config.utils.debug").Debug()
						return msg
					end,
				},
			}
		end,
	},
	--Flash
	{
		"folke/flash.nvim",
		keys = {
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"r",
				mode = "o",
				function()
					require("flash").remote()
				end,
				desc = "Remote Flash",
			},
			{
				"R",
				mode = { "o", "x" },
				function()
					require("flash").treesitter_search()
				end,
				desc = "Treesitter Search",
			},
			{
				"<c-s>",
				mode = { "c" },
				function()
					require("flash").toggle()
				end,
				desc = "Toggle Flash Search",
			},
		},
	},
	--Telescope
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		cmd = "Telescope",
		-- Looks messy btw , but this is a simple solution
		keys = {
			{
				"<leader>opc",
				function()
					require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
				end,
				desc = "Find Plugin File",
			},
			{
				"<leader>frg",
				function()
					-- MiniFiles.close()
					require("telescope.builtin").registers()
				end,
				desc = "Registers",
			},
			{
				"<leader>ff",
				function()
					-- MiniFiles.close()
					require("telescope.builtin").find_files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>fg",
				function()
					-- MiniFiles.close()
					require("telescope.builtin").live_grep()
				end,
				desc = "Live Grep",
			},
			{
				"<leader>fb",
				function()
					-- MiniFiles.close()
					require("telescope.builtin").buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>fp",
				function()
					-- MiniFiles.close()
					require("telescope").extensions.projects.projects()
				end,
				desc = "Projects",
			},
			{
				"<leader>fSt",
				function()
					-- MiniFiles.close()
					local word = vim.fn.expand("<cWORD>")
					require("telescope.builtin").grep_string({ search = word })
				end,
				desc = "Grep WORD under cursor (includes punctuation)",
			},
			{
				"<leader>fst",
				function()
					-- MiniFiles.close()
					local word = vim.fn.expand("<cword>")
					require("telescope.builtin").grep_string({ search = word })
				end,
				desc = "Grep word under cursor (stops at punctuation)",
			},
			{
				"<leader>fo",
				function()
					-- MiniFiles.close()
					require("telescope.builtin").oldfiles()
				end,
				desc = "Old Files",
			},
			{
				"<leader>fsy",
				function()
					-- MiniFiles.close()
					require("telescope.builtin").lsp_document_symbols()
				end,
				desc = "LSP Document Symbols",
			},
			{
				"<leader>fdia",
				function()
					-- MiniFiles.close()
					require("telescope.builtin").diagnostics()
				end,
				desc = "Diagnostics",
			},
		},

		dependencies = {
			"nvim-lua/plenary.nvim",
			"jmacadie/telescope-hierarchy.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
			},
			"nvim-telescope/telescope-ui-select.nvim",
			"ahmedkhalf/project.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			telescope.setup({
				defaults = {
					preview = {
						treesitter = false,
					},
					mappings = {
						i = {
							["<esc>"] = actions.close,
						},
					},
					path_display = {
						"filename_first",
					},
					previewer = false,
					prompt_prefix = "    ",
					selection_caret = " ",
					file_ignore_patterns = { "node_modules", "package-lock.json", "lazy-lock.json" },
					initial_mode = "insert",
					select_strategy = "reset",
					sorting_strategy = "ascending",
					color_devicons = true,
					set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
					layout_config = {
						prompt_position = "top",
						preview_cutoff = 120,
					},
					vimgrep_arguments = {
						"rg",
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
						"--smart-case",
						"--hidden",
						"--glob=!.git/",
					},
				},
				pickers = {
					buffers = {
						mappings = {
							i = {
								["<c-d>"] = actions.delete_buffer,
							},
							n = {
								["<c-d>"] = actions.delete_buffer,
							},
						},
						previewer = false,
						initial_mode = "normal",
						-- theme = "dropdown",
						layout_config = {
							height = 0.4,
							width = 0.6,
							prompt_position = "top",
							preview_cutoff = 120,
						},
					},
					current_buffer_fuzzy_find = {
						previewer = true,
						layout_config = {
							prompt_position = "top",
							preview_cutoff = 120,
						},
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({
							previewer = false,
							initial_mode = "normal",
							sorting_strategy = "ascending",
							layout_strategy = "horizontal",
							layout_config = {
								horizontal = {
									width = 0.5,
									height = 0.4,
									preview_width = 0.6,
								},
							},
						}),
					},
				},
			})

			-- Setup project.nvim
			require("project_nvim").setup({})

			-- Load extensions
			telescope.load_extension("ui-select")
			telescope.load_extension("projects")
			telescope.load_extension("fzf")
			telescope.load_extension("hierarchy")
		end,
	},
	--TODO:
	{
		"folke/todo-comments.nvim",
		keys = { { "<leader>ltd" } },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			highlight = {
				comments_only = false,
			},
		},
	},
	--Search and replace: spectre
	{
		cmd = "Spectre",
		"nvim-pack/nvim-spectre",
		dependecies = {
			"nvim-lua/plenary.nvim",
		},
	},
	--FileTree: Oil
	{
		{
			"stevearc/oil.nvim",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			config = function()
				vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
				require("oil").setup({
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
				})
			end,
		},
		{
			"benomahony/oil-git.nvim",
			dependencies = { "stevearc/oil.nvim" },
			event = { "InsertEnter" },
		},
		{
			"JezerM/oil-lsp-diagnostics.nvim",
			dependencies = { "stevearc/oil.nvim" },
			opts = {},
			event = { "InsertEnter" },
		},
	},
	--FileTree: NeoTree
	{
		"nvim-neo-tree/neo-tree.nvim",
		keys = {
			{ "<C-n>", "<cmd>Neotree float toggle<CR>" },
		},
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		opts = {
			mappings = {
				["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = false } },
			},
			close_if_last_window = false,
			filesystem = {
				bind_to_cwd = true,
				follow_current_file = { enabled = true },
				hijack_netrw_behavior = "disabled", -- don't auto open

				filtered_items = {
					visible = true,
					show_hidden_count = true,
					hide_dotfiles = true,
					hide_gitignored = false,
					hide_by_name = {
						".git",
						".DS_Store",
						"thumbs.db",
					},
					never_show = {},
				},
			},
		},

		config = function(_, opts)
			require("neo-tree").setup(opts)
		end,
	},
	--Undo: Undotree
	{
		"mbbill/undotree",
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
	--Diagnostics: Trouble
	{
		"folke/trouble.nvim",
		opts = {
			modes = {
				project_dia = {
					mode = "diagnostics", -- inherit from diagnostics mode
					filter = {
						any = {
							buf = 1, -- current buffer
							{
								severity = vim.diagnostic.severity.ERROR, -- errors only
								-- limit to files in the current project
								function(item)
									return item.filename:find((vim.loop or vim.uv).cwd(), 1, true)
								end,
							},
						},
					},
				},
			},
		},
		cmd = "Trouble",
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
				"<leader>xp",
				"<cmd>Trouble project_dia<CR>",
				desc = "Project Diagonstics ( Trouble )",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
	--Buf: Mini Buf Do
	{
		"nvim-mini/mini.bufremove",
		keys = {
			{
				"<leader>bd",
				function()
					MiniBufremove.delete(0, false) -- delete current buffer safely
				end,
				desc = "Delete Buffer",
			},
			{
				"<leader>bD",
				function()
					MiniBufremove.delete(0, true) -- force delete (discard changes)
				end,
				desc = "Force Delete Buffer",
			},
		},
		version = false,
		config = function()
			require("mini.bufremove").setup()
		end,
	},
	--Git
	{
		"lewis6991/gitsigns.nvim",
		-- event = "BufRead",
		-- event = "InsertEnter",
		keys = { "<leader>lgt" },

		config = function()
			require("gitsigns").setup({
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
				signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
				numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
				linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
				word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
				watch_gitdir = {
					follow_files = true,
				},
				auto_attach = true,
				attach_to_untracked = false,
				current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
				current_line_blame_opts = {
					virt_text = true,
					virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
					delay = 100,
					ignore_whitespace = false,
					virt_text_priority = 100,
					use_focus = true,
				},
				current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
				sign_priority = 6,
				update_debounce = 100,
				status_formatter = nil, -- Use default
				max_file_length = 40000, -- Disable if file is longer than this (in lines)
				preview_config = {
					-- Options passed to nvim_open_win
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
			})
		end,
	},
	--Ai: Copilot
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		keys = {
			{ "<leader>tc", "<cmd>Copilot enable | Copilot toggle<CR>", mode = "n", desc = "Toggle Copilot" },
			{ "<leader><leader>tc", "<cmd>Copilot disable<CR>", mode = "n", desc = "Toggle Copilot" },
		},
		opts = {
			suggestion = { enabled = false },
			panel = { enabled = false },
			filetypes = {
				markdown = true,
				help = true,
			},
		},
	},
	--Ai wtf
	{
		"piersolenski/wtf.nvim",
		enable = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-telescope/telescope.nvim", -- Optional: For WtfGrepHistory
		},
		opts = {
			provider = "gemini",
			providers = {
				gemini = {
					api_key = "AIzaSyCnGm9rNhratLuyDtEEmJt3W6i8fSMMy2c",
				},
				deepseek = {
					-- An alternative way to set your API key
					--
					api_key = "sk-7e17d73ea7ec446d842ab147030a9b8d",
					-- Your preferred model
				},
			},

			hooks = {
				request_started = nil,
				request_finished = nil,
			},
		},

		keys = {
			{
				"<leader>wd",
				mode = { "n", "x" },
				function()
					require("wtf").diagnose()
				end,
				desc = "Debug diagnostic with AI",
			},
			{
				"<leader>wf",
				mode = { "n", "x" },
				function()
					require("wtf").fix()
				end,
				desc = "Fix diagnostic with AI",
			},
			{
				mode = { "n" },
				"<leader>ws",
				function()
					require("wtf").search()
				end,
				desc = "Search diagnostic with Google",
			},
			{
				mode = { "n" },
				"<leader>wp",
				function()
					require("wtf").pick_provider()
				end,
				desc = "Pick provider",
			},
			{
				mode = { "n" },
				"<leader>wh",
				function()
					require("wtf").history()
				end,
				desc = "Populate the quickfix list with previous chat history",
			},
			{
				mode = { "n" },
				"<leader>wg",
				function()
					require("wtf").grep_history()
				end,
				desc = "Grep previous chat history with Telescope",
			},
		},
	},
}
