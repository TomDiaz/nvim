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
	theme = "tokyonight",
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
		-- pestañas (tabufline) con acrílico: sin fondo, se ve el tinte de Windows Terminal.
		-- base46 ya limpia TbFill/TbBuf* con transparency; acá se completan los botones y
		-- tabs, y la pestaña activa se distingue por color + subrayado en vez de fondo
		TbBufOn = { fg = "white", bg = "NONE", bold = true, underline = true, sp = "blue" },
		TbBufOnModified = { fg = "green", bg = "NONE", underline = true, sp = "blue" },
		TbBufOnClose = { fg = "red", bg = "NONE", underline = true, sp = "blue" },
		TbTabOn = { fg = "red", bg = "NONE" },
		TbTabOff = { fg = "white", bg = "NONE" },
		TbTabNewBtn = { fg = "white", bg = "NONE" },
		TbTabCloseBtn = { fg = "nord_blue", bg = "NONE" },
		TBTabTitle = { fg = "blue", bg = "NONE" },
		TbThemeToggleBtn = { fg = "white", bg = "NONE" },
		TbCloseAllBufsBtn = { fg = "red", bg = "NONE" },
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
-- barra de abajo (statusline)
M.ui = {
	statusline = {
		-- "default" | "minimal" | "vscode" | "vscode_colored"
		theme = "vscode_colored",
		-- "default" | "round" | "block" | "arrow" (solo aplica a default y minimal)
		separator_style = "round",
	},
	-- tabufline = {
	-- 	lazyload = false,
	-- },
}

return M
