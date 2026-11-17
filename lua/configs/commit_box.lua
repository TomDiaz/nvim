-- Editor de commit de neogit con aspecto de "caja de chat":
-- ventana flotante chica con título, ayuda en el borde inferior, la plantilla de git
-- (# Please enter the commit message...) plegada en una línea, y teclas tipo chat:
--   Enter            → hacer el commit
--   Shift+Enter / Ctrl+J → nueva línea
--   Esc (normal)     → cancelar
-- Las teclas Enter/Esc se definen en las mappings de neogit (plugins/init.lua);
-- acá van solo el título, el pliegue y la nueva línea.
local M = {}

M.title = " 󰜘 Mensaje del commit "
M.footer = " Enter: commit · Shift+Enter / Ctrl+J: nueva línea · Esc Esc: cancelar "

function M.setup_window(buf)
  -- solo el editor de neogit: buffer gitcommit en una ventana flotante
  local win = vim.fn.bufwinid(buf)
  if win == -1 or vim.api.nvim_win_get_config(win).relative == "" then
    return
  end

  pcall(vim.api.nvim_win_set_config, win, {
    title = M.title,
    title_pos = "left",
    footer = M.footer,
    footer_pos = "center",
  })

  local wo = vim.wo[win][0]
  wo.number = false
  wo.relativenumber = false
  wo.statuscolumn = ""
  wo.signcolumn = "no"
  wo.wrap = true
  wo.linebreak = true
  wo.cursorline = false

  -- plegar la plantilla de git (desde el primer comentario hasta el final)
  local comment = "#"
  local ok, out = pcall(vim.fn.systemlist, { "git", "config", "core.commentChar" })
  if ok and vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
    comment = out[1]
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local first
  for i, l in ipairs(lines) do
    if vim.startswith(l, comment) then
      first = i
      break
    end
  end
  if first then
    wo.foldmethod = "manual"
    wo.foldenable = true
    wo.foldtext = "'  ▸ plantilla de git y archivos del commit (za para ver)'"
    wo.fillchars = "fold: ,eob: "
    vim.api.nvim_win_call(win, function()
      vim.cmd(("silent! %d,%dfold"):format(first, #lines))
    end)
  end

  -- nueva línea sin enviar
  for _, key in ipairs { "<S-CR>", "<C-j>" } do
    vim.keymap.set("i", key, "<CR>", { buffer = buf, desc = "Commit: nueva línea" })
  end
end

return M
