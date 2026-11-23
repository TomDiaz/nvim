-- Buscador de miembros del archivo (Telescope lsp_document_symbols) con los mismos cambios
-- que el panel de aerial: firma coloreada (parámetros, tipo, puntuación) y nombres largos
-- que bajan de línea en vez de cortarse con "…"
-- (usado por <leader>fs y por "/" dentro del panel de aerial)
local M = {}

local SYMBOLS = { "class", "constructor", "field", "property", "method", "interface", "enum" }

local KIND_WIDTH = #"constructor"

local kind_hl = {
  Class = "TelescopeResultsClass",
  Interface = "TelescopeResultsClass",
  Enum = "TelescopeResultsClass",
  Struct = "TelescopeResultsStruct",
  Constructor = "TelescopeResultsMethod",
  Method = "TelescopeResultsMethod",
  Function = "TelescopeResultsFunction",
  Field = "TelescopeResultsField",
  Property = "TelescopeResultsField",
}

-- roslyn manda "Nombre(TipoParam, ...) : TipoRetorno" o "_campo : Tipo".
-- Devuelve los highlights de telescope ({ { inicio, fin }, grupo }, columnas en bytes desde 0)
-- de la firma que empieza en la columna `offset` de la línea mostrada
local function signature_highlights(name, offset)
  local hls = {}
  local function add(s, e, group)
    table.insert(hls, { { offset + s - 1, offset + e }, group })
  end

  local after = 1
  local open, close = name:find "%b()"
  if open then
    add(open, open, "AerialSignaturePunct")
    if close > open + 1 then add(open + 1, close - 1, "AerialParams") end
    add(close, close, "AerialSignaturePunct")
    after = close + 1
  end

  local colon = name:find(" : ", after, true)
  if colon then
    add(colon + 1, colon + 1, "AerialSignaturePunct")
    if colon + 3 <= #name then add(colon + 3, #name, "AerialReturnType") end
  end
  return hls
end

local function entry_maker(opts)
  local base = require("telescope.make_entry").gen_from_lsp_symbols(opts)
  -- el nombre va en la última columna (sin ancho fijo) para que no se trunque y wrap lo parta
  local displayer = require("telescope.pickers.entry_display").create {
    separator = " ",
    items = { { width = KIND_WIDTH }, { remaining = true } },
  }

  local function display(entry)
    local kind = entry.symbol_type or ""
    local name = entry.symbol_name or ""
    local text, hls = displayer { { kind:lower(), kind_hl[kind] or "TelescopeResultsComment" }, name }
    local name_col = (text:find(name, KIND_WIDTH + 1, true) or (KIND_WIDTH + 2)) - 1
    vim.list_extend(hls, signature_highlights(name, name_col))
    return text, hls
  end

  return function(item)
    local entry = base(item)
    if entry then entry.display = display end
    return entry
  end
end

function M.pick()
  -- AerialParams & cía. los define el init de aerial, que lazy corre al arrancar
  local opts = {
    symbols = SYMBOLS,
    path_display = "hidden",
    wrap_results = true,
  }
  opts.entry_maker = entry_maker(opts)
  require("telescope.builtin").lsp_document_symbols(opts)
end

return M
