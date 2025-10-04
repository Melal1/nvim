return {
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
						name = {"Dap"},
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
}
