-- Abre un archivo en una pestaña nueva de Windows Terminal con nvim
-- (usado por <C-o> en Telescope y en el panel de neogit)
local M = {}

-- wt.exe es un alias de la Store: Neovim no lo ve como ejecutable,
-- hay que lanzarlo a través de cmd.exe.
-- Con cmd.exe Neovim pasa los argumentos textuales (sin comillas),
-- así que los que pueden tener espacios hay que entrecomillarlos a mano.
local function q(s)
  -- una "\" final escaparía la comilla de cierre ("C:\" -> "C:\.")
  if s:sub(-1) == "\\" then s = s .. "." end
  return '"' .. s .. '"'
end

---@param path string
---@param lnum? integer línea en la que posicionarse
function M.open(path, lnum)
  if type(path) ~= "string" or path == "" then
    return
  end
  path = vim.fn.fnamemodify(path, ":p")
  local name = vim.fn.fnamemodify(path, ":t")
  -- ícono PNG de la pestaña: perfil oculto "nvim-<ext>" definido en el
  -- fragment de Windows Terminal (Fragments\nvim-icons), PNG en assets\icons
  local ext = vim.fn.fnamemodify(name, ":e"):lower()
  if ext == "" then ext = name:gsub("^%.", ""):lower() end -- p.ej. .editorconfig
  local icons_dir = vim.fn.stdpath("config") .. "\\assets\\icons\\"
  if vim.fn.filereadable(icons_dir .. ext .. ".png") == 0 then ext = "file" end
  local profile = "nvim-" .. ext

  local cmd = { "cmd.exe", "/c", "wt", "-w", "new", "nt", "-p", q(profile), "-d", q(vim.fn.getcwd()),
    -- título = nombre del archivo; suppress evita que nvim lo pise
    "--title", q(name), "--suppressApplicationTitle", "nvim" }
  if lnum then
    table.insert(cmd, "+" .. lnum)
  end
  table.insert(cmd, q(path))
  vim.fn.jobstart(cmd, { detach = true })
end

-- Telescope: abre el/los archivo(s) seleccionados (multi-selección con <Tab>)
function M.telescope(prompt_bufnr)
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local picker = action_state.get_current_picker(prompt_bufnr)
  local entries = picker:get_multi_selection()
  if vim.tbl_isempty(entries) then
    entries = { action_state.get_selected_entry() }
  end
  actions.close(prompt_bufnr)
  for _, entry in ipairs(entries) do
    M.open(entry.path or entry.filename or entry.value, entry.lnum)
  end
end

-- neogit: abre el archivo bajo el cursor en el panel de estado.
-- Si el cursor está sobre una línea del diff, posiciona en esa línea del archivo.
function M.neogit()
  local ok, status = pcall(require, "neogit.buffers.status")
  local self = ok and status.instance() or nil
  if not (self and self.buffer) then
    return vim.notify("No se encontró el panel de neogit", vim.log.levels.WARN)
  end
  local item = self.buffer.ui:get_item_under_cursor()
  if not (item and item.absolute_path) then
    return vim.notify("No hay un archivo bajo el cursor", vim.log.levels.INFO)
  end

  local lnum
  if rawget(item, "diff") then
    local line = self.buffer:cursor_line()
    for _, hunk in ipairs(item.diff.hunks) do
      if line >= hunk.first and line <= hunk.last then
        local jump_ok, jump = pcall(require, "neogit.lib.jump")
        if jump_ok then
          lnum = jump.adjust_row(hunk.disk_from, line - hunk.first, hunk.lines, "-")
        end
        break
      end
    end
  end
  M.open(item.absolute_path, lnum)
end

return M
