<#
.SYNOPSIS
  Fundo das janelas por regiao (fatia 065, A2): a cor do fundo e a cor da borda dos campos e quadros, medidas na
  captura, perfil novo, janela maximizada, no build, no QGIS oficial (so lido) ou na arvore instalada (so lida).

.DESCRIPTION
  Abre a GUI do alvo com perfil descartavel e o smoke\window_regions.py (via --code), que grava os fatos em
  window.json e as capturas. Regioes, pelas linhas do A2 do briefing 065:
    janela (papel Window esperado, -Expected, padrao o token bg da paleta do brand.json):
      menuBar, toolBar, statusBar                  janela principal maximizada;
      layersTitle, layersPanel                     painel Camadas (faixa do titulo; area em volta da arvore);
      layerPropertiesSymbology, layerPropertiesDialog  Propriedades da camada (pagina Simbologia; o dialogo);
      optionsGeneral                               Opcoes, pagina Geral;
      algorithmParameters, algorithmLog, algorithmDialog  dialogo do native:buffer (abas Parametros e Log; o dialogo);
      attributeTableDialog                         a janela da tabela de atributos, sem a tabela;
    Base (branco esperado, -ExpectedBase, padrao o token panel):
      menu, comboPopup                             menu aberto e caixa de lista aberta;
      lineEdit, attributeTable, algorithmLogText   um campo de texto, a tabela de atributos e o texto do Log;
    cor propria do QGIS (so medida, sem veredito; a folha do QGIS em qgisappstylesheet.cpp pinta a lista lateral de
    cinza escuro, nos dois dialogos, nos dois builds):
      layerPropertiesList, optionsList             as listas laterais das Propriedades da camada e das Opcoes.
  Em cada uma: a cor mais comum da area (sem as listas, arvores, tabelas e campos de dentro, que sao Base), a fatia
  dela e a media da faixa em torno dela (o Fusion pinta barras e titulos em degrade a partir do Window; como no #064,
  a cor do fundo e a media da faixa); e a cor da borda de um campo e de um quadro da regiao, quando ha.
  Medicao, nao gate: veredito por regiao (media a ate -Tolerance niveis por canal da cor esperada), e sai com 1 se
  alguma regiao fugir; o laudo diz qual e por que (teto honesto ou cor derivada do estilo). A guarda do QGIS oficial
  roda no fim, e o alvo Build remove o que a rodada deixar na pasta do produto (Common.ps1).
  Saida: $WorkRoot\smoke\window-<alvo>-<data>\ (window.json, result.json, PNGs).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official', 'Installed')] [string] $Target = 'Build',
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [string] $Lang = 'pt_BR',
  [string] $Expected,
  [string] $ExpectedBase,
  [int] $Tolerance = 4,
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
$brandPalette = (Get-Content (Join-Path $RepoRoot 'iman\brand\brand.json') -Raw -Encoding utf8 | ConvertFrom-Json).palette
if (-not $Expected) { $Expected = [string]$brandPalette.bg }
if (-not $ExpectedBase) { $ExpectedBase = [string]$brandPalette.panel }
$Expected = $Expected.ToUpperInvariant(); $ExpectedBase = $ExpectedBase.ToUpperInvariant()
$plainEnv = [Environment]::GetEnvironmentVariables('Process')

$run = Join-Path $Paths.Smoke ("window-{0}-{1}" -f $Target.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
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
  '--code', "`"$(Join-Path $PSScriptRoot 'smoke\window_regions.py')`"")
$vars = @{ IMAN_WINDOW_OUT = $run; IMAN_WINDOW_PROJECT = $qgz }
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

$json = Join-Path $run 'window.json'
$f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$result = [ordered]@{ target = $Target; run = $run; expected = $Expected; expectedBase = $ExpectedBase
  seconds = [int]((Get-Date) - $t0).TotalSeconds; exitedClean = $exited; theme = $f.theme; errors = $f.errors; regions = [ordered]@{} }
# maior diferenca por canal entre duas cores #RRGGBB
function Get-ChannelDiff([string] $a, [string] $b) {
  if (-not $a -or -not $b) { return 999 }
  $d = 0
  foreach ($i in 1, 3, 5) { $d = [math]::Max($d, [math]::Abs([Convert]::ToInt32($a.Substring($i, 2), 16) - [Convert]::ToInt32($b.Substring($i, 2), 16))) }
  $d
}
$windowRegions = 'menuBar', 'toolBar', 'statusBar', 'layersTitle', 'layersPanel', 'layerPropertiesSymbology', 'layerPropertiesDialog',
  'optionsGeneral', 'algorithmParameters', 'algorithmLog', 'algorithmDialog', 'attributeTableDialog'
$baseRegions = 'menu', 'comboPopup', 'lineEdit', 'attributeTable', 'algorithmLogText'
$ownRegions = 'layerPropertiesList', 'optionsList'
foreach ($id in @($windowRegions + $baseRegions + $ownRegions)) {
  $r = if ($f) { $f.regions.$id } else { $null }
  $role = if ($id -in $windowRegions) { 'Window' } elseif ($id -in $baseRegions) { 'Base' } else { 'propria' }
  $want = if ($role -eq 'Window') { $Expected } elseif ($role -eq 'Base') { $ExpectedBase } else { $null }
  # a cor do fundo e a media da faixa (o Fusion pinta barras e titulos em degrade a partir do Window)
  $color = if ($r.backgroundMean) { $r.backgroundMean } else { $r.background }
  $diff = Get-ChannelDiff $color $want
  $ok = [bool]($r -and ($role -eq 'propria' -or $diff -le $Tolerance))
  $result.regions[$id] = [ordered]@{ ok = $ok; role = $role; color = $color
    mostCommon = $r.background; share = $r.backgroundShare; band = $r.backgroundBand; expected = $want; channelDiff = $diff
    field = $r.field.color; frame = $r.frame.color; detail = $r }
  Write-Step ("{0,-25} {1,-9} fundo {2} (mais comum {3}; esperado {4}, diferenca {5}); borda campo {6}, quadro {7}" -f $id,
    $(if ($role -eq 'propria') { 'MEDIDO' } elseif ($ok) { 'OK' } else { 'DIFERENTE' }), $color, $r.background, $want, $diff, $r.field.color, $r.frame.color)
}

$restored = Restore-ProductData $productData
if ($restored) { $result.productData = $restored }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
$result.guard = [ordered]@{ ok = ($LASTEXITCODE -eq 0); last = ($guard.Trim() -split "`r?`n" | Select-Object -Last 1) }
$result.ok = $null -ne $f -and -not $f.errors -and @($result.regions.Values | Where-Object { -not $_.ok }).Count -eq 0 -and
  $result.guard.ok -and (-not $restored -or $restored.ok)
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step ("fundo {0}: {1} (guarda {2}): {3}" -f $Target, $(if ($result.ok) { "regioes de janela em $Expected e de Base em $ExpectedBase" } else { 'DIFERENTE' }),
  $(if ($result.guard.ok) { 'OK' } else { 'FALHOU' }), $run)
if (-not $result.ok) { exit 1 }
