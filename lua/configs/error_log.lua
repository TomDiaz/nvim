-- Registro de errores en <config>/errors.log
-- Captura:
--   * vim.notify con nivel WARN o ERROR (plugins, LSP, etc.)
--   * errores de Vim/Lua (E5108, "Error executing lua callback", etc.): todos
--     dejan el texto en v:errmsg, que se revisa cada vez que nvim queda libre (SafeState)
-- Comandos: :ErrorLog (abre el log), :ErrorLogNotepad (lo abre en el Bloc de notas)
-- :ErrorLogCopy (copia el último error al portapapeles), :ErrorLogClaude (lo manda
-- al panel de Claude con un pedido de análisis) y :ErrorLogClear (lo vacía)
local M = {}

M.path = vim.fn.stdpath("config") .. "/errors.log"
local MAX_SIZE = 1024 * 1024 -- 1 MB: al pasarlo se renombra a errors.log.old

local level_names = { [vim.log.levels.WARN] = "WARN", [vim.log.levels.ERROR] = "ERROR" }

-- contexto del momento: buffer actual y qué hay en cada ventana
local function context()
  local ok, ctx = pcall(function()
    local buf = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    local wins = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local b = vim.api.nvim_win_get_buf(win)
      local ft = vim.bo[b].filetype
      local bname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t")
      table.insert(wins, (ft ~= "" and ft or "-") .. (bname ~= "" and (":" .. bname) or ""))
    end
    return string.format("modo=%s buf=%d ft=%s archivo=%s\n  ventanas: %s",
      vim.api.nvim_get_mode().mode, buf, vim.bo[buf].filetype,
      name ~= "" and name or "[sin nombre]", table.concat(wins, " | "))
  end)
  return ok and ctx or "(no se pudo obtener el contexto)"
end

local function rotate()
  local stat = vim.uv.fs_stat(M.path)
  if stat and stat.size > MAX_SIZE then
    os.remove(M.path .. ".old")
    os.rename(M.path, M.path .. ".old")
  end
end

---@param level string
---@param source string
---@param msg string
function M.write(level, source, msg)
  pcall(function()
    rotate()
    local f = io.open(M.path, "a")
    if not f then return end
    f:write(string.format("[%s] %s (%s)\n  %s\n  %s\n\n",
      os.date("%Y-%m-%d %H:%M:%S"), level, source, context(),
      (tostring(msg):gsub("\n", "\n  "))))
    f:close()
  end)
end

-- última entrada de nivel ERROR del log (las entradas se separan con una línea vacía;
-- dentro de una entrada las líneas van sangradas, así que nunca quedan vacías)
---@return string|nil
function M.last_error()
  local f = io.open(M.path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  local last
  for entry in (content .. "\n\n"):gmatch("(.-)\n\n") do
    if entry:match("^%[[^%]]+%] ERROR") then last = entry end
  end
  return last
end

-- prompt listo para Claude con el último error y dónde está la config
---@return string|nil
function M.claude_prompt()
  local entry = M.last_error()
  if not entry then return nil end
  local config = vim.fn.fnamemodify(vim.fn.stdpath("config"), ":p"):gsub("[\\/]$", "")
  return table.concat({
    "Analizá este error de mi configuración de Neovim (NvChad + lazy.nvim, Windows) y dame soluciones.",
    "La config está en " .. config .. " (registro completo en " .. (M.path:gsub("/", "\\")) .. ").",
    "Explicá la causa y proponé el cambio concreto en los archivos de la config.",
    "",
    "```",
    entry,
    "```",
  }, "\n")
end

-- envía el prompt al panel de Claude (claudecode.nvim); lo abre si no está corriendo.
-- No lo envía con Enter: queda escrito para que agregues contexto y lo mandes vos.
function M.send_to_claude()
  local prompt = M.claude_prompt()
  if not prompt then
    return vim.notify("No hay errores en errors.log", vim.log.levels.INFO)
  end
  vim.fn.setreg("+", prompt) -- respaldo: también queda en el portapapeles

  local ok = pcall(function() require("lazy").load({ plugins = { "claudecode.nvim" } }) end)
  local ok_term, term = pcall(require, "claudecode.terminal")
  if not (ok and ok_term) then
    return vim.notify("claudecode.nvim no disponible: el prompt quedó en el portapapeles", vim.log.levels.WARN)
  end

  local function send()
    if term.send_to_terminal(prompt, { submit = false, focus = true }) then
      vim.notify("Último error enviado al panel de Claude (Enter para mandarlo)", vim.log.levels.INFO)
    else
      vim.notify("No se pudo enviar al panel de Claude: el prompt quedó en el portapapeles", vim.log.levels.WARN)
    end
  end

  local bufnr = term.get_active_terminal_bufnr()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    term.ensure_visible()
    return send()
  end

  -- Claude no estaba corriendo: abrirlo y esperar a que muestre su prompt antes de escribir
  term.ensure_visible()
  local waited, step, timeout = 0, 250, 20000
  local function poll()
    waited = waited + step
    local b = term.get_active_terminal_bufnr()
    local ready = false
    if b and vim.api.nvim_buf_is_valid(b) then
      local text = table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), "\n")
      ready = text:find("for shortcuts", 1, true) ~= nil or text:find("─", 1, true) ~= nil
    end
    if ready then
      vim.defer_fn(send, 800) -- margen para que termine de dibujar la entrada
    elseif waited >= timeout then
      send()
    else
      vim.defer_fn(poll, step)
    end
  end
  vim.defer_fn(poll, step)
end

function M.setup()
  -- 1) vim.notify (se envuelve el que haya en cada llamada, por si un plugin lo reemplaza después)
  local orig_notify = vim.notify
  vim.notify = function(msg, level, opts)
    if level and level_names[level] then
      local title = type(opts) == "table" and opts.title or nil
      M.write(level_names[level], "notify" .. (title and (": " .. title) or ""), msg)
    end
    return orig_notify(msg, level, opts)
  end

  -- 2) errores de Vim/Lua vía v:errmsg
  -- v:errmsg también recibe errores silenciados con silent! (que nunca se ven): se ignoran los conocidos
  local ignore = {
    "E216: No such group or event: FileExplorer", -- nvim-tree al desactivar netrw
  }
  local function check_errmsg()
    local err = vim.v.errmsg
    if err ~= nil and err ~= "" then
      vim.v.errmsg = "" -- así el mismo error repetido se vuelve a registrar
      for _, pat in ipairs(ignore) do
        if err:find(pat, 1, true) then return end
      end
      M.write("ERROR", "errmsg", err)
    end
  end
  vim.api.nvim_create_autocmd({ "SafeState", "VimLeavePre" }, {
    group = vim.api.nvim_create_augroup("ErrorLog", { clear = true }),
    callback = check_errmsg,
  })

  vim.api.nvim_create_user_command("ErrorLog", function()
    vim.cmd("split " .. vim.fn.fnameescape(M.path))
    vim.cmd("normal! G")
  end, { desc = "Abrir el log de errores" })

  vim.api.nvim_create_user_command("ErrorLogNotepad", function()
    if not vim.uv.fs_stat(M.path) then
      local f = io.open(M.path, "a")
      if f then f:close() end
    end
    local path = vim.fn.fnamemodify(M.path, ":p"):gsub("/", "\\")
    -- jobstart crea los procesos con la ventana oculta (libuv): "start" abre una ventana normal
    vim.fn.jobstart({ "cmd.exe", "/c", "start", '""', "notepad.exe", '"' .. path .. '"' }, { detach = true })
  end, { desc = "Abrir el log de errores en el Bloc de notas" })

  vim.api.nvim_create_user_command("ErrorLogCopy", function()
    local entry = M.last_error()
    if not entry then
      return vim.notify("No hay errores en errors.log", vim.log.levels.INFO)
    end
    vim.fn.setreg("+", entry)
    vim.fn.setreg('"', entry) -- también en el registro por defecto, para pegar con p
    vim.notify("Último error copiado al portapapeles", vim.log.levels.INFO)
  end, { desc = "Copiar el último error del log al portapapeles" })

  vim.api.nvim_create_user_command("ErrorLogClaude", function()
    M.send_to_claude()
  end, { desc = "Enviar el último error al panel de Claude para analizarlo" })

  vim.api.nvim_create_user_command("ErrorLogClear", function()
    local f = io.open(M.path, "w")
    if f then f:close() end
    vim.notify("errors.log vaciado", vim.log.levels.INFO)
  end, { desc = "Vaciar el log de errores" })
end

return M
