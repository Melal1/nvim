vim.loader.enable()
-- Disable unused bundled plugins before runtime plugin scripts are sourced.
-- Keep matchparen enabled for matching-pair highlighting.
vim.g.loaded_gzip = 1
vim.g.loaded_matchit = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_zipPlugin = 1

require("init")
