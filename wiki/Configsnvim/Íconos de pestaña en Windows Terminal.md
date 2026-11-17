---
tags: [nvim, nvchad, windows-terminal, iconos]
fecha: 2026-11-17
---

# Íconos de pestaña en Windows Terminal

Cuando se abre un archivo con `Ctrl + o` (desde Telescope o desde el panel de neogit), se abre en una **pestaña nueva de Windows Terminal** que muestra el **ícono PNG de su tipo de archivo** y tiene el nombre del archivo como título.

**Entorno:** Neovim 0.12.5 · NvChad v2.5 · Windows 11 · Windows Terminal

---

## Cómo funciona

Windows Terminal no deja elegir el ícono de una pestaña desde la línea de comandos: el ícono sale del **perfil** con el que se abre. Por eso:

1. Hay un **perfil oculto por cada extensión** (`nvim-cs`, `nvim-lua`, `nvim-json`, …) y cada uno tiene su PNG como ícono.
2. `lua/configs/wt_open.lua` toma la extensión del archivo y abre la pestaña con `wt -p "nvim-<ext>"`.
3. Si no hay un PNG para esa extensión, usa el perfil `nvim-file` (ícono genérico).

Los perfiles no están en el `settings.json` de Windows Terminal, sino en un **fragment**: un JSON aparte que Windows Terminal carga al arrancar y que agrega perfiles sin tocar la configuración principal.

| Qué | Dónde |
|---|---|
| Íconos PNG | `%LOCALAPPDATA%\nvim\assets\icons\<ext>.png` |
| Script que genera el fragment | `%LOCALAPPDATA%\nvim\scripts\gen-wt-icons.ps1` |
| Fragment generado | `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\nvim-icons\nvim-icons.json` |
| Lógica de apertura | `%LOCALAPPDATA%\nvim\lua\configs\wt_open.lua` |

> [!warning] El fragment no está en el repo
> El fragment está en la carpeta de Windows Terminal, fuera de la config de Neovim. En una máquina nueva (o si se borra), hay que **correr el script** para que vuelvan a aparecer los íconos. Sin el fragment, las pestañas se abren sin ícono.

---

## Script `gen-wt-icons.ps1`

**Path completo:** `%LOCALAPPDATA%\nvim\scripts\gen-wt-icons.ps1`

Recorre `assets\icons`, crea un perfil por cada PNG y escribe el fragment:

```powershell
$iconsDir = Join-Path (Split-Path $PSScriptRoot -Parent) "assets\icons"
$outDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\Fragments\nvim-icons"
$outFile = Join-Path $outDir "nvim-icons.json"

$profiles = @(Get-ChildItem $iconsDir -Filter *.png | Sort-Object Name | ForEach-Object {
  [ordered]@{
    name        = "nvim-$($_.BaseName.ToLower())"
    commandline = "nvim"
    icon        = $_.FullName
    hidden      = $true
  }
})

New-Item -ItemType Directory -Force $outDir | Out-Null
# UTF-8 sin BOM; Set-Content -Encoding utf8NoBOM no existe en Windows PowerShell 5.1
$json = @{ profiles = $profiles } | ConvertTo-Json -Depth 3
[IO.File]::WriteAllText($outFile, $json, (New-Object Text.UTF8Encoding $false))
```

> [!note] Compatible con PowerShell 5.1 y 7
> El archivo se escribe con `[IO.File]::WriteAllText` en vez de `Set-Content -Encoding utf8NoBOM`, porque ese valor no existe en la versión de PowerShell que trae Windows (5.1) y daba el error *"No se puede enlazar el parámetro 'Encoding'"*.

Cada perfil generado queda así:

```json
{
  "name": "nvim-cs",
  "commandline": "nvim",
  "icon": "C:\\Users\\TomasDiaz\\AppData\\Local\\nvim\\assets\\icons\\cs.png",
  "hidden": true
}
```

| Campo | Para qué |
|---|---|
| `name` | `nvim-<ext>`, el nombre que busca `wt_open.lua` con `wt -p` |
| `commandline` | `nvim`; igual se reemplaza por el comando que manda `wt_open.lua` |
| `icon` | Ruta absoluta al PNG (la saca de la ubicación del script, así que funciona aunque cambie el usuario) |
| `hidden` | `true` para que los perfiles no aparezcan en el menú desplegable de Windows Terminal |

### Correrlo

```powershell
& "$env:LOCALAPPDATA\nvim\scripts\gen-wt-icons.ps1"
```

Salida esperada:

```
40 perfiles -> C:\Users\...\Fragments\nvim-icons\nvim-icons.json
Reinicia Windows Terminal para que cargue los cambios.
```

Después hay que **cerrar todas las ventanas de Windows Terminal y volver a abrirlo**: los fragments solo se leen al arrancar.

---

## Agregar un ícono nuevo

1. Guardar el PNG en `assets\icons\` con el nombre de la extensión en minúsculas, por ejemplo `ts.png` para archivos `.ts`.
2. Correr el script.
3. Reiniciar Windows Terminal.

> [!tip] Archivos sin extensión
> Para archivos que empiezan con punto, como `.editorconfig`, `wt_open.lua` usa el nombre sin el punto. Por eso el ícono se llama `editorconfig.png`.

---

## Problemas comunes

> [!bug] Errores frecuentes
> - **La pestaña abre sin ícono:** falta el fragment o Windows Terminal no se reinició. Correr el script y cerrar todas las ventanas.
> - **Todas las pestañas `nvim-*` salen con el ícono por defecto:** revisar que `profiles.defaults` del `settings.json` de Windows Terminal no tenga `"icon"` (ni siquiera `null`). Lo que está en `defaults` tiene prioridad sobre lo que define el fragment y le borra el ícono a todos los perfiles.
> - **Se abre con el ícono genérico:** no hay un PNG con el nombre de esa extensión en `assets\icons`.
> - **Windows Terminal avisa de un error en un fragment al arrancar:** el JSON está mal formado. Volver a correr el script en lugar de editar el JSON a mano.

Ver también: [[Git estilo VS Code]] · [[Comandos y atajos de NvChad]]
