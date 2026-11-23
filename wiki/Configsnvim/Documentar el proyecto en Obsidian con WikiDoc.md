---
tags: [nvim, nvchad, obsidian, documentacion, lsp, arquitectura, atajos]
fecha: 2026-11-23
---

# Documentar el proyecto en Obsidian con WikiDoc

Dos comandos para documentar el código en una wiki de Obsidian. Cada archivo del proyecto tiene su nota, y con el **LSP** se llenan las relaciones entre archivos (quién usa a quién, herencia, interfaces) como `[[links]]`. Así el **Graph View** de Obsidian dibuja solo el mapa de la arquitectura.

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11 · Obsidian · Roslyn (C#)

No usa plugins de Neovim: son dos módulos propios, `lua/configs/wiki_doc.lua` y `lua/configs/wiki_doc_lsp.lua`.

---

## Comandos

| Comando | Atajo | Qué hace |
|---|---|---|
| `:WikiDoc` | `<leader>wd` | Crea o actualiza la nota del **archivo actual** y la abre en Obsidian |
| `:WikiDocAll` | `<leader>wD` | Documenta **todo el proyecto**: una nota por archivo |
| `:WikiDocAll cs xaml` | — | Igual, pero con esas extensiones (por defecto, la del archivo actual) |

---

## Qué pasa al ejecutarlo

```
Usuario.cs ──► 1. ¿Cuál es el proyecto?   →  MiApp (la carpeta con .git)
               2. ¿Existe la wiki?        →  ~/Desktop/wiki/MiApp/
                  └─ no → la crea y copia la config de Obsidian
               3. ¿Existe la nota?        →  .../MiApp/src/Servicios/Usuario.md
                  └─ no → la crea con una plantilla
               4. Pide los datos al LSP   →  llena la sección automática
               5. Abrir en Obsidian
                  └─ ¿Obsidian conoce esta bóveda?
                       sí → la abre directo
                       no → pregunta, cierra Obsidian, la registra y lo reabre
```

### 1. El proyecto

Sube desde el archivo hasta una carpeta con `.git`. El nombre de esa carpeta es el nombre de la wiki. Si no hay `.git`, usa la carpeta donde se abrió Neovim.

### 2. La bóveda

Las wikis se crean en **`~/Desktop/wiki/<proyecto>`** (`C:\Users\<usuario>\Desktop\wiki`). Es una ruta relativa al usuario, así funciona igual en cualquier PC. Es la carpeta **local** del escritorio, no la que OneDrive redirige.

> [!warning] Escritorio redirigido a OneDrive
> Si Windows tiene el Escritorio en OneDrive (como en esta PC), `C:\Users\<usuario>\Desktop` no es el escritorio que se ve. La carpeta se crea igual, pero se encuentra desde el Explorador, en la carpeta de usuario.

Una bóveda de Obsidian es una carpeta con una subcarpeta `.obsidian` (plugins, tema, ajustes). La primera vez se copia la `.obsidian` de esta wiki (`nvim/wiki/Configsnvim/.obsidian`), así cada wiki nueva tiene los mismos plugins. No se copian `workspace.json` ni `workspace-mobile.json`, que guardan el estado de las ventanas de esta bóveda.

- Son unos **160 MB** por wiki (latex-math y typst son los más pesados). La copia corre en segundo plano con `robocopy` y no traba Neovim.
- La plantilla viaja con la config: la carpeta `.obsidian` está en el repo de git de nvim.

### 3. La nota

La nota se llama como el archivo **sin la extensión**, y la extensión queda como tag. Las carpetas siguen la estructura del código:

| Archivo | Nota |
|---|---|
| `src/Servicios/Usuario.cs` | `src/Servicios/Usuario.md` |
| `src/Servicios/Usuario.xaml` | `src/Servicios/Usuario (xaml).md` (mismo nombre en la misma carpeta) |
| `Program.cs` | `Program.md` |
| `.gitignore` | `.gitignore.md` (no tiene extensión) |

Para saber a qué archivo pertenece cada nota se lee el campo `archivo:` del frontmatter. Por eso volver a correr el comando abre la nota que ya existe, en lugar de crear otra.

Plantilla:

```markdown
---
tags: [doc, cs]
fecha: 2026-11-23
archivo: src/Servicios/Usuario.cs
---

# Usuario

**Archivo:** [src/Servicios/Usuario.cs](file:///C:/...)   ← clic y abre el archivo
**Path completo:** `C:\...\Usuario.cs`

## Qué hace

## Notas
```

### 4. La sección automática (LSP)

Al final de la nota se agrega una sección entre los marcadores `<!-- wikidoc:auto -->` y `<!-- /wikidoc:auto -->`. **Cada vez que se corre el comando se regenera solo lo de adentro**: lo que escribas en "Qué hace" o "Notas" no se toca.

```markdown
<!-- wikidoc:auto -->
## Arquitectura
**Usa:** [[Datos/IUsuarioRepositorio|IUsuarioRepositorio]] · [[Modelos/Usuario|Usuario]] · [[Servicios/EmailService|EmailService]]
**Usado por:** [[Program|Program]]

## Miembros
### UsuarioService · clase
- `_repo : IUsuarioRepositorio` · campo
- `Crear(string, string) : Usuario` · método

_Generado con el LSP (roslyn) el 2026-11-23 03:10. …_
<!-- /wikidoc:auto -->
```

Las relaciones posibles:

| Relación | Qué significa | Pedido al LSP |
|---|---|---|
| **Hereda de** | Clase padre | `typeHierarchy/supertypes` |
| **Implementa** | Interfaces que implementa | `typeHierarchy/supertypes` |
| **Implementado por** | Clases que implementan esta interfaz | `textDocument/implementation` |
| **Usa** | Archivos a los que llama o que referencia | Ver abajo |
| **Usado por** | Archivos que referencian sus clases | `textDocument/references` |
| **Miembros** | Campos, propiedades y métodos, con su firma | `textDocument/documentSymbol` |

**"Usa" se calcula distinto en cada comando:**
- `:WikiDoc` pide `callHierarchy/outgoingCalls` por cada método (a qué llama), hasta 60 métodos por clase.
- `:WikiDocAll` lo saca **invirtiendo "Usado por"** de todo el proyecto: si B está en "Usado por" de A, entonces A está en "Usa" de B. No hace falta pedir `callHierarchy`, así que es más rápido.

**Sin repeticiones:** lo que está en "Hereda de"/"Implementa" no se repite en "Usa", y lo que está en "Implementado por" no se repite en "Usado por".

**Links con path:** se escriben como `[[carpeta/Nota|Nota]]`, así no hay ambigüedad si dos notas se llaman igual en carpetas distintas. Solo se enlazan archivos **del proyecto**: las clases de .NET o de librerías no aparecen.

**Lenguajes sin clases:** si el archivo no tiene clases ni interfaces (scripts, módulos de funciones), se usan sus funciones como símbolos principales (hasta 40).

**Sin LSP:** si el archivo no tiene LSP conectado, la nota se crea igual pero sin esta sección, y aparece un aviso amarillo. `:WikiDoc` espera hasta 5 segundos a que el LSP se conecte, por si el archivo se acaba de abrir o recargar.

### 5. Abrir en Obsidian

Se abre con la URI `obsidian://open?path=<ruta de la nota>`, que funciona como un link web pero abre Obsidian.

> [!important] Por qué Obsidian se reinicia la primera vez
> Obsidian solo abre archivos de **bóvedas registradas** en `%APPDATA%\obsidian\obsidian.json`, y mientras está abierto tiene esa lista **en memoria**: si se edita el archivo con Obsidian abierto, no se entera. Se verificó en el código de Obsidian instalado (`resources/obsidian.asar`): la URI busca la bóveda en la lista en memoria y, si no la encuentra, muestra "Vault not found".

Con una bóveda nueva:
1. Pregunta si puede cerrar Obsidian. Si no, muestra la ruta para abrirla a mano con *Abrir carpeta como bóveda*.
2. Cierra Obsidian (`taskkill /IM Obsidian.exe`, cierre normal, sin `/F`) y espera hasta 10 segundos.
3. Agrega la bóveda a `obsidian.json`.
4. Abre la nota: Obsidian arranca y ya conoce la bóveda.

Desde la segunda nota de ese proyecto se abre directo.

**Cuidado con `obsidian.json`:**
- **Solo inserta** la entrada nueva en el texto original. El resto del archivo queda byte por byte igual, porque no se vuelve a codificar el JSON entero (eso podía convertir objetos vacíos `{}` en `[]`).
- Antes de escribir deja una copia en `obsidian.json.bak`.
- Si el archivo no se puede leer (JSON inválido), **no escribe nada** y muestra el error. Antes de este control, un archivo ilegible se hubiera pisado con una lista vacía y se perdían todas las bóvedas.
- Al final vuelve a leer el resultado para confirmar que sigue siendo JSON válido y tiene la bóveda.

---

## `:WikiDocAll`: todo el proyecto

1. **Lista los archivos** con `git ls-files --cached --others --exclude-standard` (respeta `.gitignore`). Si no hay git, recorre las carpetas.
2. **Siempre saltea** `bin/`, `obj/`, `node_modules/`, `.git/` y `.vs/`, aunque no estén en `.gitignore` (si no, entrarían los `.cs` generados en `obj/`).
3. **Analiza cada archivo:** lo carga en un buffer oculto para que el LSP se conecte (espera hasta 10 segundos por archivo) y le pide los datos.
4. **Calcula "Usa"** invirtiendo "Usado por".
5. **Escribe todas las notas** (crea las que faltan y regenera la sección automática de las existentes).
6. **Cierra los buffers** que abrió, salvo los que estén visibles o modificados.
7. Abre en Obsidian la nota del archivo actual.

El progreso se muestra en **una sola notificación** que se va actualizando ("Analizando 5/7 · Program.cs"). Todo corre en una corrutina, así Neovim no se traba. Si ya está corriendo, un segundo `:WikiDocAll` avisa y no hace nada.

> [!warning] Esperar a que Roslyn cargue la solución
> Si se corre antes de que Roslyn termine de cargar, "Usado por" puede salir vacío: Roslyn todavía no conoce los otros archivos. Con cientos de archivos puede tardar unos minutos.

---

## Notificaciones en violeta

Los avisos informativos ("Creando la wiki…", "Nota creada", "Analizando…", "Wiki lista") salen en **violeta**. Advertencias y errores siguen en amarillo y rojo.

- El violeta es el color `purple` del tema actual de base46 (`#bb9af7` en tokyonight). Si se cambia de tema, se adapta.
- Se usa un **nivel propio `WIKI`** de nvim-notify. nvim-notify acepta niveles no estándar y busca sus colores en los grupos `NotifyWIKIBorder`, `NotifyWIKIIcon`, `NotifyWIKITitle` y `NotifyWIKIBody`, que el módulo define antes de cada aviso.
- Estos avisos se mandan **directo a nvim-notify**, sin pasar por noice, así que **no aparecen en el historial de noice** (`<leader>nh`). Advertencias y errores sí aparecen.

---

## Cambios realizados

### `lua/configs/wiki_doc.lua` (nuevo)

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\configs\wiki_doc.lua`

| Parte | Qué hace |
|---|---|
| `notify()` | Avisos en violeta (nivel `WIKI`); devuelve el registro para actualizar el mismo aviso |
| `read_registry()` / `register()` | Leen y agregan bóvedas en `obsidian.json` con los controles de arriba |
| `obsidian_running()` / `close_obsidian()` | Detectan y cierran Obsidian (`tasklist` / `taskkill`) |
| `open_in_obsidian()` | Abre la URI, registrando la bóveda si hace falta |
| `wiki_base()` | `~/Desktop/wiki`, o `M.base` si se cambió |
| `create_vault()` | Copia la plantilla `.obsidian` con `robocopy` (async) |
| `note_path()` / `ensure_note()` | Nombre de la nota (sin extensión, con `(ext)` si choca) y creación con la plantilla |
| `auto_section()` / `write_auto()` | Arman la sección automática y la reemplazan entre los marcadores |
| `M.create()` | `:WikiDoc` |
| `project_files()` / `M.create_all()` | `:WikiDocAll` |

### `lua/configs/wiki_doc_lsp.lua` (nuevo)

**Path completo:** `C:\Users\diazt\AppData\Local\nvim\lua\configs\wiki_doc_lsp.lua`

| Parte | Qué hace |
|---|---|
| `run()` / `request()` / `sleep()` | Corrutinas: cada pedido al LSP "espera" sin trabar Neovim, con timeout de 15 s |
| `client_for()` / `wait_client()` | Primer cliente del buffer que soporte `documentSymbol`; espera a que se conecte |
| `collect_types()` | Saca clases, interfaces, structs y enums (entrando en namespaces). Acepta los dos formatos de respuesta: árbol (`DocumentSymbol`) y lista plana (`SymbolInformation`) |
| `analyze()` | Hace los pedidos de la tabla de relaciones para cada tipo del archivo |

### `lua/mappings.lua`

```lua
vim.api.nvim_create_user_command("WikiDoc", function()
  require("configs.wiki_doc").create()
end, { desc = "Documentar el archivo actual en la wiki de Obsidian" })
map("n", "<leader>wd", "<cmd>WikiDoc<cr>", { desc = "Wiki: documentar archivo actual" })

vim.api.nvim_create_user_command("WikiDocAll", function(opts)
  require("configs.wiki_doc").create_all(opts.fargs)
end, { nargs = "*", desc = "Documentar todo el proyecto en la wiki de Obsidian" })
map("n", "<leader>wD", "<cmd>WikiDocAll<cr>", { desc = "Wiki: documentar todo el proyecto" })
```

---

## Pruebas

Se probó en modo headless con la config completa y **Roslyn real**, sobre un proyecto C# de prueba de 7 archivos (`EntidadBase`, `Usuario`, `IUsuarioRepositorio`, `UsuarioRepositorio`, `EmailService`, `UsuarioService`, `Program`). Obsidian se simuló para no cerrar el que estaba abierto, y se usó un `obsidian.json` falso.

| Prueba | Resultado |
|---|---|
| Roslyn soporta `references`, `implementation`, `typeHierarchy`, `callHierarchy` | Sí, los cuatro |
| `:WikiDocAll` | 7 notas creadas con las relaciones correctas |
| `Usuario` | Hereda de `EntidadBase`; usado por el repositorio y el servicio |
| `IUsuarioRepositorio` | Implementado por `UsuarioRepositorio` |
| `UsuarioService` | Usa la interfaz, `Usuario` y `EmailService`; usado por `Program` |
| `Program` (sin clases, top-level) | Usa el servicio, el repositorio y `EmailService` |
| `:WikiDoc` con texto propio en "Qué hace" | El texto se conserva; solo se regenera la sección automática |
| `Usuario.cs` y `Usuario.xaml` en la misma carpeta | `Usuario.md` y `Usuario (xaml).md` |
| `obsidian.json`: copia del real, inválido, vacío, sin archivo, con `{}` | Conserva las bóvedas existentes; con el inválido no escribe nada |

---

## Problemas conocidos

- **"Usado por" vacío:** Roslyn todavía estaba cargando la solución. Esperar y volver a correr.
- **Obsidian no se cierra:** cerrarlo a mano y volver a correr el comando.
- **OneDrive:** si se cambia la ubicación a una carpeta dentro de OneDrive, se sincronizan los ~160 MB por wiki, y OneDrive puede bloquear archivos que Obsidian está usando.
- **Plugins de la comunidad:** Obsidian puede preguntar si se confía en ellos la primera vez que abre una bóveda nueva.

## Personalización

- **Cambiar dónde se crean las wikis** (usar siempre `~` para que funcione en cualquier PC), en `lua/mappings.lua`:

```lua
require("configs.wiki_doc").base = vim.fn.expand "~/wiki"
```

- **Otra plantilla de Obsidian:** cambiar `M.template` en `wiki_doc.lua`.
- **Timeout de los pedidos al LSP:** `require("configs.wiki_doc_lsp").timeout = 30000` (ms).
- **Plantilla de la nota:** editar `note_content()` en `wiki_doc.lua`.

## Próximas ideas

- **Colores por capa en el grafo:** agregar `tipo` y `capa` al frontmatter y configurar los grupos de color del Graph View (Controllers, Services, Repositorios…).
- **`:WikiCanvas`:** generar un `.canvas` de Obsidian con una tarjeta por clase, ordenadas por capa y unidas por sus dependencias.

Ver también: [[Comandos y atajos de NvChad]] · [[Soporte .NET en NvChad]] · [[Notificaciones y cmdline con noice]]
