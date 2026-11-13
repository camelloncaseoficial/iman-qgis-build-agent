<#
.SYNOPSIS
  Destaque com a escolha do usuario e a troca em tempo de execucao (fatia 064, A4), com perfil descartavel, no build,
  no QGIS oficial (so lido) ou na arvore instalada (so lida). Mede; nao corrige.

.DESCRIPTION
  -Case, um por linha do A4 do briefing 064:
    a  perfil novo: uma abertura, uma medida;
    b  o usuario escolhe Night Mapping em Opcoes e reabre: na primeira abertura, Opcoes > Geral > tema Night Mapping
       e aceita; na segunda, com o mesmo perfil, mede;
    c  o usuario troca de default para Night Mapping e volta para default, sem reabrir: mede, troca, mede, volta,
       mede, tudo na mesma abertura (no QGIS 3.44 a troca de tema so vale ao reabrir: o que muda na hora e a chave
       UI/UITheme do perfil, que a medida registra);
    d  o usuario troca o estilo do Qt em Opcoes (o primeiro estilo da caixa diferente do atual) e reabre (o QGIS so
       aplica o estilo no arranque): troca na primeira abertura; na segunda, mede.
  A GUI abre com smoke\highlight_cases.py (via --code). Cada medida: tema, folha, estilo do Qt, UI/UITheme e
  qgis/style do perfil, a paleta (Highlight e HighlightedText, Active e Inactive) e a cor desenhada no item
  selecionado de uma lista de teste, medida na imagem.
  Desde a fatia 065 (A5: casos a, b e d), tambem o fundo das janelas: o papel Window (Active, Inactive, Disabled) e
  o fundo desenhado num dialogo de teste.
  Medicao, nao gate: sai com 0 se as aberturas coletaram os fatos e a guarda do QGIS oficial passou.
  Saida: $WorkRoot\smoke\cases-<alvo>-<caso>-<data>\ (abertura-N\cases.json, result.json).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official', 'Installed')] [string] $Target = 'Build',
  [Parameter(Mandatory)] [ValidateSet('a', 'b', 'c', 'd')] [string] $Case,
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [int] $GuiTimeoutSeconds = 180
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

# as aberturas de cada caso, com os passos de cada uma
$openings = switch ($Case) {
  'a' { , @('measure') }
  'b' { @('theme=Night Mapping;measure'), @('measure') }
  'c' { , @('measure;theme=Night Mapping;measure;theme=default;measure') }
  'd' { @('style=OTHER;measure'), @('measure') }
}

$run = Join-Path $Paths.Smoke ("cases-{0}-{1}-{2}" -f $Target.ToLowerInvariant(), $Case, (Get-Date -Format 'yyyyMMdd-HHmmss'))
$profiles = Join-Path $run 'profiles'
New-Item -ItemType Directory -Force $profiles | Out-Null
New-DisposableProfile $profiles ((Join-Path $run 'cache') -replace '\\', '/') $Target
$productData = Get-ProductDataSnapshot $Target
Import-QgisRuntime $o4w $app $profiles

$result = [ordered]@{ target = $Target; case = $Case; run = $run; openings = @() }
$n = 0
foreach ($stepsOfOpening in $openings) {
  $n++
  $out = Join-Path $run "abertura-$n"
  New-Item -ItemType Directory -Force $out | Out-Null
  $guiArgs = @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--nologo', '--noversioncheck',
    '--code', "`"$(Join-Path $PSScriptRoot 'smoke\highlight_cases.py')`"")
  $vars = @{ IMAN_CASES_OUT = $out; IMAN_CASES_STEPS = ($stepsOfOpening -join ';') }
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
  $json = Join-Path $out 'cases.json'
  $f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
  $result.openings += [ordered]@{ opening = $n; steps = ($stepsOfOpening -join ';'); exitedClean = $exited; facts = $f }
  foreach ($m in @($f.measures)) {
    Write-Step ("caso {0}, abertura {1}, {2}: tema '{3}', folha {4}, estilo {5} ({6}), Highlight {7}/{8}, desenhado {9}; Window {10}/{11}/{12}, desenhado {13}" -f $Case, $n,
      $m.label, $m.themeName, $m.styleSheetLength, $m.qtStyle, $m.qtStyleBase, $m.palette.Active[0], $m.palette.Inactive[0], $m.drawnHighlight,
      $m.window.Active, $m.window.Inactive, $m.window.Disabled, $m.drawnWindow)
    # fatia 066 (A6, acrescimo): o Button por grupo e o botao de teste desenhado (cor mais comum e raio das quinas)
    Write-Step ("caso {0}, abertura {1}, {2}: Button {3}/{4}/{5}; botao desenhado {6}, raio {7} (quinas {8}), estilo do botao {9}" -f $Case, $n,
      $m.label, $m.button.Active, $m.button.Inactive, $m.button.Disabled, $m.drawnButton.color, $m.drawnButton.radius, ($m.drawnButton.corners -join '/'), $m.drawnButton.style)
  }
  foreach ($a in @($f.actions)) { Write-Step ("caso {0}, abertura {1}: {2} {3} -> {4} (itens {5})" -f $Case, $n, $a.kind, $a.before, $a.after, ($a.items -join ', ')) }
}

$restored = Restore-ProductData $productData
if ($restored) { $result.productData = $restored }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
$result.guard = [ordered]@{ ok = ($LASTEXITCODE -eq 0); last = ($guard.Trim() -split "`r?`n" | Select-Object -Last 1) }
$result.ok = @($result.openings | Where-Object { -not $_.facts -or $_.facts.errors -or -not $_.exitedClean }).Count -eq 0 -and
  $result.guard.ok -and (-not $restored -or $restored.ok)
$result | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step ("casos {0}/{1}: {2} (guarda {3}): {4}" -f $Target, $Case, $(if ($result.ok) { 'medido' } else { 'FALHOU' }), $(if ($result.guard.ok) { 'OK' } else { 'FALHOU' }), $run)
if (-not $result.ok) { exit 1 }
