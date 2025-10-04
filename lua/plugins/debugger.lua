return {
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
}
