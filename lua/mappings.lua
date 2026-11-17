require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- nvim-tree (config de cpea2506/nvim): <leader>e abre/cierra el explorador.
-- Se redefine aqui porque nvchad.mappings lo pisa con NvimTreeFocus.
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Open Explorer" })
