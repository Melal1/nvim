return {
	--Formatting: conform
	{
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
      ColumnLimit: 150, \
      BreakBeforeBraces: Allman, \
      AlignArrayOfStructures: None, \
      SeparateDefinitionBlocks: Always, \
      EmptyLineBeforeAccessModifier: LogicalBlock, \
      AllowShortFunctionsOnASingleLine: None, \
      BinPackArguments: false, \
      AllowAllParametersOfDeclarationOnNextLine: true, \
      AllowShortLambdasOnASingleLine: false, \
      AllowAllArgumentsOnNextLine: false, \
      PenaltyBreakBeforeFirstCallParameter: 1}",
						},
					},
				},
			})
		end,
	},
	--Cmp : Blink
	{

		event = { "BufRead", "BufNewFile" },
		"saghen/blink.cmp",
		dependencies = { "fang2hou/blink-copilot" },
		-- dependencies = { "rafamadriz/friendly-snippets" },

		-- use a release tag to download pre-built binaries
		version = "1.*",
		-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
		-- build = 'cargo build --release',
		-- If you use nix, you can build from source using latest nightly rust with:
		-- build = 'nix run .#build-plugin',

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
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
				nerd_font_variant = "mono",
			},

			cmdline = {
				completion = {
					ghost_text = { enabled = true },
				},
				keymap = {
					preset = "default",
					["<C-y>"] = { "cancel" },
					["<C-e>"] = { "select_and_accept" },
				},
			},

			completion = {
				ghost_text = {
					enabled = true,
					show_with_menu = false,
				},
				menu = {
					auto_show = false,
					draw = {
						components = {
							source_name = {
								text = function(ctx)
									if ctx.source_name == "LSP" then
										return "[LSP]"
									end
									if ctx.source_name == "Snippets" then
										return "[SNIP]"
									end
									if ctx.source_name == "Buffer" then
										return "[BUF]"
									end
									if ctx.source_name == "Path" then
										return "[PATH]"
									end
								end,
							},
						},
						gap = 2,
						columns = {
							{ "source_name", gap = 1 },
							{ "label", "label_description", gap = 1 },
							{ "kind_icon", "kind", gap = 2 },
						},
					},
				},
				documentation = {
					auto_show = false,
				},
			},

			sources = {
				default = { "snippets", "lsp", "path", "buffer", "copilot" },

				providers = {
					copilot = {
						name = "copilot",
						module = "blink-copilot",
						score_offset = 100,
						async = true,
					},
					lsp = {
						score_offset = 9,
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
				implementation = "rust",
			},
		},
		opts_extend = { "sources.default" },
	},
	--Treesitter
	{

		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			branch = "main",
		},
		branch = "main",
		event = { "BufRead", "BufNew" },
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			ts.install({ "cpp", "bash", "lua", "rust", "make" })
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(details)
					vim.defer_fn(function()
						local bufnr = details.buf
						if not pcall(vim.treesitter.start, bufnr) then
							return -- Exit if treesitter was unable to start
						end
						vim.bo[bufnr].syntax = "on" -- fallback syntax highlighting
						vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- treesitter folds
					end, 50) -- delay in milliseconds
				end,
			})
		end,
	},
}
