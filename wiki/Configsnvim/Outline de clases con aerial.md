---
tags: [nvim, nvchad, lsp, outline, dotnet]
fecha: 2026-11-17
---

# Outline de clases con aerial

Ver el resumen de una clase (campos, propiedades, constructores y métodos) en un panel lateral, como el "Outline" de VS Code o el "File Structure" de Rider.

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11 · LSP de C#: `roslyn.nvim` (ver [[Soporte .NET en NvChad]])

---

## Cómo funciona

El servidor de lenguaje ya sabe qué hay dentro de cada archivo. Neovim se lo pide con el método LSP `textDocument/documentSymbol`, y el servidor responde con un árbol de símbolos: cada uno trae nombre, tipo (`Class`, `Method`, `Property`…), posición y sus hijos.

1. Abres un `.cs` y Roslyn se conecta al buffer.
2. aerial le pide a Roslyn los símbolos del archivo.
3. aerial dibuja ese árbol en un panel.
4. Mientras mueves el cursor en el código, aerial resalta el miembro donde estás.
5. Al editar o guardar, el árbol se vuelve a pedir y se actualiza solo.

Neovim ya trae `gO`, que muestra lo mismo en la location list, pero como lista plana y sin seguir el cursor. aerial agrega el árbol, los íconos y la navegación.

---

## Qué se eligió y por qué

Se usa **`stevearc/aerial.nvim`**:

- Usa el LSP (Roslyn) como fuente y cae a treesitter si el archivo no tiene LSP.
- Trae dos vistas: panel lateral y ventana flotante de navegación.
- Se integra con Telescope, que ya está en NvChad.

El panel se abre a la **izquierda** porque el lado derecho ya lo usan nvim-tree (ver [[Explorador de archivos estilo VS Code]]) y el panel de Claude (ver [[Claude Code en NvChad]]).

---

## Cómo se ve

```
┌─ aerial ──────────────────────────┬─ WorkflowEngine.cs ─────────────────────────────────┐
│ 󰠱 WorkflowEngine                  │ 12  public class WorkflowEngine : IWorkflowEngine   │
│ ├─ 󰜢 _repository                   │ 13  {                                               │
│ ├─ 󰜢 _notifier                     │ 14      private readonly IRepository _repository;   │
│ ├─  WorkflowEngine(…)             │ 15      private readonly INotifier _notifier;       │
│ ├─  Status                        │ ..                                                  │
│ ├─ 󰆧 Engage(…)              ◀──── │ 30      public async Task Engage(…)  ← cursor aquí  │
│ ├─ 󰆧 Abandon(…)                    │ 31      {                                           │
│ ├─ 󰆧 Loop(…)                       │ ..                                                  │
│ └─ 󰠱 StepResult                    │                                                     │
│    ├─  Code                       │                                                     │
│    └─  Detail                     │                                                     │
└───────────────────────────────────┴─────────────────────────────────────────────────────┘
```

| Ícono | Tipo |
|---|---|
| 󰠱 | Clase |
| 󰜢 | Campo |
|  | Propiedad |
|  | Constructor |
| 󰆧 | Método |

Las clases anidadas aparecen como subárbol. Los íconos necesitan una Nerd Font en la terminal.

---

## Cambios realizados

### `lua/plugins/init.lua`

**Path completo:** `C:\Users\TomasDiaz\AppData\Local\nvim\lua\plugins\init.lua`

Se agregó este bloque en la tabla de plugins, antes del comentario `-- test new blink`:

```lua
-- Outline: árbol de la clase (campos, propiedades, métodos) vía LSP documentSymbol
-- (a la izquierda: la derecha ya la usan nvim-tree y el panel de Claude)
{
  "stevearc/aerial.nvim",
  cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  opts = {
    backends = { "lsp", "treesitter" }, -- roslyn primero; treesitter si no hay LSP
    layout = {
      default_direction = "left",
      placement = "edge",
      min_width = 30,
      max_width = { 50, 0.25 },
    },
    attach_mode = "global", -- el panel sigue al buffer activo
    filter_kind = {
      "Class", "Constructor", "Enum", "Field", "Function",
      "Interface", "Method", "Module", "Property", "Struct",
    },
    show_guides = true,
    highlight_on_hover = true,
    close_on_select = false,
    nav = { preview = true },
  },
  keys = {
    { "<leader>o", "<cmd>AerialToggle<cr>", desc = "Outline: árbol de la clase (panel)" },
    { "<leader>O", "<cmd>AerialNavToggle<cr>", desc = "Outline: navegación flotante" },
    {
      "<leader>fs",
      function()
        require("telescope.builtin").lsp_document_symbols {
          symbols = { "class", "constructor", "field", "property", "method", "interface", "enum" },
        }
      end,
      desc = "Telescope: miembros del archivo",
    },
  },
},
```

Qué hace cada parte:

| Opción | Valor | Para qué |
|---|---|---|
| `cmd` / `keys` | comandos y atajos | Carga diferida: el plugin se carga la primera vez que se usa |
| `backends` | `{ "lsp", "treesitter" }` | Pide los símbolos a Roslyn; si no hay LSP, los saca del árbol de treesitter |
| `default_direction` | `"left"` | El panel se abre a la izquierda |
| `placement` | `"edge"` | Pegado al borde de la pantalla, no al lado de la ventana actual |
| `max_width` | `{ 50, 0.25 }` | Como máximo 50 columnas o el 25% del ancho, lo que sea menor |
| `attach_mode` | `"global"` | Un solo panel que muestra el archivo activo; al cambiar de buffer se actualiza |
| `filter_kind` | lista de tipos | Solo tipos y miembros; oculta variables locales, constantes sueltas, etc. |
| `show_guides` | `true` | Dibuja las líneas `├─ └─` del árbol |
| `highlight_on_hover` | `true` | Al pasar por un símbolo en el panel se resalta su código |
| `close_on_select` | `false` | El panel queda abierto después de saltar a un símbolo |
| `nav.preview` | `true` | La ventana flotante muestra el código del símbolo seleccionado |

#### Colores de la firma

Roslyn manda cada miembro como `Nombre(TipoParam, ...) : TipoRetorno` (los campos y propiedades como `_campo : Tipo`); no incluye el nombre de los parámetros. El `init` del plugin agrega, en la ventana del panel (`FileType aerial`), tres `matchadd` que le ganan al color del nombre que pone aerial:

| Grupo | Qué pinta | Link por defecto |
|---|---|---|
| `AerialParams` | Tipos de los parámetros, dentro de `( )` | `@variable.parameter` |
| `AerialReturnType` | Lo que va después de ` : ` (tipo de retorno, o tipo del campo/propiedad) | `@type` |
| `AerialSignaturePunct` | `(`, `)` y `:` | `Comment` |

Se definen con `default = true`, así que para cambiar un color basta con `vim.api.nvim_set_hl(0, "AerialParams", { fg = "#..." })` en la config propia.

Los `matchadd` se aplican al panel (`aerial`) y a la ventana flotante (`aerial-nav`). El flotante pone el filetype antes de abrir sus ventanas, así que el autocmd (`FileType` + `BufWinEnter`) los agrega con `vim.schedule` y por id a cada ventana que muestra el buffer. `BufWinEnter` cubre también el panel que se cierra y se vuelve a abrir con el mismo buffer.

#### Nombres largos

El panel (`layout.win_opts`) y el flotante (`nav.win_opts`) usan `wrap`, `linebreak`, `breakindent` y `breakindentopt = "shift:2"`: la firma baja de línea, cortando en palabra y con la continuación sangrada.

### `lua/configs/aerial_symbols.lua`

**Path completo:** `C:\Users\TomasDiaz\AppData\Local\nvim\lua\configs\aerial_symbols.lua`

El buscador de `<leader>fs` (Telescope `lsp_document_symbols`) con los mismos cambios que el panel:

- **Colores de la firma:** un `entry_maker` propio pinta con `AerialParams`, `AerialReturnType` y `AerialSignaturePunct` las mismas partes que el panel.
- **Nombres largos:** el tipo de símbolo va en una columna fija a la izquierda y el nombre en la columna final sin ancho fijo, así no se corta con `…`. Con `wrap_results = true` las firmas largas bajan de línea.

Se usa desde `<leader>fs` y desde `/` dentro del panel.

#### Buscador en el panel

En `keymaps` de aerial, `/` pasa a la ventana del código que muestra el panel (`aerial.util.get_source_win()`) y abre ese buscador. Al elegir un miembro salta al código, y el panel resalta el símbolo porque sigue el cursor. Reemplaza la búsqueda nativa de Vim dentro del panel.

### Instalación del plugin

```bash
cd "C:/Users/TomasDiaz/AppData/Local/nvim"
nvim --headless "+Lazy! install" +qa
```

El plugin queda en `C:\Users\TomasDiaz\AppData\Local\nvim-data\lazy\aerial.nvim`.

---

## Atajos

`<leader>` en NvChad es la **barra espaciadora**.

| Atajo | Comando | Qué hace |
|---|---|---|
| `<leader>o` | `:AerialToggle` | Abre o cierra el panel con el árbol de la clase |
| `<leader>O` | `:AerialNavToggle` | Ventana flotante con columnas (padre, actual, hijos) y vista previa |
| `<leader>fs` | Telescope `lsp_document_symbols` | Lista de miembros con búsqueda difusa |

**Choques con NvChad:** ninguno. NvChad no usa `<leader>o`, `<leader>O` ni `<leader>fs`.

### Dentro del panel

| Tecla | Acción |
|---|---|
| `Enter` | Saltar al símbolo |
| `p` | Previsualizar el símbolo sin salir del panel |
| `o` / `za` | Plegar o desplegar el nodo |
| `zM` / `zR` | Plegar / desplegar todo |
| `{` / `}` | Símbolo anterior / siguiente |
| `/` | Buscar entre los miembros del archivo (Telescope) |
| `q` | Cerrar el panel |
| `g?` | Ver todos los atajos del panel |

### Dentro de la ventana flotante (`<leader>O`)

| Tecla | Acción |
|---|---|
| `h` / `l` | Ir al nivel padre / entrar en los hijos |
| `j` / `k` | Símbolo siguiente / anterior |
| `Enter` | Saltar al símbolo y cerrar |
| `Ctrl + v` / `Ctrl + s` | Saltar al símbolo en una división vertical / horizontal |
| `Ctrl + c` | Cerrar |

---

## Clases de otro archivo o de una librería

- `gd` sobre el tipo para ir a su definición, y desde ahí `<leader>o`. Con `attach_mode = "global"`, el panel abierto se actualiza solo.
- Para tipos de NuGet o del framework, Roslyn abre los metadatos o el código decompilado en un buffer, y aerial funciona igual sobre ese buffer.
- Truco rápido: escribir `obj.` muestra en el autocompletado todos los miembros accesibles, incluidos los heredados.
- Para buscar un símbolo en todo el proyecto: `:Telescope lsp_dynamic_workspace_symbols`.

---

## Verificación

Se abrió `CommonSchemaFields.cs` (Workflow.Coordinator.Application) en modo headless: aerial se conectó con el backend `lsp` (Roslyn) y listó 29 símbolos.

Con `ActivityTools.cs` (27 símbolos), también headless:

- Panel y flotante con `wrap = true` y los tres `matchadd` en cada ventana.
- `/` desde el panel abre Telescope con 26 miembros, `wrap = true` y los grupos `AerialParams`, `AerialReturnType` y `AerialSignaturePunct` en los resultados.

Para comprobarlo a mano:

```vim
:AerialInfo          " muestra el backend en uso y los símbolos filtrados
:checkhealth aerial
```

---

## Problemas comunes

- **El panel aparece vacío:** Roslyn todavía está cargando la solución. Espera unos segundos o revisa `:checkhealth vim.lsp`.
- **Muestra pocos símbolos o sin íconos de tipo:** está usando treesitter en lugar del LSP. `:AerialInfo` muestra el backend activo.
- **Los íconos se ven como cuadrados:** la terminal no usa una Nerd Font. Se puede pasar `icons = {}` en `opts` para mostrar el tipo como texto.
- **Falta algún tipo de símbolo:** agrégalo a `filter_kind` (por ejemplo `"Variable"`, `"Constant"`, `"Event"`), o pon `filter_kind = false` para ver todo.
