<#
.SYNOPSIS
  Abre o build com um perfil descartavel novo, para o smoke do sponsor (briefing 044).

.DESCRIPTION
  Cria $WorkRoot\smoke\sponsor-<data>\profiles (perfil novo, com o cache de rede dentro dele), monta o ambiente de
  runtime da raiz OSGeo4W fixada e abre o qgis.exe de $WorkRoot\install. Nao passa --lang: o idioma e o padrao do
  produto. Nada e gravado em %APPDATA%\QGIS nem no QGIS oficial.

.EXAMPLE
  pwsh -NoProfile -File iman/build/Start-ImanTerra.ps1
#>
[CmdletBinding()]
param([string] $WorkRoot)
. "$PSScriptRoot\Common.ps1"

$app = Join-Path $Paths.Install 'apps\qgis-ltr'
$run = Join-Path $Paths.Smoke ("sponsor-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$profiles = Join-Path $run 'profiles'
New-DisposableProfile $profiles (Join-Path $run 'cache')
Import-QgisRuntime $Paths.Osgeo4w $app $profiles
Write-Step "perfil descartavel: $profiles"
Start-Process -FilePath "$app\bin\qgis.exe" -ArgumentList @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke')
