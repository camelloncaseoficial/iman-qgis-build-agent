<#
.SYNOPSIS
  Guarda estatica do tema padrao (fatia 049): o style.qss de iman/brand/theme/<ui_theme> e o aprovado na distro.

.DESCRIPTION
  Porte da guarda tools/test-tema-qss.ps1 da distro congelada (../iman-qgis-distro-agent, commit df761da), sem a
  assercao do Python do plugin de marca (o fork nao tem o plugin), mais o zero token orfao (V.5) e as regras que
  sairam. "Screenshot nao distingue 2px de 5px": o que a captura nao mede, esta guarda mede. Assercoes:
    1. exatamente 12 declaracoes de border-radius, todas 2px;
    2. QMenuBar::item com padding exatamente 3px 4px;
    3. QStatusBar sem padding (licao D2 do D-IMAN-033: o padding espremia o campo de coordenadas);
    4. QDockWidget::title sem padding vertical (licao D4: cortava o titulo);
    5. os 2 cantos especificos da aba (border-top-*-radius) em 2px;
    6. sem titlebar-close-icon (licao D1: apagava o botao de fechar das docks);
    7. zero hex orfao (D-IMAN-026): todo hex das regras esta na paleta do cabecalho do proprio arquivo;
    8. nenhuma das seis regras da camada de marca da distro (widgets do plugin de marca, que o fork nao tem).
  -Out grava o resultado em JSON. Sai com 0 se tudo passa; com 1 nomeando a linha do que falhou.
#>
[CmdletBinding()]
param([string] $Qss, [string] $Out)
. "$PSScriptRoot\Common.ps1"

if (-not $Qss) {
  $themeName = (Get-Content (Join-Path $RepoRoot 'iman\brand\brand.json') -Raw -Encoding utf8 | ConvertFrom-Json).ui_theme
  $Qss = Join-Path $RepoRoot "iman\brand\theme\$themeName\style.qss"
}
if (-not (Test-Path -LiteralPath $Qss)) { Write-Host "style.qss ausente: $Qss"; exit 2 }

$text = [IO.File]::ReadAllText($Qss)
# comentarios trocados por espacos do mesmo tamanho, com as quebras de linha: as linhas seguem batendo com o arquivo
$rules = [regex]::Replace($text, '/\*.*?\*/', { param($m) [regex]::Replace($m.Value, '[^\n]', ' ') }, 'Singleline')
$ruleLines = $rules -split "`n"
$failures = [Collections.Generic.List[string]]::new()
$results = [ordered]@{}
function Get-Matches([string] $pattern) {
  for ($i = 0; $i -lt $ruleLines.Count; $i++) {
    foreach ($m in [regex]::Matches($ruleLines[$i], $pattern)) { [pscustomobject]@{ Line = $i + 1; Match = $m } }
  }
}
function Add-Check([int] $id, [string] $label, [string[]] $problems, $detail) {
  $results["$id"] = [ordered]@{ check = $label; ok = ($problems.Count -eq 0); detail = $detail }
  foreach ($p in $problems) { $failures.Add("[$id] $p") }
  Write-Host ("  [{0}] {1,-34} {2}  {3}" -f $id, $label, $(if ($problems.Count) { 'FALHOU' } else { 'OK' }), ($detail | ConvertTo-Json -Compress))
}

$radii = @(Get-Matches '(?<![-\w])border-radius\s*:\s*(\d+)px')
$p = @($radii | Where-Object { $_.Match.Groups[1].Value -ne '2' } | ForEach-Object { "linha $($_.Line): border-radius $($_.Match.Groups[1].Value)px" })
if ($radii.Count -ne 12) { $p += "esperava 12 declaracoes de border-radius, achei $($radii.Count)" }
Add-Check 1 'border-radius 2px (12)' $p ([ordered]@{ declarations = $radii.Count })

$menubar = @(Get-Matches 'QMenuBar::item\s*\{[^}]*?padding\s*:\s*([^;}]+)') | Select-Object -First 1
$mbValue = if ($menubar) { $menubar.Match.Groups[1].Value.Trim() } else { '<ausente>' }
Add-Check 2 'QMenuBar::item padding 3px 4px' @(if ($mbValue -ne '3px 4px') { "QMenuBar::item padding '$mbValue'" }) ([ordered]@{ padding = $mbValue })

# o seletor de cada bloco: o texto antes da chave (pode comecar em linha anterior)
$blocks = [regex]::Matches($rules, '([^{}]+)\{([^}]*)\}') | ForEach-Object {
  [pscustomobject]@{ Selector = ($_.Groups[1].Value -replace '\s+', ' ').Trim(); Body = $_.Groups[2].Value
    Line = ($rules.Substring(0, $_.Groups[2].Index) -split "`n").Count }
}
$status = @($blocks | Where-Object { $_.Selector -match 'QStatusBar' -and $_.Body -match '(?<![-\w])padding(-top|-bottom|-left|-right)?\s*:' })
Add-Check 3 'QStatusBar sem padding (D2)' @($status | ForEach-Object { "linha $($_.Line): $($_.Selector) com padding" }) ([ordered]@{ blocks = $status.Count })

$dock = @($blocks | Where-Object { $_.Selector -match 'QDockWidget::title' -and $_.Body -match '(?<![-\w])padding(-top|-bottom)?\s*:' })
Add-Check 4 'QDockWidget::title sem padding vert.' @($dock | ForEach-Object { "linha $($_.Line): $($_.Selector) com padding vertical" }) ([ordered]@{ blocks = $dock.Count })

$corners = @(Get-Matches 'border-(?:top|bottom)-(?:left|right)-radius\s*:\s*(\d+)px')
$p = @($corners | Where-Object { $_.Match.Groups[1].Value -ne '2' } | ForEach-Object { "linha $($_.Line): canto $($_.Match.Groups[1].Value)px" })
if ($corners.Count -ne 2) { $p += "esperava 2 cantos especificos, achei $($corners.Count)" }
Add-Check 5 'cantos da aba 2px (2)' $p ([ordered]@{ declarations = $corners.Count })

$close = @(Get-Matches 'titlebar-close-icon')
Add-Check 6 'sem titlebar-close-icon (D1)' @($close | ForEach-Object { "linha $($_.Line): titlebar-close-icon" }) ([ordered]@{ found = $close.Count })

# a paleta: os hex do comentario de cabecalho (o primeiro), no formato "nome #RRGGBB"
$header = [regex]::Match($text, '/\*.*?\*/', 'Singleline').Value
$palette = @([regex]::Matches($header, '([a-z][a-z0-9-]*) (#[0-9A-Fa-f]{6})\b') | ForEach-Object { $_.Groups[2].Value.ToUpperInvariant() } | Sort-Object -Unique)
$hexes = @(Get-Matches '#[0-9A-Fa-f]{3,8}\b')
$orphans = @($hexes | Where-Object { $_.Match.Value.ToUpperInvariant() -notin $palette })
$used = @($hexes | ForEach-Object { $_.Match.Value.ToUpperInvariant() } | Sort-Object -Unique)
$p = @($orphans | ForEach-Object { "linha $($_.Line): $($_.Match.Value) fora da paleta" })
if ($palette.Count -eq 0) { $p += 'paleta do cabecalho nao encontrada' }
Add-Check 7 'zero hex orfao (V.5)' $p ([ordered]@{ palette = $palette.Count; usedDistinct = $used.Count; used = $used; orphans = $orphans.Count })

$brandLayer = @(Get-Matches '#(qa|qatile|rec|ImanHomeVersao|ImanSobreCreditos|ImanTerraMenuBtn)\b')
Add-Check 8 'sem regras da camada de marca' @($brandLayer | ForEach-Object { "linha $($_.Line): $($_.Match.Value)" }) ([ordered]@{ found = $brandLayer.Count })

$ok = $failures.Count -eq 0
[ordered]@{ qss = $Qss; sha256 = (Get-FileHash -Algorithm SHA256 $Qss).Hash.ToLowerInvariant(); ok = $ok; checks = $results } |
  ConvertTo-Json -Depth 6 | Set-Variable json
if ($Out) { Set-Content -Encoding utf8 $Out $json }
$failures | ForEach-Object { Write-Host "  $_" }
Write-Host $(if ($ok) { "TEMA QSS OK ($($results.Count) de $($results.Count))" } else { 'TEMA QSS FALHOU' })
if (-not $ok) { exit 1 }
