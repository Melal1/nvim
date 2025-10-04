return {
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
		},
		on_open = function(win)
			vim.fn.system([[tmux set status off]])
		end,

		on_close = function()
			vim.fn.system([[tmux set status on]])
		end,
		-- callback where you can add custom code when the Zen window opens
	},
}
