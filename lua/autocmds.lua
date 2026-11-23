require "nvchad.autocmds"

-- nvdash sin botones: sus mapeos j/k/flechas crashean (key_lines vacío).
-- Se reemplazan por <Nop>; si hay botones se deja la navegación original.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "nvdash",
  callback = function(ev)
    if #(require("nvchad.nvdash").key_lines or {}) == 0 then
      for _, k in ipairs { "j", "k", "<Down>", "<Up>", "<CR>" } do
        vim.keymap.set("n", k, "<Nop>", { buffer = ev.buf, nowait = true })
      end
    end
  end,
})
