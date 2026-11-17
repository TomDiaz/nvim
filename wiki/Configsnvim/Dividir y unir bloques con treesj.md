---
tags: [nvim, nvchad, plugins, treesitter, edicion]
fecha: 2026-11-11
---

# Dividir y unir bloques con treesj

Convierte un bloque de código (argumentos de una función, una tabla, un objeto, un array, una lista de parámetros) de **una línea a varias** y al revés, con una sola tecla.

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11

---

## Qué hace

Con el cursor dentro del bloque:

```lua
local t = { a = 1, b = 2, c = 3 }
```

`<leader>tt` lo deja así (y si se vuelve a pulsar, vuelve a una línea):

```lua
local t = {
  a = 1,
  b = 2,
  c = 3,
}
```

Funciona igual en C#:

```csharp
Foo(uno, dos, tres);
// ⇅ <leader>tt
Foo(
    uno,
    dos,
    tres
);
```

Se usa el plugin **`Wansmer/treesj`**. Como trabaja sobre el árbol de **treesitter**, entiende la sintaxis real: agrega o quita comas y llaves donde corresponde, cosa que un `J` normal de Vim no hace.

---

## Cambios realizados

### `lua/plugins/init.lua`

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\plugins\init.lua`

Se agregó este bloque en la tabla de plugins, antes del comentario `-- test new blink`:

```lua
-- Dividir / unir bloques de código (argumentos, tablas, objetos) con treesitter
{
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
  keys = {
    { "<leader>tt", "<cmd>TSJToggle<cr>", desc = "TreeSJ toggle split/join" },
    { "<leader>ts", "<cmd>TSJSplit<cr>", desc = "TreeSJ split" },
    { "<leader>tj", "<cmd>TSJJoin<cr>", desc = "TreeSJ join" },
  },
  opts = {
    use_default_keymaps = false, -- los default (<leader>m/j/s) chocan con <leader>ma de NvChad
    max_join_length = 150,
  },
},
```

Qué hace cada parte:

| Opción | Valor | Para qué |
|---|---|---|
| `dependencies` | `nvim-treesitter` | treesj necesita los parsers de treesitter para entender el código |
| `cmd` / `keys` | — | El plugin se carga recién al usar un comando o atajo, así no hace más lento el arranque |
| `use_default_keymaps` | `false` | Desactiva los atajos que trae por defecto (ver aviso abajo) |
| `max_join_length` | `150` | No une el bloque si la línea resultante pasaría de 150 caracteres (el default es 120) |

> [!note] Por qué no se usan los atajos por defecto
> treesj trae `<leader>m` (toggle), `<leader>j` (unir) y `<leader>s` (dividir). Pero NvChad ya usa `<leader>ma` (ver marcas), así que `<leader>m` obligaría a Neovim a esperar para saber si viene una `a` detrás. Por eso se movieron todos al grupo `<leader>t…`.

### Instalación del plugin

Se instaló con lazy.nvim sin abrir la interfaz:

```bash
cd "C:/Users/diazt/AppData/Local/nvim"
nvim --headless "+Lazy! install" +qa
```

También sirve abrir Neovim y ejecutar `:Lazy install` (o `:Lazy sync`).

El plugin queda en:

```
C:\Users\diazt\AppData\Local\nvim-data\lazy\treesj
```

Se probó dividiendo una tabla Lua con `:TSJToggle` y funcionó correctamente.

---

## Atajos y comandos

| Tecla | Comando | Acción |
|---|---|---|
| `<leader>tt` | `:TSJToggle` | Dividir si está en una línea, unir si está en varias |
| `<leader>ts` | `:TSJSplit` | Dividir el bloque en varias líneas |
| `<leader>tj` | `:TSJJoin` | Unir el bloque en una sola línea |

> [!tip] Dónde poner el cursor
> En cualquier parte **dentro** del bloque (sobre un argumento, una clave, la llave de apertura). Si hay bloques anidados, treesj toma el más cercano al cursor.

---

## Lenguajes soportados

Necesita el parser de treesitter del lenguaje instalado. Entre los que trae soporte y ya están en `ensure_installed` de esta config: **Lua, C#, HTML, CSS, JSON**.

Otros soportados: JavaScript, TypeScript/TSX, Python, Rust, Go, Java, Kotlin, C, C++, PHP, Ruby, Bash, YAML, TOML, SQL, Vue, Svelte y más. Para usarlos, agregar el parser en `ensure_installed` del bloque de `nvim-treesitter` (o ejecutar `:TSInstall <lenguaje>`).

---

## Personalización

- **Unir aunque quede una línea larga:** subir `max_join_length` (por ejemplo `300`).
- **Que al dividir también divida los bloques anidados:** usar `require("treesj").toggle({ split = { recursive = true } })` en un atajo:

```lua
{ "<leader>tT", function() require("treesj").toggle { split = { recursive = true } } end, desc = "TreeSJ toggle recursivo" },
```

- **Volver a los atajos originales:** borrar `keys` y poner `use_default_keymaps = true`.

Ver también: [[Comandos y atajos de NvChad]]
