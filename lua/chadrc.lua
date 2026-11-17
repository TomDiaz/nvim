-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

-- efecto de enfoque (invertido): la ventana activa tiene fondo sólido oscuro
-- y las inactivas quedan transparentes (se ve el acrílico).
-- En la terminal no hay alpha real por ventana, así que se mezcla el color
-- oscuro con el tinte del acrílico de Windows Terminal.
-- 0 = oscuro sólido (#121418), 1 = igual al fondo (sin efecto visible)
local focused_alpha = 0.70

local function blend(dark, bg, alpha)
	local function ch(hex, i)
		return tonumber(hex:sub(i, i + 1), 16)
	end
	local out = "#"
	for _, i in ipairs { 2, 4, 6 } do
		out = out .. string.format("%02x", math.floor(ch(dark, i) * (1 - alpha) + ch(bg, i) * alpha + 0.5))
	end
	return out
end

M.base46 = {
	theme = "gruvchad",
  transparency = true,
	hl_override = {
		Cursor = { bg = "#ff8c00", fg = "#000000" },
		-- ventana activa: fondo sólido más oscuro (pisa el bg = NONE de transparency)
		-- desactivado: tapaba la transparencia de la ventana activa y del explorador
		-- Normal = { bg = blend("#121418", "#1B1F27", focused_alpha) },
		-- nvim-tree estilo VS Code
		NvimTreeIndentMarker = { fg = "one_bg3" },
		NvimTreeRootFolder = { fg = "white", bold = true },
		NvimTreeFolderName = { fg = "white" },
		NvimTreeOpenedFolderName = { fg = "white" },
		NvimTreeEmptyFolderName = { fg = "white" },
		NvimTreeFolderArrowClosed = { fg = "light_grey" },
		NvimTreeFolderArrowOpen = { fg = "light_grey" },
		NvimTreeGitDirtyIcon = { fg = "yellow" },
		NvimTreeGitNewIcon = { fg = "green" },
		NvimTreeGitDeletedIcon = { fg = "red" },
		NvimTreeModifiedIcon = { fg = "white" },
		-- el fondo del explorador queda transparente (transparency = true) para que
		-- se vea el acrílico #1B1F27 de Windows Terminal; solo la línea seleccionada es sólida
		--NvimTreeCursorLine = { bg = "one_bg" },
		-- fondo sólido solo para el listado de archivos
		--NvimTreeNormal = { bg = "black" },
		--NvimTreeNormalNC = { bg = "black" },
		--NvimTreeEndOfBuffer = { bg = "black" },
	},
	-- grupos que ninguna integración de base46 define: van en hl_add
	-- (hl_override solo modifica grupos ya existentes y los ignora en silencio)
	hl_add = {
		-- ventanas inactivas: transparentes
		NormalNC = { bg = "NONE" },
	},
	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

-- pantalla de inicio: dibujo + nombre de la carpeta raíz en grande (lua/configs/dashboard.lua)
M.nvdash = {
	load_on_startup = true,
	header = function()
		return require("configs.dashboard").header()
	end,
	buttons = {},
}
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
