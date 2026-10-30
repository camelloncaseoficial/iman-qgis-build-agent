<#
.SYNOPSIS
  Tema padrao e padroes de projeto (fatia 049): o QGIS abre no tema e no SRC da fonte unica, em tres estados de
  perfil, e a escolha do usuario vence a global.

.DESCRIPTION
  Abre a GUI do alvo com perfil descartavel numa pasta nova e o smoke\theme_facts.py (via --code), que grava os
  fatos em theme.json (e as capturas por regiao, com -Captures); depois julga contra iman/brand/brand.json.
  -Target Build (padrao) | Installed | Official, como no Invoke-Smoke.ps1 (o Installed abre o bin\iman-terra.exe
  com o ambiente de antes do runtime; o Official e o QGIS 3.44.13 oficial, so lido).
  -ProfileState:
    New       perfil novo (so a pasta do cache de rede);
    Seeded    perfil semeado com o IMANTerra.ini de uma rodada do IMAN Terra 0.4.0 instalado
              (smoke\fixtures\profile-0.4.0, sem a chave UI/UITheme);
    UserTheme perfil com UI/UITheme=<-UserTheme> gravado pelo usuario (padrao 'default').
  Veredito:
    Build/Installed, New ou Seeded: o tema e o ui_theme do brand.json, com folha de estilo; projeto
      novo no default_project_crs, com o new_project_crs_behavior; camada sem SRC no layer_default_crs; Opcoes > SRC
      com o SRC e "usar SRC predefinido"; os temas de fabrica na lista e escolhiveis (T9); botao de fechar da dock com
      icone e funcionando (D1), coordenada inteira no campo da barra de status (D2), titulo da dock sem corte (D4).
    UserTheme: o tema e o do usuario (default: sem folha de estilo), nao o da global.
    Official (visto falhando): tema default, projeto novo em EPSG:4326 e o tema do produto ausente da lista.
  Ao fim, a guarda (Test-OfficialQgisUntouched.ps1). Saida em $WorkRoot\smoke\theme-<alvo>-<estado>-<data>\
  (result.json, theme.json, capturas). Sai com 1 se o veredito falhar.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official', 'Installed')] [string] $Target = 'Build',
  [ValidateSet('New', 'Seeded', 'UserTheme')] [string] $ProfileState = 'New',
  [string] $UserTheme = 'default',
  [switch] $Captures,
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
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
$brand = Get-Content (Join-Path $RepoRoot 'iman\brand\brand.json') -Raw -Encoding utf8 | ConvertFrom-Json

$label = if ($ProfileState -eq 'UserTheme') { "usertheme-$($UserTheme.ToLowerInvariant() -replace '\s', '-')" } else { $ProfileState.ToLowerInvariant() }
$run = Join-Path $Paths.Smoke ("theme-{0}-{1}-{2}" -f $Target.ToLowerInvariant(), $label, (Get-Date -Format 'yyyyMMdd-HHmmss'))
$profiles = Join-Path $run 'profiles'
$work = Join-Path $run 'work'
New-Item -ItemType Directory -Force $profiles, $work | Out-Null
$cacheDir = (Join-Path $run 'cache') -replace '\\', '/'
New-DisposableProfile $profiles $cacheDir $Target
$name = Get-InternalName $Target
$userIni = Join-Path $profiles "profiles\iman-smoke\$($name.Organization)\$($name.Application).ini"
if ($ProfileState -eq 'Seeded') {
  # o .ini de uma rodada do 0.4.0 instalado, com a pasta do cache trocada pela desta rodada
  $seed = Get-Content (Join-Path $PSScriptRoot 'smoke\fixtures\profile-0.4.0\IMANTerra.ini') -Encoding utf8
  Write-LfFile $userIni @($seed | ForEach-Object { if ($_ -match '^directory=') { "directory=$cacheDir" } else { $_ } })
} elseif ($ProfileState -eq 'UserTheme') {
  Write-LfFile $userIni @('[cache]', "directory=$cacheDir", '', '[UI]', "UITheme=$UserTheme")
}
$seededHasTheme = [bool](Select-String -Path $userIni -Pattern '^UITheme=' -Quiet)
Import-QgisRuntime $o4w $app $profiles

$fx = Join-Path $PSScriptRoot 'smoke\fixtures'
$qgz = Join-Path $work 'smoke.qgz'
Copy-Item "$fx\points.geojson" $work
Compress-Archive -Path "$fx\smoke.qgs" -DestinationPath $qgz -Force
$guiArgs = @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--nologo', '--noversioncheck',
  '--code', "`"$(Join-Path $PSScriptRoot 'smoke\theme_facts.py')`"")
$facts = @{ IMAN_THEME_OUT = $run; IMAN_THEME_PROJECT = $qgz; IMAN_THEME_CAPTURES = $(if ($Captures) { '1' } else { '0' }) }
$t0 = Get-Date
if ($Target -eq 'Installed') {
  # a GUI instalada abre com o ambiente de antes do runtime (o iman-terra.exe le o bin\iman-terra.env)
  $runtimeEnv = [Environment]::GetEnvironmentVariables('Process')
  foreach ($k in $runtimeEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
  foreach ($k in $plainEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $plainEnv[$k], 'Process') }
  foreach ($k in $facts.Keys) { [Environment]::SetEnvironmentVariable($k, $facts[$k], 'Process') }
  $p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $guiArgs
  foreach ($k in @([Environment]::GetEnvironmentVariables('Process').Keys)) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
  foreach ($k in $runtimeEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $runtimeEnv[$k], 'Process') }
} else {
  foreach ($k in $facts.Keys) { [Environment]::SetEnvironmentVariable($k, $facts[$k], 'Process') }
  $p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $guiArgs
}
# so o processo que esta rodada abriu, pelo PID (R3 do gate do 044)
$exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }

$result = [ordered]@{ target = $Target; profileState = $ProfileState; userTheme = $(if ($ProfileState -eq 'UserTheme') { $UserTheme }); run = $run
  seconds = [int]((Get-Date) - $t0).TotalSeconds; exitedClean = $exited; userIniHasUITheme = $seededHasTheme; checks = [ordered]@{} }
function Add-Check([string] $id, [bool] $ok, $detail) {
  $result.checks[$id] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-26} {1}  {2}" -f $id, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 5))
}

$json = Join-Path $run 'theme.json'
$f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
Add-Check 'facts' ($null -ne $f -and $exited -and -not $f.errors) ([ordered]@{ written = ($null -ne $f); exitedClean = $exited; errors = $f.errors })
if ($f) {
  $th = $f.theme; $crs = $f.crs; $opt = $f.options
  $product = $brand.ui_theme
  $productTheme = $Target -ne 'Official' -and $ProfileState -ne 'UserTheme'
  if ($ProfileState -eq 'UserTheme') {
    $wantStyle = $UserTheme -ne 'default'
    Add-Check 'T1:escolha-do-usuario' ($th.themeName -eq $UserTheme -and (($th.styleSheetLength -gt 0) -eq $wantStyle) -and $th.settingUITheme -eq $UserTheme) ([ordered]@{
        themeName = $th.themeName; styleSheetLength = $th.styleSheetLength; settingUITheme = $th.settingUITheme; global = $product })
  } elseif ($productTheme) {
    $themeDir = Join-Path $app "resources\themes\$product"
    Add-Check 'T1:tema-padrao' ($th.themeName -eq $product -and $th.styleSheetLength -gt 0 -and $th.settingUITheme -eq $product -and -not $seededHasTheme) ([ordered]@{
        themeName = $th.themeName; styleSheetLength = $th.styleSheetLength; qtStyle = $th.qtStyle; settingUITheme = $th.settingUITheme; userIniHasUITheme = $seededHasTheme })
    $shaRepo = (Get-FileHash -Algorithm SHA256 (Join-Path $RepoRoot "iman\brand\theme\$product\style.qss")).Hash
    $shaApp = if (Test-Path "$themeDir\style.qss") { (Get-FileHash -Algorithm SHA256 "$themeDir\style.qss").Hash } else { $null }
    $loaded = $th.themePaths.$product
    Add-Check 'tema-na-arvore' ($shaApp -eq $shaRepo -and $loaded -and ((Resolve-Path $loaded).Path -eq (Resolve-Path $themeDir).Path)) ([ordered]@{
        themeDir = $themeDir; loadedFrom = $loaded; sameAsRepo = ($shaApp -eq $shaRepo) })
    $want = $brand.default_project_crs
    Add-Check 'T5:src-projeto-novo' ($crs.atStart -eq $want -and $crs.afterNewProject -eq $want -and $crs.defaultProjectCrs -eq $want -and $crs.newProjectCrsBehavior -eq $brand.new_project_crs_behavior) ([ordered]@{
        atStart = $crs.atStart; afterNewProject = $crs.afterNewProject; description = $crs.afterNewProjectDescription; defaultProjectCrs = $crs.defaultProjectCrs; newProjectCrsBehavior = $crs.newProjectCrsBehavior; statusBar = $f.statusBarCrs })
    Add-Check 'B7:src-camada-sem-src' ($crs.layerDefaultCrs -eq $brand.layer_default_crs -and $crs.defaultCrsForNewLayers -eq $brand.layer_default_crs) ([ordered]@{
        layerDefaultCrs = $crs.layerDefaultCrs; defaultCrsForNewLayers = $crs.defaultCrsForNewLayers; unknownCrsBehavior = $crs.unknownCrsBehavior; distroKey = $f.distroLayerKey })
    Add-Check 'T5:opcoes-src' ($opt.found -and $opt.projectGlobalCrs -eq $want -and $opt.radProjectUseDefaultCrs.checked -and -not $opt.radProjectUseCrsOfFirstLayer.checked -and $opt.layerGlobalCrs -eq $brand.layer_default_crs) $opt
    $factory = @('Blend of Gray', 'Night Mapping')
    $sw = $f.switchThemes
    $t9 = @($factory | Where-Object { $_ -notin $opt.cmbUITheme.items -or $sw.$_.themeName -ne $_ -or $sw.$_.styleSheetLength -le 0 }).Count -eq 0
    Add-Check 'T9:temas-de-fabrica' ($t9 -and $opt.cmbUITheme.current -eq $product -and $sw.$product.themeName -eq $product) ([ordered]@{
        optionsItems = $opt.cmbUITheme.items; optionsCurrent = $opt.cmbUITheme.current; switched = $sw })
    $close = $f.dock.buttons.qt_dockwidget_closebutton
    Add-Check 'T3:D1-fechar-dock' ($close.visible -and -not $close.iconNull -and $close.ink -gt 0 -and $f.dockCloseReopen.closedByButton -and $f.dockCloseReopen.reopened) ([ordered]@{
        closeButton = $close; floatButton = $f.dock.buttons.qt_dockwidget_floatbutton; closeReopen = $f.dockCloseReopen })
    Add-Check 'T3:D2-coordenada' ($f.coordinateField.found -and $f.coordinateField.text -and $f.coordinateField.fits) $f.coordinateField
    Add-Check 'T3:D4-titulo-dock' ($f.dock.titleBarHeight -ge $f.dock.titleFontHeight) ([ordered]@{
        title = $f.dock.title; titleBarHeight = $f.dock.titleBarHeight; titleFontHeight = $f.dock.titleFontHeight })
  } else {
    # Official: o que o produto muda nao pode estar la (visto falhando da mesma medicao)
    Add-Check 'controle:tema-default' ($th.themeName -eq 'default' -and $th.styleSheetLength -eq 0 -and $product -notin $th.uiThemes) ([ordered]@{
        themeName = $th.themeName; styleSheetLength = $th.styleSheetLength; uiThemes = $th.uiThemes })
    Add-Check 'controle:src-4326' ($crs.atStart -eq 'EPSG:4326' -and $crs.afterNewProject -eq 'EPSG:4326') ([ordered]@{
        atStart = $crs.atStart; afterNewProject = $crs.afterNewProject; defaultProjectCrs = $crs.defaultProjectCrs; newProjectCrsBehavior = $crs.newProjectCrsBehavior; options = $opt; coordinateField = $f.coordinateField; distroKey = $f.distroLayerKey })
  }
}

$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
Add-Check 'guard' ($LASTEXITCODE -eq 0) ($guard.Trim() -split "`r?`n" | Select-Object -Last 1)
$result.ok = @($result.checks.Values | Where-Object { -not $_.ok }).Count -eq 0
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step "tema e padroes $Target/$label $(if ($result.ok) { 'OK' } else { 'FALHOU' }): $run"
if (-not $result.ok) { exit 1 }
