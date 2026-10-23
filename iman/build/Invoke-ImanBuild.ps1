<#
.SYNOPSIS
  Do clone limpo ao binario, sem passo manual: ferramentas, dependencias fixadas, build, smoke.

.EXAMPLE
  pwsh -File iman/build/Invoke-ImanBuild.ps1 -Clean -Smoke
  pwsh -File iman/build/Invoke-ImanBuild.ps1 -Offline -SkipTools      # so cache local, sem rede

.NOTES
  O primeiro uso numa maquina instala o VS 2022 Build Tools (UAC): so com a confirmacao do sponsor.
  Tudo que e gerado vai para $WorkRoot (padrao D:\iman-terra-build, ou $env:IMAN_BUILD_ROOT); nada no repo.
#>
[CmdletBinding()]
param([string] $WorkRoot, [switch] $Clean, [switch] $Offline, [switch] $SkipTools, [switch] $Smoke)
. "$PSScriptRoot\Common.ps1"
$wr = @{ WorkRoot = $WorkRoot }
$t0 = Get-Date

if (-not $SkipTools) { & "$PSScriptRoot\Install-BuildTools.ps1" @wr }
& "$PSScriptRoot\Get-Osgeo4wPackages.ps1" @wr -Offline:$Offline
& "$PSScriptRoot\Build-Qgis.ps1" @wr -Clean:$Clean
if ($Smoke) {
  & "$PSScriptRoot\Invoke-Smoke.ps1" @wr
  if ($LASTEXITCODE) { Write-Step "smoke falhou"; exit 1 }
}
Write-Step ("pronto em {0:hh\:mm\:ss}: {1}" -f ((Get-Date) - $t0), (Join-Path $Paths.Install 'apps\qgis-ltr\bin\qgis.exe'))
