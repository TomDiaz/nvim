---
tags: [nvim, nvchad, plugins, animacion, estetica, edicion]
fecha: 2026-11-16
---

# Resaltar cambios con undo-glow

Cada vez que el texto cambia por un **undo**, **redo**, **copiar** o **pegar**, o salta por una **búsqueda**, la zona afectada se ilumina con una animación corta. Así se ve de un vistazo qué cambió y dónde.

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11

---

## Qué hace

| Acción | Tecla | Color | Animación |
|---|---|---|---|
| Deshacer | `u` | Rojo apagado | zoom |
| Rehacer | `Ctrl + r` | Verde apagado | zoom |
| Copiar | `y`, `yy`, `yiw`… | Amarillo apagado | zoom |
| Pegar | `p` / `P` | Cian apagado | zoom |
| Buscar | `/` o `?` + `Enter` | Violeta apagado | fade |
| Siguiente / anterior resultado | `n` / `N` | Violeta apagado | strobe (parpadeo) |
| Buscar palabra bajo el cursor | `*` / `#` | Violeta apagado | strobe |

Se usa el plugin **`y3owk1n/undo-glow.nvim`**. La config sale del *Quick Start* de su README, con los ajustes que se explican abajo.

> [!note] No es animación "al escribir"
> En la terminal no se pueden animar letras sueltas mientras se teclea. undo-glow anima los **cambios de bloque** (deshacer, pegar…). El efecto al escribir lo da [[Cursor animado con smear-cursor]].

---

## Cambios realizados

### `lua/plugins/init.lua`

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\plugins\init.lua`

Se agregó este bloque en la tabla de plugins, antes del comentario `-- test new blink`:

```lua
-- Resalta con animación el texto que cambia: undo, redo, yank, paste y búsqueda
-- (sin cursor_moved: eso ya lo hace smear-cursor)
{
  "y3owk1n/undo-glow.nvim",
  event = "VeryLazy",
  opts = {
    animation = {
      enabled = true,
      duration = 300,
      animation_type = "zoom",
      window_scoped = true,
    },
    highlights = {
      undo = { hl_color = { bg = "#693232" } }, -- rojo apagado
      redo = { hl_color = { bg = "#2F4640" } }, -- verde apagado
      yank = { hl_color = { bg = "#7A683A" } }, -- amarillo apagado
      paste = { hl_color = { bg = "#325B5B" } }, -- cian apagado
      search = { hl_color = { bg = "#5C475C" } }, -- violeta apagado
    },
    priority = 2048 * 3,
  },
  keys = {
    { "u", function() require("undo-glow").undo() end, desc = "Undo con glow" },
    { "<C-r>", function() require("undo-glow").redo() end, desc = "Redo con glow" },
    { "p", function() require("undo-glow").paste_below() end, desc = "Pegar abajo con glow" },
    { "P", function() require("undo-glow").paste_above() end, desc = "Pegar arriba con glow" },
    { "n", function() require("undo-glow").search_next { animation = { animation_type = "strobe" } } end, desc = "Siguiente resultado con glow" },
    { "N", function() require("undo-glow").search_prev { animation = { animation_type = "strobe" } } end, desc = "Resultado anterior con glow" },
    { "*", function() require("undo-glow").search_star { animation = { animation_type = "strobe" } } end, desc = "Buscar palabra (adelante) con glow" },
    { "#", function() require("undo-glow").search_hash { animation = { animation_type = "strobe" } } end, desc = "Buscar palabra (atrás) con glow" },
  },
  init = function()
    local group = vim.api.nvim_create_augroup("undo-glow-user", { clear = true })
    vim.api.nvim_create_autocmd("TextYankPost", {
      group = group,
      desc = "Glow al copiar (yank)",
      callback = function()
        require("undo-glow").yank()
      end,
    })
    vim.api.nvim_create_autocmd("CmdlineLeave", {
      group = group,
      desc = "Glow al terminar una búsqueda con / o ?",
      callback = function()
        require("undo-glow").search_cmd { animation = { animation_type = "fade" } }
      end,
    })
  end,
},
```

Qué hace cada parte:

| Opción | Valor | Para qué |
|---|---|---|
| `event` | `VeryLazy` | Carga después del arranque, así no lo hace más lento |
| `animation.enabled` | `true` | Viene **apagado** por defecto; sin esto solo se resalta, sin animar |
| `duration` | `300` | Duración del efecto en milisegundos |
| `animation_type` | `zoom` | Efecto general (ver lista abajo) |
| `window_scoped` | `true` | Solo anima en la ventana activa (útil con splits del mismo archivo) |
| `highlights.*.hl_color` | Colores apagados | Los colores por defecto del plugin son muy chillones; estos combinan con `gruvchad` |
| `priority` | `6144` | Se dibuja por encima de otros resaltados (treesitter, LSP) |
| `keys` | — | El plugin **no trae atajos**: hay que reemplazar `u`, `p`, `n`, etc. por sus funciones |
| `TextYankPost` | autocmd | Dispara el glow al copiar |
| `CmdlineLeave` | autocmd | Dispara el glow al terminar una búsqueda con `/` o `?` |

> [!warning] Diferencias con el README
> - **Rehacer con `Ctrl + r` y no con `U`**: el README usa `U`, pero en Vim `Ctrl + r` es el rehacer estándar (`U` es "deshacer toda la línea").
> - **Sin `cursor_moved`**: el README ilumina la línea cuando el cursor salta lejos (estilo beacon). Eso ya lo hace smear-cursor, y juntos se pisan.
> - **Sin `gc` / `gcc`**: en esta config se comenta con `<leader>/` de NvChad, así que no se remapearon.

### Instalación del plugin

Se instaló con lazy.nvim sin abrir la interfaz:

```bash
cd "C:/Users/diazt/AppData/Local/nvim"
nvim --headless "+Lazy! install" +qa
```

El plugin queda en:

```
C:\Users\diazt\AppData\Local\nvim-data\lazy\undo-glow.nvim
```

Se comprobó en modo headless que `require("undo-glow")` carga sin errores y que `u` queda mapeado. NvChad no tiene su propio resaltado al copiar, así que no hay doble efecto.

---

## Tipos de animación

Se pueden usar en `animation_type` (general) o por acción:

| Tipo | Efecto |
|---|---|
| `fade` | Se desvanece (default del plugin) |
| `fade_reverse` | Aparece de a poco |
| `blink` | Parpadea |
| `pulse` | Late |
| `jitter` | Tiembla |
| `spring` | Rebota |
| `desaturate` | Pierde el color |
| `strobe` | Parpadeo rápido (usado en `n`/`N`/`*`/`#`) |
| `zoom` | Brilla fuerte y se apaga (usado por defecto acá) |
| `rainbow` | Pasa por los colores del arcoíris |
| `slide` | Se desliza de izquierda a derecha |

---

## Personalización

- **Cambiar la animación de una sola acción**: pasarle opciones a la función en `keys`:

```lua
{ "u", function() require("undo-glow").undo { animation = { animation_type = "rainbow" } } end, desc = "Undo con glow" },
```

- **Efecto más largo o más corto**: cambiar `duration` (por ejemplo `500` o `150`).
- **Cambiar un color**: editar `hl_color` en `highlights`, o enlazarlo a un grupo existente con `hl = "Visual"`.
- **Glow al comentar**: agregar en `keys` el mapeo de `gc`/`gcc` del README (`require("undo-glow").comment()` con `expr = true`).
- **Apagar las animaciones sin desinstalar**: `animation = { enabled = false }`. Así solo queda el resaltado fijo.
- **Desinstalar:** borrar el bloque `y3owk1n/undo-glow.nvim` de `lua/plugins/init.lua` y ejecutar `:Lazy clean`. `u`, `p`, `n`, etc. vuelven a su comportamiento normal.

Ver también: [[Cursor animado con smear-cursor]] · [[Notificaciones y cmdline con noice]] · [[Comandos y atajos de NvChad]]
