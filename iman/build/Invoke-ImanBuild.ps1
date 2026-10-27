<#
.SYNOPSIS
  Do clone limpo ao binario, sem passo manual: ferramentas, dependencias fixadas, build, smoke.

.EXAMPLE
  pwsh -File iman/build/Invoke-ImanBuild.ps1 -Clean -Smoke
  pwsh -File iman/build/Invoke-ImanBuild.ps1 -Offline -SkipTools      # so cache local, sem rede

.NOTES
  O primeiro uso numa maquina instala o VS 2022 Build Tools (UAC): so com a confirmacao do sponsor.
  Tudo que e gerado vai para $WorkRoot (padrao D:\iman-terra-build, ou $env:IMAN_BUILD_ROOT); nada no repo.
  Cada passo roda num pwsh filho, com o ambiente limpo (o4w_env e vcvars nao vazam de um passo para outro).
#>
[CmdletBinding()]
param([string] $WorkRoot, [switch] $Clean, [switch] $Offline, [switch] $SkipTools, [switch] $Smoke, [string] $Lock)
. "$PSScriptRoot\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path
$t0 = Get-Date

function Invoke-Step([string] $script, [string[]] $extra) {
  & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot $script) -WorkRoot $WorkRoot @extra
  if ($LASTEXITCODE) { Write-Step "$script falhou (exit $LASTEXITCODE)"; exit 1 }
}

# retrato do QGIS oficial no comeco de cada rodada, antes de qualquer passo: a guarda do smoke prova que esta
# rodada nao tocou o oficial (ressalva R1 do gate 043)
Invoke-Step 'Test-OfficialQgisUntouched.ps1' @('-Baseline')
if (-not $SkipTools) { Invoke-Step 'Install-BuildTools.ps1' @() }
$depArgs = @(); if ($Offline) { $depArgs += '-Offline' }; if ($Lock) { $depArgs += @('-Lock', $Lock) }
Invoke-Step 'Get-Osgeo4wPackages.ps1' $depArgs
Invoke-Step 'Build-Qgis.ps1' $(if ($Clean) { @('-Clean') } else { @() })
if ($Smoke) { Invoke-Step 'Invoke-Smoke.ps1' @() }
Write-Step ("pronto em {0:hh\:mm\:ss}: {1}" -f ((Get-Date) - $t0), (Join-Path $Paths.Install 'apps\qgis-ltr\bin\qgis.exe'))
