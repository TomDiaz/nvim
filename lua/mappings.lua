require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- :WikiDoc — crea una nota de Obsidian para el archivo actual en ~/Desktop/wiki/<proyecto>/
-- y la abre en Obsidian (lua/configs/wiki_doc.lua)
vim.api.nvim_create_user_command("WikiDoc", function()
  require("configs.wiki_doc").create()
end, { desc = "Documentar el archivo actual en la wiki de Obsidian" })
map("n", "<leader>wd", "<cmd>WikiDoc<cr>", { desc = "Wiki: documentar archivo actual" })

-- :WikiDocAll [ext ...] — documenta todo el proyecto usando el LSP (por defecto,
-- los archivos con la extensión del actual). Arma el grafo de arquitectura en Obsidian
vim.api.nvim_create_user_command("WikiDocAll", function(opts)
  require("configs.wiki_doc").create_all(opts.fargs)
end, { nargs = "*", desc = "Documentar todo el proyecto en la wiki de Obsidian" })
map("n", "<leader>wD", "<cmd>WikiDocAll<cr>", { desc = "Wiki: documentar todo el proyecto" })

-- Ctrl+F: buscar dentro del archivo estilo VS Code (lua/configs/find_box.lua)
map({ "n", "i", "v" }, "<C-f>", function()
  require("configs.find_box").from_mode()
end, { desc = "Buscar en el archivo (estilo VS Code)" })

-- nvim-tree (config de cpea2506/nvim): <leader>e abre/cierra el explorador.
-- Se redefine aqui porque nvchad.mappings lo pisa con NvimTreeFocus.
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Open Explorer" })
