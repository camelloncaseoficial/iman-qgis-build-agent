<#
.SYNOPSIS
  Plugin IMAN REURB embarcado (fatia 051, T1 e T3): carrega no arranque pela configuracao global, em quatro estados
  de perfil, e o assistente de projeto REURB abre e cria um projeto numa pasta descartavel.

.DESCRIPTION
  Abre a GUI do alvo com perfil descartavel numa pasta nova e o smoke\plugin_facts.py (via --code), que grava os
  fatos em plugin.json; depois julga contra a trava (iman/plugin/plugin.lock.json).
  -Target Build (padrao) | Installed | Official, como no Invoke-Smoke.ps1 (o Installed abre o bin\iman-terra.exe
  com o ambiente de antes do runtime; o Official e o QGIS 3.44.13 oficial, so lido).
  -ProfileState:
    New      perfil novo (so a pasta do cache de rede): o plugin ativo, da pasta python\plugins da arvore, na versao
             da trava, com a barra visivel, sem a chave no perfil (vem da global);
    Seeded   perfil semeado com o IMANTerra.ini de uma rodada do IMAN Terra 0.4.0 (smoke\fixtures\profile-0.4.0, sem
             a chave PythonPlugins/<id>): ativo, como no New;
    UserOff  perfil com PythonPlugins/<id>=false gravado pelo usuario: NAO carrega (visto falhando: a escolha do
             usuario vence a global);
    OwnCopy  perfil com uma copia propria do plugin em python\plugins\<id> (a copia de trabalho do clone do plugin,
             como a do sponsor em desenvolvimento): RELATA qual versao carrega e de onde, sem arbitrar.
  -Wizard (T3, so no New): abre o assistente pelo painel do plugin, le o SRC proposto (tem de ser o
    default_project_crs do brand.json, o padrao do plugin) e cria um projeto em <rodada>\work\reurb; captura o
    dialogo, a barra e o painel.
  Official (visto falhando): o plugin nao existe la; o New tem de dar o plugin inativo.
  Ao fim, a guarda (Test-OfficialQgisUntouched.ps1). Saida em $WorkRoot\smoke\plugin-<alvo>-<estado>-<data>\
  (result.json, plugin.json, capturas). Sai com 1 se o veredito falhar.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official', 'Installed')] [string] $Target = 'Build',
  [ValidateSet('New', 'Seeded', 'UserOff', 'OwnCopy')] [string] $ProfileState = 'New',
  [switch] $Wizard,
  [string] $PluginRepo,
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
if ($Wizard -and $ProfileState -ne 'New') { throw '-Wizard so com -ProfileState New' }
$plainEnv = [Environment]::GetEnvironmentVariables('Process')
$brand = Get-Content (Join-Path $RepoRoot 'iman\brand\brand.json') -Raw -Encoding utf8 | ConvertFrom-Json
$lock = Get-PluginLock

$label = $ProfileState.ToLowerInvariant() + $(if ($Wizard) { '-wizard' } else { '' })
$run = Join-Path $Paths.Smoke ("plugin-{0}-{1}-{2}" -f $Target.ToLowerInvariant(), $label, (Get-Date -Format 'yyyyMMdd-HHmmss'))
$profiles = Join-Path $run 'profiles'
$work = Join-Path $run 'work'
$workspace = Join-Path $work 'reurb'
New-Item -ItemType Directory -Force $profiles, $work | Out-Null
if ($Wizard) { New-Item -ItemType Directory -Force $workspace | Out-Null }
$cacheDir = (Join-Path $run 'cache') -replace '\\', '/'
New-DisposableProfile $profiles $cacheDir $Target
$productData = Get-ProductDataSnapshot $Target   # A3 da fatia 058: o que a rodada deixar na pasta do produto sai no fim
$name = Get-InternalName $Target
$profileDir = Join-Path $profiles 'profiles\iman-smoke'
$userIni = Join-Path $profileDir "$($name.Organization)\$($name.Application).ini"
$ownCopy = $null
if ($ProfileState -eq 'Seeded') {
  # o .ini de uma rodada do 0.4.0 instalado, com a pasta do cache trocada pela desta rodada
  $seed = Get-Content (Join-Path $PSScriptRoot 'smoke\fixtures\profile-0.4.0\IMANTerra.ini') -Encoding utf8
  Write-LfFile $userIni @($seed | ForEach-Object { if ($_ -match '^directory=') { "directory=$cacheDir" } else { $_ } })
} elseif ($ProfileState -eq 'UserOff') {
  Write-LfFile $userIni @('[cache]', "directory=$cacheDir", '', '[PythonPlugins]', "$($lock.id)=false")
} elseif ($ProfileState -eq 'OwnCopy') {
  # copia de trabalho do clone (o que o desenvolvedor tem no perfil), nunca escrita no clone
  $src = Join-Path $PluginRepo $lock.path_in_repo
  if (-not (Test-Path (Join-Path $src 'metadata.txt'))) { throw "copia de trabalho do plugin ausente em $src" }
  $ownCopy = Join-Path $profileDir "python\plugins\$($lock.id)"
  New-Item -ItemType Directory -Force (Split-Path $ownCopy) | Out-Null
  Copy-Item -Recurse $src $ownCopy
  Get-ChildItem $ownCopy -Recurse -Directory -Filter '__pycache__' | Remove-Item -Recurse -Force
  $ownHead = (& $GitExe -C $PluginRepo rev-parse HEAD).Trim()
  $ownDirty = @(& $GitExe -C $PluginRepo status --porcelain -- $lock.path_in_repo).Count -gt 0
}
$userIniHasKey = (Test-Path $userIni) -and [bool](Select-String -Path $userIni -Pattern "^$([regex]::Escape($lock.id))=" -Quiet)
Import-QgisRuntime $o4w $app $profiles

$guiArgs = @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--nologo', '--noversioncheck',
  '--code', "`"$(Join-Path $PSScriptRoot 'smoke\plugin_facts.py')`"")
$facts = @{ IMAN_PLUGIN_OUT = $run; IMAN_PLUGIN_ID = $lock.id; IMAN_PLUGIN_WIZARD = $(if ($Wizard) { '1' } else { '0' }); IMAN_PLUGIN_WORKSPACE = $workspace }
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

$result = [ordered]@{ target = $Target; profileState = $ProfileState; wizard = [bool]$Wizard; run = $run
  lock = [ordered]@{ id = $lock.id; version = $lock.version; tag = $lock.tag; commit = $lock.commit }
  seconds = [int]((Get-Date) - $t0).TotalSeconds; exitedClean = $exited; userIniHadKeyBefore = $userIniHasKey; checks = [ordered]@{} }
function Add-Check([string] $id, [bool] $ok, $detail) {
  $result.checks[$id] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-26} {1}  {2}" -f $id, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 5))
}
# mesma pasta pela forma curta (o QGIS instalado devolve caminhos 8.3)
$fso = New-Object -ComObject Scripting.FileSystemObject
function Test-SameDir([string] $a, [string] $b) {
  $a -and $b -and (Test-Path $a) -and (Test-Path $b) -and ($fso.GetFolder($a).ShortPath -eq $fso.GetFolder($b).ShortPath)
}

$json = Join-Path $run 'plugin.json'
$f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$errs = if ($f) { @($f.errors.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" }) } else { @() }
Add-Check 'facts' ($null -ne $f -and $exited -and $errs.Count -eq 0) ([ordered]@{ written = ($null -ne $f); exitedClean = $exited; errors = $errs })
if ($f) {
  $b = $f.boot
  $treeDir = Join-Path $app "python\plugins\$($lock.id)"
  $moduleDir = if ($b.module_file) { Split-Path $b.module_file } else { $null }
  $fromTree = Test-SameDir $moduleDir $treeDir
  # arranque: so o log tirado no arranque (boot.log); reprova o critico (erro de Python, watchdog), aviso e relatado
  $bootLog = @($b.log | Where-Object { $_.message -match [regex]::Escape($lock.id) -or $_.tag -match '(?i)python' })
  $pyErrors = @($bootLog | Where-Object { $_.level -ge 2 })
  $pyWarnings = @($bootLog | Where-Object { $_.level -lt 2 } | ForEach-Object { ($_.message -split "`n")[0] })
  $barMsgs = @($b.message_bar | ForEach-Object { "$($_.title) $($_.text)" })
  $detail = [ordered]@{ active = $b.active; moduleFile = $b.module_file; fromTree = $fromTree; version = $b.metadata.version
    author = $b.metadata.author; settingEffective = $b.setting_effective; settingInUserIni = $b.setting_in_user_ini
    settingUserValue = $b.setting_user_value; toolbar = $b.toolbar; messageBar = $barMsgs; bootErrors = $pyErrors; bootWarnings = $pyWarnings
    watchdogLeft = $b.watchdog_left }
  if ($Target -eq 'Official') {
    Add-Check 'controle:sem-plugin' (-not $b.active -and -not $b.available) $detail
  } elseif ($ProfileState -in 'New', 'Seeded') {
    $ok = $b.active -and $fromTree -and $b.metadata.version -eq $lock.version -and $b.toolbar.visible -and
      -not $b.setting_in_user_ini -and -not $userIniHasKey -and $pyErrors.Count -eq 0 -and $barMsgs.Count -eq 0 -and -not $b.watchdog_left
    Add-Check "T1:$($ProfileState.ToLowerInvariant())-ativo" $ok $detail
  } elseif ($ProfileState -eq 'UserOff') {
    Add-Check 'T1:usuario-desligou' (-not $b.active -and -not $b.toolbar.found -and $b.setting_in_user_ini -and "$($b.setting_user_value)" -eq 'false') $detail
  } else {
    # relato: qual carregou e de onde; nao arbitra (o veredito so exige que tenha carregado um dos dois)
    $fromProfile = Test-SameDir $moduleDir $ownCopy
    $detail.fromProfileCopy = $fromProfile
    $detail.profileCopy = $ownCopy
    $detail.profileCopyCommit = $ownHead
    $detail.profileCopyDirty = $ownDirty
    $detail.pluginPaths = $b.plugin_paths
    $detail.loadedFrom = if ($fromProfile) { 'copia do perfil' } elseif ($fromTree) { 'pasta embarcada' } else { 'outro' }
    Add-Check 'T1:copia-no-perfil (relato)' ($b.active -and ($fromProfile -or $fromTree)) $detail
  }
  if ($Wizard -and $Target -ne 'Official') {
    $w = $f.wizard
    $want = $brand.default_project_crs
    Add-Check 'T3:assistente' ($w.opened -and $w.proposed_crs -eq $want -and $w.accepted -and @($w.gpkg).Count -ge 1 -and $w.project_crs -eq $want) ([ordered]@{
        title = $w.title; proposedCrs = $w.proposed_crs; wantCrs = $want; accepted = $w.accepted; errorLabel = $w.error_label
        workspace = $workspace; files = $w.workspace_files; projectCrs = $w.project_crs; layers = $w.layers; secondsWaited = $w.seconds_waited
        sessionLog = @($f.log | Where-Object { $_.message -match [regex]::Escape($lock.id) } | ForEach-Object { "[$($_.tag) $($_.level)] $(($_.message -split "`n")[0])" })
        captures = @('wizard.png', 'toolbar.png', 'dock.png' | Where-Object { Test-Path (Join-Path $run $_) }) })
  }
}

$restored = Restore-ProductData $productData
if ($restored) { Add-Check 'dados-do-produto' $restored.ok $restored }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
Add-Check 'guard' ($LASTEXITCODE -eq 0) ($guard.Trim() -split "`r?`n" | Select-Object -Last 1)
$result.ok = @($result.checks.Values | Where-Object { -not $_.ok }).Count -eq 0
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step "plugin $Target/$label $(if ($result.ok) { 'OK' } else { 'FALHOU' }): $run"
if (-not $result.ok) { exit 1 }
