---
tags: [nvim, nvchad, atajos, comandos]
fecha: 2026-11-11
---

# Comandos y atajos de NvChad

Referencia de todas las teclas y comandos de esta configuración: los que trae NvChad, los de Neovim, y los que se añadieron para C# / .NET (ver [[Soporte .NET en NvChad]]).

> [!info] Cómo leer esta página
> - **`<leader>` es la barra espaciadora.** `<leader>ff` = pulsar `Espacio`, luego `f`, luego `f` (una tras otra, no a la vez).
> - `<C-x>` = `Ctrl + x` · `<A-x>` = `Alt + x` · `<S-x>` = `Shift + x`.
> - Los atajos funcionan en **modo normal** salvo que se indique otro modo. Para volver al modo normal: `Esc` o `jk`.
> - Si pulsas `Espacio` y esperas, **which-key** muestra las teclas disponibles. `<leader>ch` abre la chuleta de NvChad.

---

## Lo básico de Vim

### Modos

| Tecla | Modo | Para qué |
|---|---|---|
| `Esc` / `jk` | Normal | Moverse y dar órdenes (modo por defecto) |
| `i` / `a` | Insertar | Escribir antes / después del cursor |
| `I` / `A` | Insertar | Escribir al principio / al final de la línea |
| `o` / `O` | Insertar | Nueva línea debajo / encima |
| `v` / `V` / `Ctrl + v` | Visual | Seleccionar caracteres / líneas / bloque |
| `:` o `;` | Comando | Escribir comandos como `:w` |

### Moverse

| Tecla | Acción |
|---|---|
| `h` `j` `k` `l` | Izquierda, abajo, arriba, derecha |
| `w` / `b` / `e` | Palabra siguiente / anterior / final de palabra |
| `0` / `^` / `$` | Inicio de línea / primer carácter / final de línea |
| `gg` / `G` | Principio / final del archivo |
| `:42` o `42G` | Ir a la línea 42 |
| `Ctrl + d` / `Ctrl + u` | Media página abajo / arriba |
| `%` | Saltar al paréntesis o llave que empareja |
| `Ctrl + o` / `Ctrl + i` | Volver atrás / adelante en los saltos |

### Editar

| Tecla | Acción |
|---|---|
| `x` | Borrar carácter |
| `dd` / `yy` / `p` | Cortar línea / copiar línea / pegar |
| `dw` / `cw` | Borrar palabra / cambiar palabra |
| `ciw` / `ci"` / `ci(` | Cambiar palabra entera / dentro de comillas / dentro de paréntesis |
| `u` / `Ctrl + r` | Deshacer / rehacer |
| `.` | Repetir el último cambio |
| `>>` / `<<` | Indentar / desindentar línea |

### Buscar y reemplazar

| Comando | Acción |
|---|---|
| `Ctrl + F` | Buscar en el archivo estilo VS Code (ver [[Búsqueda en el archivo estilo VS Code]]) |
| `Ctrl + F` → `Ctrl + A` | Seleccionar todos los resultados y editarlos a la vez |
| `/texto` | Buscar hacia adelante (`n` siguiente, `N` anterior) |
| `*` | Buscar la palabra bajo el cursor |
| `:%s/viejo/nuevo/g` | Reemplazar en todo el archivo |
| `:%s/viejo/nuevo/gc` | Igual, pidiendo confirmación en cada uno |
| `Esc` | Quitar el resaltado de la búsqueda |

### Guardar y salir

| Comando | Acción |
|---|---|
| `:w` o `Ctrl + s` | Guardar |
| `:q` | Cerrar la ventana |
| `:wq` | Guardar y cerrar |
| `:q!` | Cerrar sin guardar |
| `:qa` | Cerrar todo |

---

## Atajos propios de esta config

Definidos en `lua/mappings.lua`:

| Tecla | Modo | Acción |
|---|---|---|
| `;` | Normal | Igual que `:` (entrar en modo comando) |
| `jk` | Insertar | Salir al modo normal (igual que `Esc`) |
| `Ctrl + F` | Normal, Insertar, Visual | Buscar en el archivo estilo VS Code (ver [[Búsqueda en el archivo estilo VS Code]]) |
| `<leader>wd` | Normal | Documentar el archivo actual en Obsidian (ver [[Documentar el proyecto en Obsidian con WikiDoc]]) |
| `<leader>wD` | Normal | Documentar todo el proyecto en Obsidian |

---

## General (NvChad)

| Tecla | Modo | Acción |
|---|---|---|
| `Ctrl + s` | Normal | Guardar el archivo |
| `Ctrl + c` | Normal | Copiar todo el archivo al portapapeles |
| `Esc` | Normal | Quitar resaltado de búsqueda |
| `<leader>fm` | Normal / Visual | Formatear el archivo (CSharpier en C#, stylua en Lua) |
| `<leader>/` | Normal / Visual | Comentar o descomentar línea / selección |
| `<leader>n` | Normal | Mostrar u ocultar números de línea |
| `<leader>rn` | Normal | Números de línea relativos |
| `<leader>th` | Normal | Elegir tema de colores |
| `<leader>ch` | Normal | Abrir la chuleta de atajos de NvChad |
| `<leader>wK` | Normal | Ver todos los atajos (which-key) |
| `<leader>wk` | Normal | Buscar un atajo concreto (which-key) |
| `<leader>tt` | Normal | Dividir o unir el bloque bajo el cursor (ver [[Dividir y unir bloques con treesj]]) |
| `<leader>ts` | Normal | Dividir el bloque en varias líneas |
| `<leader>tj` | Normal | Unir el bloque en una línea |
| `<leader>nh` | Normal | Historial de mensajes en Telescope (ver [[Notificaciones y cmdline con noice]]) |
| `<leader>nl` | Normal | Ver el último mensaje |
| `<leader>nd` | Normal | Cerrar las notificaciones abiertas |
| `u` / `Ctrl + r` | Normal | Deshacer / rehacer, con animación sobre lo que cambió (ver [[Resaltar cambios con undo-glow]]) |
| `p` / `P` | Normal | Pegar abajo / arriba, con animación |
| `n` / `N` / `*` / `#` | Normal | Saltar entre resultados de búsqueda, con animación |
| `<leader>gg` | Normal | Panel de git estilo Source Control de VS Code (ver [[Git estilo VS Code]]) |
| `<leader>gd` / `<leader>gq` | Normal | Abrir / cerrar el diff lado a lado |
| `<leader>gh` | Normal | Historial del archivo actual |
| `]h` / `[h` | Normal | Siguiente / anterior cambio de git |
| `<leader>gp` / `<leader>gs` / `<leader>gr` | Normal / Visual | Previsualizar / stage / descartar el cambio bajo el cursor |
| `<leader>gb` | Normal | Blame de la línea |

### Moverse en modo insertar

| Tecla | Acción |
|---|---|
| `Ctrl + b` | Ir al principio de la línea |
| `Ctrl + e` | Ir al final de la línea |
| `Ctrl + h` `j` `k` `l` | Mover el cursor izquierda / abajo / arriba / derecha |

---

## Ventanas y buffers

Un **buffer** es un archivo abierto (las pestañas de arriba). Una **ventana** es una división de la pantalla.

| Tecla | Acción |
|---|---|
| `Tab` / `Shift + Tab` | Buffer siguiente / anterior |
| `<leader>x` | Cerrar el buffer actual |
| `<leader>b` | Nuevo buffer vacío |
| `Ctrl + h` `j` `k` `l` | Ir a la ventana de la izquierda / abajo / arriba / derecha |
| `:vsp` / `:sp` | Dividir en vertical / horizontal |
| `Ctrl + w` `q` | Cerrar la ventana |
| `Ctrl + w` `=` | Igualar el tamaño de las ventanas |

---

## Explorador de archivos (nvim-tree)

| Tecla | Acción |
|---|---|
| `Ctrl + n` | Abrir o cerrar el explorador |
| `<leader>e` | Poner el cursor en el explorador |

Dentro del explorador:

| Tecla | Acción |
|---|---|
| `Enter` / `o` | Abrir archivo o carpeta |
| `Ctrl + v` / `Ctrl + x` | Abrir en división vertical / horizontal |
| `a` | Crear archivo (termina en `/` para crear carpeta) |
| `r` | Renombrar |
| `d` | Borrar |
| `x` / `c` / `p` | Cortar / copiar / pegar |
| `y` / `Y` / `gy` | Copiar nombre / ruta relativa / ruta absoluta |
| `H` | Mostrar u ocultar archivos ocultos |
| `I` | Mostrar u ocultar archivos ignorados por git |
| `-` | Subir a la carpeta padre |
| `R` | Refrescar |
| `g?` | Ver todas las teclas del explorador |
| `q` | Cerrar |

> [!tip] Iconos
> Los iconos de cada tipo de archivo necesitan una **Nerd Font** en la terminal (por ejemplo JetBrainsMono Nerd Font). Sin ella se ven cuadrados o `?`.

---

## Buscar (Telescope)

| Tecla | Acción |
|---|---|
| `<leader>ff` | Buscar archivo por nombre |
| `<leader>fa` | Buscar en **todos** los archivos (incluye ocultos e ignorados) |
| `<leader>fw` | Buscar texto en todo el proyecto (live grep) |
| `<leader>fz` | Buscar texto en el archivo actual |
| `<leader>fb` | Buscar entre los buffers abiertos |
| `<leader>fo` | Archivos abiertos recientemente |
| `<leader>fh` | Buscar en la ayuda de Neovim |
| `<leader>fs` | Miembros del archivo actual: clases, propiedades, métodos (ver [[Outline de clases con aerial]]) |
| `<leader>ma` | Ver las marcas |
| `<leader>cm` | Commits de git |
| `<leader>gt` | Estado de git (archivos modificados) |
| `<leader>pt` | Elegir una terminal oculta |

Dentro de Telescope:

| Tecla | Acción |
|---|---|
| `Ctrl + n` / `Ctrl + p` | Resultado siguiente / anterior |
| `Enter` | Abrir |
| `Ctrl + v` / `Ctrl + x` | Abrir en división vertical / horizontal |
| `Ctrl + u` / `Ctrl + d` | Desplazar la vista previa |
| `Ctrl + q` | Mandar los resultados a la lista quickfix |
| `Esc` | Cerrar |

> [!note] `<leader>fw` necesita ripgrep
> La búsqueda de texto usa `rg`. Si no funciona: `winget install BurntSushi.ripgrep.MSVC`.

---

## Terminal

| Tecla | Acción |
|---|---|
| `Alt + i` | Abrir o cerrar terminal flotante |
| `Alt + h` | Abrir o cerrar terminal horizontal |
| `Alt + v` | Abrir o cerrar terminal vertical |
| `<leader>h` | Nueva terminal horizontal |
| `<leader>v` | Nueva terminal vertical |
| `Ctrl + x` | (Dentro de la terminal) salir del modo terminal para moverte con Vim |

> [!tip]
> La terminal flotante (`Alt + i`) es cómoda para lanzar `dotnet build` o `dotnet run` sin salir de Neovim.

---

## LSP: código (C# con Roslyn, Lua, HTML, CSS)

Funcionan cuando el servidor de lenguaje está conectado al archivo.

| Tecla | Acción |
|---|---|
| `K` | Ver documentación de lo que está bajo el cursor |
| `gd` | Ir a la definición |
| `gD` | Ir a la declaración |
| `grr` | Ver todas las referencias |
| `gri` | Ir a la implementación |
| `<leader>D` / `grt` | Ir a la definición del tipo |
| `<leader>ra` | Renombrar símbolo (versión de NvChad) |
| `grn` | Renombrar símbolo (versión de Neovim) |
| `gra` | Acciones de código (arreglos rápidos, `using` que faltan, etc.) |
| `gO` | Lista de símbolos del archivo (clases, métodos) |
| `<leader>o` | Panel con el árbol de la clase: campos, propiedades, métodos (ver [[Outline de clases con aerial]]) |
| `<leader>O` | Árbol de la clase en ventana flotante, con vista previa |
| `<leader>fs` | Buscar entre los miembros del archivo con Telescope (también `/` dentro del panel) |
| `Ctrl + s` | (Modo insertar) ver la firma de la función que estás escribiendo |
| `Ctrl + o` | Volver de donde saltaste con `gd` |

### Diagnósticos (errores y avisos)

| Tecla | Acción |
|---|---|
| `]d` / `[d` | Siguiente / anterior error o aviso |
| `Ctrl + w` `d` | Ver el mensaje completo del error bajo el cursor |
| `<leader>ds` | Lista de todos los errores del archivo |

### Autocompletado

| Tecla | Acción |
|---|---|
| `Ctrl + n` / `Ctrl + p` o `Tab` / `Shift + Tab` | Siguiente / anterior sugerencia |
| `Enter` | Aceptar la sugerencia |
| `Ctrl + Espacio` | Abrir las sugerencias a mano |
| `Ctrl + e` | Cerrar las sugerencias |

---

## Debugger (nvim-dap)

Definidos en `lua/plugins/init.lua`. Solo funcionan en archivos `.cs`.

| Tecla | Acción |
|---|---|
| `F5` | Iniciar la depuración / continuar hasta el siguiente breakpoint |
| `F10` | Siguiente línea, sin entrar en funciones (step over) |
| `F11` | Entrar en la función (step into) |
| `F12` | Salir de la función (step out) |
| `<leader>db` | Poner o quitar breakpoint |
| `<leader>du` | Mostrar u ocultar el panel del debugger |
| `<leader>dr` | Abrir o cerrar la consola REPL |
| `<leader>dt` | Detener la depuración |

Pasos para depurar:

1. Compilar: `dotnet build` (por ejemplo desde la terminal flotante con `Alt + i`).
2. Abrir un archivo `.cs` del proyecto. Neovim tiene que estar abierto en la carpeta donde está el `.csproj`.
3. Poner un breakpoint con `<leader>db`.
4. Pulsar `F5` y elegir **Launch** (o **Attach** para conectarse a un proceso que ya está corriendo).

> [!warning] Errores comunes
> - **`You need to add configs to dap.configurations.`**: pulsaste `F5` fuera de un archivo `.cs` (en el explorador, en la terminal o en un buffer vacío). Ponte en un `.cs` y vuelve a pulsar. Con `:set ft?` debe salir `filetype=cs`.
> - **Pide la ruta del dll**: no encontró `bin/Debug/<framework>/<Proyecto>.dll`. Compila primero o revisa que Neovim esté abierto en la carpeta del proyecto.
> - **`F11` pone la terminal en pantalla completa**: Windows Terminal usa esa tecla. Se puede quitar en Configuración → Acciones.

---

## Comandos útiles

Se escriben en modo normal empezando por `:` (o `;`).

### Plugins y herramientas

| Comando | Para qué |
|---|---|
| `:Lazy` | Gestor de plugins: ver, actualizar (`U`), sincronizar (`S`) |
| `:Mason` | Instalar o actualizar servidores LSP, formateadores y debuggers |
| `:MasonInstall roslyn csharpier netcoredbg` | Instalar las herramientas de C# |
| `:TSInstallAll` | Instalar los parsers de treesitter de la config |
| `:TSUpdate` | Actualizar los parsers de treesitter |
| `:checkhealth` | Revisar que todo esté bien instalado |
| `:checkhealth nvim-treesitter` | Revisar solo treesitter |

### Documentación (ver [[Documentar el proyecto en Obsidian con WikiDoc]])

| Comando | Para qué |
|---|---|
| `:WikiDoc` | Crear o actualizar la nota del archivo actual (con datos del LSP) y abrirla en Obsidian |
| `:WikiDocAll` | Documentar todos los archivos del proyecto con la extensión del actual |
| `:WikiDocAll cs xaml` | Igual, con esas extensiones |

### LSP y C#

| Comando | Para qué |
|---|---|
| `:checkhealth vim.lsp` | Ver qué servidores LSP están conectados al archivo |
| `:Roslyn target` | Elegir la solución (`.sln`) si hay varias en la carpeta |
| `:lsp restart` | Reiniciar el LSP (Roslyn) si deja de responder |
| `:lua vim.lsp.buf.format()` | Formatear con el LSP en lugar de CSharpier |

### NvChad

| Comando | Para qué |
|---|---|
| `:NvCheatsheet` | Chuleta de atajos (igual que `<leader>ch`) |
| `:Telescope` | Ver todos los buscadores de Telescope |
| `:WhichKey` | Ver todos los atajos |

### Errores (ver [[Registro de errores en errors.log]])

| Comando | Para qué |
|---|---|
| `:ErrorLog` | Abrir el log de errores en un split |
| `:ErrorLogNotepad` | Abrir el log de errores en el Bloc de notas |
| `:ErrorLogCopy` | Copiar el último error al portapapeles |
| `:ErrorLogClaude` | Mandar el último error al panel de Claude para que lo analice |
| `:ErrorLogClear` | Vaciar el log de errores |

### Archivos y ayuda

| Comando | Para qué |
|---|---|
| `:e ruta/archivo` | Abrir un archivo |
| `:cd ruta` | Cambiar la carpeta de trabajo |
| `:set ft?` | Ver el tipo del archivo actual |
| `:h tema` | Ayuda de Neovim sobre cualquier cosa (por ejemplo `:h motion`) |
| `:Tutor` | Tutorial interactivo de Vim (unos 30 minutos) |
