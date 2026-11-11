<#
.SYNOPSIS
  Medidas e capturas das regioes do tema que o smoke do sponsor de 2026-11-11 reprovou (fatia 058, T1, T2, T4 e T7),
  sempre com perfil novo, no build, no QGIS oficial (so lido) ou na arvore instalada.

.DESCRIPTION
  1. GUI com smoke\theme_regions.py: rodape com a rotacao em 359,9 (B1: rotacao, escala e lupa), barras "Arquivo de
     projeto" e de navegacao do mapa (B5), dialogo do native:buffer nas duas abas (B2), botoes ao lado dos campos (B3)
     e borda dos campos em repouso (B4). Cada campo e cada aba no formato do D2 da 049: largura util, largura do
     texto, cabe ou nao.
  2. splash real (C1, T4): o QGIS abre sem --nologo e a janela do splash e capturada da tela enquanto carrega, em
     quadros; a faixa do rodape (onde o QGIS escreve a mensagem) e comparada pixel a pixel com o splash derivado
     (iman/brand/derived/splash.png): os pixels que mudaram sao o texto, e a luminancia mediana deles diz a cor (a
     media sai puxada pela borda suavizada das letras).
  Vereditos (result.json, regions):
    B1 o texto inteiro da rotacao (359,9 °), da escala e da lupa cabe na largura e na altura uteis;
    B2 o texto de cada aba do dialogo, nas duas abas selecionadas, cabe na largura util (a aba menos padding e borda),
       na pesagem com que e desenhado (negrito na selecionada se o style.qss do alvo pede font-weight nela);
    B3 so com -Reference: todo QToolButton dos campos do dialogo que tem borda visivel em repouso no oficial (anel de
       1 px com contraste contra o fundo) tem borda visivel aqui; os planos no oficial (autoRaise) ficam fora;
    B4 a borda dos campos em repouso e a cor esperada (-FieldBorder, padrao #D0D5C9, token border-strong);
    B5 so com -Reference (o result.json de uma rodada do oficial): passo entre os dois primeiros icones e altura das
       barras iguais aos do oficial, com tolerancia de 1 px;
    splash: texto claro (luminancia mediana dos pixels de texto acima de 128, mais perto do branco que do preto) ou
       escuro (abaixo de 128), contra -SplashText; no oficial, que tem outro splash, so as capturas.
  Medicao, nao gate: sai com 0 mesmo com veredito falho; quem le e o laudo. A guarda do QGIS oficial roda no fim, e o
  alvo Build remove o que a rodada deixar na pasta do produto (A3, Common.ps1).
  Saida: $WorkRoot\smoke\regions-<target>-<data>\ (regions.json, result.json, PNGs).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official', 'Installed')] [string] $Target = 'Build',
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [string] $Lang = 'pt_BR',
  [string] $Reference,
  [string] $FieldBorder = '#D0D5C9',
  [ValidateSet('Light', 'Dark')] [string] $SplashText = 'Light',
  [switch] $SkipSplash,
  [int] $GuiTimeoutSeconds = 240
)
. "$PSScriptRoot\Common.ps1"
. "$PSScriptRoot\WindowCapture.ps1"
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

$run = Join-Path $Paths.Smoke ("regions-{0}-{1}" -f $Target.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
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

# o processo da GUI: no Installed, com o ambiente de antes do runtime (o iman-terra.exe le o bin\iman-terra.env)
function Start-Gui([string[]] $GuiArgs, [hashtable] $Vars) {
  if ($Target -eq 'Installed') {
    $runtimeEnv = [Environment]::GetEnvironmentVariables('Process')
    foreach ($k in $runtimeEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
    foreach ($k in $plainEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $plainEnv[$k], 'Process') }
    foreach ($k in $Vars.Keys) { [Environment]::SetEnvironmentVariable($k, $Vars[$k], 'Process') }
    $p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $GuiArgs
    foreach ($k in @([Environment]::GetEnvironmentVariables('Process').Keys)) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
    foreach ($k in $runtimeEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $runtimeEnv[$k], 'Process') }
  } else {
    foreach ($k in $Vars.Keys) { [Environment]::SetEnvironmentVariable($k, $Vars[$k], 'Process') }
    $p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $GuiArgs
  }
  $p
}

$result = [ordered]@{ target = $Target; run = $run; reference = $Reference; regions = [ordered]@{} }
function Add-Region([string] $id, [bool] $ok, $detail) {
  $result.regions[$id] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-12} {1}  {2}" -f $id, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 6))
}

# 1. regioes, com a GUI (so o processo que esta rodada abriu, pelo PID: R3 do gate do 044)
$t0 = Get-Date
$p = Start-Gui @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--nologo', '--noversioncheck', '--lang', $Lang,
  '--code', "`"$(Join-Path $PSScriptRoot 'smoke\theme_regions.py')`"") @{ IMAN_REGIONS_OUT = $run; IMAN_REGIONS_PROJECT = $qgz }
$exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }
$json = Join-Path $run 'regions.json'
$f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$result.gui = [ordered]@{ seconds = [int]((Get-Date) - $t0).TotalSeconds; exitedClean = $exited; written = ($null -ne $f); errors = $f.errors; themeName = $f.themeName }
Write-Step ("gui          {0}" -f ($result.gui | ConvertTo-Json -Compress -Depth 4))

if ($f) {
  $sb = $f.statusBar
  $b1 = [ordered]@{}
  foreach ($k in 'rotation', 'scale', 'magnifier') {
    $w = $sb.$k
    $b1[$k] = if ($w) { [ordered]@{ text = $w.text; available = $w.available; needed = $w.needed; fitsWidth = $w.fitsWidth
        availableHeight = $w.availableHeight; textHeight = $w.textHeight; fitsHeight = $w.fitsHeight; outer = @($w.outerWidth, $w.outerHeight) } } else { $null }
  }
  $b1ok = $sb.rotation -and $sb.rotation.text -match '359,9' -and @('rotation', 'scale', 'magnifier' | Where-Object { -not ($b1[$_] -and $b1[$_].fitsWidth -and $b1[$_].fitsHeight) }).Count -eq 0
  Add-Region 'B1:rodape' $b1ok $b1

  # B2: a caixa da aba (padding e borda) e a aba menos o texto normal, a menor das abas medidas (o Qt da a aba a largura
  # do texto normal); a largura util e a aba menos a caixa. A selecionada e desenhada em negrito se o style.qss que o
  # alvo carrega tem font-weight na regra QTabBar::tab:selected (o oficial, sem tema, nao tem)
  $tabs = @($f.dialog.tabs.first) + @($f.dialog.tabs.second)
  $themeQss = if ($f.themeName -and $f.themeName -ne 'default') { Join-Path $app "resources\themes\$($f.themeName)\style.qss" }
  $bold = [bool]($themeQss -and (Test-Path -LiteralPath $themeQss) -and
    ([IO.File]::ReadAllText($themeQss) -replace '(?s)/\*.*?\*/', '') -match 'QTabBar::tab:selected\s*\{[^}]*font-weight')
  $box = ($tabs | ForEach-Object { $_.tabWidth - $_.normalWidth } | Measure-Object -Minimum).Minimum
  $b2 = @($tabs | ForEach-Object {
      $needed = if ($bold -and $_.selected) { $_.boldWidth } else { $_.normalWidth }
      [ordered]@{ text = $_.text; selected = $_.selected; tabWidth = $_.tabWidth; box = $box; available = $_.tabWidth - $box
        needed = $needed; drawnBold = ($bold -and $_.selected); fits = ($needed -le $_.tabWidth - $box) } })
  $b2ok = $b2.Count -ge 4 -and @($b2 | Where-Object { -not $_.fits }).Count -eq 0
  Add-Region 'B2:abas' $b2ok ([ordered]@{ selectedBold = $bold; themeQss = $themeQss; tabs = $b2 })

  # borda visivel: ao menos metade do anel de 1 px se distingue do fundo; a chave de cada botao e a classe, o pai e a
  # dica, na ordem em que o dialogo os lista (o oficial e o build montam o mesmo dialogo)
  $buttons = @($f.dialog.toolButtons)
  $b3 = @($buttons | ForEach-Object { [ordered]@{ key = "$($_.class)|$($_.parentClass)|$($_.objectName)|$($_.toolTip)"; class = $_.class
        parent = $_.parentClass; objectName = $_.objectName; toolTip = $_.toolTip; size = $_.size; background = $_.background
        border = $_.borderLeftMiddle; contrast = $_.contrastLeft; ring = "$($_.ringVisible)/$($_.ringPixels)"
        bordered = [bool]($_.ringPixels -and $_.ringVisible -ge ($_.ringPixels / 2)) } })
  $refB3 = if ($Reference -and (Test-Path $Reference)) { @((Get-Content $Reference -Raw -Encoding utf8 | ConvertFrom-Json).regions.'B3:botoes'.detail.buttons) } else { @() }
  $b3ok = $true
  if ($refB3.Count) {
    foreach ($r in @($refB3 | Where-Object bordered)) {
      $mine = @($b3 | Where-Object { $_.key -eq $r.key })
      $ok = $mine.Count -gt 0 -and @($mine | Where-Object { -not $_.bordered }).Count -eq 0
      foreach ($m in $mine) { $m.borderedInReference = $true }
      if (-not $ok) { $b3ok = $false }
    }
  }
  Add-Region 'B3:botoes' $(if ($refB3.Count) { $b3ok } else { $true }) ([ordered]@{ comparedWithReference = [bool]$refB3.Count; buttons = $b3 })

  $fields = @($f.dialog.fields | Where-Object { -not $_.hasFocus })
  $want = $FieldBorder.ToUpperInvariant()
  $b4 = @($fields | ForEach-Object { [ordered]@{ class = $_.class; objectName = $_.objectName; border = $_.borderLeftMiddle; borderTop = $_.borderTopMiddle; background = $_.background; contrast = $_.contrastLeft } })
  $b4ok = $fields.Count -gt 0 -and @($fields | Where-Object { $_.borderLeftMiddle -ne $want }).Count -eq 0
  Add-Region 'B4:campos' $b4ok ([ordered]@{ expected = $want; fields = $b4 })

  $b5 = [ordered]@{}
  $ref = if ($Reference -and (Test-Path $Reference)) { (Get-Content $Reference -Raw -Encoding utf8 | ConvertFrom-Json).regions.'B5:barras'.detail } else { $null }
  $b5ok = $true
  foreach ($k in 'mFileToolBar', 'mMapNavToolBar') {
    $t = $f.toolbars.$k
    $entry = [ordered]@{ height = $t.height; firstStep = $t.firstStep; iconSize = $t.iconSize; buttons = $t.buttons; firstButton = $t.firstButton }
    if ($ref) {
      $r = $ref.$k
      $entry.reference = [ordered]@{ height = $r.height; firstStep = $r.firstStep; firstButton = $r.firstButton }
      $entry.equal = $t -and $r -and [math]::Abs($t.height - $r.height) -le 1 -and [math]::Abs($t.firstStep - $r.firstStep) -le 1
      $b5ok = $b5ok -and $entry.equal
    }
    $b5[$k] = $entry
  }
  Add-Region 'B5:barras' $(if ($ref) { $b5ok } else { $true }) $b5
}

# 2. splash real, num segundo perfil novo
if (-not $SkipSplash) {
  $profiles2 = Join-Path $run 'profiles-splash'
  New-DisposableProfile $profiles2 ((Join-Path $run 'cache-splash') -replace '\\', '/') $Target
  $exitScript = Join-Path $run 'sair.py'
  Write-LfFile $exitScript @('from qgis.PyQt.QtCore import QTimer', 'from qgis.utils import iface', 'QTimer.singleShot(2000, iface.actionExit().trigger)')
  $p = Start-Gui @('--profiles-path', "`"$profiles2`"", '--profile', 'iman-smoke', '--noversioncheck', '--lang', $Lang, '--code', "`"$exitScript`"") @{}
  $h = Wait-ProcessWindow $p.Id { param($w) $s = [ImanWindowCapture]::Size($w); $s[0] -ge 300 -and $s[0] -le 1400 -and $s[1] -ge 150 -and $s[1] -le 700 } 90
  $frames = @()
  if ($h) {
    for ($i = 1; $i -le 8; $i++) {
      Start-Sleep -Milliseconds 250
      $file = "c1-splash-{0:d2}.png" -f $i
      if ((Save-WindowImage $h (Join-Path $run $file))) { $frames += $file }
    }
  }
  if (-not $p.WaitForExit($GuiTimeoutSeconds * 1000)) { Stop-Process -Id $p.Id -Force }
  # a faixa do rodape: os pixels que diferem do splash derivado sao o texto da mensagem
  Add-Type -AssemblyName System.Drawing
  $derived = [Drawing.Bitmap]::new((Join-Path $RepoRoot 'iman\brand\derived\splash.png'))
  $best = $null
  foreach ($file in $frames) {
    $shot = [Drawing.Bitmap]::new((Join-Path $run $file))
    $ref2 = if ($shot.Width -ne $derived.Width -or $shot.Height -ne $derived.Height) { [Drawing.Bitmap]::new($derived, $shot.Width, $shot.Height) } else { $derived }
    $top = [int]($shot.Height * 0.85); $count = 0; $lum = 0.0; $lums = [Collections.Generic.List[double]]::new()
    for ($y = $top; $y -lt $shot.Height; $y++) {
      for ($x = 0; $x -lt $shot.Width; $x++) {
        $a = $shot.GetPixel($x, $y); $b = $ref2.GetPixel($x, $y)
        if ([math]::Abs($a.R - $b.R) + [math]::Abs($a.G - $b.G) + [math]::Abs($a.B - $b.B) -gt 90) {
          $l = 0.2126 * $a.R + 0.7152 * $a.G + 0.0722 * $a.B; $count++; $lum += $l; $lums.Add($l)
        }
      }
    }
    $entry = [ordered]@{ frame = $file; size = @($shot.Width, $shot.Height); band = "$top..$($shot.Height - 1)"; textPixels = $count
      meanLuminance = $(if ($count) { [math]::Round($lum / $count, 1) } else { $null })
      medianLuminance = $(if ($count) { $s = @($lums | Sort-Object); [math]::Round($s[[int]($s.Count / 2)], 1) } else { $null }) }
    if (-not $best -or $count -gt $best.textPixels) { $best = $entry }
    if ($ref2 -ne $derived) { $ref2.Dispose() }
    $shot.Dispose()
  }
  $derived.Dispose()
  if ($Target -eq 'Official') { $best = [ordered]@{ note = 'o oficial tem outro splash: so as capturas'; frames = $frames } }
  $splashOk = $best -and $best.textPixels -gt 50 -and $(if ($SplashText -eq 'Light') { $best.medianLuminance -gt 128 } else { $best.medianLuminance -lt 128 })
  Add-Region 'C1:splash' $(if ($Target -eq 'Official') { $true } else { [bool] $splashOk }) ([ordered]@{ expectedText = $SplashText; frames = $frames; best = $best })
}

$restored = Restore-ProductData $productData
if ($restored) { $result.productData = $restored; Write-Step ("dados-do-produto {0}" -f ($restored | ConvertTo-Json -Compress -Depth 4)) }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
$result.guard = [ordered]@{ ok = ($LASTEXITCODE -eq 0); last = ($guard.Trim() -split "`r?`n" | Select-Object -Last 1) }
Write-Step ("guard        {0}  {1}" -f $(if ($result.guard.ok) { 'OK' } else { 'FALHOU' }), $result.guard.last)
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step "regioes $Target`: $run"
