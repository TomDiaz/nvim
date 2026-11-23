---
tags: [nvim, nvchad, errores, debug, claude]
fecha: 2026-11-23
---

# Registro de errores en errors.log

Todos los errores de Neovim (los de Lua, los de Vim y los avisos de plugins o del LSP) se guardan en un archivo `errors.log` dentro de la config. Hay comandos para verlo, copiar el último error o mandárselo a Claude para que lo analice.

Sirve para los errores que aparecen un instante y desaparecen, o que pasan en una situación difícil de repetir (por ejemplo, cerrar un archivo con el panel de aerial abierto, ver [[Outline de clases con aerial]]).

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11 · `coder/claudecode.nvim` (ver [[Claude Code en NvChad]])

---

## Comandos

| Comando | Para qué |
|---|---|
| `:ErrorLog` | Abrir el log en un split, posicionado al final |
| `:ErrorLogNotepad` | Abrir el log en el Bloc de notas |
| `:ErrorLogCopy` | Copiar el **último error** al portapapeles (y al registro de nvim, para pegarlo con `p`) |
| `:ErrorLogClaude` | Mandar el último error al **panel de Claude** con un pedido de análisis |
| `:ErrorLogClear` | Vaciar el log |

**Archivo:** `C:\Users\diazt\AppData\Local\nvim\errors.log`

> [!tip] Flujo para arreglar un error
> 1. Pasa el error.
> 2. `:ErrorLogClaude`: se abre el panel de Claude con el error ya escrito.
> 3. Agregá contexto si hace falta (qué estabas haciendo) y pulsá `Enter`.

---

## Qué se registra

- **Errores de Lua y de Vim**: `E5108`, `Error executing lua callback`, errores de mapeos, autocmds, `vim.schedule`… Incluye el *stack traceback* completo.
- **`vim.notify` con nivel WARN o ERROR**: es lo que usan los plugins y el LSP para avisar.

Cada entrada tiene esta forma:

```
[2026-11-23 01:08:46] ERROR (errmsg)
  modo=n buf=2 ft=nvdash archivo=[sin nombre]
  ventanas: aerial | cs:Program.cs
  E5108: Lua: ...: mensaje del error
  stack traceback:
  	...
```

- **Fuente**: `errmsg` (error de Vim/Lua) o `notify: <título>` (aviso de un plugin).
- **Contexto**: modo, buffer y archivo activos, y qué hay en cada ventana de la pestaña (`filetype:archivo`). Eso ayuda a saber en qué situación pasó.

---

## Cómo funciona

Neovim no tiene un evento "ocurrió un error", así que se capturan por dos lados:

1. **`vim.notify`** se reemplaza por una función que primero escribe en el log (si el nivel es WARN o ERROR) y después llama al `vim.notify` original (noice, ver [[Notificaciones y cmdline con noice]]).
2. **`v:errmsg`**: Neovim guarda ahí el texto de cada error que muestra. Con el autocmd `SafeState` (se dispara cada vez que nvim queda libre, esperando una tecla) se revisa: si tiene algo, se escribe en el log y se vacía. Vaciarlo permite registrar el mismo error si se repite.

Otros detalles:

- **Se carga antes que lazy** (`init.lua`) para capturar también los errores al cargar plugins.
- **Rotación**: al pasar de 1 MB, el log se renombra a `errors.log.old` y empieza uno nuevo.
- **Errores silenciados**: `v:errmsg` también recibe errores de comandos con `silent!`, que nunca se ven en pantalla. Los conocidos se ignoran con la lista `ignore`. Por ahora solo `E216: No such group or event: FileExplorer`, que genera nvim-tree al desactivar netrw al arrancar. Si aparece otro error "fantasma" en el log, se agrega a esa lista.
- **`:ErrorLogCopy` y `:ErrorLogClaude`** leen el archivo (sirven después de reiniciar nvim) y toman la última entrada **ERROR**, saltando los WARN.
- **`.gitignore`**: `errors.log` y `errors.log.old` no se suben al repo.

### `:ErrorLogClaude`

Arma este mensaje con el último error:

```
Analizá este error de mi configuración de Neovim (NvChad + lazy.nvim, Windows) y dame soluciones.
La config está en C:\Users\diazt\AppData\Local\nvim (registro completo en ...\errors.log).
Explicá la causa y proponé el cambio concreto en los archivos de la config.

<error completo>
```

- Si el panel de Claude **ya está abierto**, lo escribe ahí y pone el foco en el panel.
- Si **no está abierto**, lo abre y espera a que Claude muestre su barra de entrada (hasta 20 s) antes de escribir.
- **No lo envía solo**: queda escrito para que agregues contexto y lo mandes con `Enter`.
- También lo copia al portapapeles: si el panel falla, avisa y se puede pegar con `Ctrl + V` en cualquier otro lado.

Usa `send_to_terminal` de `claudecode.terminal`, que escribe en la terminal del panel como si se tecleara. Los textos de varias líneas van como *bracketed paste*, así los saltos de línea no envían el mensaje antes de tiempo.

> [!warning] Detección de "Claude listo"
> Para saber si Claude terminó de arrancar se busca en la terminal el texto `for shortcuts` o el borde `─` de la barra de entrada. Si una versión nueva de Claude Code cambia eso, se usa el tiempo límite (20 s). Si el mensaje no aparece, igual está en el portapapeles.

### `:ErrorLogNotepad`: por qué pasa por `cmd.exe /c start`

`vim.fn.jobstart` crea los procesos con la **ventana oculta** (libuv lo hace así en Windows). Lanzar `notepad.exe` directo deja un Notepad corriendo pero invisible. `cmd.exe /c start "" notepad.exe archivo` lo abre con una ventana normal. Es el mismo motivo por el que `wt_open.lua` lanza Windows Terminal a través de `cmd.exe` (ver [[Íconos de pestaña en Windows Terminal]]).

Si quedaron Notepads invisibles de antes, se cierran en PowerShell con:

```powershell
Get-Process notepad | Where-Object { $_.MainWindowTitle -eq '' } | Stop-Process
```

El Bloc de notas no se actualiza solo: si llegan errores nuevos, hay que cerrarlo y volver a abrirlo.

---

## Cambios realizados

### `init.lua`

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\init.lua`

Justo después de `vim.g.mapleader`, antes de cargar lazy:

```lua
-- log de errores en errors.log (antes de lazy, para capturar también los de carga de plugins)
require("configs.error_log").setup()
```

### `.gitignore` (nuevo)

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\.gitignore`

```
errors.log
errors.log.old
```

### `lua/configs/error_log.lua` (nuevo)

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\configs\error_log.lua`

```lua
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
```

---

## Personalización

- **Registrar también INFO**: agregar `[vim.log.levels.INFO] = "INFO"` a `level_names`.
- **Cambiar el tamaño de rotación**: `MAX_SIZE` (en bytes).
- **Enviar a Claude con Enter automático**: en `send_to_claude`, cambiar `submit = false` por `submit = true`.
- **Ignorar otro error silenciado**: agregar un fragmento de su texto a la lista `ignore`.

Ver también: [[Claude Code en NvChad]] · [[Notificaciones y cmdline con noice]] · [[Comandos y atajos de NvChad]]
