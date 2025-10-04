return {
  {
    "kylechui/nvim-surround",
    event = "BufReadPost",
    enabled = false,
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end,
  },
  {
    "echasnovski/mini.surround",
    version = false,
    event = "InsertEnter",
    config = function()
      require("mini.surround").setup()
    end,
  },
}
