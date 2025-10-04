return {
  --TODO:
  "folke/todo-comments.nvim",
  keys = { { "<leader>ltd" }},
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    highlight = {
      comments_only = false,
    },
  },
}
