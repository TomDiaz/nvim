-- Consultas al LSP para :WikiDoc / :WikiDocAll (lua/configs/wiki_doc.lua)
--
-- Todo corre dentro de una corrutina: cada pedido al LSP "espera" sin trabar
-- Neovim. Para cada archivo se obtiene:
--   symbols      tipos principales (clases, interfaces…) con sus miembros
--   used_by      archivos que referencian esos tipos            (references)
--   impl_by      archivos que implementan las interfaces        (implementation)
--   supers       clases padre / interfaces que implementa       (typeHierarchy)
--   uses         archivos a los que llama                       (callHierarchy, opcional)

local M = {}

M.timeout = 15000 -- ms por pedido

local K = vim.lsp.protocol.SymbolKind
local TYPE_KINDS = {
  [K.Class] = true,
  [K.Interface] = true,
  [K.Struct] = true,
  [K.Enum] = true,
}
local CONTAINER_KINDS = { [K.File] = true, [K.Module] = true, [K.Namespace] = true, [K.Package] = true }
local CALLABLE_KINDS = { [K.Method] = true, [K.Constructor] = true, [K.Function] = true }

M.kind_names = {
  [K.File] = "archivo",
  [K.Module] = "módulo",
  [K.Namespace] = "namespace",
  [K.Package] = "paquete",
  [K.Class] = "clase",
  [K.Method] = "método",
  [K.Property] = "propiedad",
  [K.Field] = "campo",
  [K.Constructor] = "constructor",
  [K.Enum] = "enum",
  [K.Interface] = "interfaz",
  [K.Function] = "función",
  [K.Variable] = "variable",
  [K.Constant] = "constante",
  [K.EnumMember] = "valor",
  [K.Struct] = "struct",
  [K.Event] = "evento",
  [K.Operator] = "operador",
  [K.TypeParameter] = "tipo genérico",
}

function M.kind_name(kind)
  return M.kind_names[kind] or "símbolo"
end

---------------------------------------------------------------------------
-- Corrutinas
---------------------------------------------------------------------------

-- corre fn como corrutina; los errores se informan con on_error
function M.run(fn, on_error)
  local co = coroutine.create(function()
    local ok, err = xpcall(fn, debug.traceback)
    if not ok and on_error then
      vim.schedule(function()
        on_error(err)
      end)
    end
  end)
  local ok, err = coroutine.resume(co)
  if not ok and on_error then
    on_error(err)
  end
end

local function resume(co, ...)
  local ok, err = coroutine.resume(co, ...)
  if not ok then
    vim.notify("WikiDoc: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.sleep(ms)
  local co = coroutine.running()
  vim.defer_fn(function()
    resume(co)
  end, ms)
  coroutine.yield()
end

-- pedido al LSP que "espera" la respuesta; devuelve err, result
function M.request(client, method, params, bufnr)
  local co = coroutine.running()
  local done = false
  local ok, id = client:request(method, params, function(err, result)
    if done then
      return
    end
    done = true
    vim.schedule(function()
      resume(co, err, result)
    end)
  end, bufnr)
  if not ok then
    return "no se pudo enviar " .. method, nil
  end
  vim.defer_fn(function()
    if not done then
      done = true
      pcall(client.cancel_request, client, id)
      resume(co, "timeout en " .. method, nil)
    end
  end, M.timeout)
  return coroutine.yield()
end

---------------------------------------------------------------------------
-- Cliente
---------------------------------------------------------------------------

-- primer cliente del buffer que sepa listar símbolos
function M.client_for(bufnr)
  for _, c in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if c:supports_method("textDocument/documentSymbol", bufnr) then
      return c
    end
  end
end

-- espera hasta `ms` a que un cliente LSP se conecte al buffer
function M.wait_client(bufnr, ms)
  local waited = 0
  while waited < ms do
    local c = M.client_for(bufnr)
    if c then
      return c
    end
    M.sleep(200)
    waited = waited + 200
  end
end

---------------------------------------------------------------------------
-- Análisis de un archivo
---------------------------------------------------------------------------

local function uri_file(uri)
  if type(uri) ~= "string" or not uri:match "^file:" then
    return nil
  end
  return vim.fs.normalize(vim.uri_to_fname(uri))
end

-- DocumentSymbol[] (árbol) o SymbolInformation[] (lista plana) -> tipos principales
local function collect_types(result)
  local types, others = {}, {}
  if not result or #result == 0 then
    return types
  end

  if result[1].location then
    -- lista plana: los tipos son los de kind tipo; los miembros, los que tienen containerName
    local by_name = {}
    for _, s in ipairs(result) do
      if TYPE_KINDS[s.kind] then
        local t = { name = s.name, kind = s.kind, pos = s.location.range.start, members = {} }
        table.insert(types, t)
        by_name[s.name] = t
      end
    end
    for _, s in ipairs(result) do
      local parent = s.containerName and by_name[s.containerName]
      if parent and not TYPE_KINDS[s.kind] then
        table.insert(parent.members, { name = s.name, kind = s.kind, pos = s.location.range.start })
      elseif not parent and not TYPE_KINDS[s.kind] and CALLABLE_KINDS[s.kind] then
        table.insert(others, { name = s.name, kind = s.kind, pos = s.location.range.start, members = {} })
      end
    end
  else
    local function walk(list)
      for _, s in ipairs(list) do
        if CONTAINER_KINDS[s.kind] then
          walk(s.children or {})
        elseif TYPE_KINDS[s.kind] then
          local t = { name = s.name, kind = s.kind, pos = s.selectionRange.start, members = {} }
          for _, ch in ipairs(s.children or {}) do
            table.insert(t.members, {
              name = ch.name,
              detail = ch.detail,
              kind = ch.kind,
              pos = ch.selectionRange.start,
            })
          end
          table.insert(types, t)
        elseif CALLABLE_KINDS[s.kind] then
          table.insert(others, { name = s.name, kind = s.kind, pos = s.selectionRange.start, members = {} })
        end
      end
    end
    walk(result)
  end

  -- lenguajes sin clases (scripts, módulos de funciones): se usan las funciones
  if #types == 0 then
    return vim.list_slice(others, 1, 40)
  end
  return types
end

-- agrega a `set` los archivos de `locations` que estén en el proyecto y no sean `self`
local function add_files(set, locations, ctx)
  if not locations then
    return
  end
  if locations.uri or locations.targetUri then
    locations = { locations }
  end
  for _, loc in ipairs(locations) do
    local f = uri_file(loc.uri or loc.targetUri)
    if f and f ~= ctx.file and ctx.in_project(f) then
      set[f] = true
    end
  end
end

-- analiza un buffer. opts.outgoing = true también pide callHierarchy (más lento)
-- ctx = { file, in_project = function(f) -> bool }
function M.analyze(client, bufnr, ctx, opts)
  opts = opts or {}
  local uri = vim.uri_from_bufnr(bufnr)
  local doc = { uri = uri }
  local data = { symbols = {}, used_by = {}, impl_by = {}, supers = {}, uses = {}, errors = {} }

  local err, result = M.request(client, "textDocument/documentSymbol", { textDocument = doc }, bufnr)
  if err then
    table.insert(data.errors, tostring(err.message or err))
    return data
  end
  data.symbols = collect_types(result)

  local can = function(m)
    return client:supports_method(m, bufnr)
  end

  for _, t in ipairs(data.symbols) do
    local pos_params = { textDocument = doc, position = t.pos }

    if can "textDocument/references" then
      local _, refs = M.request(client, "textDocument/references", {
        textDocument = doc,
        position = t.pos,
        context = { includeDeclaration = false },
      }, bufnr)
      add_files(data.used_by, refs, ctx)
    end

    if t.kind == K.Interface and can "textDocument/implementation" then
      local _, impls = M.request(client, "textDocument/implementation", pos_params, bufnr)
      add_files(data.impl_by, impls, ctx)
    end

    if TYPE_KINDS[t.kind] and can "textDocument/prepareTypeHierarchy" then
      local _, items = M.request(client, "textDocument/prepareTypeHierarchy", pos_params, bufnr)
      if items and items[1] then
        local _, supers = M.request(client, "typeHierarchy/supertypes", { item = items[1] }, bufnr)
        for _, s in ipairs(supers or {}) do
          local f = uri_file(s.uri)
          if f and f ~= ctx.file and ctx.in_project(f) then
            data.supers[f] = s.kind == K.Interface and "interface" or "class"
          end
        end
      end
    end

    if opts.outgoing and can "textDocument/prepareCallHierarchy" then
      local callables = {}
      if CALLABLE_KINDS[t.kind] then
        table.insert(callables, t)
      end
      for _, m in ipairs(t.members) do
        if CALLABLE_KINDS[m.kind] then
          table.insert(callables, m)
        end
      end
      for i = 1, math.min(#callables, 60) do
        local _, items = M.request(client, "textDocument/prepareCallHierarchy", {
          textDocument = doc,
          position = callables[i].pos,
        }, bufnr)
        if items and items[1] then
          local _, calls = M.request(client, "callHierarchy/outgoingCalls", { item = items[1] }, bufnr)
          for _, call in ipairs(calls or {}) do
            local f = uri_file(call.to and call.to.uri)
            if f and f ~= ctx.file and ctx.in_project(f) then
              data.uses[f] = true
            end
          end
        end
      end
    end
  end

  return data
end

return M
