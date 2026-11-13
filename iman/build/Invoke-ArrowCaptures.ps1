<#
.SYNOPSIS
  Setas dos controles do Qt (fatia 063, A2): capturas e medida de cada seta, perfil novo, janela maximizada, no build,
  no QGIS oficial (so lido) ou na arvore instalada (so lida).

.DESCRIPTION
  Abre a GUI do alvo com perfil descartavel e o smoke\arrow_controls.py (via --code), que grava os fatos em
  arrows.json e as capturas. Controles medidos, um por linha do A2 do briefing 063:
    toolButtonMenu      botao de barra com menu (a seta de lista da selecao de feicoes);
    layerTreeBranches   setas de expandir da arvore do painel Camadas (um grupo aberto e um fechado);
    scrollBar           barra de rolagem da caixa de ferramentas do Processamento (setas de cima e de baixo), e as
                        setas de expandir da arvore dela;
    comboBox            caixa de lista do tipo de simbologia, em Propriedades da camada;
    spinBox             caixa de numero com setas, em Propriedades da camada (a rotacao do simbolo, se houver);
    processingTabs      abas do dialogo do Processamento (native:buffer): visiveis e com o texto inteiro;
    pushButtonMenu      desde a fatia 066, a seta do botao com menu "Estilo" (QPushButton) em Propriedades da camada,
                        na faixa do indicador de menu (fora de result.controls, que segue com os 7 controles da 063).
  Seta visivel: ao menos -MinInk pixels de tinta no retangulo da seta que o proprio estilo informa (pixels que diferem
  da cor mais comum do retangulo). O laudo le as capturas ao lado do numero.
  Medicao, nao gate: sai com 1 se alguma seta nao aparece, e o laudo diz qual. A guarda do QGIS oficial roda no fim, e
  o alvo Build remove o que a rodada deixar na pasta do produto (A3 da 058, Common.ps1).
  Saida: $WorkRoot\smoke\arrows-<alvo>-<data>\ (arrows.json, result.json, PNGs).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official', 'Installed')] [string] $Target = 'Build',
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [string] $Lang = 'pt_BR',
  [int] $MinInk = 3,
  [int] $GuiTimeoutSeconds = 240
)
. "$PSScriptRoot\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path

if ($Target -eq 'Build') {
  $o4w = $Paths.Osgeo4w; $app = Join-Path $Paths.Install 'apps\qgis-ltr'; $guiExe = "$app\bin\qgis.exe"
} elseif ($Target -eq 'Installed') {
  $o4w = $InstalledRoot; $app = Join-Path $InstalledRoot 'apps\qgis-ltr'; $guiExe = "$o4w\bin\iman-terra.exe"
} else {
  $o4w = $OfficialRoot; $app = Join-Path $OfficialRoot 'apps\qgis-ltr'; $guiExe = "$o4w\bin\qgis-ltr-bin.exe"
}
if (-not (Test-Path $guiExe)) { throw "GUI ausente: $guiExe" }
$plainEnv = [Environment]::GetEnvironmentVariables('Process')

$run = Join-Path $Paths.Smoke ("arrows-{0}-{1}" -f $Target.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
$profiles = Join-Path $run 'profiles'
$work = Join-Path $run 'work'
New-Item -ItemType Directory -Force $profiles, $work | Out-Null
New-DisposableProfile $profiles ((Join-Path $run 'cache') -replace '\\', '/') $Target
$productData = Get-ProductDataSnapshot $Target
Import-QgisRuntime $o4w $app $profiles

$fx = Join-Path $PSScriptRoot 'smoke\fixtures'
$qgz = Join-Path $work 'smoke.qgz'
Copy-Item "$fx\points.geojson" $work
Compress-Archive -Path "$fx\smoke.qgs" -DestinationPath $qgz -Force

$guiArgs = @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--nologo', '--noversioncheck', '--lang', $Lang,
  '--code', "`"$(Join-Path $PSScriptRoot 'smoke\arrow_controls.py')`"")
$vars = @{ IMAN_ARROWS_OUT = $run; IMAN_ARROWS_PROJECT = $qgz }
$t0 = Get-Date
if ($Target -eq 'Installed') {
  # a GUI instalada abre com o ambiente de antes do runtime (o iman-terra.exe le o bin\iman-terra.env)
  $runtimeEnv = [Environment]::GetEnvironmentVariables('Process')
  foreach ($k in $runtimeEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
  foreach ($k in $plainEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $plainEnv[$k], 'Process') }
  foreach ($k in $vars.Keys) { [Environment]::SetEnvironmentVariable($k, $vars[$k], 'Process') }
  $p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $guiArgs
  foreach ($k in @([Environment]::GetEnvironmentVariables('Process').Keys)) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
  foreach ($k in $runtimeEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $runtimeEnv[$k], 'Process') }
} else {
  foreach ($k in $vars.Keys) { [Environment]::SetEnvironmentVariable($k, $vars[$k], 'Process') }
  $p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $guiArgs
}
# so o processo que esta rodada abriu, pelo PID (R3 do gate do 044)
$exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }

$json = Join-Path $run 'arrows.json'
$f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$result = [ordered]@{ target = $Target; run = $run; seconds = [int]((Get-Date) - $t0).TotalSeconds; exitedClean = $exited
  theme = $f.theme; errors = $f.errors; controls = [ordered]@{} }
function Add-Control([string] $id, [bool] $ok, $detail) {
  $result.controls[$id] = [ordered]@{ visible = $ok; detail = $detail }
  Write-Step ("{0,-20} {1}  {2}" -f $id, $(if ($ok) { 'seta visivel' } else { 'SETA AUSENTE' }), ($detail | ConvertTo-Json -Compress -Depth 5))
}
function Test-Ink($measure) { [bool]($measure -and $measure.ink -ge $MinInk) }

if ($f) {
  $c = $f.controls
  $tb = $c.toolButtonMenu
  Add-Control 'toolButtonMenu' (Test-Ink $tb.arrow) ([ordered]@{ toolbar = $tb.toolbar; objectName = $tb.objectName; toolTip = $tb.toolTip; arrow = $tb.arrow })
  $rows = @($c.layerTreeBranches.rows)
  Add-Control 'layerTreeBranches' ($rows.Count -ge 2 -and @($rows | Where-Object { -not (Test-Ink $_) }).Count -eq 0) ([ordered]@{ rows = $rows })
  $sb = $c.scrollBar
  Add-Control 'scrollBar' ((Test-Ink $sb.up) -and (Test-Ink $sb.down)) ([ordered]@{ size = $sb.size; range = $sb.range; up = $sb.up; down = $sb.down })
  $tbr = @($sb.toolboxBranches)
  Add-Control 'toolboxBranches' ($tbr.Count -ge 1 -and @($tbr | Where-Object { -not (Test-Ink $_) }).Count -eq 0) ([ordered]@{ rows = $tbr })
  $cb = $c.comboBox
  Add-Control 'comboBox' (Test-Ink $cb.arrow) ([ordered]@{ objectName = $cb.objectName; text = $cb.text; size = $cb.size; arrow = $cb.arrow })
  $sp = $c.spinBox
  Add-Control 'spinBox' ((Test-Ink $sp.up) -and (Test-Ink $sp.down)) ([ordered]@{ objectName = $sp.objectName; class = $sp.class; text = $sp.text; size = $sp.size; up = $sp.up; down = $sp.down })
  $tabs = @($c.processingTabs.tabs) + @($c.processingTabs.tabsSecond)
  Add-Control 'processingTabs' ($tabs.Count -ge 4 -and @($tabs | Where-Object { -not $_.visible -or $_.tabWidth -lt $_.textWidth }).Count -eq 0) ([ordered]@{ tabs = $tabs })
  # fatia 066 (A3, acrescimo): a seta do botao com menu "Estilo", um QPushButton, cujo painel ganha o raio da 066
  $pm = $c.pushButtonMenu
  $result.pushButtonMenu = [ordered]@{ visible = (Test-Ink $pm.arrow); detail = [ordered]@{ text = $pm.text; size = $pm.size; candidates = $pm.candidates; arrow = $pm.arrow } }
  Write-Step ("{0,-20} {1}  {2}" -f 'pushButtonMenu', $(if ($result.pushButtonMenu.visible) { 'seta visivel' } else { 'SETA AUSENTE' }), ($result.pushButtonMenu.detail | ConvertTo-Json -Compress -Depth 5))
}

$restored = Restore-ProductData $productData
if ($restored) { $result.productData = $restored }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
$result.guard = [ordered]@{ ok = ($LASTEXITCODE -eq 0); last = ($guard.Trim() -split "`r?`n" | Select-Object -Last 1) }
$result.ok = $null -ne $f -and -not $f.errors -and @($result.controls.Values | Where-Object { -not $_.visible }).Count -eq 0 -and
  $result.controls.Count -eq 7 -and $result.guard.ok -and (-not $restored -or $restored.ok) -and $result.pushButtonMenu.visible
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step ("setas {0}: {1} (guarda {2}): {3}" -f $Target, $(if ($result.ok) { 'todas visiveis' } else { 'FALHOU' }), $(if ($result.guard.ok) { 'OK' } else { 'FALHOU' }), $run)
if (-not $result.ok) { exit 1 }
