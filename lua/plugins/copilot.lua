return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  keys = {
    { "<leader>tc", "<cmd>Copilot enable | Copilot toggle<CR>", mode = "n", desc = "Toggle Copilot" },
    { "<leader><leader>tc", "<cmd>Copilot disable<CR>", mode = "n", desc = "Toggle Copilot" },
  },
  opts = {
    suggestion = { enabled = false },
    panel = { enabled = false },
    filetypes = {
      markdown = true,
      help = true,
    },
  },
}

