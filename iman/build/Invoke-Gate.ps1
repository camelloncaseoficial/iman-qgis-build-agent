<#
.SYNOPSIS
  Comando de gate PROPOSTO para o kind qgis-build (o oficial e registrado pelo arquiteto no crew_gate.sh).

.DESCRIPTION
  Um comando, tres verificacoes, na arvore commitada:
    1. patchset: Test-Patchset.ps1 (todo arquivo do QGIS alterado esta em iman/PATCHES.md, e vice-versa);
    2. build incremental: Build-Qgis.ps1 sem -Clean, sem rede para dependencias (Get-Osgeo4wPackages -Offline);
    3. smoke: Invoke-Smoke.ps1 (versao, provedores, plugins, native:buffer, janela + .qgz, guarda do QGIS oficial).
  Pre-requisito: a bancada ja montada uma vez por Invoke-ImanBuild.ps1. Sai com 0 so se as tres passarem.
#>
[CmdletBinding()]
param([string] $WorkRoot)
. "$PSScriptRoot\Common.ps1"
$wr = @{ WorkRoot = $WorkRoot }
$ErrorActionPreference = 'Continue'

$dirty = & git -C $RepoRoot status --porcelain
if ($dirty) { Write-Host 'GATE: arvore com mudanca nao commitada; o gate roda na arvore commitada'; $dirty; exit 1 }
Write-Host "GATE qgis-build em $(& git -C $RepoRoot rev-parse --short HEAD)"

& pwsh -NoProfile -File "$PSScriptRoot\Test-Patchset.ps1" @wr
if ($LASTEXITCODE) { Write-Host 'GATE FALHOU: patchset'; exit 1 }

& pwsh -NoProfile -File "$PSScriptRoot\Get-Osgeo4wPackages.ps1" @wr -Offline
if ($LASTEXITCODE) { Write-Host 'GATE FALHOU: dependencias'; exit 1 }

& pwsh -NoProfile -File "$PSScriptRoot\Build-Qgis.ps1" @wr
if ($LASTEXITCODE) { Write-Host 'GATE FALHOU: build'; exit 1 }

& pwsh -NoProfile -File "$PSScriptRoot\Invoke-Smoke.ps1" @wr
if ($LASTEXITCODE) { Write-Host 'GATE FALHOU: smoke'; exit 1 }

Write-Host 'GATE OK'
