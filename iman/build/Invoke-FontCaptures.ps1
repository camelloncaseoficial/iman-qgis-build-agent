<#
.SYNOPSIS
  Fonte da interface (fatia 067): capturas e fatos do A1 e do A3 ao A7 do briefing, perfil novo, as mesmas janelas
  nos mesmos tamanhos, no build desta branch ou numa copia da arvore de outro build (-AppRoot).

.DESCRIPTION
  Abre a GUI com perfil descartavel e o smoke\font_captures.py (via --code), que grava font.json e as capturas.
  Telas (A3): pagina inicial e Sobre IMAN; janela principal, barra de status e os menus Projeto, Camada e Vetor;
  Opcoes (Geral, Sistema, Mapas e legenda, Ferramentas de mapa, SRC); Propriedades da camada (Fonte, Simbologia,
  Rotulos, Campos e Rotulos com "rotulos simples"); Gerenciador de fontes de dados (Vetor e WMS); a caixa de
  ferramentas do Processamento (flutuando, 420x700) e o native:buffer (Parametros e Log); tabela de atributos;
  calculadora de campo; salvar camada como; gerenciador de complementos (pela interface do gerenciador, sem a busca
  na rede); compositor vazio e com um rotulo; o painel do plugin REURB (flutuando, 440x800) nas quatro abas.
  Em cada tela, todo texto visivel com o que precisa e o que tem (font_captures.py diz como). Com -Reference (o
  font.json de outra rodada), a tabela do A3: textos que cortam, somem ou ganham reticencias so nesta rodada, com o
  recorte nas duas capturas, e a contagem ANTES e DEPOIS por tela. A4 (algarismos, coordenada, cursor), A5 (menu
  Projeto e Opcoes > Geral ampliados 400%), A6 (pesos) e A7 (fonte padrao de rotulo e de compositor) no mesmo
  font.json.
  -Dpi96: abre com QT_ENABLE_HIGHDPI_SCALING=0 e QT_FONT_DPI=96, o texto desenhado no tamanho de pixel da escala de
  100% sem mexer na configuracao do Windows (A5); o font.json diz o DPI que o Qt usou.
  Medicao, nao gate: nada aqui reprova. A guarda do QGIS oficial roda no fim, e o que a rodada deixar na pasta do
  produto sai (Common.ps1). Saida: $WorkRoot\smoke\font-<rotulo>-<data>\ (font.json, result.json, PNGs).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [string] $AppRoot,
  [string] $Label = 'depois',
  [string] $Reference,
  [switch] $Dpi96,
  [string] $Lang = 'pt_BR',
  [int] $GuiTimeoutSeconds = 400
)
. "$PSScriptRoot\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path
$o4w = $Paths.Osgeo4w
$app = if ($AppRoot) { $AppRoot } else { Join-Path $Paths.Install 'apps\qgis-ltr' }
$guiExe = "$app\bin\qgis.exe"
if (-not (Test-Path $guiExe)) { throw "GUI ausente: $guiExe" }
if ($Reference -and -not (Test-Path $Reference)) { throw "referencia ausente: $Reference" }

$run = Join-Path $Paths.Smoke ("font-{0}{1}-{2}" -f $Label.ToLowerInvariant(), $(if ($Dpi96) { '-96dpi' } else { '' }), (Get-Date -Format 'yyyyMMdd-HHmmss'))
$profiles = Join-Path $run 'profiles'
$work = Join-Path $run 'work'
New-Item -ItemType Directory -Force $profiles, $work | Out-Null
New-DisposableProfile $profiles ((Join-Path $run 'cache') -replace '\\', '/') 'Build'
$productData = Get-ProductDataSnapshot 'Build'
Import-QgisRuntime $o4w $app $profiles

$fx = Join-Path $PSScriptRoot 'smoke\fixtures'
$qgz = Join-Path $work 'smoke.qgz'
Copy-Item "$fx\points.geojson" $work
Compress-Archive -Path "$fx\smoke.qgs" -DestinationPath $qgz -Force

$guiArgs = @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--nologo', '--noversioncheck', '--lang', $Lang,
  '--code', "`"$(Join-Path $PSScriptRoot 'smoke\font_captures.py')`"")
$env:IMAN_FONT_OUT = $run
$env:IMAN_FONT_PROJECT = $qgz
$env:IMAN_FONT_REFERENCE = $(if ($Reference) { (Resolve-Path $Reference).Path } else { '' })
if ($Dpi96) { $env:QT_ENABLE_HIGHDPI_SCALING = '0'; $env:QT_FONT_DPI = '96' }
$t0 = Get-Date
$p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $guiArgs
# so o processo que esta rodada abriu, pelo PID (R3 do gate do 044)
$exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }

$json = Join-Path $run 'font.json'
$f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$result = [ordered]@{ label = $Label; dpi96 = [bool]$Dpi96; run = $run; app = $app; seconds = [int]((Get-Date) - $t0).TotalSeconds
  exitedClean = $exited; written = ($null -ne $f); errors = $f.errors }
if ($f) {
  $a = $f.font.app
  Write-Step ("fonte da aplicacao: {0} {1} pt (resolvida {2}, estilo '{3}', {4} px); estilos: {5}" -f $a.family, $a.pointSizeF, $a.resolvedFamily, $a.resolvedStyle, $a.resolvedPixelSize, ($f.font.styles -join ', '))
  Write-Step ("algarismos 0 a 9 iguais: {0} ({1})" -f $f.font.digitsEqual, (($f.font.digitAdvances.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ' '))
  Write-Step ("tela: escala {0}, DPI logico {1}" -f $f.font.screen.devicePixelRatio, $f.font.screen.logicalDpi)
  $screens = @($f.screens.PSObject.Properties)
  Write-Step ("telas: {0}; textos com problema: {1}" -f $screens.Count, (($screens | ForEach-Object { $_.Value.issues } | Measure-Object -Sum).Sum))
  $c = $f.coordinate
  if ($c) {
    Write-Step ("coordenada mais larga {0}: '{1}' precisa {2} de {3} px, cabe {4}; cursor: {5} movimentos, larguras do campo {6}, todos cabem {7}" -f ($c.widest.point -join ' '),
      $c.emitted.'mais-larga'.text, $c.emitted.'mais-larga'.needed, $c.emitted.'mais-larga'.available, $c.emitted.'mais-larga'.fits, $c.cursorMoves.count, ($c.cursorMoves.widths -join ','), $c.cursorMoves.allFit)
  }
  if ($f.weights) { Write-Step ("pesos: titulo do grupo {0}; mesmo desenho: {1}" -f ($f.weights.groupBox.font | ConvertTo-Json -Compress), ($f.weights.sameDrawing | ConvertTo-Json -Compress)) }
  if ($f.labelDefaults) { Write-Step ("rotulos: {0}" -f ($f.labelDefaults | ConvertTo-Json -Compress -Depth 4)) }
  if ($f.compare) {
    $result.compare = $f.compare.totals
    Write-Step ("contra {0}: ANTES {1}, DEPOIS {2}, so DEPOIS {3}, so ANTES {4}, nos dois {5}" -f $f.compare.reference, $f.compare.totals.before, $f.compare.totals.after, $f.compare.totals.onlyAfter, $f.compare.totals.onlyBefore, $f.compare.totals.both)
  }
  if ($f.errors) { Write-Step ("erros: {0}" -f ($f.errors | ConvertTo-Json -Compress -Depth 4)) }
}

$restored = Restore-ProductData $productData
if ($restored) { $result.productData = $restored }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
$result.guard = [ordered]@{ ok = ($LASTEXITCODE -eq 0); last = ($guard.Trim() -split "`r?`n" | Select-Object -Last 1) }
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step ("fonte {0}: {1} (guarda {2}, dados do produto {3}): {4}" -f $Label, $(if ($f -and $exited) { 'medido' } else { 'INCOMPLETO' }),
  $(if ($result.guard.ok) { 'OK' } else { 'FALHOU' }), $(if (-not $restored -or $restored.ok) { 'OK' } else { 'FALHOU' }), $run)
if (-not ($f -and $exited -and $result.guard.ok)) { exit 1 }
