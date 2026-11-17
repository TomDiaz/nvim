require "nvchad.options"

-- add yours here!

-- números de línea híbridos: absoluto en la línea actual, relativos en el resto
vim.opt.number = true
vim.opt.relativenumber = true

-- mostrar ambos a la vez en cada línea: absoluto | relativo
-- (en líneas envueltas no se repite el número)
vim.opt.statuscolumn =
  "%s%{v:virtnum ? '' : printf('%4d %3s', v:lnum, v:relnum ? v:relnum : '')} "

-- sin números en el chat de Claude (terminal), el árbol de archivos, la pantalla de inicio
-- y el panel de git (neogit: status, log, commit, popups).
-- Hay que vaciar también statuscolumn: el de arriba dibuja los números por su cuenta,
-- sin mirar la opción number.
local function no_numbers()
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.statuscolumn = ""
end

local function wants_no_numbers(buf)
  local ft = vim.bo[buf].filetype
  return vim.bo[buf].buftype == "terminal" or ft == "NvimTree" or ft == "nvdash" or ft:match "^Neogit" ~= nil
end

vim.api.nvim_create_autocmd("TermOpen", { callback = no_numbers })
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
  callback = function(ev)
    if wants_no_numbers(ev.buf) then
      -- opciones de ventana: aplicarlas en cada ventana que muestra el buffer
      for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
        vim.api.nvim_win_call(win, no_numbers)
      end
    end
  end,
})

-- cursor: barra vertical en todos los modos (color en chadrc.lua -> hl_override.Cursor, para GUIs)
vim.opt.guicursor = "a:ver25-Cursor"

-- en terminal el color lo pinta la terminal: se lo pedimos con OSC 12 (naranja)
-- y al salir lo restauramos (OSC 112) junto con la forma de barra
local function term_send(seq)
  pcall(vim.api.nvim_chan_send, vim.v.stderr, seq)
end

vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
  callback = function() term_send "\027]12;#ff8c00\007" end,
})

vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  callback = function()
    vim.opt.guicursor = "a:ver25"
    term_send "\027]112\007"
  end,
})

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!
