return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	init = function()
		require("nvim-treesitter-textobjects").setup({
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
		})

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
		vim.keymap.set({ "x", "o" }, "ai", function()
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
		vim.keymap.set({"o" , "x"}, "aa", function()
			require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer")
		end)
		vim.keymap.set({"o" , "x"}, "ia", function()
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
			require("nvim-treesitter-textobjects.move").goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
		end)
		vim.keymap.set({ "n", "x", "o" }, "[l", function()
			require("nvim-treesitter-textobjects.move").goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
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

		-- Repeat
		  local ts_repeat_move = require "nvim-treesitter-textobjects.repeatable_move"
		vim.keymap.set({ "n", "x", "o" }, "<leader>;", ts_repeat_move.repeat_last_move)
		vim.keymap.set({ "n", "x", "o" }, "<leader>,", ts_repeat_move.repeat_last_move_opposite)
	end,
}
