return {
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
}
