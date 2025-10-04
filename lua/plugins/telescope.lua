return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		cmd = "Telescope",
		event = { "BufReadPost" },
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
}
