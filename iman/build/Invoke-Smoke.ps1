<#
.SYNOPSIS
  Smoke do QGIS compilado (briefing 043, item 4), sempre com perfil descartavel numa pasta nova.

.DESCRIPTION
  -Target Build (padrao): o binario de $WorkRoot\install contra a raiz $WorkRoot\osgeo4w.
    1. qgis_process --version, --json list (provedores) e --json plugins;
    2. qgis_process run native:buffer no fixture points.geojson; confere 3 feicoes na saida;
    3. qgis.exe abre a janela, carrega o smoke.qgz (gerado do fixture smoke.qgs), grava capturas e fecha;
    4. guarda: Test-OfficialQgisUntouched.ps1 (o QGIS oficial, o perfil e o registro dele nao mudaram).
  -Target Official: so o passo 1, contra o QGIS 3.44.13 oficial instalado (comparacao; nada e gravado nele).
  Saida: $WorkRoot\smoke\<target>-<data>\ (summary.json, capturas, logs). Sai com 1 se algum passo falhar.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official')] [string] $Target = 'Build',
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [int] $GuiTimeoutSeconds = 240
)
. "$PSScriptRoot\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path   # o o4w_env troca o PATH: pwsh e git sao resolvidos antes
$gitExe = (Get-Command git.exe -ErrorAction Stop).Source

if ($Target -eq 'Build') { $o4w = $Paths.Osgeo4w; $app = Join-Path $Paths.Install 'apps\qgis-ltr' }
else { $o4w = $OfficialRoot; $app = Join-Path $OfficialRoot 'apps\qgis-ltr' }
if (-not (Test-Path "$app\bin\qgis_process.exe")) { throw "qgis_process ausente em $app\bin" }

$run = Join-Path $Paths.Smoke ("{0}-{1}" -f $Target.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
$profiles = Join-Path $run 'profiles'
$work = Join-Path $run 'work'
New-Item -ItemType Directory -Force $profiles, $work | Out-Null

# ambiente de runtime: o mesmo de bin\qgis_process-qgis-ltr.bat do oficial (o4w_env, GRASS, apps\qgis-ltr)
$grassEnv = Get-ChildItem "$o4w\apps\grass\grass*\etc\env.bat" -ErrorAction SilentlyContinue | Select-Object -First 1
$cmdline = "call `"$o4w\bin\o4w_env.bat`" >nul"
if ($grassEnv) { $cmdline += " && call `"$($grassEnv.FullName)`" >nul" }
$lines = & cmd.exe /c "$cmdline && set"
foreach ($l in $lines) { if ($l -match '^([^=]+)=(.*)$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] } }
$grassDir = if ($grassEnv) { Split-Path (Split-Path $grassEnv.FullName) } else { $null }
$env:PATH = (@("$app\bin") + $(if ($grassDir) { @("$grassDir\lib", "$grassDir\bin") } else { @() }) + @($env:PATH)) -join ';'
$env:QGIS_PREFIX_PATH = $app -replace '\\', '/'
$env:GDAL_FILENAME_IS_UTF8 = 'YES'
$env:VSI_CACHE = 'TRUE'
$env:VSI_CACHE_SIZE = '1000000'
$env:QT_PLUGIN_PATH = "$app\qtplugins;$o4w\apps\qt5\plugins"
$env:PYTHONPATH = "$app\python;$env:PYTHONPATH"
# perfil descartavel: nunca %APPDATA%\QGIS
$env:QGIS_CUSTOM_CONFIG_PATH = $profiles

$summary = [ordered]@{ target = $Target; app = $app; run = $run; profiles = $profiles; steps = [ordered]@{} }
$failed = $false
function Add-Result([string] $name, [bool] $ok, $detail) {
  $summary.steps[$name] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-14} {1}  {2}" -f $name, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 4))
  if (-not $ok) { $script:failed = $true }
}

$qp = "$app\bin\qgis_process.exe"
$ver = & $qp --version 2>&1 | Out-String
Set-Content (Join-Path $run 'version.txt') $ver
$verOk = $LASTEXITCODE -eq 0 -and $ver -match 'QGIS 3\.44\.13'
$rev = if ($ver -match 'QGIS code revision ([0-9a-f]+)') { $Matches[1] } else { 'unknown' }
if ($Target -eq 'Build') {
  # BL-6: o binario se identifica pelo commit publico de que saiu
  $head = (& $gitExe -C $RepoRoot rev-parse HEAD).Trim()
  $verOk = $verOk -and $rev -ne 'unknown' -and $head.StartsWith($rev)
  $summary.head = $head
}
Add-Result 'version' $verOk ([ordered]@{ revision = $rev; lines = @($ver.Trim() -split "`r?`n" | Select-Object -First 3) })

$listRaw = & $qp --json list 2>$null | Out-String
Set-Content (Join-Path $run 'list.json') $listRaw
try {
  $list = $listRaw | ConvertFrom-Json
  $providers = @($list.providers.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object)
  $algCount = ($list.providers.PSObject.Properties | ForEach-Object { @($_.Value.algorithms.PSObject.Properties).Count } | Measure-Object -Sum).Sum
  $hasBuffer = [bool]($list.providers.native.algorithms.PSObject.Properties.Name -contains 'native:buffer')
  Add-Result 'providers' ($providers.Count -gt 0 -and $hasBuffer) ([ordered]@{ providers = $providers; algorithms = $algCount })
} catch { Add-Result 'providers' $false "json invalido: $_" }

$plugRaw = & $qp --json plugins 2>$null | Out-String
Set-Content (Join-Path $run 'plugins.json') $plugRaw
try {
  $plugins = @(($plugRaw | ConvertFrom-Json).plugins.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object)
  Add-Result 'plugins' ($plugins.Count -gt 0) $plugins
} catch { Add-Result 'plugins' $false "json invalido: $_" }
$corePlugins = @(Get-ChildItem "$app\python\plugins" -Directory -ErrorAction SilentlyContinue | ForEach-Object Name | Sort-Object)
$summary.corePluginFolders = $corePlugins

if ($Target -eq 'Build') {
  $fx = Join-Path $PSScriptRoot 'smoke\fixtures'
  Copy-Item "$fx\points.geojson" $work
  $bufOut = Join-Path $work 'buffer.gpkg'
  $res = & $qp --json run native:buffer -- "INPUT=$work\points.geojson" 'DISTANCE=0.01' 'SEGMENTS=8' "OUTPUT=$bufOut" 2>&1 | Out-String
  Set-Content (Join-Path $run 'buffer.json') $res
  $exit = $LASTEXITCODE
  $info = & "$o4w\bin\ogrinfo.exe" -so -al $bufOut 2>&1 | Out-String
  $count = if ($info -match 'Feature Count:\s*(\d+)') { [int]$Matches[1] } else { -1 }
  $geom = if ($info -match 'Geometry:\s*([^\r\n]+)') { $Matches[1] } else { '' }
  Add-Result 'native:buffer' ($exit -eq 0 -and $count -eq 3 -and $geom -match 'Polygon') ([ordered]@{ exit = $exit; features = $count; geometry = $geom })

  # GUI: .qgz montado a partir do .qgs versionado (zip com o .qgs na raiz)
  $qgz = Join-Path $work 'smoke.qgz'
  $stage = Join-Path $run 'qgz'
  New-Item -ItemType Directory -Force $stage | Out-Null
  Copy-Item "$fx\smoke.qgs" $stage
  Compress-Archive -Path "$stage\smoke.qgs" -DestinationPath $qgz -Force
  $env:IMAN_SMOKE_OUT = $run
  $env:IMAN_SMOKE_PROJECT = $qgz
  $t0 = Get-Date
  $p = Start-Process -FilePath "$app\bin\qgis.exe" -PassThru -ArgumentList @(
    '--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--nologo', '--noversioncheck',
    '--code', "`"$(Join-Path $PSScriptRoot 'smoke\smoke_gui.py')`"")
  $exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
  if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }
  $guiJson = Join-Path $run 'gui.json'
  if (Test-Path $guiJson) {
    $g = Get-Content $guiJson -Raw | ConvertFrom-Json
    $layer = @($g.layers)[0]
    $ok = $g.project_read -and $g.window_visible -and $layer.valid -and $layer.features -eq 3 -and $exited
    Add-Result 'gui+qgz' $ok ([ordered]@{ seconds = [int]((Get-Date) - $t0).TotalSeconds; exitedClean = $exited; exitCode = $(if ($exited) { $p.ExitCode } else { $null }); title = $g.window_title; layers = $g.layers; capture = 'gui.png' })
  } else {
    Add-Result 'gui+qgz' $false ([ordered]@{ exitedClean = $exited; note = 'gui.json nao foi gravado' })
  }

  $guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
  Add-Result 'guard' ($LASTEXITCODE -eq 0) ($guard.Trim() -split "`r?`n" | Select-Object -Last 1)
  $summary.profileWrittenTo = @(Get-ChildItem $profiles -Recurse -File | ForEach-Object { $_.FullName.Substring($profiles.Length) })
}

$summary.ok = -not $failed
$summary | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $run 'summary.json')
Write-Step "smoke $Target $(if ($failed) { 'FALHOU' } else { 'OK' }): $run"
if ($failed) { exit 1 }
