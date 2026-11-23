-- :WikiDoc — documentar el archivo actual en una wiki de Obsidian del proyecto
--
--   1. Busca la raíz del proyecto (carpeta con .git; si no hay, la carpeta de trabajo)
--   2. Si no existe, crea ~/Desktop/wiki/<NombreProyecto>/ como bóveda de Obsidian,
--      copiando la config .obsidian de la wiki de nvim (plugins, tema, ajustes)
--   3. Crea <bóveda>/<carpeta del archivo>/<archivo sin extensión>.md con
--      referencia al archivo (si ya existe, no toca lo que escribiste)
--   4. Con el LSP llena la sección automática (<!-- wikidoc:auto --> … ): Hereda de,
--      Implementa, Implementado por, Usa, Usado por y Miembros, con [[links]] entre
--      notas para que el Graph View de Obsidian muestre la arquitectura
--      (consultas en lua/configs/wiki_doc_lsp.lua)
--   5. Lo abre en Obsidian. Si la bóveda es nueva hay que registrarla en Obsidian,
--      y eso solo se puede hacer con Obsidian cerrado: pregunta antes de cerrarlo.
--
-- :WikiDocAll [ext ...] hace lo mismo para todos los archivos del proyecto.

local M = {}

local uv = vim.uv or vim.loop
local is_win = vim.fn.has "win32" == 1

-- config de Obsidian que se copia a cada wiki nueva
M.template = vim.fn.stdpath "config" .. "/wiki/Configsnvim/.obsidian"
-- archivos de la plantilla que NO se copian (estado de ventanas de esa bóveda)
M.skip = { "workspace.json", "workspace-mobile.json" }

-- violeta del tema actual (base46), o uno fijo si no se puede leer
local function violet()
  local ok, colors = pcall(function()
    return require("base46").get_theme_tb "base_30"
  end)
  return ok and colors and colors.purple or "#bb9af7"
end

-- los avisos informativos (wiki creada, nota creada…) salen en violeta usando
-- un nivel propio "WIKI" de nvim-notify (grupos NotifyWIKI*). Advertencias y
-- errores siguen con sus colores normales.
-- devuelve el registro de la notificación; pasándolo en `replace` se actualiza
-- la misma (para mostrar progreso sin llenar la pantalla de avisos)
local function notify(msg, level, replace)
  level = level or vim.log.levels.INFO
  if level == vim.log.levels.INFO then
    local ok, nvim_notify = pcall(require, "notify")
    if ok then
      local c = violet()
      vim.api.nvim_set_hl(0, "NotifyWIKIBorder", { fg = c })
      vim.api.nvim_set_hl(0, "NotifyWIKIIcon", { fg = c })
      vim.api.nvim_set_hl(0, "NotifyWIKITitle", { fg = c, bold = true })
      vim.api.nvim_set_hl(0, "NotifyWIKIBody", { link = "NotifyINFOBody" })
      local okr, rec = pcall(nvim_notify, msg, "WIKI", { title = "WikiDoc", icon = "󰠮", replace = replace })
      if not okr then
        rec = nvim_notify(msg, "WIKI", { title = "WikiDoc", icon = "󰠮" })
      end
      return rec
    end
  end
  vim.notify(msg, level, { title = "WikiDoc" })
end

local function norm(p)
  p = vim.fs.normalize(p)
  return is_win and p:lower() or p
end

local function to_os(p)
  return is_win and (p:gsub("/", "\\")) or p
end

local function exists(p)
  return uv.fs_stat(p) ~= nil
end

local function urlencode(s, keep)
  return (s:gsub("[^%w%-%._~/" .. (keep or "") .. "]", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

---------------------------------------------------------------------------
-- Obsidian: registro de bóvedas (%APPDATA%/obsidian/obsidian.json)
---------------------------------------------------------------------------

local function obsidian_json()
  local base = is_win and os.getenv "APPDATA" or (vim.fn.has "mac" == 1 and vim.fn.expand "~/Library/Application Support" or vim.fn.expand "~/.config")
  return vim.fs.normalize(base .. "/obsidian/obsidian.json")
end

-- devuelve la tabla, o nil + error si el archivo existe pero no se puede leer
-- (en ese caso NUNCA se escribe, para no perder la lista de bóvedas)
local function read_registry()
  local f = io.open(obsidian_json(), "r")
  if not f then
    return {}
  end
  local raw = f:read "*a"
  f:close()
  if raw:match "^%s*$" then
    return {}
  end
  local ok, data = pcall(vim.json.decode, raw, { luanil = { object = true, array = true } })
  if not ok or type(data) ~= "table" then
    return nil, "no se pudo leer " .. to_os(obsidian_json()) .. ": " .. tostring(data)
  end
  return data
end

local function is_registered(vault)
  local data = read_registry() or {}
  for _, v in pairs(data.vaults or {}) do
    if v.path and norm(v.path) == norm(vault) then
      return true
    end
  end
  return false
end

-- agrega la bóveda insertando solo su entrada en el texto del archivo: el resto
-- de obsidian.json queda byte por byte igual (no se re-codifica el JSON entero)
local function register(vault)
  local data, err = read_registry()
  if not data then
    return false, err
  end
  local vaults = data.vaults or {}
  local id
  repeat
    id = string.format("%08x%08x", math.random(0, 0x7fffffff), math.random(0, 0x7fffffff))
  until not vaults[id]
  local entry = string.format('"%s":%s', id, vim.json.encode { path = to_os(vault), ts = os.time() * 1000 })

  local path = obsidian_json()
  local raw = ""
  local f = io.open(path, "r")
  if f then
    raw = f:read "*a"
    f:close()
  end

  local new
  if raw:match "^%s*$" then
    new = "{\"vaults\":{" .. entry .. "}}"
  else
    local s, e = raw:find('"vaults"%s*:%s*{')
    if s then
      local empty = raw:sub(e + 1):match "^%s*}" ~= nil
      new = raw:sub(1, e) .. entry .. (empty and "" or ",") .. raw:sub(e + 1)
    else
      local b = raw:find "{"
      local empty = raw:sub(b + 1):match "^%s*}" ~= nil
      new = raw:sub(1, b) .. '"vaults":{' .. entry .. "}" .. (empty and "" or ",") .. raw:sub(b + 1)
    end
  end
  -- control: el resultado tiene que seguir siendo JSON válido y tener la bóveda
  local ok, check = pcall(vim.json.decode, new)
  if not ok or type(check) ~= "table" or not (check.vaults and check.vaults[id]) then
    return false, "el JSON resultante no es válido"
  end

  vim.fn.mkdir(vim.fs.dirname(path), "p")
  -- copia de seguridad antes de escribir
  if raw ~= "" then
    uv.fs_copyfile(path, path .. ".bak")
  end
  local out, ferr = io.open(path, "w")
  if not out then
    return false, ferr
  end
  out:write(new)
  out:close()
  return true
end

local function obsidian_running()
  if not is_win then
    return vim.fn.system({ "pgrep", "-x", "obsidian" }) ~= ""
  end
  local out = vim.fn.system { "tasklist", "/FI", "IMAGENAME eq Obsidian.exe", "/NH" }
  return out:lower():find("obsidian.exe", 1, true) ~= nil
end

-- cierra Obsidian (cierre normal, sin /F) y espera a que termine
local function close_obsidian()
  if is_win then
    vim.fn.system { "taskkill", "/IM", "Obsidian.exe" }
  else
    vim.fn.system { "pkill", "-x", "obsidian" }
  end
  return vim.wait(10000, function()
    return not obsidian_running()
  end, 300)
end

local function open_uri(md)
  vim.ui.open("obsidian://open?path=" .. urlencode(to_os(md)))
end

-- abre el .md en Obsidian, registrando la bóveda si hace falta
local function open_in_obsidian(vault, md)
  if is_registered(vault) then
    return open_uri(md)
  end
  if obsidian_running() then
    local choice = vim.fn.confirm(
      "La bóveda es nueva y hay que registrarla en Obsidian.\nPara eso Obsidian tiene que cerrarse y volver a abrirse.\n¿Cerrarlo ahora?",
      "&Sí\n&No",
      1
    )
    if choice ~= 1 then
      notify(
        "No se abrió en Obsidian. Abrila a mano con 'Abrir carpeta como bóveda':\n" .. to_os(vault),
        vim.log.levels.WARN
      )
      return
    end
    if not close_obsidian() then
      notify("Obsidian no se cerró. Cerralo a mano y volvé a correr :WikiDoc", vim.log.levels.ERROR)
      return
    end
  end
  local ok, err = register(vault)
  if not ok then
    notify("No se pudo registrar la bóveda en Obsidian (" .. tostring(err) .. ").\nAbrila a mano con 'Abrir carpeta como bóveda':\n" .. to_os(vault), vim.log.levels.ERROR)
    return
  end
  open_uri(md)
end

---------------------------------------------------------------------------
-- Bóveda y nota
---------------------------------------------------------------------------

-- carpeta donde se crean las wikis: ~/Desktop/wiki (C:\Users\<usuario>\Desktop\wiki)
-- Ruta relativa al usuario, así funciona igual en cualquier PC. Es la carpeta
-- local, no la del Escritorio redirigido a OneDrive. Se crea si no existe.
-- Se puede cambiar con: require("configs.wiki_doc").base = vim.fn.expand "~/otra"
M.base = nil

local function wiki_base()
  return vim.fs.normalize(M.base or vim.fn.expand "~/Desktop/wiki")
end

local function project_root(file)
  return vim.fs.root(file, ".git") or vim.fs.normalize(vim.fn.getcwd())
end

-- copia la plantilla .obsidian a la bóveda nueva (async: son ~160 MB)
local function create_vault(vault, done)
  if not exists(M.template) then
    notify("No encuentro la plantilla de Obsidian:\n" .. to_os(M.template), vim.log.levels.ERROR)
    return
  end
  local dest = vault .. "/.obsidian"
  vim.fn.mkdir(dest, "p")
  notify("Creando la wiki y copiando la config de Obsidian…")

  local cmd
  if is_win then
    cmd = { "robocopy", to_os(M.template), to_os(dest), "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NP", "/XF" }
    vim.list_extend(cmd, M.skip)
  else
    cmd = { "rsync", "-a" }
    for _, s in ipairs(M.skip) do
      vim.list_extend(cmd, { "--exclude", s })
    end
    vim.list_extend(cmd, { M.template .. "/", dest .. "/" })
  end

  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      -- robocopy: 0-7 = bien, 8+ = error
      local ok = is_win and res.code < 8 or (not is_win and res.code == 0)
      if not ok then
        notify("Falló la copia de .obsidian:\n" .. (res.stdout or "") .. (res.stderr or ""), vim.log.levels.ERROR)
        return
      end
      done()
    end)
  end)
end

-- "Usuario.cs" -> "Usuario", "cs"  ·  ".gitignore" -> ".gitignore", nil
local function split_name(name)
  local base, ext = name:match "^(.+)%.([^.]+)$"
  if not base then
    return name, nil
  end
  return base, ext
end

local function note_content(file, rel)
  local title, ext = split_name(vim.fs.basename(file))
  local tags = { "doc" }
  if ext then
    table.insert(tags, ext)
  end
  return {
    "---",
    "tags: [" .. table.concat(tags, ", ") .. "]",
    "fecha: " .. os.date "%Y-%m-%d",
    "archivo: " .. rel,
    "---",
    "",
    "# " .. title,
    "",
    "**Archivo:** [" .. rel .. "](file:///" .. urlencode(vim.fs.normalize(file), ":") .. ")",
    "",
    "**Path completo:** `" .. to_os(file) .. "`",
    "",
    "---",
    "",
    "## Qué hace",
    "",
    "",
    "",
    "## Notas",
    "",
    "",
  }
end

-- lee el campo "archivo:" del frontmatter de una nota existente
local function note_source(md)
  local ok, lines = pcall(vim.fn.readfile, md, "", 10)
  if not ok then
    return nil
  end
  for _, l in ipairs(lines) do
    local v = l:match "^archivo:%s*(.-)%s*$"
    if v then
      return v
    end
  end
end

-- path de la nota de un archivo (sin crearla).
-- La nota se llama como el archivo SIN extensión (Usuario.cs -> Usuario.md).
-- Si en la misma carpeta ya hay una nota de otro archivo con ese nombre
-- (Usuario.cs y Usuario.xaml), la segunda se llama "Usuario (xaml).md".
local function note_path(vault, file, root)
  local rel = file:sub(#root + 2)
  local dir = vim.fs.dirname(rel)
  local title, ext = split_name(vim.fs.basename(file))
  local prefix = vault .. "/" .. ((dir == "." or dir == "") and "" or dir .. "/")

  local candidates = { prefix .. title .. ".md" }
  if ext then
    table.insert(candidates, prefix .. title .. " (" .. ext .. ").md")
  end
  local free
  for _, c in ipairs(candidates) do
    if not exists(c) then
      free = free or c
    elseif note_source(c) == rel then
      return c, rel
    end
  end
  return free or candidates[#candidates], rel
end

-- crea la nota si no existe; devuelve path y si fue creada
local function ensure_note(vault, file, root)
  local md, rel = note_path(vault, file, root)
  if exists(md) then
    return md, false
  end
  vim.fn.mkdir(vim.fs.dirname(md), "p")
  vim.fn.writefile(note_content(file, rel), md)
  return md, true
end

---------------------------------------------------------------------------
-- Sección automática (datos del LSP)
---------------------------------------------------------------------------

local AUTO_START = "<!-- wikidoc:auto -->"
local AUTO_END = "<!-- /wikidoc:auto -->"

-- [[carpeta/Nota|Nota]]: link con path relativo a la bóveda, así no hay
-- ambigüedad si dos notas se llaman igual en carpetas distintas
local function link_for(vault, root, file)
  local md = note_path(vault, file, root)
  local rel = md:sub(#vault + 2):gsub("%.md$", "")
  return "[[" .. rel .. "|" .. vim.fs.basename(rel) .. "]]"
end

local function links(vault, root, set)
  local files = vim.tbl_keys(set)
  table.sort(files)
  local out = {}
  for _, f in ipairs(files) do
    table.insert(out, link_for(vault, root, f))
  end
  return table.concat(out, " · ")
end

local function auto_section(ctx, data, client_name)
  local L = require "configs.wiki_doc_lsp"
  local lines = { AUTO_START, "## Arquitectura", "" }

  local classes, ifaces = {}, {}
  for f, kind in pairs(data.supers) do
    if kind == "interface" then
      ifaces[f] = true
    else
      classes[f] = true
    end
  end
  -- sin repetir: lo que ya está en "Hereda de"/"Implementa" no va en "Usa", y
  -- lo que está en "Implementado por" no va en "Usado por"
  local function minus(a, b)
    local r = {}
    for k in pairs(a) do
      if not b[k] then
        r[k] = true
      end
    end
    return r
  end
  local rels = {
    { "Hereda de", classes },
    { "Implementa", ifaces },
    { "Implementado por", data.impl_by },
    { "Usa", minus(data.uses, data.supers) },
    { "Usado por", minus(data.used_by, data.impl_by) },
  }
  local any = false
  for _, r in ipairs(rels) do
    if next(r[2]) then
      any = true
      table.insert(lines, "**" .. r[1] .. ":** " .. links(ctx.vault, ctx.root, r[2]))
      table.insert(lines, "")
    end
  end
  if not any then
    table.insert(lines, "_Sin relaciones con otros archivos del proyecto._")
    table.insert(lines, "")
  end

  if #data.symbols > 0 then
    table.insert(lines, "## Miembros")
    table.insert(lines, "")
    for _, t in ipairs(data.symbols) do
      table.insert(lines, "### " .. t.name .. " · " .. L.kind_name(t.kind))
      table.insert(lines, "")
      for _, m in ipairs(t.members) do
        table.insert(lines, "- `" .. m.name .. "` · " .. L.kind_name(m.kind))
      end
      if #t.members > 0 then
        table.insert(lines, "")
      end
    end
  end

  table.insert(
    lines,
    "_Generado con el LSP ("
      .. client_name
      .. ") el "
      .. os.date "%Y-%m-%d %H:%M"
      .. ". Esta sección se regenera con :WikiDoc; escribí tus notas fuera de ella._"
  )
  table.insert(lines, AUTO_END)
  return lines
end

-- reemplaza la sección automática de la nota (o la agrega al final)
local function write_auto(md, section)
  local lines = vim.fn.readfile(md)
  local s, e
  for i, l in ipairs(lines) do
    if l == AUTO_START then
      s = i
    elseif l == AUTO_END and s then
      e = i
      break
    end
  end
  local out = {}
  if s and e then
    vim.list_extend(out, lines, 1, s - 1)
    vim.list_extend(out, section)
    vim.list_extend(out, lines, e + 1, #lines)
  else
    vim.list_extend(out, lines)
    if out[#out] ~= "" then
      table.insert(out, "")
    end
    vim.list_extend(out, section)
  end
  vim.fn.writefile(out, md)
end

---------------------------------------------------------------------------
-- Comandos
---------------------------------------------------------------------------

-- contexto del proyecto del archivo: raíz, bóveda y filtro "está en el proyecto"
local function project_ctx(file)
  local root = project_root(file)
  if norm(file):sub(1, #root + 1) ~= norm(root) .. "/" then
    root = vim.fs.dirname(file)
  end
  local nroot = norm(root) .. "/"
  return {
    root = root,
    vault = wiki_base() .. "/" .. vim.fs.basename(root),
    in_project = function(f)
      return norm(f):sub(1, #nroot) == nroot
    end,
  }
end

local function current_file()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if vim.bo[buf].buftype ~= "" or name == "" or not exists(name) then
    notify("Pará el cursor en un archivo guardado para documentarlo", vim.log.levels.WARN)
    return
  end
  return buf, vim.fs.normalize(name)
end

local function with_vault(ctx, fn)
  if exists(ctx.vault .. "/.obsidian") then
    fn()
  else
    create_vault(ctx.vault, fn)
  end
end

local function on_error(err)
  notify("Error: " .. tostring(err), vim.log.levels.ERROR)
end

-- :WikiDoc — nota del archivo actual, con la sección del LSP
function M.create()
  local buf, file = current_file()
  if not buf then
    return
  end
  local ctx = project_ctx(file)
  ctx.file = file
  local L = require "configs.wiki_doc_lsp"

  with_vault(ctx, function()
    L.run(function()
      local md, created = ensure_note(ctx.vault, file, ctx.root)
      -- el LSP puede tardar en conectarse (archivo recién abierto o recargado)
      local client = L.wait_client(buf, 5000)
      if client then
        local rec = notify((created and "Nota creada" or "Actualizando nota") .. " · analizando con " .. client.name .. "…")
        local data = L.analyze(client, buf, ctx, { outgoing = true })
        -- "Usa" también incluye clases padre / interfaces
        for f in pairs(data.supers) do
          data.uses[f] = true
        end
        write_auto(md, auto_section(ctx, data, client.name))
        notify((created and "Nota creada: " or "Nota actualizada: ") .. to_os(md), nil, rec)
      else
        notify((created and "Nota creada: " or "La nota ya existía: ") .. to_os(md))
        notify("Sin LSP en este archivo: la nota no tiene la sección de arquitectura", vim.log.levels.WARN)
      end
      open_in_obsidian(ctx.vault, md)
    end, on_error)
  end)
end

-- archivos del proyecto con alguna de las extensiones
local function project_files(root, exts)
  local want = {}
  for _, e in ipairs(exts) do
    want[(e:lower():gsub("^%.", ""))] = true
  end
  -- carpetas generadas que nunca se documentan (aunque no estén en .gitignore)
  local skip = { [".git"] = true, bin = true, obj = true, node_modules = true, [".vs"] = true }
  local function ok_ext(f)
    for part in f:gmatch "[^/\\]+" do
      if skip[part:lower()] then
        return false
      end
    end
    local _, ext = split_name(vim.fs.basename(f))
    return ext and want[ext:lower()]
  end

  local files = {}
  local res = vim
    .system({ "git", "ls-files", "--cached", "--others", "--exclude-standard" }, { cwd = root, text = true })
    :wait()
  if res.code == 0 then
    for line in res.stdout:gmatch "[^\r\n]+" do
      if ok_ext(line) then
        local f = vim.fs.normalize(root .. "/" .. line)
        if exists(f) then
          table.insert(files, f)
        end
      end
    end
  else
    for name, type in
      vim.fs.dir(root, {
        depth = 20,
        skip = function(dir)
          return not skip[vim.fs.basename(dir)]
        end,
      })
    do
      if type == "file" and ok_ext(name) then
        table.insert(files, vim.fs.normalize(root .. "/" .. name))
      end
    end
  end
  table.sort(files)
  return files
end

local running_all = false

-- :WikiDocAll [ext ...] — documenta todos los archivos del proyecto con esas
-- extensiones (por defecto, la del archivo actual). Primero analiza todo y
-- después escribe: así "Usa" sale de invertir "Usado por" (sin callHierarchy).
function M.create_all(exts)
  if running_all then
    notify(":WikiDocAll ya está corriendo", vim.log.levels.WARN)
    return
  end
  local cur_buf, cur_file = current_file()
  if not cur_buf then
    return
  end
  if not exts or #exts == 0 then
    local _, ext = split_name(vim.fs.basename(cur_file))
    if not ext then
      notify("Indicá las extensiones: :WikiDocAll cs", vim.log.levels.WARN)
      return
    end
    exts = { ext }
  end
  local L = require "configs.wiki_doc_lsp"
  if not L.client_for(cur_buf) then
    notify(
      "El archivo actual no tiene LSP. Abrí un archivo del proyecto con LSP y esperá a que cargue.",
      vim.log.levels.WARN
    )
    return
  end

  local ctx = project_ctx(cur_file)
  local files = project_files(ctx.root, exts)
  if #files == 0 then
    notify("No hay archivos ." .. table.concat(exts, ", .") .. " en " .. to_os(ctx.root), vim.log.levels.WARN)
    return
  end

  running_all = true
  with_vault(ctx, function()
    L.run(function()
      local rec = notify(string.format("Analizando %d archivos con el LSP…", #files))
      local results, client_name = {}, "LSP"
      local opened = {}

      for i, f in ipairs(files) do
        local buf = vim.fn.bufadd(f)
        if not vim.api.nvim_buf_is_loaded(buf) then
          vim.fn.bufload(buf)
          opened[buf] = true
          -- disparar la detección de tipo para que el LSP se conecte
          vim.api.nvim_buf_call(buf, function()
            vim.cmd "filetype detect"
          end)
        end
        local client = L.wait_client(buf, 10000)
        if client then
          client_name = client.name
          results[f] = L.analyze(client, buf, vim.tbl_extend("force", ctx, { file = f }), { outgoing = false })
        else
          results[f] = { symbols = {}, used_by = {}, impl_by = {}, supers = {}, uses = {}, errors = { "sin LSP" } }
        end
        if i % 5 == 0 or i == #files then
          rec = notify(string.format("Analizando %d/%d · %s", i, #files, vim.fs.basename(f)), nil, rec)
        end
      end

      -- Usa(A) = { B : A aparece en "Usado por" de B } ∪ padres/interfaces de A
      for f, data in pairs(results) do
        for g in pairs(data.used_by) do
          if results[g] then
            results[g].uses[f] = true
          end
        end
      end
      for _, data in pairs(results) do
        for g in pairs(data.supers) do
          data.uses[g] = true
        end
      end

      local created, updated, failed = 0, 0, 0
      for _, f in ipairs(files) do
        local data = results[f]
        local md, was_created = ensure_note(ctx.vault, f, ctx.root)
        if #data.errors > 0 and #data.symbols == 0 then
          failed = failed + 1
        end
        write_auto(md, auto_section(vim.tbl_extend("force", ctx, { file = f }), data, client_name))
        if was_created then
          created = created + 1
        else
          updated = updated + 1
        end
      end

      for buf in pairs(opened) do
        if vim.api.nvim_buf_is_valid(buf) and not vim.bo[buf].modified and vim.fn.bufwinid(buf) == -1 then
          pcall(vim.api.nvim_buf_delete, buf, {})
        end
      end
      running_all = false

      notify(
        string.format(
          "Wiki lista: %d notas nuevas, %d actualizadas%s",
          created,
          updated,
          failed > 0 and string.format(" (%d sin datos del LSP)", failed) or ""
        ),
        nil,
        rec
      )
      open_in_obsidian(ctx.vault, (note_path(ctx.vault, cur_file, ctx.root)))
    end, function(err)
      running_all = false
      on_error(err)
    end)
  end)
end

return M
