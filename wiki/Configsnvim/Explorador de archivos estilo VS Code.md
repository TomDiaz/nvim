---
tags: [nvim, nvchad, plugins, nvim-tree, explorador, estetica]
fecha: 2026-11-11
---

# Explorador de archivos estilo VS Code

El árbol de archivos de NvChad (**nvim-tree**) se configuró para que se parezca al panel EXPLORER de Visual Studio Code: título del proyecto en mayúsculas, flechas en las carpetas, guías de indentación, carpetas compactas y estado de git con letras a la derecha.

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11

---

## Cómo se ve

```
 NVIM
 ├  lua
 │  ├  configs
 │  │   lazy.lua
 │  └  plugins/init.lua
 ├  wiki
   init.lua                     M
   lazy-lock.json
```

| Parecido con VS Code | Cómo se logra |
|---|---|
| Título `NOMBRE-DEL-PROYECTO` arriba | `renderer.root_folder_label` |
| Flechas `` / `` en las carpetas | `icons.show.folder_arrow` + `glyphs.folder.arrow_*` |
| Guías verticales de indentación | `renderer.indent_markers` |
| *Compact folders* (`src/foo/bar` en una línea) | `renderer.group_empty` |
| Archivo coloreado según git (amarillo = modificado, verde = nuevo) | `renderer.highlight_git = "name"` |
| Letras `M` `U` `A` `D` alineadas a la derecha | `icons.git_placement = "right_align"` |
| Archivo en rojo / amarillo si tiene errores / warnings | `diagnostics` + `highlight_diagnostics` |
| `●` en archivos sin guardar | `modified` |
| Se resalta el archivo que está abierto | `update_focused_file` |
| Carpetas en blanco, no en azul | `hl_override` en `chadrc.lua` |

---

## Cambios realizados

### `lua/plugins/init.lua`

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\plugins\init.lua`

Se agregó este bloque en la tabla de plugins, antes del comentario `-- test new blink`. NvChad ya trae nvim-tree; lazy.nvim **combina** estas `opts` con las de NvChad, así que solo hace falta poner lo que se cambia.

```lua
-- Explorador de archivos estilo VS Code
{
  "nvim-tree/nvim-tree.lua",
  opts = {
    view = {
      width = 32,
      side = "left",
      signcolumn = "no",
    },
    filters = {
      dotfiles = false,
      git_ignored = false,
      custom = { "^\\.git$" },
    },
    git = { enable = true },
    diagnostics = {
      enable = true,
      show_on_dirs = true,
      icons = { hint = "", info = "", warning = "", error = "" },
    },
    modified = { enable = true, show_on_dirs = true },
    update_focused_file = { enable = true }, -- resalta el archivo activo
    renderer = {
      -- título "NOMBRE-DEL-PROYECTO" en mayúsculas, como el EXPLORER de VS Code
      root_folder_label = function(path)
        return " " .. vim.fn.fnamemodify(path, ":t"):upper()
      end,
      group_empty = true, -- "compact folders": src/foo/bar en una línea
      indent_width = 2,
      indent_markers = {
        enable = true, -- guías de indentación verticales
        inline_arrows = true,
        icons = { corner = "│", edge = "│", item = "│", bottom = " ", none = " " },
      },
      highlight_git = "name",          -- archivo coloreado según estado git
      highlight_diagnostics = "name",  -- archivo coloreado si tiene errores
      highlight_opened_files = "none",
      highlight_modified = "name",
      icons = {
        git_placement = "right_align", -- letras M/U/D a la derecha, como VS Code
        modified_placement = "right_align",
        diagnostics_placement = "right_align",
        padding = " ",
        show = {
          file = true,
          folder = true,
          folder_arrow = true,
          git = true,
          modified = true,
          diagnostics = false,
        },
        glyphs = {
          modified = "●",
          folder = {
            arrow_closed = "",
            arrow_open = "",
            default = "",
            open = "",
            empty = "",
            empty_open = "",
            symlink = "",
            symlink_open = "",
          },
          git = {
            unstaged = "M",
            staged = "A",
            unmerged = "!",
            renamed = "R",
            untracked = "U",
            deleted = "D",
            ignored = "",
          },
        },
      },
    },
  },
},
```

Qué hace cada parte:

| Opción | Valor | Para qué |
|---|---|---|
| `view.width` | `32` | Ancho del panel en columnas |
| `view.side` | `"left"` | Panel a la izquierda (`"right"` para el otro lado) |
| `view.signcolumn` | `"no"` | Quita la columna de signos para que quede más limpio |
| `filters.dotfiles` | `false` | Muestra los archivos que empiezan con `.` |
| `filters.git_ignored` | `false` | Muestra lo que está en `.gitignore` (VS Code lo muestra en gris) |
| `filters.custom` | `{ "^\\.git$" }` | Oculta la carpeta `.git`, igual que VS Code |
| `git.enable` | `true` | Lee el estado de git de cada archivo |
| `diagnostics.enable` | `true` | Usa los errores / warnings del LSP |
| `diagnostics.show_on_dirs` | `true` | La carpeta también se marca si un archivo de adentro tiene errores |
| `modified.enable` | `true` | Marca los archivos con cambios sin guardar |
| `update_focused_file.enable` | `true` | Al cambiar de buffer, el árbol salta al archivo y lo resalta |
| `root_folder_label` | función | Muestra solo el nombre de la carpeta raíz, en mayúsculas |
| `group_empty` | `true` | Carpetas que solo contienen otra carpeta se ven en una sola línea |
| `indent_width` | `2` | Sangría de cada nivel |
| `indent_markers.enable` | `true` | Dibuja las guías verticales `│` |
| `indent_markers.inline_arrows` | `true` | Las flechas de carpeta quedan sobre la guía, sin columna extra |
| `highlight_git` | `"name"` | Colorea el **nombre** del archivo según git |
| `highlight_diagnostics` | `"name"` | Colorea el nombre si tiene errores / warnings |
| `highlight_opened_files` | `"none"` | No marca los archivos abiertos en otros buffers (VS Code no lo hace) |
| `highlight_modified` | `"name"` | Colorea el nombre si tiene cambios sin guardar |
| `git_placement` | `"right_align"` | La letra de git (`M`, `U`…) va pegada al borde derecho |
| `modified_placement` | `"right_align"` | El `●` también a la derecha |
| `show.diagnostics` | `false` | Sin íconos de error en el árbol: solo el color del nombre, como VS Code |
| `glyphs.git` | letras | Reemplaza los íconos de git por las letras que usa VS Code |

Significado de las letras de git:

| Letra | Estado |
|---|---|
| `M` | Modificado, sin agregar al stage |
| `A` | Agregado al stage |
| `U` | Nuevo, git todavía no lo sigue (*untracked*) |
| `D` | Borrado |
| `R` | Renombrado |
| `!` | Conflicto de merge |

### `lua/chadrc.lua`

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\chadrc.lua`

Se agregaron estos colores dentro de `M.base46.hl_override`, debajo de la línea `Cursor`:

```lua
-- nvim-tree estilo VS Code
NvimTreeIndentMarker = { fg = "one_bg3" },
NvimTreeRootFolder = { fg = "white", bold = true },
NvimTreeFolderName = { fg = "white" },
NvimTreeOpenedFolderName = { fg = "white" },
NvimTreeEmptyFolderName = { fg = "white" },
NvimTreeFolderArrowClosed = { fg = "light_grey" },
NvimTreeFolderArrowOpen = { fg = "light_grey" },
NvimTreeGitDirtyIcon = { fg = "yellow" },
NvimTreeGitNewIcon = { fg = "green" },
NvimTreeGitDeletedIcon = { fg = "red" },
NvimTreeModifiedIcon = { fg = "white" },
-- el fondo del explorador queda transparente (transparency = true) para que
-- se vea el acrílico #1B1F27 de Windows Terminal; solo la línea seleccionada es sólida
NvimTreeCursorLine = { bg = "one_bg" },
-- fondo sólido solo para el listado de archivos
NvimTreeNormal = { bg = "#1b1f27" },
NvimTreeNormalNC = { bg = "#1b1f27" },
NvimTreeEndOfBuffer = { bg = "#1b1f27" },
```

| Grupo | Color | Para qué |
|---|---|---|
| `NvimTreeIndentMarker` | `one_bg3` | Guías de indentación grises y tenues |
| `NvimTreeRootFolder` | `white`, negrita | Título del proyecto |
| `NvimTreeFolderName` / `Opened` / `Empty` | `white` | Carpetas en blanco (NvChad las pone en azul) |
| `NvimTreeFolderArrowClosed` / `Open` | `light_grey` | Flechas en gris |
| `NvimTreeGitDirtyIcon` | `yellow` | Letra `M` en amarillo |
| `NvimTreeGitNewIcon` | `green` | Letra `U` / `A` en verde |
| `NvimTreeGitDeletedIcon` | `red` | Letra `D` en rojo |
| `NvimTreeModifiedIcon` | `white` | El `●` de sin guardar |
| `NvimTreeCursorLine` | fondo `one_bg` | Línea seleccionada sólida, visible sobre el fondo desenfocado |

### `lua/autocmds.lua` — ancho fijo aunque no haya archivo abierto

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\autocmds.lua`

Antes, si el árbol quedaba como única ventana (por ejemplo, al cerrar el último split), ocupaba toda la pantalla. Ahora un autocmd (`NvimTreeKeepWidth`) lo detecta, abre un buffer vacío a la derecha (`botright vnew`) y devuelve el árbol a `TREE_WIDTH = 32` columnas, como el editor vacío de VS Code.

- Si se cambia `view.width`, cambiar también `TREE_WIDTH` en `autocmds.lua`.
- `:q` en el último archivo cierra también el árbol, así que Neovim se cierra normalmente.

---

## Fondo `#1B1F27` con blur (acrílico)

El fondo del explorador (y del editor) es **`#1B1F27` semitransparente y desenfocado**. Neovim no puede hacer blur por sí mismo: el desenfoque lo hace **Windows Terminal** con su efecto acrílico, y solo se ve en las zonas donde Neovim no pinta un fondo propio. Por eso:

- En `chadrc.lua` se deja `transparency = true`: el editor queda transparente y muestra el acrílico.
- El explorador, en cambio, tiene fondo sólido `#1b1f27` (`NvimTreeNormal`, `NvimTreeNormalNC`, `NvimTreeEndOfBuffer`), así que ahí no hay blur. Para volver a tenerlo transparente, borrar esas tres líneas.
- El color `#1B1F27`, la opacidad y el blur se configuran en Windows Terminal.

### `settings.json` de Windows Terminal

**Path completo:** `C:\Users\diazt\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`

Se cambió `"defaults": {}` dentro de `profiles` por:

```json
"defaults":
{
    "background": "#1B1F27",
    "opacity": 80,
    "useAcrylic": true
},
```

| Opción | Valor | Para qué |
|---|---|---|
| `background` | `"#1B1F27"` | Color de fondo (el tinte del acrílico) |
| `opacity` | `80` | Opacidad en % (`100` = sólido, más bajo = más transparente) |
| `useAcrylic` | `true` | Desenfoca lo que hay detrás de la ventana |

Se guardó una copia del archivo original en `settings.json.bak-2026-11-11`, en la misma carpeta.

> [!note] Afecta a todos los perfiles
> Al estar en `defaults`, el fondo y el blur se aplican a **todas** las pestañas (PowerShell, cmd, Ubuntu…). Para que sea solo en un perfil, mover las tres opciones dentro de ese perfil en `list` y dejar `"defaults": {}`.

> [!tip] Ajustes
> - **Más blur / más transparente:** bajar `opacity` (por ejemplo `65`).
> - **Más sólido:** subir `opacity` (por ejemplo `90`).
> - **Explorador opaco sin blur:** en `chadrc.lua`, agregar `NvimTreeNormal = { bg = "#1b1f27" }` y `NvimTreeNormalNC = { bg = "#1b1f27" }`. Las zonas con fondo propio no se desenfocan.

> [!info] Nombres de colores
> `white`, `one_bg3`, `light_grey`, etc. son colores del tema de NvChad (base46), no colores fijos. Si se cambia de tema, se adaptan solos. También se puede poner un hex, por ejemplo `{ fg = "#cccccc" }`.

---

## Aplicar los cambios

1. **Reiniciar Neovim.**
2. Abrir el árbol con `Ctrl + n` (o `<leader>e` para enfocarlo).
3. Si los colores de `chadrc.lua` no cambiaron, NvChad los tiene cacheados. Ejecutar:

```vim
:lua require("base46").load_all_highlights()
```

> [!important] Caché de base46
> NvChad compila los colores en `C:\Users\diazt\AppData\Local\nvim-data\base46\` y solo recompila al guardar `chadrc.lua` **desde Neovim**. Si se edita desde fuera (otro editor, Claude Code), reiniciar no alcanza: hay que ejecutar el comando de arriba, o desde la terminal:
> ```powershell
> nvim --headless "+lua require('base46').compile()" +qa
> ```

> [!warning] Nerd Font
> Las flechas y los íconos de carpeta necesitan una **Nerd Font** configurada en la terminal. Si se ven cuadrados o `?`, falta la fuente.

---

## Atajos dentro del árbol

| Tecla | Acción |
|---|---|
| `Ctrl + n` | Abrir / cerrar el árbol |
| `<leader>e` | Enfocar el árbol |
| `Enter` / `o` | Abrir archivo o desplegar carpeta |
| `Ctrl + v` / `Ctrl + x` | Abrir en split vertical / horizontal |
| `a` | Crear archivo (terminar con `/` para crear carpeta) |
| `r` | Renombrar |
| `d` | Borrar |
| `x` / `c` / `p` | Cortar / copiar / pegar |
| `H` | Mostrar / ocultar dotfiles |
| `I` | Mostrar / ocultar archivos de `.gitignore` |
| `R` | Refrescar |
| `W` | Colapsar todas las carpetas |
| `g?` | Ver todos los atajos |

---

## Personalización

- **Ocultar `bin/` y `obj/` de .NET** (como `files.exclude` de VS Code): agregarlos a `filters.custom`:
  ```lua
  custom = { "^\\.git$", "^bin$", "^obj$" },
  ```
- **Panel a la derecha:** `view.side = "right"`.
- **Más ancho:** subir `view.width` (por ejemplo `40`).
- **Sin carpetas compactas:** `group_empty = false`.
- **Sin guías de indentación:** `indent_markers.enable = false`.
- **Cerrar el árbol al abrir un archivo:** agregar `actions = { open_file = { quit_on_open = true } }`.
- **Ver todas las opciones:** `:help nvim-tree-opts`. Los valores por defecto de NvChad están en `C:\Users\diazt\AppData\Local\nvim-data\lazy\NvChad\lua\nvchad\configs\nvimtree.lua`.

Ver también: [[Comandos y atajos de NvChad]] · [[Cursor animado con smear-cursor]]
