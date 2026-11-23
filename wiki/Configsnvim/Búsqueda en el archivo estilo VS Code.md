---
tags: [nvim, nvchad, busqueda, edicion, vscode, atajos]
fecha: 2026-11-23
---

# Búsqueda en el archivo estilo VS Code

`Ctrl + F` abre una cajita de búsqueda flotante arriba a la derecha, como la de VS Code. Resalta los resultados mientras escribís, muestra un contador ("2 de 5") y con `Ctrl + A` selecciona **todos** los resultados para editarlos a la vez.

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11

No usa plugins: es un módulo propio en `lua/configs/find_box.lua`. La búsqueda nativa con `/` sigue funcionando igual, abajo (ver [[Notificaciones y cmdline con noice]]).

---

## Cómo se usa

### Buscar

| Tecla | Acción |
|---|---|
| `Ctrl + F` | Abre la cajita. Funciona en modo normal, insert y visual |
| *escribir* | Resalta todo y salta al resultado más cercano, en vivo |
| `Enter` / `↓` | Siguiente resultado |
| `Shift + Enter` / `↑` | Resultado anterior |
| `Esc` | Cierra la cajita. El cursor queda en el resultado |

- **En modo visual**, si seleccionás texto y apretás `Ctrl + F`, la búsqueda arranca con ese texto.
- **Contador:** a la derecha de la cajita aparece `2 de 5`, o `Sin resultados` en rojo.
- **Resultado actual:** se resalta con otro color (`CurSearch`), porque mientras escribís en la cajita el cursor del código no se ve. Si el resultado está fuera de pantalla, la vista se centra en él y abre los pliegues que lo tapen.
- **Cómo busca:** como VS Code por defecto, **no distingue mayúsculas** y busca el **texto literal** (`.`, `*`, `(`… no son regex).
- **Después de cerrar:** el texto queda en el historial de búsqueda, así que `n` y `N` siguen pasando por los resultados, con la animación de [[Resaltar cambios con undo-glow]].

### Seleccionar todos y editarlos

| Tecla | Acción |
|---|---|
| `Ctrl + A` | Selecciona todos los resultados. El título cambia a **"Editar todos"** y el contador muestra `N seleccionados` |
| *escribir* | Lo que hay en la cajita reemplaza **todos** los resultados, en vivo |
| `Backspace` / `Ctrl + W` | Borra letras / la última palabra en todos |
| `Ctrl + U` | Borra todo el texto, para escribir uno nuevo desde cero |
| `Enter` / `Esc` | Termina la edición y cierra la cajita |
| `u` *(ya cerrada)* | Deshace **toda** la edición de una sola vez |

Ejemplo: `Ctrl + F` → `hola` → `Ctrl + A` → `Ctrl + U` → `chau` → `Enter`. Todos los `hola` (también `Hola`) pasan a ser `chau`.

> [!note] No es multicursor de verdad
> Solo se edita el texto encontrado: no se pueden mover los cursores por separado ni tocar lo que está alrededor. Para eso haría falta un plugin como `jake-stewart/multicursor.nvim` (no instalado).

> [!tip] `Alt + Enter`
> También selecciona todos, igual que en VS Code. Pero en Windows Terminal `Alt + Enter` pone la ventana en pantalla completa, por eso se recomienda `Ctrl + A`.

---

## Cambios realizados

### `lua/configs/find_box.lua` (nuevo)

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\configs\find_box.lua`

Módulo con toda la lógica. Partes principales:

| Función | Qué hace |
|---|---|
| `M.from_mode()` | Punto de entrada de `Ctrl + F`. En visual toma el texto seleccionado; en insert sale de insert primero |
| `M.open(initial)` | Crea la ventana flotante (`relative = "win"`, `anchor = "NE"`, borde redondeado, título `Buscar`) y registra las teclas |
| `update()` | En cada tecla: arma el patrón, lo guarda en el registro `/`, activa `hlsearch` y busca desde donde estaba el cursor al abrir |
| `jump(forward)` | `Enter` / flechas: busca el siguiente o el anterior, con vuelta al principio |
| `refresh_counter()` | Calcula `N de M` con `searchcount()` y lo muestra como texto virtual a la derecha |
| `mark_current()` | Resalta el resultado actual con un extmark `CurSearch` y centra la vista si hace falta |
| `select_all()` | `Ctrl + A`: con `matchbufline()` encuentra todos los resultados y pone un extmark en cada uno (resaltado `Visual`) |
| `apply_replace()` | En modo "Editar todos": reemplaza el texto de cada extmark por el de la cajita, juntando todo en un solo undo con `undojoin` |
| `M.close()` | Limpia resaltados, vuelve a activar autopairs, cierra la cajita y vuelve a la ventana del código |

Detalles de implementación:

- **Patrón literal sin mayúsculas:** el texto se convierte en `\V\c` + texto (con `\` escapadas). `\V` = "very nomagic" (todo literal) y `\c` = ignorar mayúsculas.
- **Rangos que se estiran:** cada extmark de "Editar todos" usa `right_gravity = false` en el inicio y `end_right_gravity = true` en el final. Así, al borrar todo y escribir de nuevo, el rango crece con el texto nuevo y no se pierde.
- **Un solo undo:** cada tecla hace `undojoin` antes de modificar el buffer, así `u` deshace toda la edición de una vez.
- **Teclas protegidas:** nvim-cmp y nvim-autopairs registran `<CR>` (y cmp también las flechas) al entrar en modo insert y le robaban `Enter` a la cajita. Por eso la cajita:
  - desactiva cmp en su buffer (`require("cmp").setup.buffer { enabled = false }`),
  - desactiva autopairs mientras está abierta (`require("nvim-autopairs").disable()`, y `enable()` al cerrar),
  - vuelve a registrar sus teclas en cada `InsertEnter` (con `vim.schedule`, para que ganen).
- **Se cierra sola** si salís de la ventana (`WinLeave`).

### `lua/mappings.lua`

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\mappings.lua`

```lua
-- Ctrl+F: buscar dentro del archivo estilo VS Code (lua/configs/find_box.lua)
map({ "n", "i", "v" }, "<C-f>", function()
  require("configs.find_box").from_mode()
end, { desc = "Buscar en el archivo (estilo VS Code)" })
```

> [!warning] Reemplaza "página abajo"
> En Vim `Ctrl + F` es *página abajo*. Para bajar queda `Ctrl + D` (media página).

---

## Pruebas

Se probó en modo headless con la config completa (cmp y autopairs cargados), simulando las teclas:

| Prueba | Resultado |
|---|---|
| Escribir `hola` | Salta al primer resultado, contador `1 de 2` |
| `Enter`, `Enter` | Línea 1 → línea 3 → vuelve a la línea 1 |
| `↓` / `↑` | Siguiente / anterior |
| `Ctrl + A`, `Backspace` ×2, `XY` | Los 3 resultados pasan a `hoXY` |
| `Ctrl + U`, `chau`, `Enter` | Los 3 pasan a `chau`, la cajita se cierra |
| `u` | El archivo vuelve al original, incluido `Hola` con mayúscula |

---

## Problemas conocidos

- **`Shift + Enter` no hace nada:** algunas terminales no le mandan `Shift + Enter` a Neovim. Usar `↑`.
- **`Enter` no se mueve:** si se agrega otro plugin que mapee `<CR>` en modo insert, puede volver a pisarlo. Revisar con `:verbose imap <CR>` dentro de la cajita.

## Personalización

- **Distinguir mayúsculas:** en `to_pattern()` cambiar `\\c` por `\\C`.
- **Usar regex:** en `to_pattern()` sacar `\\V` y el escapado de `\`.
- **Ancho de la cajita:** cambiar el `45` de `local width = math.min(45, ...)` en `M.open()`.
- **Colores:** el resultado actual usa `CurSearch` y la selección de "Editar todos" usa `Visual`. Se pueden cambiar en `chadrc.lua` → `hl_override`.
- **Desactivar:** borrar el mapeo de `<C-f>` en `lua/mappings.lua`. `Ctrl + F` vuelve a ser *página abajo*.

Ver también: [[Comandos y atajos de NvChad]] · [[Notificaciones y cmdline con noice]] · [[Resaltar cambios con undo-glow]]
