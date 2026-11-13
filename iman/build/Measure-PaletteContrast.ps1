<#
.SYNOPSIS
  Contraste do texto sobre o fundo das janelas (fatia 065, A4), pela formula WCAG 2.x, medido nas cores da paleta.

.DESCRIPTION
  Le o theme.json de duas rodadas do Test-ThemeDefaults.ps1 (-Before e -After; a chave theme.paletteAll do
  smoke\theme_facts.py, desde a 065, com as cores em #AARRGGBB) e calcula, em cada uma, o contraste de:
    normal       WindowText do grupo Active sobre o Window do grupo Active;
    desabilitado WindowText do grupo Disabled sobre o Window do grupo Disabled.
  Cor de texto com alfa abaixo de 255 e composta sobre o fundo antes da conta (como o Qt a desenharia).
  Contraste WCAG: (L1 + 0,05) / (L2 + 0,05), L a luminancia relativa do sRGB. Saida: os quatro numeros e a variacao de
  cada um; sai com 1 se algum cair mais que -MaxDropPercent (padrao 10, o limite do briefing 065).
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $Before,
  [Parameter(Mandatory)] [string] $After,
  [double] $MaxDropPercent = 10
)

function Get-Rgb([string] $argb, [double[]] $over) {
  $h = $argb.TrimStart('#')
  if ($h.Length -eq 6) { $h = 'FF' + $h }
  $a = [Convert]::ToInt32($h.Substring(0, 2), 16) / 255.0
  $c = foreach ($i in 2, 4, 6) { [Convert]::ToInt32($h.Substring($i, 2), 16) }
  if ($over -and $a -lt 1) { $c = for ($k = 0; $k -lt 3; $k++) { [math]::Round($c[$k] * $a + $over[$k] * (1 - $a)) } }
  , [double[]] $c
}
function Get-Luminance([double[]] $rgb) {
  $l = foreach ($v in $rgb) { $s = $v / 255.0; if ($s -le 0.04045) { $s / 12.92 } else { [math]::Pow(($s + 0.055) / 1.055, 2.4) } }
  0.2126 * $l[0] + 0.7152 * $l[1] + 0.0722 * $l[2]
}
function Get-Contrast([string] $fg, [string] $bg) {
  $b = Get-Rgb $bg $null
  $f = Get-Rgb $fg $b
  $l1 = Get-Luminance $f; $l2 = Get-Luminance $b
  [math]::Round(([math]::Max($l1, $l2) + 0.05) / ([math]::Min($l1, $l2) + 0.05), 2)
}
function Read-Pairs([string] $path) {
  $p = (Get-Content $path -Raw -Encoding utf8 | ConvertFrom-Json).theme.paletteAll
  if (-not $p) { throw "sem theme.paletteAll em $path (theme_facts.py de antes da 065?)" }
  [ordered]@{
    normal = [ordered]@{ text = $p.Active.WindowText; window = $p.Active.Window; contrast = Get-Contrast $p.Active.WindowText $p.Active.Window }
    desabilitado = [ordered]@{ text = $p.Disabled.WindowText; window = $p.Disabled.Window; contrast = Get-Contrast $p.Disabled.WindowText $p.Disabled.Window }
  }
}

$b = Read-Pairs $Before; $a = Read-Pairs $After
$fail = $false
foreach ($k in 'normal', 'desabilitado') {
  $change = [math]::Round(100 * ($a[$k].contrast - $b[$k].contrast) / $b[$k].contrast, 1)
  if (-$change -gt $MaxDropPercent) { $fail = $true }
  "{0,-13} ANTES {1} sobre {2}: {3}:1   DEPOIS {4} sobre {5}: {6}:1   variacao {7}%" -f $k, $b[$k].text, $b[$k].window, $b[$k].contrast,
    $a[$k].text, $a[$k].window, $a[$k].contrast, $change
}
"veredito: $(if ($fail) { "QUEDA MAIOR QUE $MaxDropPercent%" } else { "nenhuma queda maior que $MaxDropPercent%" })"
if ($fail) { exit 1 }
