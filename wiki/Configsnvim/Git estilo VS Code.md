---
tags: [nvim, nvchad, plugins, git]
fecha: 2026-11-16
---

# Git estilo VS Code

Todo lo de la pestaña **Source Control** de VS Code (y algo de GitLens) dentro de Neovim: panel de cambios, stage, commit, push y pull, diff lado a lado, historial de un archivo, editor de conflictos de merge y blame en la línea actual.

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11 · git 2.54

---

## Equivalencias con VS Code

| En VS Code | En Neovim | Plugin |
|---|---|---|
| Panel **Source Control** (`Ctrl + Shift + G`) | `<leader>gg` | neogit |
| Botón **+** (stage) en un archivo | `s` sobre el archivo en el panel | neogit |
| Escribir mensaje + **✓ Commit** | `c` `c` en el panel, o `<leader>gc` | neogit |
| **Sync / Push / Pull** | `P` `p` / `p` `p` en el panel, o `<leader>gP` / `<leader>gl` | neogit |
| Rama en la barra de estado (cambiar rama) | `<leader>gB` | Telescope |
| Clic en un archivo modificado → diff lado a lado | `<leader>gd` | diffview |
| **Timeline** / historial del archivo | `<leader>gh` | diffview |
| Editor de conflictos de merge (Current / Incoming) | `<leader>gd` durante un merge | diffview |
| Barras de color al lado de los números de línea | Automático | gitsigns |
| Clic en la barra → ver el cambio / revertirlo | `<leader>gp` / `<leader>gr` | gitsigns |
| Blame de **GitLens** al final de la línea | Automático (a los 0,5 s) | gitsigns |

Se usan tres plugins:
- **`NeogitOrg/neogit`**: el panel de Source Control. Es una copia de Magit, de Emacs.
- **`sindrets/diffview.nvim`**: diffs lado a lado, historial y conflictos.
- **`lewis6991/gitsigns.nvim`**: ya venía con NvChad. Se le agregaron atajos y blame en línea.

---

## Cambios realizados

### `lua/plugins/init.lua`

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\plugins\init.lua`

Se agregaron estos tres bloques en la tabla de plugins, antes del comentario `-- test new blink`:

```lua
-- Panel "Source Control": stage, commit, push, pull, ramas, stash, log
{
  "NeogitOrg/neogit",
  cmd = "Neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    { "<leader>gg", "<cmd>Neogit<cr>", desc = "Git: panel Source Control (neogit)" },
    { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Git: commit" },
    { "<leader>gP", "<cmd>Neogit push<cr>", desc = "Git: push" },
    { "<leader>gl", "<cmd>Neogit pull<cr>", desc = "Git: pull" },
    { "<leader>gB", "<cmd>Telescope git_branches<cr>", desc = "Git: cambiar de rama" },
  },
  opts = {
    kind = "vsplit_left", -- panel a la izquierda, como la barra lateral de VS Code
    graph_style = "unicode",
    integrations = {
      diffview = true, -- los diffs se abren lado a lado con diffview
      telescope = true,
    },
    -- editor del commit como "caja de chat" flotante (ver lua/configs/commit_box.lua)
    commit_editor = { kind = "floating", show_staged_diff = false, spell_check = false },
    floating = { relative = "editor", width = 0.5, height = 10, style = "minimal", border = "rounded" },
    disable_insert_on_commit = false, -- siempre empezar escribiendo
    mappings = {
      commit_editor_I = { ["<cr>"] = "Submit" }, -- Enter = commit (como enviar en un chat)
      commit_editor = { ["<cr>"] = "Submit", ["<esc>"] = "Abort" }, -- Esc en normal = cancelar
    },
  },
},

-- Diff lado a lado, historial de archivo y editor de conflictos de merge
{
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git: ver cambios (diff lado a lado)" },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Git: cerrar diffview" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Git: historial del archivo" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Git: historial del repo" },
  },
  opts = {
    enhanced_diff_hl = true, -- resaltado de diff más parecido a VS Code
    view = {
      merge_tool = { layout = "diff3_mixed" }, -- arriba: actual | entrante; abajo: resultado
    },
  },
},

-- gitsigns ya viene con NvChad: se le suma blame en línea (estilo GitLens) y atajos
{
  "lewis6991/gitsigns.nvim",
  opts = function()
    local opts = require "nvchad.configs.gitsigns"
    opts.current_line_blame = true
    opts.current_line_blame_opts = { delay = 500, virt_text_pos = "eol" }
    opts.current_line_blame_formatter = "    <author>, <author_time:%R> • <summary>"
    return opts
  end,
  keys = {
    { "]h", "<cmd>Gitsigns nav_hunk next<cr>", desc = "Git: siguiente cambio" },
    { "[h", "<cmd>Gitsigns nav_hunk prev<cr>", desc = "Git: cambio anterior" },
    { "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Git: previsualizar cambio" },
    { "<leader>gs", "<cmd>Gitsigns stage_hunk<cr>", mode = { "n", "v" }, desc = "Git: stage del cambio" },
    { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", mode = { "n", "v" }, desc = "Git: descartar cambio" },
    { "<leader>gS", "<cmd>Gitsigns stage_buffer<cr>", desc = "Git: stage del archivo" },
    { "<leader>gR", "<cmd>Gitsigns reset_buffer<cr>", desc = "Git: descartar cambios del archivo" },
    { "<leader>gb", "<cmd>Gitsigns blame_line full=true<cr>", desc = "Git: blame de la línea" },
    { "<leader>ga", "<cmd>Gitsigns blame<cr>", desc = "Git: blame del archivo" },
    { "<leader>gx", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Git: mostrar/ocultar blame en línea" },
  },
},
```

Qué hace cada parte:

| Opción | Valor | Para qué |
|---|---|---|
| `cmd` / `keys` | — | neogit y diffview se cargan recién al usarlos, así no hacen más lento el arranque |
| `kind` (neogit) | `vsplit_left` | El panel se abre a la izquierda, como la barra lateral de VS Code. El explorador (nvim-tree) queda a la derecha, así no chocan |
| `graph_style` | `unicode` | El gráfico de ramas en el log se dibuja con líneas unicode |
| `integrations.diffview` | `true` | Al abrir un diff desde neogit se usa diffview (lado a lado) |
| `integrations.telescope` | `true` | Los selectores de neogit (ramas, commits) usan Telescope |
| `commit_editor`, `floating`, `mappings` | — | El mensaje del commit se escribe en una caja flotante estilo chat (ver **Caja de texto para el commit** abajo) |
| `enhanced_diff_hl` | `true` | Colores de diff más claros (líneas agregadas y borradas) |
| `merge_tool.layout` | `diff3_mixed` | En un conflicto: arriba **tu versión** y la **entrante**, abajo el **resultado** que se guarda |
| `opts = function()` (gitsigns) | — | Parte de la config de NvChad (íconos y colores del tema) y le suma el blame; así no se pierde lo que trae NvChad |
| `current_line_blame` | `true` | Muestra autor, fecha relativa y mensaje del commit al final de la línea actual, como GitLens |
| `delay` | `500` | Espera medio segundo quieto antes de mostrarlo, para que no moleste al moverse |

> [!note] Atajos de NvChad que se respetan
> NvChad ya usa `<leader>gt` (estado de git en Telescope) y `<leader>cm` (commits en Telescope). Siguen funcionando igual. Todo lo nuevo va bajo `<leader>g…`.

### `Ctrl + o` en el panel: abrir en una terminal nueva

Igual que el `Ctrl + o` de Telescope, en el panel de neogit `Ctrl + o` abre el archivo bajo el cursor en una **pestaña nueva de Windows Terminal**, con su ícono y su nombre como título. Si el cursor está sobre una línea del diff (después de expandirlo con `Tab`), el archivo se abre **en esa línea**.

Para no duplicar código, la lógica que antes estaba dentro del bloque de Telescope se movió a un módulo compartido:

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\configs\wt_open.lua`

| Función | Uso |
|---|---|
| `open(path, lnum)` | Lanza `wt` (a través de `cmd.exe`) con el perfil `nvim-<ext>` del ícono, el título y `nvim +lnum archivo` |
| `telescope(prompt_bufnr)` | La acción de `Ctrl + o` en Telescope (con multi-selección por `Tab`) |
| `neogit()` | Toma el archivo bajo el cursor del panel de neogit y, si está sobre un cambio, calcula la línea real en el archivo |

El bloque de Telescope en `lua/plugins/init.lua` ahora solo hace:

```lua
local open_in_new_terminal = require("configs.wt_open").telescope
```

Y al bloque de neogit se le agregó un `config` que registra el atajo solo dentro del panel (`FileType NeogitStatus`):

```lua
config = function(_, opts)
  require("neogit").setup(opts)
  -- <C-o> en el panel: abrir el archivo bajo el cursor en una pestaña nueva
  -- de Windows Terminal (igual que <C-o> en Telescope; ver lua/configs/wt_open.lua)
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("neogit-wt-open", { clear = true }),
    pattern = "NeogitStatus",
    callback = function(args)
      vim.keymap.set("n", "<C-o>", function()
        require("configs.wt_open").neogit()
      end, { buffer = args.buf, desc = "Abrir archivo en nueva terminal" })
    end,
  })
end,
```

### Caja de texto para el commit (estilo chat)

El mensaje del commit no se escribe en un split con la plantilla de git a la vista, sino en una **caja flotante** chica, con título y una línea de ayuda abajo, como la caja de un chat:

```
╭ 󰜘 Mensaje del commit ──────────────────────────╮
│ Arreglar el login cuando falta el token        │
│                                                │
│   ▸ plantilla de git y archivos del commit     │
│                                                │
╰ Enter: commit · Shift+Enter / Ctrl+J: nueva … ─╯
```

| Tecla | Acción |
|---|---|
| `Enter` | **Hacer el commit** (como "enviar") |
| `Shift + Enter` o `Ctrl + j` | Nueva línea (para escribir un cuerpo debajo del título) |
| `Esc` `Esc` | **Cancelar**: el primer `Esc` pasa a modo normal y el segundo aborta el commit |
| `za` (en modo normal, sobre la línea plegada) | Ver u ocultar la plantilla de git (rama, archivos incluidos) |
| `Alt + p` / `Alt + n` | Mensaje anterior / siguiente del historial (de neogit) |

> [!tip] `Shift + Enter` vs `Ctrl + j`
> Algunas terminales no distinguen `Shift + Enter` de `Enter`. Si al pulsarlo se hace el commit en vez de bajar de línea, usá `Ctrl + j`, que siempre funciona.

Se hace en dos partes:

**1. Opciones de neogit** (en `lua/plugins/init.lua`, dentro de `opts` de neogit):

| Opción | Valor | Para qué |
|---|---|---|
| `commit_editor.kind` | `floating` | El editor se abre en una ventana flotante |
| `show_staged_diff` | `false` | No abre el diff al lado (en flotante no tiene lugar) |
| `spell_check` | `false` | Sin subrayado de ortografía en inglés sobre mensajes en español |
| `floating` | `width = 0.5`, `height = 10` | Caja de la mitad del ancho y 10 líneas de alto, con borde redondeado |
| `disable_insert_on_commit` | `false` | Siempre arranca en modo insertar, listo para escribir |
| `mappings.commit_editor_I` | `<cr> = "Submit"` | `Enter` en modo insertar hace el commit |
| `mappings.commit_editor` | `<cr> = "Submit"`, `<esc> = "Abort"` | En modo normal, `Enter` hace el commit y `Esc` lo cancela |

**2. Módulo `lua/configs/commit_box.lua`**

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\configs\commit_box.lua`

neogit no permite ponerle título a su ventana flotante, así que en el `config` de neogit un autocmd (`FileType gitcommit`) llama a `require("configs.commit_box").setup_window(buf)`, que:

- Agrega el **título** y la **línea de ayuda** en el borde (`nvim_win_set_config` con `title` / `footer`).
- Quita números, signos y `statuscolumn`, y activa el ajuste de línea (`wrap`).
- **Pliega la plantilla de git** (las líneas `# ...`) en una sola línea. No se borra porque neogit la usa para saber dónde termina el mensaje, y git la descarta al hacer el commit.
- Mapea `Shift + Enter` y `Ctrl + j` a "nueva línea" en ese buffer.

Solo actúa si el buffer `gitcommit` está en una **ventana flotante**, así que un `git commit` normal desde la terminal no se ve afectado.

Se probó en un repo de prueba: `Enter` crea el commit, `Ctrl + j` arma un mensaje con título y cuerpo, y `Esc Esc` cancela sin crear nada.

### Panel sin números de línea

El panel y las demás ventanas de neogit (log, commit, popups) se muestran **sin números de línea**, como el panel de VS Code.

> [!warning] Por qué no alcanza con `number = false`
> En `lua/options.lua` hay un `statuscolumn` propio que dibuja el número absoluto y el relativo **por su cuenta**, sin mirar la opción `number`. Por eso, para quitar los números, también hay que vaciar `statuscolumn`.

Esta config ya tenía en `lua/options.lua` una función `no_numbers()` para la terminal (chat de Claude), nvim-tree y nvdash. Se amplió para que también cubra los buffers cuyo filetype empieza con `Neogit`:

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\options.lua`

```lua
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
```

- Se aplica en `FileType` y en `BufWinEnter`. El panel se abre en un split, que **hereda** los números de la ventana de la que salió, y así sigue sin números al cerrarlo y volver a abrirlo.
- Para quitar los números de otra ventana más, agregar su filetype en `wants_no_numbers` (se ve con `:set ft?`).

Se probó en un repo de prueba: el panel y el log quedan con `number = false` y `statuscolumn` vacío. El archivo normal conserva sus números.

> [!note] `Ctrl + o` fuera del panel
> El atajo es **local al panel**. En los archivos normales, `Ctrl + o` sigue siendo "volver al salto anterior" de Vim.

Se probó en un repo de prueba. Sobre el nombre del archivo lo abre, y sobre una línea agregada del diff lo abre en la línea correcta.

### Instalación de los plugins

Se instalaron con lazy.nvim sin abrir la interfaz:

```bash
cd "C:/Users/diazt/AppData/Local/nvim"
nvim --headless "+Lazy! install" +qa
```

Quedan en:

```
C:\Users\diazt\AppData\Local\nvim-data\lazy\neogit
C:\Users\diazt\AppData\Local\nvim-data\lazy\diffview.nvim
```

Se probó en un repo de prueba que `:Neogit`, `:DiffviewOpen` y `:DiffviewClose` abren sin errores, y que el blame en línea queda activado.

---

## Atajos

### Generales (en cualquier archivo)

| Tecla | Acción |
|---|---|
| `<leader>gg` | Abrir / cerrar el panel **Source Control** (neogit) |
| `<leader>gc` | Hacer commit |
| `<leader>gP` | Push |
| `<leader>gl` | Pull |
| `<leader>gB` | Cambiar de rama (Telescope) |
| `<leader>gd` | Ver todos los cambios lado a lado (diffview) |
| `<leader>gq` | Cerrar diffview |
| `<leader>gh` | Historial del archivo actual (Timeline) |
| `<leader>gH` | Historial de todo el repo |
| `<leader>gt` | Estado de git en Telescope (de NvChad) |
| `<leader>cm` | Commits en Telescope (de NvChad) |

### Sobre el archivo abierto (gitsigns)

| Tecla | Acción |
|---|---|
| `]h` / `[h` | Ir al siguiente / anterior cambio |
| `<leader>gp` | Previsualizar el cambio bajo el cursor (popup con el diff) |
| `<leader>gs` | Stage del cambio bajo el cursor (en visual: solo las líneas elegidas) |
| `<leader>gr` | Descartar el cambio bajo el cursor (en visual: solo las líneas elegidas) |
| `<leader>gS` | Stage de todo el archivo |
| `<leader>gR` | Descartar todos los cambios del archivo |
| `<leader>gb` | Blame completo de la línea (popup con el commit entero) |
| `<leader>ga` | Blame de todo el archivo (columna a la izquierda) |
| `<leader>gx` | Mostrar / ocultar el blame en línea |

> [!warning] `<leader>gr` y `<leader>gR` borran cambios
> Igual que **Discard Changes** en VS Code: lo que se descarta no queda en git. Si fue sin querer, `u` lo deshace mientras el archivo siga abierto.

### Dentro del panel de neogit

| Tecla | Acción |
|---|---|
| `Tab` | Expandir / plegar un archivo para ver su diff ahí mismo |
| `s` | Stage del archivo o cambio bajo el cursor |
| `S` | Stage de todo |
| `u` | Unstage del archivo o cambio |
| `U` | Unstage de todo |
| `x` | Descartar el cambio |
| `Enter` | Abrir el archivo |
| `Ctrl + o` | Abrir el archivo en una **pestaña nueva de Windows Terminal** (en la línea del cambio si el cursor está sobre el diff) |
| `d` | Abrir el diff en diffview |
| `c` → `c` | Commit: se abre la caja de texto; `Enter` confirma, `Esc Esc` cancela |
| `c` → `a` | Amend (modificar el último commit) |
| `P` → `p` | Push a la rama remota |
| `p` → `p` | Pull |
| `b` | Menú de ramas (crear, cambiar, borrar) |
| `Z` | Stash |
| `l` → `l` | Log (historial con gráfico) |
| `?` | Ver **todos** los atajos del panel |
| `q` | Cerrar el panel |

> [!tip] Todo es un menú
> En neogit, las letras como `c`, `P`, `p`, `b` y `l` abren un menú con opciones (por ejemplo `--force` o `--rebase`). Si no te acordás de una, apretá la primera letra y mirá el menú.

### Dentro de diffview

| Tecla | Acción |
|---|---|
| `Tab` / `Shift + Tab` | Siguiente / anterior archivo |
| `-` | Stage / unstage del archivo (en la lista de la izquierda) |
| `<leader>e` | Ir a la lista de archivos (`<leader>b` la muestra u oculta) |
| `]x` / `[x` | Siguiente / anterior conflicto (en un merge) |
| `<leader>co` | Quedarse con **tu versión** (ours) |
| `<leader>ct` | Quedarse con la versión **entrante** (theirs) |
| `<leader>ca` | Quedarse con **ambas** |
| `<leader>cb` | Quedarse con la versión **base** (antes de los dos cambios) |
| `<leader>cO` / `<leader>cT` / `<leader>cA` | Lo mismo, pero para **todo el archivo** |
| `dx` | Borrar el bloque de conflicto |
| `g?` | Ver todos los atajos |

> [!note] `<leader>e` y `<leader>cb` dentro de diffview
> Dentro de diffview, `<leader>e` es de diffview y no abre nvim-tree. `<leader>cb`, `<leader>ca` y `<leader>cd` también son de diffview, no los atajos de Claude Code. Fuera de diffview funcionan como siempre.

---

## Flujo típico (como en VS Code)

1. Editar archivos. Las barras de color aparecen solas al lado de los números.
2. `<leader>gg` → se abre el panel con los cambios.
3. `Tab` sobre un archivo para ver qué cambió, o `d` para verlo lado a lado.
4. `s` en cada archivo que se quiera incluir (o `S` para todo).
5. `c` `c` → escribir el mensaje en la caja → `Enter`.
6. `P` `p` para subirlo.

### Resolver un conflicto de merge

1. Después de un `pull` o `merge` con conflictos, `<leader>gd`.
2. Elegir el archivo en conflicto. Arriba se ven las dos versiones y abajo el resultado.
3. `]x` para ir a cada conflicto y elegir con `<leader>co`, `<leader>ct` o `<leader>ca`.
4. Guardar (`Ctrl + s`), `-` para marcarlo como resuelto, `<leader>gq` para cerrar.
5. Commit desde neogit.

---

## Personalización

- **Panel en otra pestaña en vez de a la izquierda:** cambiar `kind = "tab"` (o `"floating"` para una ventana flotante).
- **Blame en línea apagado por defecto:** `current_line_blame = false`. Igual se puede prender con `<leader>gx`.
- **Formato del blame:** editar `current_line_blame_formatter`. Variables: `<author>`, `<author_time:%d/%m/%Y>`, `<summary>`, `<abbrev_sha>`.
- **Conflictos en dos columnas en vez de tres:** `merge_tool = { layout = "diff3_horizontal" }`.
- **Desinstalar:** borrar los bloques `NeogitOrg/neogit` y `sindrets/diffview.nvim` de `lua/plugins/init.lua` y ejecutar `:Lazy clean`. Para gitsigns, borrar solo su bloque: vuelve a la config original de NvChad (no se desinstala, porque viene con NvChad).

Ver también: [[Comandos y atajos de NvChad]] · [[Explorador de archivos estilo VS Code]]
