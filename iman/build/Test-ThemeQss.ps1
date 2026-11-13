<#
.SYNOPSIS
  Guarda estatica do tema (fatia 049): o style.qss de iman/brand/theme/<pasta> e o aprovado na distro. Desde a 063 o
  arquivo fica no repositorio e fora do build (emenda de 2026-11-12 ao D-IMAN-040); a guarda segue sobre ele.

.DESCRIPTION
  Porte da guarda tools/test-tema-qss.ps1 da distro congelada (../iman-qgis-distro-agent, commit df761da), sem a
  assercao do Python do plugin de marca (o fork nao tem o plugin), mais o zero token orfao (V.5) e as regras que
  sairam. "Screenshot nao distingue 2px de 5px": o que a captura nao mede, esta guarda mede. Assercoes:
    1. exatamente 12 declaracoes de border-radius, todas 2px;
    2. QMenuBar::item com padding exatamente 3px 4px;
    3. QStatusBar sem padding (licao D2 do D-IMAN-033: o padding espremia o campo de coordenadas), salvo
       padding-left e padding-right com valor 0 ou 0px (patch 049p, emenda de 2026-11-04 ao D-IMAN-040);
    4. QDockWidget::title sem padding vertical (licao D4: cortava o titulo);
    5. os 2 cantos especificos da aba (border-top-*-radius) em 2px;
    6. sem titlebar-close-icon (licao D1: apagava o botao de fechar das docks);
    7. zero hex orfao (D-IMAN-026): todo hex das regras esta na paleta do cabecalho do proprio arquivo;
    8. nenhuma das seis regras da camada de marca da distro (widgets do plugin de marca, que o fork nao tem);
    9. QStatusBar QLineEdit zera padding-left e padding-right (D2 no fork: sem o recuo horizontal da regra geral dos
       campos, a coordenada cabe na largura que o QGIS da ao campo; patch 049p).
  Desde a fatia 058 (smoke do sponsor de 2026-11-11), por acrescimo, uma por regra nova:
   10. B1: nenhum campo com recuo (QLineEdit, QComboBox, QSpinBox, QDoubleSpinBox, QAbstractSpinBox, QPlainTextEdit,
       QTextEdit como alvo do seletor, sem subcontrole) declara padding diferente de 0: o da rotacao (QDoubleSpinBox)
       e o da escala (QComboBox) do rodape, que o QGIS dimensiona, inclusive;
   11. B2: QTabBar::tab:selected sem font-weight (o negrito cortava o texto da aba, medida no tamanho normal);
   12. B3: o QToolButton fora das barras tem borda visivel (cor da paleta, nao transparent), e QToolBar QToolButton
       segue com borda transparent em repouso;
   13. B4: a regra geral dos campos tem borda 1px solid #D0D5C9 (border-strong);
   14. B5: QToolBar sem spacing e com padding 4px, e QToolBar QToolButton com padding 1px: os valores que dao a
       altura e o passo da barra do QGIS oficial (+-1 px), medidos na 058.
  -Out grava o resultado em JSON. Sai com 0 se tudo passa; com 1 nomeando a linha do que falhou.
#>
[CmdletBinding()]
param([string] $Qss, [string] $Out)
. "$PSScriptRoot\Common.ps1"

if (-not $Qss) {
  # desde a fatia 063 o tema esta fora do build e o brand.json nao tem ui_theme: o arquivo e o da unica pasta de
  # iman/brand/theme com style.qss
  $themeDirs = @(Get-ChildItem (Join-Path $RepoRoot 'iman\brand\theme') -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'style.qss') })
  if ($themeDirs.Count -ne 1) { Write-Host "esperada uma pasta com style.qss em iman\brand\theme, achadas $($themeDirs.Count)"; exit 2 }
  $Qss = Join-Path $themeDirs[0].FullName 'style.qss'
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
# a unica excecao (patch 049p, emenda de 2026-11-04 ao D-IMAN-040): padding-left e padding-right com valor 0 ou 0px
$status = @($blocks | Where-Object { $_.Selector -match 'QStatusBar' } | ForEach-Object {
  $b = $_
  foreach ($m in [regex]::Matches($b.Body, '(?<![-\w])padding(-top|-bottom|-left|-right)?\s*:\s*([^;}]*)')) {
    $side = $m.Groups[1].Value; $value = $m.Groups[2].Value.Trim()
    if (-not ($side -in '-left', '-right' -and $value -match '^0(px)?$')) {
      [pscustomobject]@{ Line = $b.Line; Selector = $b.Selector; Declaration = "padding${side}: $value" }
    }
  }
})
Add-Check 3 'QStatusBar sem padding (D2)' @($status | ForEach-Object { "linha $($_.Line): $($_.Selector) com $($_.Declaration)" }) ([ordered]@{ blocks = @($status | Select-Object -Unique Line).Count })

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

# o valor que vale e o da ultima declaracao, na ordem do arquivo, dos blocos cuja lista de seletores tem QStatusBar QLineEdit
$coordinate = [ordered]@{ 'padding-left' = '<ausente>'; 'padding-right' = '<ausente>' }
foreach ($b in $blocks | Where-Object { 'QStatusBar QLineEdit' -in @($_.Selector -split ',' | ForEach-Object { $_.Trim() }) }) {
  foreach ($m in [regex]::Matches($b.Body, '(?<![-\w])(padding-left|padding-right)\s*:\s*([^;}]*)')) { $coordinate[$m.Groups[1].Value] = $m.Groups[2].Value.Trim() }
}
$p = @($coordinate.Keys | Where-Object { $coordinate[$_] -notmatch '^0(px)?$' } | ForEach-Object { "QStatusBar QLineEdit com $_ '$($coordinate[$_])'" })
Add-Check 9 'QStatusBar QLineEdit padding-h 0 (D2)' $p $coordinate

# fatia 058: os seletores de um bloco, um a um, e o alvo de cada um (o ultimo termo, sem pseudo-estado nem atributo)
function Get-Selectors($b) { @($b.Selector -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
function Get-Subject([string] $sel) { (($sel -split '\s+')[-1]) }
function Get-Declarations($b, [string] $prop) {
  @([regex]::Matches($b.Body, "(?<![-\w])$([regex]::Escape($prop))\s*:\s*([^;}]*)") | ForEach-Object { $_.Groups[1].Value.Trim() })
}

$fieldTypes = 'QLineEdit', 'QComboBox', 'QSpinBox', 'QDoubleSpinBox', 'QAbstractSpinBox', 'QPlainTextEdit', 'QTextEdit'
$p = @(foreach ($b in $blocks) {
    $fieldSelectors = @(Get-Selectors $b | Where-Object { $_ -notmatch '::' -and ((Get-Subject $_) -replace '[:\[].*$', '') -in $fieldTypes })
    if (-not $fieldSelectors) { continue }
    foreach ($m in [regex]::Matches($b.Body, '(?<![-\w])(padding(?:-top|-bottom|-left|-right)?)\s*:\s*([^;}]*)')) {
      $values = @($m.Groups[2].Value.Trim() -split '\s+' | Where-Object { $_ })
      if (@($values | Where-Object { $_ -notmatch '^0(px)?$' }).Count) { "linha $($b.Line): $($b.Selector) com $($m.Groups[1].Value): $($m.Groups[2].Value.Trim())" }
    }
  })
Add-Check 10 'campos sem padding (B1)' $p ([ordered]@{ fieldTypes = $fieldTypes; offending = $p.Count })

$selectedTab = @($blocks | Where-Object { 'QTabBar::tab:selected' -in (Get-Selectors $_) })
$p = @($selectedTab | Where-Object { Get-Declarations $_ 'font-weight' } | ForEach-Object { "linha $($_.Line): $($_.Selector) com font-weight $(Get-Declarations $_ 'font-weight')" })
if (-not $selectedTab) { $p += 'regra QTabBar::tab:selected ausente' }
Add-Check 11 'aba selecionada sem negrito (B2)' $p ([ordered]@{ blocks = $selectedTab.Count })

$plainButton = @($blocks | Where-Object { (Get-Selectors $_) -contains 'QToolButton' -and @(Get-Selectors $_).Count -eq 1 })
$barButton = @($blocks | Where-Object { (Get-Selectors $_) -contains 'QToolBar QToolButton' })
$buttonBorder = @($plainButton | ForEach-Object { Get-Declarations $_ 'border' }) | Select-Object -Last 1
$barBorder = @($barButton | ForEach-Object { Get-Declarations $_ 'border' }) | Select-Object -Last 1
$p = @()
if ($buttonBorder -notmatch '^1px solid #[0-9A-Fa-f]{6}$') { $p += "QToolButton com borda '$buttonBorder' (esperava 1px solid e uma cor da paleta)" }
if ($barBorder -notmatch '^1px solid transparent$') { $p += "QToolBar QToolButton com borda '$barBorder' (esperava 1px solid transparent)" }
Add-Check 12 'QToolButton fora da barra c/ borda (B3)' $p ([ordered]@{ toolButton = $buttonBorder; toolBarToolButton = $barBorder })

$general = @($blocks | Where-Object { $s = Get-Selectors $_; 'QLineEdit' -in $s -and 'QComboBox' -in $s -and 'QSpinBox' -in $s })
$fieldBorder = @($general | ForEach-Object { Get-Declarations $_ 'border' }) | Select-Object -Last 1
Add-Check 13 'borda dos campos #D0D5C9 (B4)' @(if ($fieldBorder -ne '1px solid #D0D5C9') { "regra geral dos campos com borda '$fieldBorder' (esperava 1px solid #D0D5C9)" }) ([ordered]@{ border = $fieldBorder; blocks = $general.Count })

$toolBar = @($blocks | Where-Object { (Get-Selectors $_) -contains 'QToolBar' })
$barSpacing = @($toolBar | ForEach-Object { Get-Declarations $_ 'spacing' })
$barPadding = @($toolBar | ForEach-Object { Get-Declarations $_ 'padding' }) | Select-Object -Last 1
$barButtonPadding = @($barButton | ForEach-Object { Get-Declarations $_ 'padding' }) | Select-Object -Last 1
$p = @()
if ($barSpacing) { $p += "QToolBar com spacing $($barSpacing -join ', ')" }
if ($barPadding -ne '4px') { $p += "QToolBar com padding '$barPadding' (esperava 4px)" }
if ($barButtonPadding -ne '1px') { $p += "QToolBar QToolButton com padding '$barButtonPadding' (esperava 1px)" }
Add-Check 14 'barras como no oficial (B5)' $p ([ordered]@{ spacing = $barSpacing; toolBarPadding = $barPadding; toolBarToolButtonPadding = $barButtonPadding })

$ok = $failures.Count -eq 0
[ordered]@{ qss = $Qss; sha256 = (Get-FileHash -Algorithm SHA256 $Qss).Hash.ToLowerInvariant(); ok = $ok; checks = $results } |
  ConvertTo-Json -Depth 6 | Set-Variable json
if ($Out) { Set-Content -Encoding utf8 $Out $json }
$failures | ForEach-Object { Write-Host "  $_" }
Write-Host $(if ($ok) { "TEMA QSS OK ($($results.Count) de $($results.Count))" } else { 'TEMA QSS FALHOU' })
if (-not $ok) { exit 1 }
