<#
.SYNOPSIS
  Capturas por regiao da marca (briefing 044: A5, A8, A9, A13), no build ou no QGIS oficial, sempre com perfil novo.

.DESCRIPTION
  Uma rodada com guarda propria (retrato no comeco, comparacao no fim):
    1. GUI com capture_gui.py: janela, splash montado com a mensagem final, caixa de Processamento, menu Ajuda,
       Sobre, Navegador com o .qgz, Propriedades da camada, Opcoes > Processamento > Provedores;
    2. splash real: o QGIS abre sem --nologo e o splash e capturado da tela enquanto carrega;
    3. crash handler com um relatorio sintetico (A8): o processo "travado" e um ping descartavel; o crash handler
       grava uma pasta em %LOCALAPPDATA%\<org>\<app>\crashes (o nome interno do alvo; o do produto desde a 047): o report.txt dela
       vira evidencia e a pasta criada nesta rodada e removida (decisao do sponsor em 2026-10-25);
    4. caixa de erro de carga (A9) numa COPIA da pasta bin sem o qgis_app.dll, nunca na instalacao de trabalho
       nem no oficial.
  Saida: $WorkRoot\smoke\captures-<target>-<lang>-<data>\ (PNGs, captures.json, summary.json).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official', 'Installed')] [string] $Target = 'Build',
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [string] $Lang = 'pt_BR',
  [int] $GuiTimeoutSeconds = 300
)
. "$PSScriptRoot\Common.ps1"
. "$PSScriptRoot\WindowCapture.ps1"
$pwshExe = (Get-Process -Id $PID).Path

if ($Target -eq 'Build') {
  $o4w = $Paths.Osgeo4w; $app = Join-Path $Paths.Install 'apps\qgis-ltr'; $guiExe = "$app\bin\qgis.exe"
} elseif ($Target -eq 'Installed') {
  # a arvore instalada pelo instalador (fatia 047); o iman-terra.exe aplica o proprio ambiente por cima deste
  $o4w = $InstalledRoot; $app = Join-Path $InstalledRoot 'apps\qgis-ltr'; $guiExe = "$o4w\bin\iman-terra.exe"
} else {
  $o4w = $OfficialRoot; $app = Join-Path $OfficialRoot 'apps\qgis-ltr'; $guiExe = "$o4w\bin\qgis-ltr-bin.exe"
}
$run = Join-Path $Paths.Smoke ("captures-{0}-{1}-{2}" -f $Target.ToLowerInvariant(), $Lang, (Get-Date -Format 'yyyyMMdd-HHmmss'))
$work = Join-Path $run 'work'
New-Item -ItemType Directory -Force $work | Out-Null
$summary = [ordered]@{ target = $Target; lang = $Lang; run = $run; steps = [ordered]@{} }
function Add-Fact([string] $name, $detail) {
  $summary.steps[$name] = $detail
  Write-Step ("{0,-14} {1}" -f $name, ($detail | ConvertTo-Json -Compress -Depth 5))
}

& $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot -Baseline | Out-Null

$profiles = Join-Path $run 'profiles'
New-DisposableProfile $profiles (Join-Path $run 'cache') $Target
Import-QgisRuntime $o4w $app $profiles
$runtimePath = $env:PATH

# projeto do smoke
$fx = Join-Path $PSScriptRoot 'smoke\fixtures'
$stage = Join-Path $run 'qgz'
New-Item -ItemType Directory -Force $stage | Out-Null
Copy-Item "$fx\smoke.qgs" $stage
Copy-Item "$fx\points.geojson" $work
$qgz = Join-Path $work 'smoke.qgz'
Compress-Archive -Path "$stage\smoke.qgs" -DestinationPath $qgz -Force
$env:IMAN_SMOKE_OUT = $run
$env:IMAN_SMOKE_PROJECT = $qgz

# 1. capturas dentro do QGIS
$p = Start-Process -FilePath $guiExe -PassThru -ArgumentList @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke',
  '--nologo', '--noversioncheck', '--lang', $Lang, '--code', "`"$(Join-Path $PSScriptRoot 'smoke\capture_gui.py')`"")
$exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }
$facts = if (Test-Path "$run\captures.json") { Get-Content "$run\captures.json" -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
Add-Fact 'gui' ([ordered]@{ exitedClean = $exited; facts = $facts })

# 2. splash real, num segundo perfil novo
$profiles2 = Join-Path $run 'profiles-splash'
New-DisposableProfile $profiles2 (Join-Path $run 'cache-splash') $Target
$env:QGIS_CUSTOM_CONFIG_PATH = $profiles2
$exitScript = Join-Path $run 'sair.py'
Write-LfFile $exitScript @('from qgis.PyQt.QtCore import QTimer', 'from qgis.utils import iface', 'QTimer.singleShot(2000, iface.actionExit().trigger)')
$p = Start-Process -FilePath $guiExe -PassThru -ArgumentList @('--profiles-path', "`"$profiles2`"", '--profile', 'iman-smoke',
  '--noversioncheck', '--lang', $Lang, '--code', "`"$exitScript`"")
$h = Wait-ProcessWindow $p.Id { param($w) $s = [ImanWindowCapture]::Size($w); $s[0] -ge 300 -and $s[0] -le 1000 -and $s[1] -ge 150 -and $s[1] -le 500 } 90
$splashFile = $null
if ($h) {
  Start-Sleep -Milliseconds 700
  if ((Save-WindowImage $h "$run\02-splash-real.png")) { $splashFile = '02-splash-real.png' }
}
if (-not $p.WaitForExit($GuiTimeoutSeconds * 1000)) { Stop-Process -Id $p.Id -Force }
Add-Fact 'splash' ([ordered]@{ capture = $splashFile; size = $(if ($h) { [ImanWindowCapture]::Size($h) }) })
$env:QGIS_CUSTOM_CONFIG_PATH = $profiles

# 3. crash handler com relatorio sintetico
$internal = Get-InternalName $Target
$crashRoot = Join-Path $env:LOCALAPPDATA "$($internal.Organization)\$($internal.Application)\crashes"
$crashRootExisted = Test-Path $crashRoot
$before = @(if ($crashRootExisted) { Get-ChildItem $crashRoot -Directory | ForEach-Object FullName })
$dummy = Start-Process -FilePath "$env:SystemRoot\System32\PING.EXE" -ArgumentList @('-n', '300', '127.0.0.1') -WindowStyle Hidden -PassThru
$info = Join-Path $run 'crash-info.txt'
Write-LfFile $info @("$($dummy.Id)", '0', '0', '', '', "`"$guiExe`"", 'QGIS Version: 3.44.13-Solothurn', 'Relatorio sintetico do smoke da fatia 044')
$crash = Start-Process -FilePath "$app\qgiscrashhandler.exe" -ArgumentList "`"$info`"" -PassThru
$h = Wait-ProcessWindow $crash.Id { param($w) [ImanWindowCapture]::Title($w) -like 'Uh-oh*' } 60
$crashFacts = [ordered]@{}
if ($h) {
  Start-Sleep -Seconds 2
  $crashFacts.title = [ImanWindowCapture]::Title($h)
  $crashFacts.capture = $(if ((Save-WindowImage $h "$run\09-crash-handler.png")) { '09-crash-handler.png' })
  $crashFacts.texts = Get-WindowTexts $h
  [ImanWindowCapture]::Close($h)
}
if (-not $crash.WaitForExit(30000)) { Stop-Process -Id $crash.Id -Force }
Stop-Process -Id $dummy.Id -Force -ErrorAction SilentlyContinue
$created = @(if (Test-Path $crashRoot) { Get-ChildItem $crashRoot -Directory | Where-Object { $_.FullName -notin $before } })
foreach ($d in $created) {
  if (Test-Path "$($d.FullName)\report.txt") { Copy-Item "$($d.FullName)\report.txt" "$run\crash-report.txt" }
  Remove-Item -Recurse -Force $d.FullName
}
if (-not $crashRootExisted -and (Test-Path $crashRoot) -and -not (Get-ChildItem $crashRoot -Force)) { Remove-Item $crashRoot }
$crashFacts.crashFoldersCreatedAndRemoved = @($created | ForEach-Object Name)
$crashFacts.report = $(if (Test-Path "$run\crash-report.txt") { Get-Content "$run\crash-report.txt" -Encoding utf8 | Select-Object -First 3 })
Add-Fact 'crash' $crashFacts

# 4. caixa de erro de carga numa copia da pasta bin sem o qgis_app.dll
$copy = Join-Path $run 'copia-sem-qgis_app\bin'
New-Item -ItemType Directory -Force $copy | Out-Null
if ($Target -eq 'Build') { Copy-Item "$app\bin\*" $copy -Exclude 'qgis_app.dll' } else { Copy-Item $guiExe $copy }
$copyExe = Join-Path $copy (Split-Path $guiExe -Leaf)
$env:PATH = "$env:SystemRoot\System32;$env:SystemRoot"
$p = Start-Process -FilePath $copyExe -PassThru
$env:PATH = $runtimePath
$h = Wait-ProcessWindow $p.Id { param($w) [ImanWindowCapture]::ClassName($w) -eq '#32770' } 60
$errFacts = [ordered]@{ copy = $copy; qgisAppDllInCopy = (Test-Path "$copy\qgis_app.dll") }
if ($h) {
  Start-Sleep -Milliseconds 700
  $errFacts.title = [ImanWindowCapture]::Title($h)
  $errFacts.capture = $(if ((Save-WindowImage $h "$run\10-erro-de-carga.png")) { '10-erro-de-carga.png' })
  $errFacts.texts = Get-WindowTexts $h
  [ImanWindowCapture]::Close($h)
}
if (-not $p.WaitForExit(30000)) { Stop-Process -Id $p.Id -Force }
Add-Fact 'erro-de-carga' $errFacts

$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
$summary.guard = ($guard.Trim() -split "`r?`n" | Select-Object -Last 1)
$summary.guardOk = $LASTEXITCODE -eq 0
$summary.captures = @(Get-ChildItem $run -Filter '*.png' | ForEach-Object Name)
$summary | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'summary.json')
Write-Step "capturas $Target ${Lang}: $run (guarda $(if ($summary.guardOk) { 'OK' } else { 'FALHOU' }))"
if (-not $summary.guardOk) { exit 1 }
