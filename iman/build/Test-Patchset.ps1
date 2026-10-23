<#
.SYNOPSIS
  Confere o patchset (BL-5): todo arquivo do QGIS alterado desde a tag base esta listado em iman/PATCHES.md, e
  todo arquivo listado esta de fato alterado. Sai com 1 se divergir.
#>
[CmdletBinding()]
param([string] $WorkRoot, [string] $BaseTag = 'final-3_44_13')
. "$PSScriptRoot\Common.ps1"

$changed = @(& git -C $RepoRoot diff --name-only "$BaseTag..HEAD" -- . ':!iman' ':!.claude' ':!.memory' ':!CLAUDE.md')
if ($LASTEXITCODE) { throw "git diff falhou (a tag $BaseTag existe neste clone?)" }
$listed = @(Get-Content (Join-Path $RepoRoot 'iman\PATCHES.md') |
  Where-Object { $_ -match '^\|\s*`([^`]+)`\s*\|' } | ForEach-Object { ([regex]::Match($_, '^\|\s*`([^`]+)`')).Groups[1].Value })

$notListed = @($changed | Where-Object { $_ -notin $listed })
$notChanged = @($listed | Where-Object { $_ -notin $changed })
Write-Host "patchset: $($changed.Count) arquivo(s) do QGIS alterado(s) desde $BaseTag; $($listed.Count) listado(s) em iman/PATCHES.md"
$notListed | ForEach-Object { Write-Host "  alterado e NAO listado: $_" }
$notChanged | ForEach-Object { Write-Host "  listado e NAO alterado: $_" }
if ($notListed -or $notChanged) { Write-Host 'PATCHSET FALHOU'; exit 1 }
Write-Host 'PATCHSET OK'
