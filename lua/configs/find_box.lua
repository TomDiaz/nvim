-- Búsqueda dentro del archivo estilo VS Code (Ctrl+F)
-- Cajita flotante arriba a la derecha de la ventana actual:
--   escribir      -> resalta y salta al resultado más cercano (en vivo)
--   Enter / ↓     -> siguiente resultado
--   Shift+Enter / ↑ -> resultado anterior
--   Esc           -> cerrar (el cursor queda en el resultado; n/N siguen funcionando)
--   Ctrl+A        -> seleccionar todos: lo que escribas reemplaza todos en vivo
--                    (Enter/Esc terminan, `u` deshace todo de una vez)
-- Sin distinguir mayúsculas y texto literal (sin regex), como VS Code por defecto.

local M = {}

local ns = vim.api.nvim_create_namespace "find_box"
local ns_cur = vim.api.nvim_create_namespace "find_box_current"
local state = {}

-- resalta el resultado actual en el código (el cursor de esa ventana no se ve
-- mientras estás escribiendo en la cajita) y centra la vista en él
local function mark_current()
  local src_buf = vim.api.nvim_win_get_buf(state.src_win)
  vim.api.nvim_buf_clear_namespace(src_buf, ns_cur, 0, -1)
  local text = vim.api.nvim_buf_get_lines(state.buf, 0, 1, false)[1] or ""
  if text == "" then
    return
  end
  local pos = vim.api.nvim_win_get_cursor(state.src_win)
  local line = vim.api.nvim_buf_get_lines(src_buf, pos[1] - 1, pos[1], false)[1] or ""
  pcall(vim.api.nvim_buf_set_extmark, src_buf, ns_cur, pos[1] - 1, pos[2], {
    end_col = math.min(pos[2] + #text, #line),
    hl_group = "CurSearch",
    priority = 5000,
  })
  vim.api.nvim_win_call(state.src_win, function()
    vim.cmd "normal! zv"
    local top, bot = vim.fn.line "w0", vim.fn.line "w$"
    if pos[1] < top or pos[1] > bot then
      vim.cmd "normal! zz"
    end
  end)
  vim.cmd "redraw"
end

local function valid_src()
  return state.src_win and vim.api.nvim_win_is_valid(state.src_win)
end

local function get_text()
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return ""
  end
  return vim.api.nvim_buf_get_lines(state.buf, 0, 1, false)[1] or ""
end

local function to_pattern(text)
  return "\\V\\c" .. text:gsub("\\", "\\\\")
end

local function set_counter(msg, hl)
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return
  end
  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(state.buf, ns, 0, 0, {
    virt_text = { { msg, hl } },
    virt_text_pos = "right_align",
  })
end

local function refresh_counter(pat)
  local count = vim.api.nvim_win_call(state.src_win, function()
    return vim.fn.searchcount { pattern = pat, recompute = 1, maxcount = 99999, timeout = 200 }
  end)
  if not count.total or count.total == 0 then
    set_counter("Sin resultados", "DiagnosticError")
  else
    set_counter(string.format("%d de %d", count.current, count.total), "Comment")
  end
  mark_current()
end

-- se llama en cada tecla: busca desde donde estaba el cursor al abrir
local function update()
  if not valid_src() then
    return
  end
  local text = get_text()
  if text == "" then
    vim.v.hlsearch = 0
    vim.api.nvim_win_set_cursor(state.src_win, state.origin)
    set_counter("", "Comment")
    mark_current()
    return
  end
  local pat = to_pattern(text)
  vim.fn.setreg("/", pat)
  vim.v.hlsearch = 1
  vim.api.nvim_win_call(state.src_win, function()
    vim.api.nvim_win_set_cursor(0, state.origin)
    vim.fn.search(pat, "cw")
  end)
  refresh_counter(pat)
end

local function jump(forward)
  if state.mode == "replace" or not valid_src() or get_text() == "" then
    return
  end
  local pat = to_pattern(get_text())
  vim.api.nvim_win_call(state.src_win, function()
    vim.fn.search(pat, forward and "w" or "bw")
  end)
  -- el próximo cambio de texto busca desde el resultado actual
  state.origin = vim.api.nvim_win_get_cursor(state.src_win)
  refresh_counter(pat)
end

-- Ctrl+A: selecciona todos los resultados. A partir de ahí, lo que escribas en
-- la cajita reemplaza todos a la vez, en vivo. Enter o Esc terminan. Un solo
-- `u` deshace toda la edición.
local ns_sel = vim.api.nvim_create_namespace "find_box_selection"

local function select_all()
  if state.mode == "replace" or not valid_src() then
    return
  end
  local text = get_text()
  if text == "" then
    return
  end
  local src_buf = vim.api.nvim_win_get_buf(state.src_win)
  if not vim.bo[src_buf].modifiable then
    vim.notify("Este buffer no se puede modificar", vim.log.levels.WARN)
    return
  end
  local ok, matches = pcall(vim.fn.matchbufline, src_buf, to_pattern(text), 1, "$")
  if not ok or #matches == 0 then
    return
  end

  state.marks = {}
  for _, m in ipairs(matches) do
    -- el rango se estira con lo que se escribe: el inicio queda fijo a la
    -- izquierda y el final se corre a la derecha
    local id = vim.api.nvim_buf_set_extmark(src_buf, ns_sel, m.lnum - 1, m.byteidx, {
      end_row = m.lnum - 1,
      end_col = m.byteidx + #m.text,
      right_gravity = false,
      end_right_gravity = true,
      hl_group = "Visual",
      priority = 6000,
    })
    table.insert(state.marks, id)
  end
  state.mode = "replace"
  state.src_buf = src_buf
  state.edits = 0

  vim.v.hlsearch = 0
  vim.api.nvim_buf_clear_namespace(src_buf, ns_cur, 0, -1)
  vim.api.nvim_win_set_config(state.win, { title = "  Editar todos ", title_pos = "left" })
  set_counter(#matches .. " seleccionados", "DiagnosticWarn")
  vim.cmd "redraw"
end

-- se llama en cada tecla en modo "Editar todos"
local function apply_replace()
  if not vim.api.nvim_buf_is_valid(state.src_buf) then
    return
  end
  local text = get_text()
  vim.api.nvim_buf_call(state.src_buf, function()
    -- juntar todo en un solo paso de undo
    if state.edits > 0 then
      pcall(vim.cmd, "undojoin")
    end
    for i = #state.marks, 1, -1 do
      local p = vim.api.nvim_buf_get_extmark_by_id(state.src_buf, ns_sel, state.marks[i], { details = true })
      if p[1] then
        vim.api.nvim_buf_set_text(state.src_buf, p[1], p[2], p[3].end_row, p[3].end_col, { text })
      end
    end
  end)
  state.edits = state.edits + 1
  set_counter(#state.marks .. " editados", "DiagnosticOk")
  vim.cmd "redraw"
end

local function on_change()
  if state.mode == "replace" then
    apply_replace()
  else
    update()
  end
end

function M.close()
  if state.closing then
    return
  end
  state.closing = true
  local text = get_text()
  if text ~= "" and state.mode ~= "replace" then
    vim.fn.histadd("/", to_pattern(text))
  end
  vim.cmd "stopinsert"
  if valid_src() then
    vim.api.nvim_buf_clear_namespace(vim.api.nvim_win_get_buf(state.src_win), ns_cur, 0, -1)
  end
  if state.src_buf and vim.api.nvim_buf_is_valid(state.src_buf) then
    vim.api.nvim_buf_clear_namespace(state.src_buf, ns_sel, 0, -1)
  end
  pcall(function()
    require("nvim-autopairs").enable()
  end)
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if valid_src() then
    vim.api.nvim_set_current_win(state.src_win)
  end
  state = {}
end

function M.open(initial)
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
    return
  end

  local src_win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  local width = math.min(45, math.max(20, vim.api.nvim_win_get_width(src_win) - 4))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "win",
    win = src_win,
    anchor = "NE",
    row = 0,
    col = vim.api.nvim_win_get_width(src_win),
    width = width,
    height = 1,
    style = "minimal",
    border = "rounded",
    title = "  Buscar ",
    title_pos = "left",
    zindex = 200,
  })
  vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"

  state = {
    src_win = src_win,
    win = win,
    buf = buf,
    origin = vim.api.nvim_win_get_cursor(src_win),
  }

  local text = initial or ""
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

  local group = vim.api.nvim_create_augroup("find_box", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
    group = group,
    buffer = buf,
    callback = on_change,
  })
  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(M.close)
    end,
  })

  -- sin autocompletado ni autopairs en la cajita: los dos registran <CR>
  -- (y cmp también las flechas) al entrar en insert y pisaban estas teclas
  vim.b[buf].cmp_enabled = false
  pcall(function()
    require("cmp").setup.buffer { enabled = false }
  end)
  pcall(function()
    require("nvim-autopairs").disable()
  end)

  local function bmap(modes, lhs, fn)
    vim.keymap.set(modes, lhs, fn, { buffer = buf, nowait = true, silent = true })
  end
  local function set_keys()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    bmap({ "i", "n" }, "<CR>", function()
      if state.mode == "replace" then
        M.close()
      else
        jump(true)
      end
    end)
    bmap({ "i", "n" }, "<C-a>", select_all)
    bmap({ "i", "n" }, "<M-CR>", select_all)
    bmap({ "i", "n" }, "<Down>", function() jump(true) end)
    bmap({ "i", "n" }, "<S-CR>", function() jump(false) end)
    bmap({ "i", "n" }, "<Up>", function() jump(false) end)
    bmap({ "i", "n" }, "<C-f>", function() end)
    bmap("i", "<Esc>", M.close)
    bmap("n", "<Esc>", M.close)
    bmap("n", "q", M.close)
  end
  set_keys()
  -- volver a ponerlas después de que otros plugins mapeen en InsertEnter
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    buffer = buf,
    callback = function()
      vim.schedule(set_keys)
    end,
  })

  vim.cmd "startinsert!"
  if text ~= "" then
    update()
  end
end

-- Ctrl+F: en visual arranca con el texto seleccionado; si no, vacío
function M.from_mode()
  local mode = vim.fn.mode()
  local initial
  if mode == "v" or mode == "V" or mode == "\22" then
    local ok, region = pcall(vim.fn.getregion, vim.fn.getpos "v", vim.fn.getpos ".", { type = mode })
    if ok and region[1] then
      initial = region[1]
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  else
    if mode == "i" then
      vim.cmd "stopinsert"
    end
  end
  M.open(initial)
end

return M
