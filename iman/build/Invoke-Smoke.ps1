<#
.SYNOPSIS
  Smoke do QGIS compilado (briefings 043 e 044), sempre com perfil descartavel numa pasta nova.

.DESCRIPTION
  -Target Build (padrao): o binario de $WorkRoot\install contra a raiz $WorkRoot\osgeo4w.
  -Target Official: o QGIS 3.44.13 oficial instalado, so lido; e o CONTROLE das checagens de marca.
    1. qgis_process --version, --json list (provedores e ids de algoritmo) e --json plugins, comparados com a
       referencia medida no oficial (smoke\expected\*.txt: o comportamento e o do QGIS, A11);
    2. so no Build: qgis_process run native:buffer no fixture points.geojson; confere 3 feicoes na saida;
    3. qgis.exe (ou o qgis-ltr-bin.exe do oficial) abre a janela, carrega o smoke.qgz, coleta os fatos de marca
       (smoke_gui.py), exporta um PDF de layout, salva uma copia do projeto, grava capturas e fecha;
    4. checagens de marca (marca:*), contra iman/brand/brand.json e iman/brand/derived;
    5. guarda: Test-OfficialQgisUntouched.ps1 (o QGIS oficial, os dados e o registro dele nao mudaram).
  Veredito: no Build, todo passo tem de passar. No Official sem -Lang, os passos de comportamento e o controle do
  Sobre tem de passar e TODA checagem de marca tem de falhar: e a prova de que a checagem enxerga a marca.
  -Lang passa --lang ao QGIS (ex.: pt_BR, para comparar o oficial no mesmo idioma); com ele, o Official nao da
  veredito de controle.
  O perfil descartavel recebe so a pasta do cache de rede ([cache] directory), para o QGIS nao gravar no cache
  padrao %LOCALAPPDATA%\QGIS\QGIS3\cache, que o nome interno QGIS3 compartilha com o QGIS oficial.
  Saida: $WorkRoot\smoke\<target>-<data>\ (summary.json, capturas, logs). Sai com 1 se o veredito falhar.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official')] [string] $Target = 'Build',
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string] $Lang,
  [int] $GuiTimeoutSeconds = 240
)
. "$PSScriptRoot\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path   # o o4w_env troca o PATH: pwsh e git sao resolvidos antes
$gitExe = (Get-Command git.exe -ErrorAction Stop).Source

if ($Target -eq 'Build') {
  $o4w = $Paths.Osgeo4w; $app = Join-Path $Paths.Install 'apps\qgis-ltr'; $guiExe = "$app\bin\qgis.exe"
} else {
  $o4w = $OfficialRoot; $app = Join-Path $OfficialRoot 'apps\qgis-ltr'; $guiExe = "$o4w\bin\qgis-ltr-bin.exe"
}
if (-not (Test-Path "$app\bin\qgis_process.exe")) { throw "qgis_process ausente em $app\bin" }

$suffix = if ($Lang) { "-$Lang" } else { '' }
$run = Join-Path $Paths.Smoke ("{0}{1}-{2}" -f $Target.ToLowerInvariant(), $suffix, (Get-Date -Format 'yyyyMMdd-HHmmss'))
$profiles = Join-Path $run 'profiles'
$work = Join-Path $run 'work'
New-Item -ItemType Directory -Force $profiles, $work | Out-Null

# cache de rede dentro do perfil descartavel (perfil 'default' do qgis_process e o perfil da GUI)
$cacheDir = (Join-Path $run 'cache') -replace '\\', '/'
New-DisposableProfile $profiles $cacheDir
Import-QgisRuntime $o4w $app $profiles
$py = "$($Paths.Osgeo4w)\bin\python3.exe"

$summary = [ordered]@{ target = $Target; lang = $Lang; app = $app; run = $run; profiles = $profiles; steps = [ordered]@{} }
function Add-Result([string] $name, [bool] $ok, $detail) {
  $summary.steps[$name] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-22} {1}  {2}" -f $name, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 5))
}
function Get-Sha([string] $path) { if (Test-Path $path) { (Get-FileHash -Algorithm SHA256 $path).Hash.ToLowerInvariant() } }
function Read-Lines([string] $path) { @(Get-Content $path | Where-Object { $_ -and -not $_.StartsWith('#') }) }

$qp = "$app\bin\qgis_process.exe"
$ver = & $qp --version 2>&1 | Out-String
Set-Content (Join-Path $run 'version.txt') $ver
$verOk = $LASTEXITCODE -eq 0 -and $ver -match 'QGIS 3\.44\.13'
$rev = if ($ver -match 'QGIS code revision ([0-9a-f]+)') { $Matches[1] } else { 'unknown' }
if ($Target -eq 'Build') {
  # BL-6: o binario se identifica pelo commit publico de que saiu
  $head = (& $gitExe -C $RepoRoot rev-parse HEAD).Trim()
  $verOk = $verOk -and $rev -ne 'unknown' -and $head.StartsWith($rev)
  $summary.head = $head
}
Add-Result 'version' $verOk ([ordered]@{ revision = $rev; lines = @($ver.Trim() -split "`r?`n" | Select-Object -First 3) })

# A11: provedores, ids de algoritmo e complementos iguais aos do QGIS oficial (referencia em smoke\expected)
$expected = Join-Path $PSScriptRoot 'smoke\expected'
$listRaw = & $qp --json list 2>$null | Out-String
Set-Content (Join-Path $run 'list.json') $listRaw
try {
  $list = $listRaw | ConvertFrom-Json
  $providers = @($list.providers.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object)
  $algIds = @($list.providers.PSObject.Properties | ForEach-Object { $_.Value.algorithms.PSObject.Properties.Name } | Sort-Object)
  Set-Content (Join-Path $run 'algorithms.txt') $algIds
  $diffAlg = @(Compare-Object (Read-Lines "$expected\algorithms.txt") $algIds | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" })
  $diffProv = @(Compare-Object (Read-Lines "$expected\providers.txt") $providers | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" })
  Add-Result 'providers' ($diffAlg.Count -eq 0 -and $diffProv.Count -eq 0) ([ordered]@{
      providers = $providers; algorithms = $algIds.Count; differences = @($diffProv + $diffAlg) })
} catch { Add-Result 'providers' $false "json invalido: $_" }

$plugRaw = & $qp --json plugins 2>$null | Out-String
Set-Content (Join-Path $run 'plugins.json') $plugRaw
try {
  $plugins = @(($plugRaw | ConvertFrom-Json).plugins.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object)
  $diffPlug = @(Compare-Object (Read-Lines "$expected\plugins.txt") $plugins | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" })
  Add-Result 'plugins' ($plugins.Count -gt 0 -and $diffPlug.Count -eq 0) ([ordered]@{ plugins = $plugins; differences = $diffPlug })
} catch { Add-Result 'plugins' $false "json invalido: $_" }
$summary.corePluginFolders = @(Get-ChildItem "$app\python\plugins" -Directory -ErrorAction SilentlyContinue | ForEach-Object Name | Sort-Object)

$fx = Join-Path $PSScriptRoot 'smoke\fixtures'
if ($Target -eq 'Build') {
  Copy-Item "$fx\points.geojson" $work
  $bufOut = Join-Path $work 'buffer.gpkg'
  $res = & $qp --json run native:buffer -- "INPUT=$work\points.geojson" 'DISTANCE=0.01' 'SEGMENTS=8' "OUTPUT=$bufOut" 2>&1 | Out-String
  Set-Content (Join-Path $run 'buffer.json') $res
  $exit = $LASTEXITCODE
  $info = & "$o4w\bin\ogrinfo.exe" -so -al $bufOut 2>&1 | Out-String
  $count = if ($info -match 'Feature Count:\s*(\d+)') { [int]$Matches[1] } else { -1 }
  $geom = if ($info -match 'Geometry:\s*([^\r\n]+)') { $Matches[1] } else { '' }
  Add-Result 'native:buffer' ($exit -eq 0 -and $count -eq 3 -and $geom -match 'Polygon') ([ordered]@{ exit = $exit; features = $count; geometry = $geom })
}

# GUI: .qgz montado a partir do .qgs versionado (zip com o .qgs na raiz)
$qgz = Join-Path $work 'smoke.qgz'
$stage = Join-Path $run 'qgz'
New-Item -ItemType Directory -Force $stage | Out-Null
Copy-Item "$fx\smoke.qgs" $stage
Copy-Item "$fx\points.geojson" $work -Force
Compress-Archive -Path "$stage\smoke.qgs" -DestinationPath $qgz -Force
$env:IMAN_SMOKE_OUT = $run
$env:IMAN_SMOKE_PROJECT = $qgz
$t0 = Get-Date
$guiArgs = @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--nologo', '--noversioncheck')
if ($Lang) { $guiArgs += @('--lang', $Lang) }
$guiArgs += @('--code', "`"$(Join-Path $PSScriptRoot 'smoke\smoke_gui.py')`"")
$p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $guiArgs
$exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }
$guiJson = Join-Path $run 'gui.json'
$g = $null
if (Test-Path $guiJson) {
  $g = Get-Content $guiJson -Raw -Encoding utf8 | ConvertFrom-Json
  $layer = @($g.layers)[0]
  $ok = $g.project_read -and $g.window_visible -and $layer.valid -and $layer.features -eq 3 -and $exited
  Add-Result 'gui+qgz' $ok ([ordered]@{ seconds = [int]((Get-Date) - $t0).TotalSeconds; exitedClean = $exited; exitCode = $(if ($exited) { $p.ExitCode } else { $null }); title = $g.window_title; layers = $g.layers; errors = $g.errors; capture = 'gui.png' })
  Add-Result 'projeto-salvo' ($g.saved_project.written -and $g.saved_project.qgis_version_attribute -eq $g.version) $g.saved_project
} else {
  Add-Result 'gui+qgz' $false ([ordered]@{ exitedClean = $exited; note = 'gui.json nao foi gravado' })
}

# checagens de marca: os fatos do gui.json contra a fonte unica
$brand = Get-Content (Join-Path $RepoRoot 'iman\brand\brand.json') -Raw -Encoding utf8 | ConvertFrom-Json
$curation = Get-Content (Join-Path $RepoRoot 'iman\brand\i18n\curadoria_pt_BR.json') -Raw -Encoding utf8 | ConvertFrom-Json
$derived = Join-Path $RepoRoot 'iman\brand\derived'
$product = $brand.product_name
$engine = $brand.engine_label
function T([string] $key) { if ($g) { $g.translations.$key } }
function Test-Title([string] $t) {
  # o nome do aplicativo e o do produto; QGIS so aparece como motor
  $t -and $t.Contains($product) -and -not ($t.Replace($engine, '') -match 'QGIS')
}
if ($g) {
  $titles = [ordered]@{ atStart = $g.window_title_at_start; afterLoad = $g.window_title; caption = (T "QgisApp|QGIS - %1 ('%2')") }
  Add-Result 'marca:titulo' ((Test-Title $titles.atStart) -and (Test-Title $titles.afterLoad) -and $titles.caption -eq "$product - $engine %1 ('%2')") $titles

  Add-Result 'marca:traducao' ((T 'QgisApp|QGIS') -eq $product) ([ordered]@{ 'QgisApp|QGIS' = (T 'QgisApp|QGIS'); 'MainWindow|Exit QGIS' = (T 'MainWindow|Exit QGIS') })

  $aboutPt = ($curation.messages | Where-Object { $_.context -eq 'QgsAbout' -and $_.source -eq 'About QGIS' }).qgis
  Add-Result 'marca:idioma' ($g.translation -eq $brand.default_locale -and (T 'QgsAbout|About QGIS') -eq $aboutPt) ([ordered]@{
      translation = $g.translation; userLocale = $g.settings.'locale/userLocale'; overrideFlag = $g.settings.'locale/overrideFlag'; 'QgsAbout|About QGIS' = (T 'QgsAbout|About QGIS') })

  $splashSha = Get-Sha "$derived\splash.png"
  Add-Result 'marca:splash' ($g.resources.':/images/splash/splash.png' -eq $splashSha -and (T 'QgisApp|QGIS Ready!') -eq "$product pronto!") ([ordered]@{
      resource = $g.resources.':/images/splash/splash.png'; derived = $splashSha; message = (T 'QgisApp|QGIS Ready!') })

  $iconMap = [ordered]@{
    ':/images/icons/qgis_icon.svg' = 'qgis_icon.svg'; ':/images/icons/qgis-icon-16x16.png' = 'qgis-icon-16x16.png'
    ':/images/icons/qgis-icon-60x60.png' = 'qgis-icon-60x60.png'; ':/images/themes/default/providerQgis.svg' = 'providerQgis.svg'
  }
  $icons = [ordered]@{}
  $iconsOk = $true
  foreach ($k in $iconMap.Keys) {
    $want = Get-Sha (Join-Path $derived $iconMap[$k]); $got = $g.resources.$k
    $icons[$k] = ($got -eq $want); $iconsOk = $iconsOk -and ($got -eq $want)
  }
  $icons['disco:qgis-icon-60x60.png'] = ($g.app_icon_sha256 -eq (Get-Sha "$derived\qgis-icon-60x60.png"))
  $iconsOk = $iconsOk -and $icons['disco:qgis-icon-60x60.png']
  foreach ($exe in @($guiExe, "$app\qgiscrashhandler.exe")) {
    $pe = & $py (Join-Path $PSScriptRoot 'smoke\pe_icon.py') $exe "$derived\qgis.ico" | Out-String | ConvertFrom-Json
    $icons["IDI_ICON1:$(Split-Path $exe -Leaf)"] = [bool]$pe.match
    $iconsOk = $iconsOk -and [bool]$pe.match
  }
  Add-Result 'marca:icones' $iconsOk $icons

  $urlOk = $true
  $urls = [ordered]@{}
  foreach ($a in 'mActionQgisHomePage', 'mActionReportaBug', 'mActionNeedSupport') {
    $u = @($g.help_actions.$a.urls); $urls[$a] = $u
    $urlOk = $urlOk -and $u.Count -eq 1 -and $u[0] -eq $brand.product_url
  }
  foreach ($a in 'mActionDonate', 'mActionGetInvolved', 'mActionSponsors') {
    $u = @($g.help_actions.$a.urls); $urls[$a] = $u
    $urlOk = $urlOk -and $u.Count -eq 1 -and $u[0] -match '^https://([a-z]+\.)?qgis\.org/'
  }
  Add-Result 'marca:enderecos' $urlOk $urls

  # alem das chaves: o cache de rede do perfil descartavel nao pode ter resposta do feed de noticias do QGIS
  $s = $g.settings
  $feedHits = @(Get-ChildItem (Join-Path $run 'cache') -Recurse -File -ErrorAction SilentlyContinue |
    Select-String -Pattern 'feed.qgis.org' -SimpleMatch -List | ForEach-Object { $_.Path.Substring($run.Length) })
  Add-Result 'marca:noticias-versao' ($s.'core/httpsfeedqgisorg/disabled' -eq $true -and $s.'qgis/allowVersionCheck' -eq $false -and $s.'qgis/checkVersion' -eq $false -and $g.check_version_action_visible -eq $false -and $feedHits.Count -eq 0) ([ordered]@{
      feedDisabled = $s.'core/httpsfeedqgisorg/disabled'; allowVersionCheck = $s.'qgis/allowVersionCheck'; checkVersion = $s.'qgis/checkVersion'; checkVersionActionVisible = $g.check_version_action_visible; feedInNetworkCache = $feedHits })

  # o PDF tem atualizacao incremental (o GDAL reescreve os metadados depois do Qt): o dicionario Info que vale e o
  # ultimo; o XMP e um so
  $creator = "$product ($engine $($g.version))"
  $lastCreator = @($g.pdf.creator)[-1]; $lastProducer = @($g.pdf.producer)[-1]
  $xmp = @($g.pdf.xmp_creator_tool) + @($g.pdf.xmp_producer)
  $pdfOk = $g.pdf.status -eq 0 -and $lastCreator -eq $creator -and $lastProducer -eq $creator -and $xmp.Count -gt 0 -and @($xmp | Where-Object { $_ -ne $creator }).Count -eq 0
  Add-Result 'marca:pdf' $pdfOk ([ordered]@{ expected = $creator; status = $g.pdf.status; creator = $lastCreator; producer = $lastProducer; xmp = $xmp; allInfoCreator = $g.pdf.creator; allInfoProducer = $g.pdf.producer })

  # controle negativo do BL-1: o logo do Sobre e o do QGIS, byte a byte, nos dois alvos
  $fullSha = Get-Sha (Join-Path $RepoRoot 'images\icons\qgis-full.png')
  Add-Result 'controle:sobre' ($g.resources.':/images/icons/qgis-full.png' -eq $fullSha) ([ordered]@{ resource = $g.resources.':/images/icons/qgis-full.png'; qgisSource = $fullSha })
}

$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
Add-Result 'guard' ($LASTEXITCODE -eq 0) ($guard.Trim() -split "`r?`n" | Select-Object -Last 1)
$summary.profileWrittenTo = @(Get-ChildItem $profiles -Recurse -File | ForEach-Object { $_.FullName.Substring($profiles.Length) })

$brandSteps = @($summary.steps.Keys | Where-Object { $_ -like 'marca:*' })
$otherSteps = @($summary.steps.Keys | Where-Object { $_ -notlike 'marca:*' })
$othersOk = @($otherSteps | Where-Object { -not $summary.steps[$_].ok }).Count -eq 0
if ($Target -eq 'Build') {
  $verdict = $othersOk -and $brandSteps.Count -gt 0 -and @($brandSteps | Where-Object { -not $summary.steps[$_].ok }).Count -eq 0
} elseif (-not $Lang) {
  $caught = @($brandSteps | Where-Object { $summary.steps[$_].ok })
  $summary.brandControl = [ordered]@{ brandChecks = $brandSteps.Count; passedOnOfficial = $caught }
  $verdict = $othersOk -and $brandSteps.Count -gt 0 -and $caught.Count -eq 0
} else {
  $verdict = $othersOk
}
$summary.ok = $verdict
$summary | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'summary.json')
Write-Step "smoke $Target$suffix $(if ($verdict) { 'OK' } else { 'FALHOU' }): $run"
if (-not $verdict) { exit 1 }
