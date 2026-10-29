<#
.SYNOPSIS
  P4 do patch de 2026-10-29 da fatia 047 (ressalva R4): o runtime do Visual C++ que o qgis_process instalado carrega,
  com versao e caminho de cada DLL, em duas chamadas: --json plugins e native:buffer num fixture. So mede: nao troca
  nem move DLL (STOP do briefing).

.DESCRIPTION
  Cada chamada roda bin\qgis_process-iman-terra.bat (o lancador instalado) num perfil descartavel novo
  (QGIS_CUSTOM_CONFIG_PATH na pasta da rodada), com PYQGIS_STARTUP=qgis_process_facts.py, que lista de dentro do
  processo os msvcp140*, vcruntime140* e concrt140* carregados (EnumProcessModules + VerQueryValue, o metodo do A5).
    1. --json plugins: sai com 0 e a saida e JSON;
    2. run native:buffer sobre o points.geojson do smoke: sai com 0 e a saida tem 3 feicoes de poligono (ogrinfo da
       arvore instalada);
    3. o VC++ de cada chamada: pelo menos um modulo, e uma versao so entre todos (versoes misturadas reprovam e sao
       STOP do briefing);
    4. guarda no comeco e no fim.
  Saida em $WorkRoot\verify\qgis-process-runtime-<data>\result.json. Sai com 1 se alguma checagem falhar.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra')
)
. "$PSScriptRoot\..\..\build\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path
$run = Join-Path $WorkRoot ("verify\qgis-process-runtime-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$guardDir = Join-Path $run 'guard'
New-Item -ItemType Directory -Force $run, $guardDir | Out-Null
$result = [ordered]@{ run = $run; installedRoot = $InstalledRoot; checks = [ordered]@{} }
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
$qpBat = Join-Path $InstalledRoot 'bin\qgis_process-iman-terra.bat'
# uma chamada do qgis_process instalado, com os fatos do VC++ gravados de dentro do processo
function Invoke-QgisProcess([string] $label, [string] $arguments) {
  $facts = Join-Path $run "vc-runtime-$label.json"
  $env:PYQGIS_STARTUP = Join-Path $PSScriptRoot 'qgis_process_facts.py'
  $env:IMAN_FACTS_FILE = $facts
  $t0 = Get-Date
  $out = & cmd.exe /d /c "`"$qpBat`" $arguments" 2>$null | Out-String
  $exit = $LASTEXITCODE
  $end = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() / 1000
  $seconds = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
  Remove-Item env:PYQGIS_STARTUP, env:IMAN_FACTS_FILE
  Set-Content (Join-Path $run "qgis_process-$label.json") $out
  $f = if (Test-Path $facts) { Get-Content $facts -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
  # segundos entre a ultima volta da thread e o fim do processo, visto daqui: o que a lista nao cobre
  $gap = if ($f.last_poll_epoch) { [math]::Round($end - $f.last_poll_epoch, 3) } else { $null }
  [pscustomobject]@{ command = "bin\qgis_process-iman-terra.bat $arguments"; exit = $exit; seconds = $seconds; output = $out; facts = $f; uncoveredSeconds = $gap }
}

$null = Invoke-Guard -Baseline
$profiles = Join-Path $run 'profiles'
New-DisposableProfile $profiles (Join-Path $run 'cache') 'Installed'
$env:QGIS_CUSTOM_CONFIG_PATH = $profiles

# 1. --json plugins
$pl = Invoke-QgisProcess 'plugins' '--json plugins'
$plugins = try { @(($pl.output | ConvertFrom-Json).plugins.PSObject.Properties.Name) } catch { @() }
Add-Check 'P4:plugins' ($pl.exit -eq 0 -and $plugins.Count -gt 0) ([ordered]@{ command = $pl.command; exit = $pl.exit; seconds = $pl.seconds; plugins = $plugins })

# 2. native:buffer
Copy-Item (Join-Path $RepoRoot 'iman\build\smoke\fixtures\points.geojson') $run
$bufOut = Join-Path $run 'buffer.gpkg'
$bf = Invoke-QgisProcess 'buffer' "--json run native:buffer -- INPUT=$run\points.geojson DISTANCE=0.01 SEGMENTS=8 OUTPUT=$bufOut"
$ogr = Join-Path $run 'ogrinfo-buffer.cmd'
[IO.File]::WriteAllLines($ogr, @('@echo off', "call `"$InstalledRoot\bin\o4w_env.bat`" >nul 2>&1", "ogrinfo -so -al `"$bufOut`""), [Text.Encoding]::ASCII)
$info = & cmd.exe /d /c $ogr 2>&1 | Out-String
Set-Content (Join-Path $run 'ogrinfo-buffer.txt') $info
$count = if ($info -match 'Feature Count:\s*(\d+)') { [int]$Matches[1] } else { -1 }
$geom = if ($info -match 'Geometry:\s*([^\r\n]+)') { $Matches[1] } else { '' }
Add-Check 'P4:native-buffer' ($bf.exit -eq 0 -and $count -eq 3 -and $geom -match 'Polygon') ([ordered]@{ command = $bf.command; exit = $bf.exit; seconds = $bf.seconds; features = $count; geometry = $geom })
Remove-Item env:QGIS_CUSTOM_CONFIG_PATH

# 3. VC++ carregado
foreach ($c in @(@{ id = 'plugins'; r = $pl }, @{ id = 'buffer'; r = $bf })) {
  $mods = @($c.r.facts.vc_runtime)
  Add-Check "P4:vc-runtime-$($c.id)" ($mods.Count -gt 0) ([ordered]@{ modules = $mods; polls = $c.r.facts.polls; lastPollSeconds = $c.r.facts.last_poll_s
      uncoveredSecondsAtExit = $c.r.uncoveredSeconds; how = 'EnumProcessModules + VerQueryValue dentro do processo (qgis_process_facts.py)' })
}
$all = @(@($pl.facts.vc_runtime) + @($bf.facts.vc_runtime))
$versions = @($all | ForEach-Object version | Sort-Object -Unique)
$dirs = @($all | ForEach-Object { Split-Path $_.module } | Sort-Object -Unique)
Add-Check 'P4:vc-runtime-uma-versao' ($all.Count -gt 0 -and $versions.Count -eq 1) ([ordered]@{ versions = $versions; dirs = $dirs })

# 4. guarda
$g = Invoke-Guard
Add-Check 'guarda' ($g.exit -eq 0) $g.last

$result.ok = @($result.checks.Values | Where-Object { -not $_.ok }).Count -eq 0
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step "qgis_process $(if ($result.ok) { 'OK' } else { 'FALHOU' }): $run"
if (-not $result.ok) { exit 1 }
