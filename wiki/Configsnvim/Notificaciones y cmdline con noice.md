---
tags: [nvim, nvchad, plugins, notificaciones, ui]
fecha: 2026-11-16
---

# Notificaciones y cmdline con noice

Cambia cómo se ven los mensajes de Neovim. La línea de comandos (`:`) aparece como un popup arriba, y los mensajes, errores y avisos del LSP salen como **notificaciones animadas** en la esquina. También sirve para crear **alertas propias** desde Lua.

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11

---

## Qué hace

| Antes | Con noice |
|---|---|
| La cmdline `:` está abajo, en la última línea | Popup centrado arriba, con resaltado de sintaxis y el menú de autocompletado pegado debajo |
| Los mensajes y errores se pisan en la última línea | Notificaciones flotantes que desaparecen solas a los 3 segundos |
| Los mensajes largos piden "Press ENTER" | Se abren en un split que se cierra con `q` |
| El progreso del LSP (roslyn cargando) no se ve | Aparece abajo a la derecha mientras carga |
| Los mensajes viejos se pierden | Quedan en un historial que se puede buscar con Telescope |

La búsqueda con `/` y `?` **sigue abajo**, como siempre (preset `bottom_search`).

Se usan tres plugins:
- **`folke/noice.nvim`**: el plugin principal.
- **`rcarriga/nvim-notify`**: dibuja los popups de notificación.
- **`MunifTanjim/nui.nvim`**: librería de UI que necesita noice.

---

## Cambios realizados

### `lua/plugins/init.lua`

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\plugins\init.lua`

Se agregó este bloque en la tabla de plugins, antes del comentario `-- test new blink`:

```lua
-- Noice: UI nueva para mensajes, cmdline y notificaciones (popups vía nvim-notify)
{
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "rcarriga/nvim-notify",
      opts = {
        -- con transparency = true el bg de Normal es NONE; notify necesita un color fijo
        background_colour = "#000000",
        timeout = 3000,
        stages = "fade_in_slide_out",
        render = "wrapped-compact",
      },
      config = function(_, opts)
        pcall(dofile, vim.g.base46_cache .. "notify")
        require("notify").setup(opts)
      end,
    },
  },
  opts = {
    lsp = {
      -- usar markdown de treesitter en hover/docs
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
      },
      -- NvChad ya tiene su propio signature help
      signature = { enabled = false },
    },
    presets = {
      bottom_search = true, -- / y ? abajo, como siempre
      command_palette = true, -- cmdline y popupmenu juntos arriba
      long_message_to_split = true, -- mensajes largos van a un split
      lsp_doc_border = true,
    },
  },
  keys = {
    { "<leader>nh", "<cmd>Noice telescope<cr>", desc = "Noice historial (telescope)" },
    { "<leader>nl", "<cmd>Noice last<cr>", desc = "Noice último mensaje" },
    { "<leader>nd", "<cmd>Noice dismiss<cr>", desc = "Noice cerrar notificaciones" },
  },
  config = function(_, opts)
    require("noice").setup(opts)
    pcall(require("telescope").load_extension, "noice")
  end,
},
```

Qué hace cada parte:

| Opción | Valor | Para qué |
|---|---|---|
| `event` | `VeryLazy` | Carga después del arranque, así no lo hace más lento |
| `background_colour` | `#000000` | Con `transparency = true` en `chadrc.lua` el fondo es `NONE`, y nvim-notify lo necesita para calcular el fundido. Sin esto avisa en cada notificación |
| `timeout` | `3000` | Las notificaciones se cierran solas a los 3 segundos |
| `stages` | `fade_in_slide_out` | Animación de entrada y salida |
| `render` | `wrapped-compact` | Formato compacto que corta las líneas largas |
| `dofile(... "notify")` | — | Carga los colores de base46 (tema de NvChad) para nvim-notify. Va en `pcall` por si el tema no trae esa integración |
| `lsp.override` | `true` | Los hovers del LSP (`K`) se dibujan con markdown de treesitter |
| `lsp.signature` | `enabled = false` | Ver aviso abajo |
| `presets.*` | — | Ver la tabla de la sección **Qué hace** |
| `load_extension "noice"` | — | Registra `:Telescope noice` para el historial |

> [!warning] Por qué se desactivó la firma de noice
> NvChad ya muestra la firma de la función mientras escribís los argumentos (signature help). Si noice también la muestra, aparecen dos popups superpuestos. Por eso queda solo la de NvChad.

### Parsers de treesitter

En el bloque de `nvim-treesitter` del mismo archivo se agregaron a `ensure_installed`:

```lua
-- usados por noice (cmdline, hover)
"markdown", "markdown_inline", "regex", "bash",
```

Noice los usa para resaltar la cmdline y los hovers del LSP. Si no se instalan solos, ejecutar:

```vim
:TSInstall markdown markdown_inline regex bash
```

### Instalación del plugin

Se instaló con lazy.nvim sin abrir la interfaz:

```bash
cd "C:/Users/diazt/AppData/Local/nvim"
nvim --headless "+Lazy! install" +qa
```

Los plugins quedan en:

```
C:\Users\diazt\AppData\Local\nvim-data\lazy\noice.nvim
C:\Users\diazt\AppData\Local\nvim-data\lazy\nvim-notify
C:\Users\diazt\AppData\Local\nvim-data\lazy\nui.nvim
```

Se comprobó en modo headless que `require("noice")` carga sin errores.

---

## Atajos y comandos

| Tecla | Comando | Acción |
|---|---|---|
| `<leader>nh` | `:Noice telescope` | Buscar en el historial de mensajes con Telescope |
| `<leader>nl` | `:Noice last` | Ver el último mensaje en un popup |
| `<leader>nd` | `:Noice dismiss` | Cerrar todas las notificaciones abiertas |
| — | `:Noice` o `:Noice history` | Historial completo en un split |
| — | `:Noice errors` | Solo los errores |
| — | `:Noice disable` / `:Noice enable` | Apagar o prender noice sin reiniciar |
| — | `:Notifications` | Historial de nvim-notify |

> [!note] Grupo `<leader>n`
> NvChad usa `<leader>n` para mostrar u ocultar los números de línea, y easy-dotnet usa `<leader>nb`, `<leader>nr`, etc. Por eso, al pulsar `<leader>n` Neovim espera un momento (`timeoutlen`) para ver si viene otra tecla. Es normal.

> [!tip] Dentro del split de mensajes
> `q` cierra el split. Es un buffer normal, así que se puede buscar con `/` y copiar con `y`.

---

## Crear alertas propias

Cualquier `vim.notify` sale como popup de noice:

```vim
:lua vim.notify("Hola desde noice", vim.log.levels.WARN, { title = "Test" })
```

Los niveles cambian el color y el ícono:

| Nivel | Uso |
|---|---|
| `vim.log.levels.INFO` | Información (azul/verde) |
| `vim.log.levels.WARN` | Aviso (amarillo) |
| `vim.log.levels.ERROR` | Error (rojo) |
| `vim.log.levels.DEBUG` / `TRACE` | Depuración |

### Ejemplos

**Alerta al guardar un archivo** (en `lua/autocmds.lua`):

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function(args)
    vim.notify("Guardado: " .. vim.fn.fnamemodify(args.file, ":t"), vim.log.levels.INFO, { title = "Archivo" })
  end,
})
```

**Recordatorio con temporizador** (te avisa en 25 minutos):

```lua
vim.defer_fn(function()
  vim.notify("¡Tomate un descanso!", vim.log.levels.WARN, { title = "Pomodoro", timeout = 10000 })
end, 25 * 60 * 1000)
```

**Alerta cuando termina un comando externo** (por ejemplo `dotnet build`):

```lua
vim.system({ "dotnet", "build" }, { text = true }, function(res)
  vim.schedule(function()
    if res.code == 0 then
      vim.notify("Build OK", vim.log.levels.INFO, { title = "dotnet" })
    else
      vim.notify("Build falló\n" .. (res.stdout or ""), vim.log.levels.ERROR, { title = "dotnet" })
    end
  end)
end)
```

> [!tip] `timeout` por notificación
> Se puede pasar `timeout = <ms>` en el tercer argumento para que una alerta dure más (o `timeout = false` para que no se cierre sola).

---

## Personalización

- **Cmdline abajo como antes:** poner `command_palette = false` y agregar `cmdline = { view = "cmdline" }` en `opts`.
- **Notificaciones más cortas o más largas:** cambiar `timeout` en las opts de `nvim-notify`.
- **Animación más liviana:** `stages = "static"` (sin animación) o `"fade"`.
- **Notificaciones abajo:** agregar `top_down = false` en las opts de `nvim-notify`.
- **Ocultar un mensaje molesto** (por ejemplo "written" al guardar):

```lua
routes = {
  { filter = { event = "msg_show", find = "written" }, opts = { skip = true } },
},
```

(va dentro de `opts` de noice, al mismo nivel que `presets`).

- **Desinstalar:** borrar el bloque `folke/noice.nvim` de `lua/plugins/init.lua` y ejecutar `:Lazy clean`.

Ver también: [[Comandos y atajos de NvChad]]
