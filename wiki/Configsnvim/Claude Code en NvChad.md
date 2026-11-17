---
tags: [nvim, nvchad, claude, ia]
fecha: 2026-11-11
---

# Claude Code en NvChad

Abrir un chat de Claude Code en un panel al costado de Neovim con un solo atajo.

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11 · CLI `claude` en `C:\Users\diazt\.local\bin\claude`

---

## Qué se eligió y por qué

Se usa el plugin **`coder/claudecode.nvim`**. No se usa una terminal común con `claude` adentro porque el plugin conecta Claude Code a Neovim como si fuera un IDE:

- Claude sabe qué archivo tienes abierto y qué código seleccionaste.
- Puedes mandarle una selección o un archivo entero al contexto.
- Cuando Claude propone un cambio, aparece como **diff dentro de Neovim** y lo aceptas o lo rechazas desde ahí.

**Requisito:** tener el CLI `claude` instalado y en el `PATH`. Para comprobarlo:

```bash
which claude        # Git Bash
claude --version
```

---

## Cambios realizados

### `lua/plugins/init.lua`

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\plugins\init.lua`

Se agregó este bloque en la tabla de plugins, antes del comentario `-- test new blink`:

```lua
-- Claude Code en un panel lateral
{
  "coder/claudecode.nvim",
  cmd = { "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSend", "ClaudeCodeAdd" },
  opts = {
    terminal = {
      split_side = "right",
      split_width_percentage = 0.35,
      provider = "native",
    },
  },
  keys = {
    { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Claude toggle" },
    { "<leader>cf", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude focus" },
    { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude send selection" },
    { "<leader>cb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude add current buffer" },
    { "<leader>ca", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude accept diff" },
    { "<leader>cd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude deny diff" },
  },
},
```

Qué hace cada parte:

| Opción | Valor | Para qué |
|---|---|---|
| `cmd` | `ClaudeCode`, `ClaudeCodeFocus`, … | El plugin se carga solo cuando usas uno de estos comandos (carga diferida) |
| `keys` | atajos `<leader>c…` | El plugin también se carga la primera vez que usas uno de estos atajos |
| `split_side` | `"right"` | El panel se abre a la derecha |
| `split_width_percentage` | `0.35` | El panel ocupa el 35% del ancho (el plugin trae `0.30` por defecto) |
| `provider` | `"native"` | Usa la terminal integrada de Neovim, sin depender de `snacks.nvim` |

### Instalación del plugin

Se instaló con lazy.nvim sin abrir la interfaz:

```bash
cd "C:/Users/diazt/AppData/Local/nvim"
nvim --headless "+Lazy! install" +qa
```

También sirve abrir Neovim y ejecutar `:Lazy install` (o `:Lazy sync`).

El plugin queda en:

```
C:\Users\diazt\AppData\Local\nvim-data\lazy\claudecode.nvim
```

---

## Atajos

`<leader>` en NvChad es la **barra espaciadora**.

| Atajo | Modo | Comando | Qué hace |
|---|---|---|---|
| `<leader>cc` | normal | `:ClaudeCode` | Abre o cierra el panel de Claude |
| `<leader>cf` | normal | `:ClaudeCodeFocus` | Salta al panel de Claude (lo abre si está cerrado) |
| `<leader>cs` | visual | `:ClaudeCodeSend` | Manda a Claude el código seleccionado |
| `<leader>cb` | normal | `:ClaudeCodeAdd %` | Agrega el archivo actual al contexto |
| `<leader>ca` | normal | `:ClaudeCodeDiffAccept` | Acepta el cambio que propone Claude |
| `<leader>cd` | normal | `:ClaudeCodeDiffDeny` | Rechaza el cambio que propone Claude |

**Choques con NvChad:** ninguno. NvChad solo usa `<leader>ch` (cheatsheet) y `<leader>cm` (commits de git en Telescope) dentro de `<leader>c`.

---

## Comandos útiles

```vim
:ClaudeCode              " abrir/cerrar el panel
:ClaudeCodeFocus         " ir al panel
:'<,'>ClaudeCodeSend     " mandar la selección (desde modo visual)
:ClaudeCodeAdd %         " agregar el archivo actual
:ClaudeCodeAdd lua/      " agregar una carpeta entera
:ClaudeCodeDiffAccept    " aceptar el diff
:ClaudeCodeDiffDeny      " rechazar el diff
```

---

## Flujo de uso

1. Abre un archivo y aprieta `<leader>cc`. Claude Code se abre a la derecha.
2. Escribe tu pregunta en el panel.
3. Para preguntar por un pedazo de código: selecciónalo con `v` o `V` y aprieta `<leader>cs`.
4. Si Claude propone un cambio, se abre un diff. Lo aceptas con `<leader>ca` o lo rechazas con `<leader>cd`.
5. `<leader>cc` otra vez cierra el panel.

### Moverse entre el panel y el código

El panel es una terminal, así que las teclas van a Claude hasta que salgas del modo terminal:

| Tecla | Qué hace |
|---|---|
| `<C-\><C-n>` | Sale del modo terminal (pasa a modo normal) |
| `<C-w>h` | Vuelve a la ventana del código (izquierda) |
| `<C-w>l` | Va al panel de Claude (derecha) |
| `i` | Vuelve a escribir en el panel |

---

## Personalización

- **Ancho del panel:** cambia `split_width_percentage` (por ejemplo `0.5` para la mitad).
- **Panel a la izquierda:** `split_side = "left"`.
- **Ventana flotante:** se puede usar `provider = "snacks"`, pero hay que instalar `folke/snacks.nvim`.
