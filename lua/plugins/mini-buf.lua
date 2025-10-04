return {
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
}
