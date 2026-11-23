---
tags: [nvim, nvchad, dotnet, csharp, solucion]
fecha: 2026-11-11
---

# Gestión de soluciones .NET en NvChad

Abrir y manejar soluciones de .NET (`.sln` / `.slnx`) desde Neovim: elegir la solución, compilar, ejecutar, pasar tests y gestionar NuGet sin salir del editor.

Esta página continúa [[Soporte .NET en NvChad]], donde se configuraron el LSP (Roslyn), treesitter y el debugger.

**Entorno:** .NET SDK 11.0.100 · Neovim 0.12.5 · NvChad v2.5 · Windows 11

---

## Qué se eligió y por qué

El trabajo se reparte entre tres piezas. Cada una hace una cosa:

| Pieza | Plugin | Para qué | Estado |
|---|---|---|---|
| **LSP** | `seblyng/roslyn.nvim` | Autocompletado, ir a definición, diagnósticos, refactors. Carga la solución al abrir un `.cs` | Ya estaba instalado |
| **Gestión de la solución** | `GustavEikaas/easy-dotnet.nvim` | Elegir la solución, build, run, tests, NuGet y referencias entre proyectos | **Nuevo** |
| **Debugger** | `mfussenegger/nvim-dap` + `netcoredbg` | Breakpoints y depuración | Ya estaba instalado |

> [!warning] Un solo servidor Roslyn
> easy-dotnet trae su propio LSP de Roslyn, **activado por defecto** (`lsp.enabled = true`). Como el LSP ya lo da `roslyn.nvim`, en easy-dotnet se desactivó con `lsp = { enabled = false }`. Si no, habría **dos servidores Roslyn** a la vez sobre los mismos archivos, con diagnósticos y sugerencias repetidos.

---

## Cambios realizados

### `lua/plugins/init.lua`

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\plugins\init.lua`

Se añadió este bloque justo antes del comentario `-- Debugger .NET (netcoredbg)`:

```lua
-- C# / .NET: gestión de soluciones (.sln), build, run, tests, NuGet
{
  "GustavEikaas/easy-dotnet.nvim",
  ft = { "cs", "fsharp", "razor" },
  cmd = "Dotnet",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  opts = {
    picker = "telescope",
    -- el LSP ya lo da roslyn.nvim; evitar un segundo servidor Roslyn
    lsp = { enabled = false },
  },
  keys = {
    { "<leader>nb", "<cmd>Dotnet build<cr>", desc = "Dotnet build" },
    { "<leader>nr", "<cmd>Dotnet run<cr>", desc = "Dotnet run" },
    { "<leader>nt", "<cmd>Dotnet testrunner<cr>", desc = "Dotnet test runner" },
    { "<leader>ns", "<cmd>Dotnet solution select<cr>", desc = "Dotnet select solution" },
    { "<leader>np", "<cmd>Dotnet project view<cr>", desc = "Dotnet project view" },
    { "<leader>nn", "<cmd>Dotnet<cr>", desc = "Dotnet commands" },
  },
},
```

Qué hace cada parte:

- **`ft` y `cmd`**: el plugin se carga al abrir un archivo C#, F# o Razor, o al escribir `:Dotnet`. No ralentiza el arranque.
- **`dependencies`**: `plenary.nvim` y `telescope.nvim` ya venían con NvChad.
- **`picker = "telescope"`**: los menús para elegir solución, proyecto o paquete se abren en Telescope, igual que el resto de NvChad.
- **`lsp = { enabled = false }`**: ver el aviso de arriba.

Ningún otro archivo cambió. `lua/configs/dap.lua` y `lua/configs/lspconfig.lua` se quedaron como estaban.

### Instalación

Se instaló con `:Lazy install`. La primera vez que carga, easy-dotnet instala solo su servidor auxiliar (`easy-dotnet-server`, una herramienta global de `dotnet`). Después de eso hay que **reiniciar Neovim una vez**.

---

## Atajos nuevos

| Atajo        | Comando                   | Acción                                        |
| ------------ | ------------------------- | --------------------------------------------- |
| `<leader>nn` | `:Dotnet`                 | Menú con todos los comandos de easy-dotnet    |
| `<leader>ns` | `:Dotnet solution select` | Elegir la solución (`.sln`)                   |
| `<leader>nb` | `:Dotnet build`           | Compilar                                      |
| `<leader>nr` | `:Dotnet run`             | Ejecutar el proyecto                          |
| `<leader>nt` | `:Dotnet testrunner`      | Abrir el explorador de tests                  |
| `<leader>np` | `:Dotnet project view`    | Ver el proyecto: referencias y paquetes NuGet |

> [!note] Conflicto con `<leader>n` de NvChad
> NvChad usa `<leader>n` para mostrar u ocultar los números de línea. Como ahora hay atajos que empiezan por `<leader>n`, al pulsar solo `<leader>n` Neovim espera un momento (`timeoutlen`) por si viene otra tecla, y después cambia los números. Para evitarlo se puede cambiar el prefijo de estos atajos, por ejemplo a `<leader>.`.

Atajos de depuración que ya existían (definidos en [[Soporte .NET en NvChad]]):

| Atajo | Acción |
|---|---|
| `<F5>` | Iniciar / continuar |
| `<F10>` / `<F11>` / `<F12>` | Step over / into / out |
| `<leader>db` | Poner o quitar un breakpoint |
| `<leader>du` | Mostrar u ocultar la interfaz del debugger |
| `<leader>dr` | Abrir la consola REPL |
| `<leader>dt` | Terminar la depuración |

---

## Cómo se usa

1. **Abrir Neovim en la carpeta de la solución**, donde está el `.sln`:
   ```bash
   cd C:\ruta\a\MiSolucion
   nvim .
   ```
2. **Abrir cualquier `.cs`.** `roslyn.nvim` busca la solución y la carga. Si hay varias, se elige con `:Roslyn target`.
3. **Elegir la solución en easy-dotnet** (solo la primera vez, o si hay varias): `<leader>ns`.
4. **Compilar** con `<leader>nb` y **ejecutar** con `<leader>nr`.
5. **Pasar tests** con `<leader>nt`: se abre un árbol con los tests de la solución y desde ahí se ejecutan.
6. **Depurar:** compilar primero, poner un breakpoint con `<leader>db` y pulsar `<F5>`. El debugger busca el `.dll` en `bin/Debug/<tfm>/`. Si no lo encuentra, pide la ruta.

### Otros comandos útiles de `:Dotnet`

Todos aparecen en el menú `<leader>nn`. Algunos:

| Comando | Acción |
|---|---|
| `:Dotnet restore` | Restaurar paquetes NuGet |
| `:Dotnet clean` | Limpiar la compilación |
| `:Dotnet watch` | Ejecutar con recarga en caliente (`dotnet watch`) |
| `:Dotnet add package` | Buscar y añadir un paquete NuGet |
| `:Dotnet new` | Crear un proyecto o archivo nuevo desde una plantilla |
| `:Dotnet secrets` | Editar los *user secrets* del proyecto |

---

## Comprobación

- `:Dotnet` existe y abre el menú. Se comprobó cargando el plugin en modo headless.
- `:checkhealth easy-dotnet` revisa que el SDK de `dotnet` y el servidor auxiliar estén bien.
- `:LspInfo` con un `.cs` abierto debe mostrar **un solo** cliente Roslyn.
- **Pendiente:** probarlo con una solución real.
