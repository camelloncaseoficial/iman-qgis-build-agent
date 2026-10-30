<#
.SYNOPSIS
  P1 do patch de 2026-10-29 da fatia 047: a arvore do produto sem o driver ECW/JP2 (pacote gdal-ecw), medida na
  arvore, no manifesto e no GDAL, com o "visto falhando" contra o QGIS 3.44.13 oficial (so lido).

.DESCRIPTION
  -Root: a arvore a medir (padrao: a instalada, %LOCALAPPDATA%\Programs\IMAN Terra; para a montada pelo
  New-RuntimeTree.ps1, $WorkRoot\stage\tree).
    1. busca na arvore inteira por NCSEcw.dll e gdal_ECW_JP2ECW.dll, os dois arquivos do gdal-ecw.lst.gz do oficial:
       nenhum;
    2. o conjunto pelo manifesto: o alvo e o installed.db do oficial menos os qgis-ltr* e menos o gdal-ecw. O
       Test-RuntimeSet.ps1 (A4, intocado) compara com o oficial menos os qgis-ltr*; contra o alvo, a diferenca e
       vazia quando a dele e exatamente "so-no-oficial gdal-ecw <arquivo>", sem -devel e sem pacote com diferenca de
       arquivo;
    3. os drivers do GDAL (gdalinfo --formats com o bin\o4w_env.bat de cada arvore): no produto, sem ECW nem JP2ECW
       e com JP2OpenJPEG; no oficial, a mesma checagem tem de reprovar (ECW e JP2ECW presentes): o visto falhando;
    4. guarda no comeco e no fim.
  Saida em $WorkRoot\verify\no-ecw-<data>\ (result.json, as listas de drivers). Sai com 1 se alguma checagem falhar.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [string] $Root = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13'
)
. "$PSScriptRoot\..\build\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path
$run = Join-Path $WorkRoot ("verify\no-ecw-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$guardDir = Join-Path $run 'guard'
New-Item -ItemType Directory -Force $run, $guardDir | Out-Null
$result = [ordered]@{ run = $run; root = $Root; official = $OfficialRoot; checks = [ordered]@{} }
function Add-Check([string] $id, [bool] $ok, $detail) {
  $result.checks[$id] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-30} {1}  {2}" -f $id, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 6))
}
function Invoke-Guard([switch] $Baseline) {
  $a = @('-NoProfile', '-File', (Join-Path $RepoRoot 'iman\build\Test-OfficialQgisUntouched.ps1'), '-WorkRoot', $WorkRoot, '-GuardDir', $guardDir)
  if ($Baseline) { $a += '-Baseline' }
  $o = & $pwshExe @a 2>&1 | Out-String
  [pscustomobject]@{ exit = $LASTEXITCODE; last = ($o.Trim() -split "`r?`n" | Select-Object -Last 1) }
}
# gdalinfo --formats no ambiente do o4w_env.bat da arvore (o mesmo para os dois alvos), por um .cmd da rodada
function Get-GdalDrivers([string] $treeRoot, [string] $label) {
  $cmd = Join-Path $run "gdal-formats-$label.cmd"
  [IO.File]::WriteAllLines($cmd, @('@echo off', "call `"$treeRoot\bin\o4w_env.bat`" >nul 2>&1", 'gdalinfo --formats'), [Text.Encoding]::ASCII)
  $out = @(& cmd.exe /d /c $cmd 2>&1 | ForEach-Object { "$_" })
  $exit = $LASTEXITCODE
  $out | Set-Content (Join-Path $run "gdal-formats-$label.txt")
  [pscustomobject]@{ exit = $exit; drivers = @($out | ForEach-Object { if ($_ -match '^\s+(\S+)\s+-') { $Matches[1] } }) }
}

$null = Invoke-Guard -Baseline

# 1. arquivos do gdal-ecw na arvore
$ecwFiles = @('NCSEcw.dll', 'gdal_ECW_JP2ECW.dll')
$found = @(Get-ChildItem $Root -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -in $ecwFiles } | ForEach-Object FullName)
$inOfficial = @($ecwFiles | ForEach-Object { Get-ChildItem $OfficialRoot -Recurse -File -Filter $_ -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName })
Add-Check 'P1:sem-arquivo-ecw' ($found.Count -eq 0) ([ordered]@{ searched = $ecwFiles; found = $found; controlInOfficial = $inOfficial })

# 2. conjunto pelo manifesto
$offDb = @{}
Get-Content (Join-Path $OfficialRoot 'etc\setup\installed.db') | Select-Object -Skip 1 | ForEach-Object { $n, $f, $null = $_ -split '\s+'; if ($n) { $offDb[$n] = $f } }
$expected = @("so-no-oficial gdal-ecw $($offDb['gdal-ecw'])")
$rsOut = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-RuntimeSet.ps1') -WorkRoot $WorkRoot -Root $Root -OfficialRoot $OfficialRoot 2>&1 | Out-String
$rsExit = $LASTEXITCODE
$rsDir = if ($rsOut -match 'conjunto (?:OK|FALHOU): ([^\r\n]+)') { $Matches[1].Trim() } else { $null }
$rs = if ($rsDir -and (Test-Path "$rsDir\result.json")) { Get-Content "$rsDir\result.json" -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$diff = @($rs.packages.differences)
$okSet = $rs -and $offDb['gdal-ecw'] -and (($diff -join "`n") -eq ($expected -join "`n")) -and @($rs.packages.devel).Count -eq 0 -and
  $rs.filesPerPackage.withDifferences -eq 0
Add-Check 'P1:conjunto-oficial-menos-ecw' $okSet ([ordered]@{
    target = 'installed.db do oficial menos qgis-ltr* e gdal-ecw, mais o nosso build'
    testRuntimeSet = [ordered]@{ exit = $rsExit; run = $rsDir; differences = $diff; expected = $expected; devel = @($rs.packages.devel)
      packagesCompared = $rs.filesPerPackage.compared; packagesWithFileDifferences = $rs.filesPerPackage.withDifferences }
    treePackages = $rs.packages.treeWithoutOurBuild; officialWithoutQgisLtr = $rs.packages.officialWithoutQgisLtr })

# 3. drivers do GDAL
$ours = Get-GdalDrivers $Root 'produto'
$off = Get-GdalDrivers $OfficialRoot 'oficial'
function Test-NoEcwDrivers($g) { $g.exit -eq 0 -and 'ECW' -notin $g.drivers -and 'JP2ECW' -notin $g.drivers -and 'JP2OpenJPEG' -in $g.drivers }
Add-Check 'P1:gdal-sem-ecw' (Test-NoEcwDrivers $ours) ([ordered]@{ exit = $ours.exit; drivers = $ours.drivers.Count
    ECW = ('ECW' -in $ours.drivers); JP2ECW = ('JP2ECW' -in $ours.drivers); JP2OpenJPEG = ('JP2OpenJPEG' -in $ours.drivers) })
Add-Check 'P1:visto-falhando-no-oficial' ($off.exit -eq 0 -and -not (Test-NoEcwDrivers $off) -and 'ECW' -in $off.drivers -and 'JP2ECW' -in $off.drivers) ([ordered]@{
    exit = $off.exit; drivers = $off.drivers.Count
    ECW = ('ECW' -in $off.drivers); JP2ECW = ('JP2ECW' -in $off.drivers); JP2OpenJPEG = ('JP2OpenJPEG' -in $off.drivers) })

# 4. guarda
$g = Invoke-Guard
Add-Check 'guarda' ($g.exit -eq 0) $g.last

$result.ok = @($result.checks.Values | Where-Object { -not $_.ok }).Count -eq 0
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step "sem ECW $(if ($result.ok) { 'OK' } else { 'FALHOU' }): $run"
if (-not $result.ok) { exit 1 }
