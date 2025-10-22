return {
	--Markdown
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
		ft = { "markdown", "Avante" },
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {},
	},
	--Movement training
	{
		"ThePrimeagen/vim-be-good",
		cmd = { "VimBeGood" },
	},
	--WritingEx: typr
	{
		"nvzone/typr",
		dependencies = "nvzone/volt",
		opts = {},
		cmd = { "Typr", "TyprStats" },
	},
	--Tips
	{
		"saxon1964/neovim-tips",
		version = "*", -- Only update on tagged releases
		cmd = "NeovimTips",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"MeanderingProgrammer/render-markdown.nvim",
		},
		opts = {
			-- OPTIONAL: Location of user defined tips (default value shown below)
			user_file = vim.fn.stdpath("config") .. "/neovim_tips/user_tips.md",
			-- OPTIONAL: Prefix for user tips to avoid conflicts (default: "[User] ")
			user_tip_prefix = "[User] ",
			-- OPTIONAL: Show warnings when user tips conflict with builtin (default: true)
			warn_on_conflicts = true,
			-- OPTIONAL: Daily tip mode (default: 1)
			-- 0 = off, 1 = once per day, 2 = every startup
			daily_tip = 1,
		},
		init = function()
			-- OPTIONAL: Change to your liking or drop completely
			-- The plugin does not provide default key mappings, only commands
			local map = vim.keymap.set
			map("n", "<leader>nto", ":NeovimTips<CR>", { desc = "Neovim tips", noremap = true, silent = true })
			map(
				"n",
				"<leader>nte",
				":NeovimTipsEdit<CR>",
				{ desc = "Edit your Neovim tips", noremap = true, silent = true }
			)
			map(
				"n",
				"<leader>nta",
				":NeovimTipsAdd<CR>",
				{ desc = "Add your Neovim tip", noremap = true, silent = true }
			)
			map(
				"n",
				"<leader>ntr",
				":NeovimTipsRandom<CR>",
				{ desc = "Show random tip", noremap = true, silent = true }
			)
		end,
	},
	--Tumx Nav
	{
		"alexghergh/nvim-tmux-navigation",
		keys = {
			{ "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>" },
		},
		config = function()
			require("nvim-tmux-navigation").setup({})
		end,
	},
	--Gx
	{
		"chrishrb/gx.nvim",
		keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
		cmd = { "Browse" },
		init = function()
			vim.g.netrw_nogx = 1 -- disable netrw gx
		end,
		dependencies = { "nvim-lua/plenary.nvim" }, -- Required for Neovim < 0.10.0
		config = true, -- default settings
		submodules = false, -- not needed, submodules are required only for tests

		-- you can specify also another config if you want
		-- config = function() require("gx").setup {
		--   open_browser_app = "os_specific", -- specify your browser app; default for macOS is "open", Linux "xdg-open" and Windows "powershell.exe"
		--   open_browser_args = { "--background" }, -- specify any arguments, such as --background for macOS' "open".
		--   handlers = {
		--     plugin = true, -- open plugin links in lua (e.g. packer, lazy, ..)
		--     github = true, -- open github issues
		--     brewfile = true, -- open Homebrew formulaes and casks
		--     package_json = true, -- open dependencies from package.json
		--     search = true, -- search the web/selection on the web if nothing else is found
		--     go = true, -- open pkg.go.dev from an import statement (uses treesitter)
		--     jira = { -- custom handler to open Jira tickets (these have higher precedence than builtin handlers)
		--       name = "jira", -- set name of handler
		--       handle = function(mode, line, _)
		--         local ticket = require("gx.helper").find(line, mode, "(%u+-%d+)")
		--         if ticket and #ticket < 20 then
		--           return "http://jira.company.com/browse/" .. ticket
		--         end
		--       end,
		--     },
		--     rust = { -- custom handler to open rust's cargo packages
		--       name = "rust", -- set name of handler
		--       filetype = { "toml" }, -- you can also set the required filetype for this handler
		--       filename = "Cargo.toml", -- or the necessary filename
		--       handle = function(mode, line, _)
		--         local crate = require("gx.helper").find(line, mode, "(%w+)%s-=%s")
		--
		--         if crate then
		--           return "https://crates.io/crates/" .. crate
		--         end
		--       end,
		--     },
		--   },
		--   handler_options = {
		--     search_engine = "google", -- you can select between google, bing, duckduckgo, ecosia and yandex
		--     search_engine = "https://search.brave.com/search?q=", -- or you can pass in a custom search engine
		--     select_for_search = false, -- if your cursor is e.g. on a link, the pattern for the link AND for the word will always match. This disables this behaviour for default so that the link is opened without the select option for the word AND link
		--
		--     git_remotes = { "upstream", "origin" }, -- list of git remotes to search for git issue linking, in priority
		--     git_remotes = function(fname) -- you can also pass in a function
		--         if fname:match("myproject") then
		--             return { "mygit" }
		--         end
		--         return { "upstream", "origin" }
		--     end,
		--
		--     git_remote_push = false, -- use the push url for git issue linking,
		--     git_remote_push = function(fname) -- you can also pass in a function
		--       return fname:match("myproject")
		--     end,
		--   },
		-- } end,
	},
	--Profiling:Startuptime
	{
		"dstein64/vim-startuptime",
		lazy = true,
		cmd = { "StartupTime" },
	},
	--MovementTrain: Hardtime
	{
		"m4xshen/hardtime.nvim",
		event = { "BufReadPost", "BufNewFile" },
		keys = { { "<leader>lht", "<cmd>Hardtime toggle" } },
		dependencies = { "MunifTanjim/nui.nvim" },
		opts = {},
	},
	--UndoHighlight
	{
		"tzachar/highlight-undo.nvim",
		event = { "BufReadPost" },
		opts = {
			hlgroup = "IncSearch",
			duration = 300,
			pattern = { "*" },
			ignored_filetypes = { "neo-tree", "fugitive", "TelescopePrompt", "mason", "lazy" },
		},
	},
	--Disocrd
	{
		"vyfor/cord.nvim",
		build = ":Cord update",
		opts = {
			display = {
				theme = "atom",
				flavor = "dark",
			},
		},
	},
}
