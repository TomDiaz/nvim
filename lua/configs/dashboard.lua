-- Header del dashboard (nvdash): un dibujo + el nombre de la carpeta raíz en letras grandes.
local M = {}

-- fuente de bloques de 5 filas ('#' = lleno)
local font = {
  A = { ".###.", "#...#", "#####", "#...#", "#...#" },
  B = { "####.", "#...#", "####.", "#...#", "####." },
  C = { ".####", "#....", "#....", "#....", ".####" },
  D = { "####.", "#...#", "#...#", "#...#", "####." },
  E = { "#####", "#....", "####.", "#....", "#####" },
  F = { "#####", "#....", "####.", "#....", "#...." },
  G = { ".####", "#....", "#..##", "#...#", ".####" },
  H = { "#...#", "#...#", "#####", "#...#", "#...#" },
  I = { "###", ".#.", ".#.", ".#.", "###" },
  J = { "..###", "...#.", "...#.", "#..#.", ".##.." },
  K = { "#...#", "#..#.", "###..", "#..#.", "#...#" },
  L = { "#....", "#....", "#....", "#....", "#####" },
  M = { "#...#", "##.##", "#.#.#", "#...#", "#...#" },
  N = { "#...#", "##..#", "#.#.#", "#..##", "#...#" },
  O = { ".###.", "#...#", "#...#", "#...#", ".###." },
  P = { "####.", "#...#", "####.", "#....", "#...." },
  Q = { ".###.", "#...#", "#.#.#", "#..#.", ".##.#" },
  R = { "####.", "#...#", "####.", "#..#.", "#...#" },
  S = { ".####", "#....", ".###.", "....#", "####." },
  T = { "#####", "..#..", "..#..", "..#..", "..#.." },
  U = { "#...#", "#...#", "#...#", "#...#", ".###." },
  V = { "#...#", "#...#", "#...#", ".#.#.", "..#.." },
  W = { "#...#", "#...#", "#.#.#", "##.##", "#...#" },
  X = { "#...#", ".#.#.", "..#..", ".#.#.", "#...#" },
  Y = { "#...#", ".#.#.", "..#..", "..#..", "..#.." },
  Z = { "#####", "...#.", "..#..", ".#...", "#####" },
  ["0"] = { ".###.", "#..##", "#.#.#", "##..#", ".###." },
  ["1"] = { ".#.", "##.", ".#.", ".#.", "###" },
  ["2"] = { "####.", "....#", ".###.", "#....", "#####" },
  ["3"] = { "####.", "....#", ".###.", "....#", "####." },
  ["4"] = { "#...#", "#...#", "#####", "....#", "....#" },
  ["5"] = { "#####", "#....", "####.", "....#", "####." },
  ["6"] = { ".###.", "#....", "####.", "#...#", ".###." },
  ["7"] = { "#####", "....#", "...#.", "..#..", "..#.." },
  ["8"] = { ".###.", "#...#", ".###.", "#...#", ".###." },
  ["9"] = { ".###.", "#...#", ".####", "....#", ".###." },
  ["-"] = { "....", "....", "####", "....", "...." },
  ["_"] = { "....", "....", "....", "....", "####" },
  ["."] = { ".", ".", ".", ".", "#" },
  [" "] = { "...", "...", "...", "...", "..." },
  ["?"] = { ".###.", "#...#", "..##.", ".....", "..#.." },
}

local drawing = {
  [[              ;i.]],
  [[               M$L                    .;i.]],
  [[               M$Y;                .;iii;;.]],
  [[              ;$YY$i._           .iiii;;;;;]],
  [[             .iiiYYYYYYiiiii;;;;i;iii;; ;;;]],
  [[           .;iYYYYYYiiiiiiYYYiiiiiii;;  ;;;]],
  [[        .YYYY$$$$YYYYYYYYYYYYYYYYiii;; ;;;;]],
  [[      .YYY$$$$$$YYYYYY$$$$iiiY$$$$$$$ii;;;;]],
  [[     :YYYF`,  TYYYYY$$$$$YYYYYYYi$$$$$iiiii;]],
  [[     Y$MM: \  :YYYY$$P"````"T$YYMMMMMMMMiiYY.]],
  [[  `.;$$M$$b.,dYY$$Yi; .(     .YYMMM$$$MMMMYY]],
  [[.._$MMMMM$!YYYYYYYYYi;.`"  .;iiMMM$MMMMMMMYY]],
  [[ ._$MMMP` ```""4$$$$$iiiiiiii$MMMMMMMMMMMMMY;]],
  [[  MMMM$:       :$$$$$$$MMMMMMMMMMM$$MMMMMMMYYL]],
  [[ :MMMM$$.    .;PPb$$$$MMMMMMMMMM$$$$MMMMMMiYYU:]],
  [[  iMM$$;;: ;;;;i$$$$$$$MMMMM$$$$MMMMMMMMMMYYYYY]],
  [[  `$$$$i .. ``:iiii!*"``.$$$$$$$$$MMMMMMM$YiYYY]],
  [[   :Y$$iii;;;.. ` ..;;i$$$$$$$$$MMMMMM$$YYYYiYY:]],
  [[    :$$$$$iiiiiii$$$$$$$$$$$MMMMMMMMMMYYYYiiYYYY.]],
  [[     `$$$$$$$$$$$$$$$$$$$$MMMMMMMM$YYYYYiiiYYYYYY]],
  [[      YY$$$$$$$$$$$$$$$$MMMMMMM$$YYYiiiiiiYYYYYYY]],
  [[     :YYYYYY$$$$$$$$$$$$$$$$$$YYYYYYYiiiiYYYYYYi']],
}

-- rellenar a la derecha para que el dibujo quede como un bloque y no se deforme al centrar
do
  local dw = 0
  for _, l in ipairs(drawing) do
    dw = math.max(dw, vim.api.nvim_strwidth(l))
  end
  for i, l in ipairs(drawing) do
    drawing[i] = l .. string.rep(" ", dw - vim.api.nvim_strwidth(l))
  end
end

local function big_text(str, scale)
  local fill, empty, gap = string.rep("█", scale), string.rep(" ", scale), string.rep(" ", scale)
  local rows = { "", "", "", "", "" }
  for i = 1, #str do
    local glyph = font[str:sub(i, i):upper()] or font["?"]
    for r = 1, 5 do
      local line = glyph[r]:gsub("#", fill):gsub("%.", empty)
      rows[r] = rows[r] .. (i > 1 and gap or "") .. line
    end
  end
  return rows
end

local function root_name()
  -- `nvim carpeta`: entrar a esa carpeta para que sea la raíz
  local arg = vim.fn.argv(0)
  if arg ~= "" and vim.fn.isdirectory(arg) == 1 then
    vim.cmd.cd(vim.fn.fnameescape(arg))
  end
  local cwd = vim.fn.getcwd()
  local name = vim.fn.fnamemodify(cwd, ":t")
  return name ~= "" and name or cwd
end

M.header = function()
  local name = root_name()
  local maxw = vim.api.nvim_win_get_width(0) - 14

  local title = big_text(name, 2)
  if vim.api.nvim_strwidth(title[1]) > maxw then
    title = big_text(name, 1)
  end
  if vim.api.nvim_strwidth(title[1]) > maxw then
    title = { name }
  end

  local lines = {}
  vim.list_extend(lines, drawing)
  table.insert(lines, "")
  table.insert(lines, "")
  vim.list_extend(lines, title)

  -- nvdash centra cada línea por separado: igualar anchos para que no se desalineen
  local w = 0
  for _, l in ipairs(lines) do
    w = math.max(w, vim.api.nvim_strwidth(l))
  end
  for i, l in ipairs(lines) do
    local pad = w - vim.api.nvim_strwidth(l)
    local left = math.floor(pad / 2)
    lines[i] = string.rep(" ", left) .. l .. string.rep(" ", pad - left)
  end
  return lines
end

return M
