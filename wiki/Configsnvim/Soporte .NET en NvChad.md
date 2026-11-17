---
tags: [nvim, nvchad, dotnet, csharp]
fecha: 2026-11-11
---

# Soporte .NET en NvChad

Configuración de Neovim (NvChad v2.5) para trabajar con C# / .NET.

**Entorno:** .NET SDK 10.0.301 · Neovim 0.12.5 · Windows 11

---

## Diagnóstico inicial

La configuración era prácticamente el starter de NvChad sin tocar: no tenía nada para C#/.NET. En Mason solo estaba instalado `stylua`.

| Pieza | Para qué | Estado inicial |
|---|---|---|
| **LSP de C#** | Autocompletado, ir a definición, diagnósticos, refactors | `lspconfig.lua` solo activaba `html` y `cssls` |
| **Treesitter `c_sharp`** | Resaltado e indentación | El bloque de treesitter estaba comentado |
| **Formateador** | Formatear `.cs` | `conform.lua` solo tenía `lua` |
| **Debugger** (opcional) | Breakpoints y depuración | No había `nvim-dap` |
| **Tests** (opcional) | Ejecutar tests de xUnit/NUnit/MSTest | Nada |

## Opciones de LSP

- **Roslyn** con el plugin `seblyng/roslyn.nvim`** ← *elegida*. Es el mismo servidor que usa VS Code (C# Dev Kit), el más completo y el más rápido en soluciones grandes.
- **`csharp_ls`** (`dotnet tool install -g csharp-ls`). Se activa con una línea: `vim.lsp.enable({ "html", "cssls", "csharp_ls" })`. Más simple, con menos funciones.
- **OmniSharp**: prácticamente abandonado, no recomendado.

Otras piezas opcionales que no se instalaron:

- **Tests:** `nvim-neotest/neotest` + adaptador `Issafalcon/neotest-dotnet`.

---

## Cambios realizados

### `lua/plugins/init.lua`

- Añadido `seblyng/roslyn.nvim` (carga en `ft = cs, razor`), con `nvim-lspconfig` como dependencia para que se apliquen las capabilities y los mappings de NvChad.
- Añadido a Mason el registro extra `github:Crashdummyy/mason-registry`, porque el servidor de Roslyn no está en el oficial.
- Añadido el debugger: `mfussenegger/nvim-dap`, `rcarriga/nvim-dap-ui` y `nvim-neotest/nvim-nio`.
- Activado treesitter con los parsers `c_sharp`, `xml`, `json` y `razor`, además de los que ya traía NvChad.

```lua
{
  "mason-org/mason.nvim",
  opts = {
    registries = {
      "github:mason-org/mason-registry",
      "github:Crashdummyy/mason-registry",
    },
  },
},

{
  "seblyng/roslyn.nvim",
  ft = { "cs", "razor" },
  dependencies = { "neovim/nvim-lspconfig" },
  opts = {},
},
```

### `lua/configs/dap.lua` (nuevo)

Configura el adaptador `coreclr` con `netcoredbg` (instalado por Mason) y abre/cierra `dap-ui` automáticamente. Tiene dos configuraciones:

- **Launch**: busca solo `bin/Debug/*/<Proyecto>.dll` y, si no lo encuentra, pide la ruta.
- **Attach**: permite elegir un proceso que ya esté corriendo.

### `lua/configs/conform.lua`

```lua
cs = { "csharpier" },
```

### Mason

Instalados: `roslyn`, `csharpier` y `netcoredbg`.

```vim
:MasonInstall roslyn csharpier netcoredbg
```

---

## Atajos del debugger

| Tecla | Acción |
|---|---|
| `F5` | Iniciar / continuar |
| `F10` | Saltar línea (step over) |
| `F11` | Entrar en la función (step into) |
| `F12` | Salir de la función (step out) |
| `<leader>db` | Poner o quitar breakpoint |
| `<leader>du` | Mostrar u ocultar el panel del debugger |
| `<leader>dr` | Abrir o cerrar la REPL |
| `<leader>dt` | Detener la sesión |

> [!warning] Compilar antes de depurar
> Antes de depurar con `F5` hay que compilar con `dotnet build`. La configuración no compila el proyecto automáticamente.

---

## Verificación

Probado abriendo un `.cs` en un proyecto de consola de prueba (`dotnet new console`):

- ✅ El LSP **Roslyn** se conecta al buffer.
- ✅ **CSharpier** formatea correctamente:
  ```csharp
  // antes
  class   A{void M( ){int x=1;}}
  // después
  class A
  {
      void M()
      {
          int x = 1;
      }
  }
  ```
- ✅ `nvim-dap` carga sin errores.
- ❌ El resaltado con treesitter **no funciona todavía** (ver abajo).

---

## Pendiente: treesitter

> [!important] No hay parsers de treesitter instalados
> No hay ningún parser instalado, ni siquiera los que NvChad trae por defecto. La versión de `nvim-treesitter` instalada (rama `main`) compila los parsers en local, y para eso necesita el **`tree-sitter` CLI** y un **compilador de C**. Ninguno de los dos está en el PATH, así que de momento no hay resaltado de sintaxis.

Para arreglarlo:

```powershell
npm install -g --allow-scripts=tree-sitter-cli tree-sitter-cli
winget install zig.zig        # o LLVM/MinGW, cualquier compilador de C
```

> [!note] npm 11 y `--allow-scripts`
> npm 11 no ejecuta por defecto los scripts de instalación de los paquetes. `tree-sitter-cli` descarga su ejecutable en ese script, así que con un `npm install -g tree-sitter-cli` normal el paquete se instala pero queda sin el programa (aparece el aviso `allow-scripts`). Por eso hay que añadir `--allow-scripts=tree-sitter-cli`. Comprobar con `tree-sitter --version` (instalado: 0.27.2).

Después abrir Neovim y ejecutar:

```vim
:TSInstallAll
```

---

## Notas

- En el primer `.cs` que se abre, Roslyn tarda unos segundos en cargar la solución. Si en la carpeta hay varios `.sln`, `roslyn.nvim` pide elegir uno con `:Roslyn target`.
- El formateo automático al guardar sigue **desactivado**. Para activarlo, descomentar `event = 'BufWritePre'` en `plugins/init.lua` y `format_on_save` en `conform.lua`.
- Al instalar los plugins nuevos se actualizó también `lazy-lock.json`.
