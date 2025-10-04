return {
	"echasnovski/mini.ai",
	version = false,
	event = "InsertEnter",
	config = function()
		require("mini.ai").setup()
	end,
}
