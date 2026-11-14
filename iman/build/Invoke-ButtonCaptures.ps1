<#
.SYNOPSIS
  Botoes e abas (fatia 066): caminho do desenho, raio das quinas do QPushButton, componentes e regioes do papel
  Button, medidos na GUI do alvo com perfil novo e janela maximizada; com -Reference, comparados com outra rodada.

.DESCRIPTION
  Abre a GUI do alvo com perfil descartavel e o smoke\button_facts.py (via --code), que grava os fatos em buttons.json
  e as capturas. O que e medido:
    paths       Fase A: por componente, as chamadas de desenho do estilo e quem passa pelo PE_PanelButtonCommand (o
                painel do botao), com o widget de cada chamada;
    radius      o raio das quinas do QPushButton desenhado pelo estilo da aplicacao (normal, hover, pressionado,
                desabilitado, padrao, com foco, com menu), pela area que falta em cada quina e pelo raio de referencia
                mais parecido, com a calibracao do estimador; e quantos pixels diferem do fusion puro fora das quinas;
    components  capturas fixas dos outros componentes (A5 iii);
    regions     A2: a cor de cada regiao que o Fusion pinta a partir do papel Button (botoes OK e Cancelar de Opcoes, o
                botao "Estilo" com menu, o botao Executar, abas e painel das abas do Processamento, cabecalho da tabela
                de atributos, caixa de selecao fechada, botoes da caixa numerica, botao de cor da Simbologia, trilho e
                alca da barra de rolagem), com as cores que o Fusion deriva do Button (qfusionstyle_p_p.h).
  -Reference <pasta de outra rodada>: compara as capturas dos componentes e dos botoes pixel a pixel com as dela, e as
  regioes com as cores dela. Veredito so com -Reference e -Expect:
    Color   (A2, a rodada de referencia e a develop): cada regiao muda de cor ou o laudo diz por que nao; sai com 1 so
            se a rodada falhar (medicao, nao gate);
    Radius  (A5, a referencia e o build da cor): zero pixel diferente em todo componente fora do QPushButton, raio de
            cada estado do botao igual a -TargetRadius (+-0,25) e nada diferente do fusion fora das quinas;
    Same    (controle de ruido: duas rodadas do mesmo build): zero pixel diferente em tudo.
  A guarda do QGIS oficial roda no fim, e o alvo Build remove o que a rodada deixar na pasta do produto (Common.ps1).
  Saida: $WorkRoot\smoke\buttons-<alvo>-<data>\ (buttons.json, result.json, PNGs).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official', 'Installed')] [string] $Target = 'Build',
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [string] $Lang = 'pt_BR',
  [string] $Reference,
  [ValidateSet('None', 'Color', 'Radius', 'Same')] [string] $Expect = 'None',
  [double] $TargetRadius,
  [int] $GuiTimeoutSeconds = 300
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
if ($Reference -and -not (Test-Path (Join-Path $Reference 'buttons.json'))) { throw "referencia sem buttons.json: $Reference" }
if ($Expect -ne 'None' -and -not $Reference) { throw "-Expect $Expect pede -Reference" }
if ($Expect -eq 'Radius' -and -not $TargetRadius) { throw '-Expect Radius pede -TargetRadius' }
$plainEnv = [Environment]::GetEnvironmentVariables('Process')

$run = Join-Path $Paths.Smoke ("buttons-{0}-{1}" -f $Target.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
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
  '--code', "`"$(Join-Path $PSScriptRoot 'smoke\button_facts.py')`"")
$vars = @{ IMAN_BUTTONS_OUT = $run; IMAN_BUTTONS_PROJECT = $qgz; IMAN_BUTTONS_REFERENCE = $(if ($Reference) { (Resolve-Path $Reference).Path } else { '' }) }
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

$json = Join-Path $run 'buttons.json'
$f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$result = [ordered]@{ target = $Target; run = $run; reference = $Reference; expect = $Expect; targetRadius = $TargetRadius
  seconds = [int]((Get-Date) - $t0).TotalSeconds; exitedClean = $exited; theme = $f.theme; errors = $f.errors; checks = [ordered]@{} }
function Add-Check([string] $id, [bool] $ok, $detail) {
  $result.checks[$id] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-34} {1}  {2}" -f $id, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 4))
}
Add-Check 'facts' ($null -ne $f -and $exited -and -not $f.errors) ([ordered]@{ written = ($null -ne $f); exitedClean = $exited; errors = $f.errors })

if ($f) {
  Write-Step ("estilo {0} (objectName {1}, base {2}); Button {3}; o Fusion deriva buttonColor {4} e tabFrameColor {5}" -f $f.theme.qtStyle,
    $f.theme.qtStyleObjectName, $f.theme.qtStyleBase, $f.theme.palette.Active.Button, $f.theme.fusionDerived.buttonColor, $f.theme.fusionDerived.tabFrameColor)
  foreach ($name in $f.paths.PSObject.Properties.Name) {
    $pth = $f.paths.$name
    Write-Step ("caminho {0,-24} {1,-22} painel do botao: {2}{3}" -f $name, $pth.class, $(if ($pth.panelButtonCommand) { 'SIM, widget ' + ($pth.panelButtonCommandWidgets -join ', ') } else { 'nao' }),
      $(if ($pth.panelButtonCommandWithPushButton) { ' (QPushButton)' } else { '' }))
  }
  Write-Step ("raio: escala {0}, quina de {1} px; calibracao (raio conhecido -> estimado) {2}" -f $f.radius.scale, $f.radius.boxPixels,
    (($f.radius.calibration.PSObject.Properties | ForEach-Object { "$($_.Name)->$($_.Value)" }) -join ' '))
  foreach ($which in $f.radius.states.PSObject.Properties.Name) {
    $s = $f.radius.states.$which
    Write-Step ("raio {0,-9} estimado {1}; referencia mais parecida {2}; fora das quinas, diferente do fusion: {3} px (nas quinas {4})" -f $which, $s.estimate,
      ($s.fit -join '/'), $s.diffFromFusionOutsideCorners, $s.diffFromFusionInCorners)
  }
  foreach ($id in $f.regions.PSObject.Properties.Name) {
    $r = $f.regions.$id
    Write-Step ("regiao {0,-14} media da faixa {1} (mais comum {2}, fatia {3}) {4}" -f $id, $r.backgroundMean, $r.background, $r.backgroundShare, $(if ($r.text) { "'$($r.text)'" }))
  }
  $cmp = $f.compare
  if ($Reference -and -not $cmp) { Add-Check 'comparacao' $false 'sem a comparacao no buttons.json' }
  if ($cmp) {
    foreach ($name in $cmp.components.PSObject.Properties.Name) {
      $c = $cmp.components.$name
      Write-Step ("componente {0,-24} diferentes {1} de {2} px (quinas {3}, fora {4})" -f $name, $c.different, $c.pixels, $c.differentInCorners, $c.differentOutsideCorners)
    }
    foreach ($which in $cmp.buttons.PSObject.Properties.Name) {
      $c = $cmp.buttons.$which
      Write-Step ("botao {0,-9} diferentes {1} de {2} px (quinas {3}, fora {4})" -f $which, $c.different, $c.pixels, $c.differentInCorners, $c.differentOutsideCorners)
    }
    foreach ($id in $cmp.regions.PSObject.Properties.Name) {
      $c = $cmp.regions.$id
      Write-Step ("regiao {0,-14} {1} -> {2} (mais comum {3} -> {4}) {5}" -f $id, $c.before, $c.after, $c.beforeMostCommon, $c.afterMostCommon,
        $(if ($c.before -eq $c.after) { 'IGUAL' } else { 'mudou' }))
    }
    $others = @($cmp.components.PSObject.Properties | Where-Object { $_.Name -notlike 'pushButton*' })
    $pushes = @($cmp.components.PSObject.Properties | Where-Object { $_.Name -like 'pushButton*' })
    $missing = @($cmp.components.PSObject.Properties + $cmp.buttons.PSObject.Properties | Where-Object { -not $_.Value.found -or -not $_.Value.sameSize })
    if ($Expect -eq 'Same') {
      $diffs = @($cmp.components.PSObject.Properties + $cmp.buttons.PSObject.Properties | Where-Object { $_.Value.different -ne 0 })
      Add-Check 'ruido:tudo-igual' ($missing.Count -eq 0 -and $diffs.Count -eq 0) ([ordered]@{ different = @($diffs | ForEach-Object Name); missing = @($missing | ForEach-Object Name) })
    } elseif ($Expect -eq 'Radius') {
      $diffs = @($others | Where-Object { $_.Value.different -ne 0 })
      Add-Check 'A5iii:outros-componentes-iguais' ($missing.Count -eq 0 -and $diffs.Count -eq 0) ([ordered]@{
          compared = $others.Count; different = @($diffs | ForEach-Object { "$($_.Name)=$($_.Value.different)" }); missing = @($missing | ForEach-Object Name) })
      $outside = @($cmp.buttons.PSObject.Properties + $pushes | Where-Object { $_.Value.differentOutsideCorners -ne 0 })
      Add-Check 'A5:botao-so-nas-quinas' ($outside.Count -eq 0) ([ordered]@{ outsideCorners = @($outside | ForEach-Object { "$($_.Name)=$($_.Value.differentOutsideCorners)" }) })
      $states = @($f.radius.states.PSObject.Properties)
      $off = @($states | Where-Object { [math]::Abs($_.Value.estimate - $TargetRadius) -gt 0.25 -or $_.Value.diffFromFusionOutsideCorners -ne 0 })
      $estimates = [ordered]@{}
      foreach ($s in $states) { $estimates[$s.Name] = $s.Value.estimate }
      Add-Check 'A5:raio-no-alvo' ($states.Count -eq 7 -and $off.Count -eq 0) ([ordered]@{ target = $TargetRadius; estimates = $estimates; off = @($off | ForEach-Object Name) })
    }
  }
}

$restored = Restore-ProductData $productData
if ($restored) { Add-Check 'dados-do-produto' $restored.ok $restored }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
Add-Check 'guard' ($LASTEXITCODE -eq 0) ($guard.Trim() -split "`r?`n" | Select-Object -Last 1)
$result.ok = @($result.checks.Values | Where-Object { -not $_.ok }).Count -eq 0
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step ("botoes {0} {1}: {2}" -f $Target, $(if ($result.ok) { 'OK' } else { 'FALHOU' }), $run)
if (-not $result.ok) { exit 1 }
