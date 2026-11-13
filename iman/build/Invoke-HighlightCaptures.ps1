<#
.SYNOPSIS
  Destaque IMAN por regiao (fatia 064, A2): o item ou texto selecionado em seis lugares, com a cor medida na captura,
  perfil novo, janela maximizada, no build, no QGIS oficial (so lido) ou na arvore instalada (so lida).

.DESCRIPTION
  Abre a GUI do alvo com perfil descartavel e o smoke\highlight_regions.py (via --code), que grava os fatos em
  highlight.json e as capturas. Regioes, uma por linha do A2 do briefing 064:
    layers          painel Camadas, a camada selecionada;
    toolbox         caixa de ferramentas do Processamento, um algoritmo selecionado;
    attributeTable  tabela de atributos, a primeira linha selecionada;
    menu            menu Projeto aberto, com o primeiro item habilitado ativo (o que o mouse marcaria);
    comboPopup      caixa de lista aberta do dialogo do native:buffer, com o segundo item corrente;
    textSelection   texto selecionado no campo da distancia do native:buffer.
  Em cada uma: a cor mais comum do retangulo do item selecionado, na imagem da tela (o fundo do destaque), e os pixels
  perto da cor de texto selecionado da paleta (o texto). Veredito por regiao: fundo = -Expected (padrao: o token
  brand-2 da paleta do brand.json) e texto legivel (ao menos -MinTextPixels pixels de texto sobre ele).
  Medicao, nao gate: sai com 1 se alguma regiao nao fica com o destaque esperado, e o laudo diz qual e por que. A
  guarda do QGIS oficial roda no fim, e o alvo Build remove o que a rodada deixar na pasta do produto (Common.ps1).
  Saida: $WorkRoot\smoke\highlight-<alvo>-<data>\ (highlight.json, result.json, PNGs).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official', 'Installed')] [string] $Target = 'Build',
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [string] $Lang = 'pt_BR',
  [string] $Expected,
  [int] $MinTextPixels = 5,
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
if (-not $Expected) {
  $Expected = [string](Get-Content (Join-Path $RepoRoot 'iman\brand\brand.json') -Raw -Encoding utf8 | ConvertFrom-Json).palette.'brand-2'
}
$Expected = $Expected.ToUpperInvariant()
$plainEnv = [Environment]::GetEnvironmentVariables('Process')

$run = Join-Path $Paths.Smoke ("highlight-{0}-{1}" -f $Target.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
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
  '--code', "`"$(Join-Path $PSScriptRoot 'smoke\highlight_regions.py')`"")
$vars = @{ IMAN_HIGHLIGHT_OUT = $run; IMAN_HIGHLIGHT_PROJECT = $qgz }
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

$json = Join-Path $run 'highlight.json'
$f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$result = [ordered]@{ target = $Target; run = $run; expected = $Expected; seconds = [int]((Get-Date) - $t0).TotalSeconds
  exitedClean = $exited; theme = $f.theme; errors = $f.errors; regions = [ordered]@{} }
foreach ($id in 'layers', 'toolbox', 'attributeTable', 'menu', 'comboPopup', 'textSelection') {
  $r = if ($f) { $f.regions.$id } else { $null }
  $green = [bool]($r -and $r.background -eq $Expected)
  $legible = [bool]($r -and $r.textPixels -ge $MinTextPixels)
  $result.regions[$id] = [ordered]@{ ok = ($green -and $legible); background = $r.background; expected = $Expected
    textPixels = $r.textPixels; legible = $legible; item = $(if ($r.item) { $r.item } else { $r.text }); detail = $r }
  Write-Step ("{0,-15} {1}  fundo {2} (esperado {3}), texto {4} px" -f $id, $(if ($green -and $legible) { 'OK' } else { 'DIFERENTE' }),
    $r.background, $Expected, $r.textPixels)
}

$restored = Restore-ProductData $productData
if ($restored) { $result.productData = $restored }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
$result.guard = [ordered]@{ ok = ($LASTEXITCODE -eq 0); last = ($guard.Trim() -split "`r?`n" | Select-Object -Last 1) }
$result.ok = $null -ne $f -and -not $f.errors -and @($result.regions.Values | Where-Object { -not $_.ok }).Count -eq 0 -and
  $result.guard.ok -and (-not $restored -or $restored.ok)
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step ("destaque {0}: {1} (guarda {2}): {3}" -f $Target, $(if ($result.ok) { "todas as regioes em $Expected" } else { 'DIFERENTE' }),
  $(if ($result.guard.ok) { 'OK' } else { 'FALHOU' }), $run)
if (-not $result.ok) { exit 1 }
