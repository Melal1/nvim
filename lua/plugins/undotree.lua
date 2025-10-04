return {
  "mbbill/undotree",
  keys = {
    {
      "<leader>lut",
      "<cmd>UndotreeToggle<CR>",
      desc = "Toggle Undotree",
    },
  },
  config = function()
    vim.g.undotree_WindowLayout = 3
  end,
}

