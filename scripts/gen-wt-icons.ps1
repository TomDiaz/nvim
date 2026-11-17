# Genera el fragment de Windows Terminal con un perfil oculto "nvim-<ext>"
# por cada PNG en assets\icons (usado por lua/configs/wt_open.lua).
# Volver a correrlo después de agregar/quitar íconos y reiniciar Windows Terminal.

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

Write-Host "$($profiles.Count) perfiles -> $outFile"
Write-Host "Reinicia Windows Terminal para que cargue los cambios."
