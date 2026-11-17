---
tags: [nvim, nvchad, plugins, cursor, estetica]
fecha: 2026-11-11
---

# Cursor animado con smear-cursor

El cursor deja una estela cuando se mueve y suelta partículas naranjas que suben, como si fuera fuego.

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11

---

## Qué se eligió y por qué

Se usa el plugin **`sphamba/smear-cursor.nvim`** con la config **"Fire Hazard"**. Es uno de los ejemplos que trae el README del plugin.

- Al saltar de un lado a otro (`gg`, `G`, `Ctrl + d`, cambiar de ventana) se ve hacia dónde fue el cursor, así no se pierde de vista.
- Las partículas son puramente decorativas.

> [!warning] Aviso del propio README
> Con esta combinación de opciones el cursor puede **parpadear** o "prenderse fuego". Es esperado, no es un error de la config.

---

## Cambios realizados

### `lua/plugins/init.lua`

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\plugins\init.lua`

Se agregó este bloque en la tabla de plugins, antes del comentario `-- test new blink`:

```lua
-- Cursor animado con estela + partículas (config "Fire Hazard" del README)
{
  "sphamba/smear-cursor.nvim",
  event = "VeryLazy",
  opts = {
    cursor_color = "#ff4000",
    particles_enabled = true,
    stiffness = 0.5,
    trailing_stiffness = 0.2,
    trailing_exponent = 5,
    damping = 0.6,
    gradient_exponent = 0,
    gamma = 1,
    never_draw_over_target = true, -- para ver lo que hay bajo el cursor
    hide_target_hack = true,
    particle_spread = 1,
    particles_per_second = 500,
    particles_per_length = 50,
    particle_max_lifetime = 800,
    particle_max_initial_velocity = 20,
    particle_velocity_from_cursor = 0.5,
    particle_damping = 0.15,
    particle_gravity = -50,
    min_distance_emit_particles = 0,
  },
},
```

Qué hace cada parte:

| Opción | Valor | Para qué |
|---|---|---|
| `event` | `"VeryLazy"` | Se carga después del arranque, así no lo hace más lento |
| `cursor_color` | `"#ff4000"` | Color de la estela y de las partículas (naranja fuego) |
| `particles_enabled` | `true` | Activa las partículas |
| `stiffness` | `0.5` | Qué tan rápido llega la cabeza de la estela al destino (`0` a `1`) |
| `trailing_stiffness` | `0.2` | Qué tan rápido la sigue la cola. Más bajo = estela más larga |
| `trailing_exponent` | `5` | Forma de la estela: la cola se queda atrás más tiempo |
| `damping` | `0.6` | Frena el movimiento para que no rebote |
| `gradient_exponent` | `0` | Estela de un color parejo, sin degradado |
| `gamma` | `1` | Corrección de color de los bordes de la estela |
| `never_draw_over_target` | `true` | No dibuja encima del carácter de destino, así se puede leer |
| `hide_target_hack` | `true` | Igual que lo anterior: deja ver lo que hay bajo el cursor |
| `particle_spread` | `1` | Qué tanto se dispersan las partículas |
| `particles_per_second` | `500` | Cuántas partículas salen por segundo |
| `particles_per_length` | `50` | Cuántas partículas salen por cada celda que recorre el cursor |
| `particle_max_lifetime` | `800` | Cuánto dura cada partícula, en milisegundos |
| `particle_max_initial_velocity` | `20` | Velocidad máxima con la que sale una partícula |
| `particle_velocity_from_cursor` | `0.5` | Cuánto heredan las partículas la velocidad del cursor |
| `particle_damping` | `0.15` | Qué tan rápido se frenan las partículas |
| `particle_gravity` | `-50` | Gravedad negativa: las partículas **suben**, como llamas |
| `min_distance_emit_particles` | `0` | Suelta partículas aunque el cursor se mueva una sola celda |

### Instalación del plugin

Se instaló con lazy.nvim sin abrir la interfaz:

```bash
cd "C:/Users/diazt/AppData/Local/nvim"
nvim --headless "+Lazy! install" +qa
```

También sirve abrir Neovim y ejecutar `:Lazy install` (o `:Lazy sync`).

El plugin queda en:

```
C:\Users\diazt\AppData\Local\nvim-data\lazy\smear-cursor.nvim
```

Hay que **reiniciar Neovim** para ver el efecto.

---

## Comandos útiles

```vim
:SmearCursorToggle       " activar/desactivar la animación
```

No se le asignó atajo. Si se quiere uno, se puede agregar en `keys` del bloque del plugin, por ejemplo:

```lua
keys = {
  { "<leader>tc", "<cmd>SmearCursorToggle<cr>", desc = "Toggle smear cursor" },
},
```

---

## Personalización

- **Menos partículas:** bajar `particles_per_second` (por ejemplo `100`) o `particles_per_length` (por ejemplo `10`).
- **Solo la estela, sin fuego:** `particles_enabled = false`.
- **Estela más corta:** subir `trailing_stiffness` (por ejemplo `0.5`).
- **Otro color:** cambiar `cursor_color`. Si se borra la opción, usa el color del cursor del tema.
- **Partículas que caen en vez de subir:** poner `particle_gravity` en positivo (por ejemplo `20`).

> [!tip] Terminal
> El efecto se ve mejor en una terminal con aceleración por GPU (Windows Terminal, WezTerm, Alacritty). En terminales lentas la animación puede ir a saltos.

Ver también: [[Comandos y atajos de NvChad]]
