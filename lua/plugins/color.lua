return {
  "uga-rosa/ccc.nvim",
  keys = {
    { "<leader>cct", "<cmd>CccHighlighterToggle<CR>", desc = "Toggle color highlighter" },
  },
  config = function()
    require("ccc").setup({
      highlighter = {
        auto_enable = false, -- Keep disabled by default to save time
        lsp = true, -- Leverage LSP for accuracy
      },
      outputs = {
        require("ccc").output.hex, -- #RRGGBB
        require("ccc").output.css_rgb, -- rgb(255, 0, 0)
        require("ccc").output.css_rgba, -- rgba(255, 0, 0, 0.5)
      },
    })

    -- Add other keybindings after the plugin is set up
    vim.api.nvim_set_keymap('n', '<leader>cp', '<cmd>CccPick<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader>cc', '<cmd>CccConvert<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('v', '<leader>cs', '<Plug>(ccc-select-color)', { noremap = true, silent = true })
  end,
}

