<#
.SYNOPSIS
  Medicoes na arvore instalada (briefing 047): A2 nome interno num perfil novo, A3 um atalho so com o AUMI do
  processo, A5 o produto pelo atalho e o runtime do Visual C++ carregado, A7 "Abrir com" e o padrao do .qgz, A9
  creditos do QGIS na arvore. Nunca escreve nas areas do QGIS oficial; a guarda roda no fim.

.DESCRIPTION
  1. A2: as pastas e a chave do produto (%APPDATA%\<org>\<app>, %LOCALAPPDATA%\<org>\<app>,
     HKCU\Software\<org>\<app>) tem de estar ausentes antes (perfil novo; -ResetProductData apaga as do PRODUTO,
     nunca as do QGIS);
  2. A5/A3: abre o produto pelo atalho do Menu Iniciar (ShellExecute do .lnk, sem o ambiente do runtime deste
     script) com PYQGIS_STARTUP=launch_facts.py, que grava o nome interno, as pastas, o AUMI, o VC++ carregado e
     o resultado de uma notificacao, e fecha o QGIS. O processo e o que o ShellExecute devolveu (PID);
  3. A2: depois, as pastas e a chave do produto existem; o qgis_process (bin\qgis_process-iman-terra.bat) lista
     um plugin marcador posto so no perfil novo; o crash handler instalado grava a pasta de crash do produto
     (relatorio sintetico, processo "travado" descartavel, como no Invoke-BrandCaptures.ps1);
  4. A3: os atalhos do produto no Menu Iniciar e o AUMI de cada um;
  5. A7: o OpenWithProgids dos tres tipos, o ProgID e o padrao do .qgz (HKCR e UserChoice);
  6. A9: os arquivos de creditos e a licenca do QGIS (apps\qgis-ltr\doc) iguais aos do QGIS oficial;
  7. guarda contra o retrato tirado no comeco.
  Saida em $WorkRoot\verify\installed-<data>\result.json. Sai com 1 se alguma checagem falhar.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [switch] $ResetProductData,
  [int] $TimeoutSeconds = 180
)
. "$PSScriptRoot\..\..\build\Common.ps1"
. "$PSScriptRoot\..\..\build\WindowCapture.ps1"
$pwshExe = (Get-Process -Id $PID).Path
$run = Join-Path $WorkRoot ("verify\installed-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$guardDir = Join-Path $run 'guard'
New-Item -ItemType Directory -Force $run, $guardDir | Out-Null
$brand = Get-Content (Join-Path $RepoRoot 'iman\brand\brand.json') -Raw -Encoding utf8 | ConvertFrom-Json
$name = Get-InternalName 'Installed'
$roaming = Join-Path $env:APPDATA "$($name.Organization)\$($name.Application)"
$local = Join-Path $env:LOCALAPPDATA "$($name.Organization)\$($name.Application)"
$regKey = "HKCU:\Software\$($name.Organization)\$($name.Application)"
$result = [ordered]@{ run = $run; installedRoot = $InstalledRoot; checks = [ordered]@{} }
function Add-Check([string] $id, [bool] $ok, $detail) {
  $result.checks[$id] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-28} {1}  {2}" -f $id, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 6))
}
function Invoke-Guard([switch] $Baseline) {
  $a = @('-NoProfile', '-File', (Join-Path $RepoRoot 'iman\build\Test-OfficialQgisUntouched.ps1'), '-WorkRoot', $WorkRoot, '-GuardDir', $guardDir)
  if ($Baseline) { $a += '-Baseline' }
  $o = & $pwshExe @a 2>&1 | Out-String
  [pscustomobject]@{ exit = $LASTEXITCODE; last = ($o.Trim() -split "`r?`n" | Select-Object -Last 1) }
}
function Get-ShortcutAumi([string] $lnk) {
  $shell = New-Object -ComObject Shell.Application
  $item = $shell.Namespace((Split-Path $lnk)).ParseName((Split-Path $lnk -Leaf))
  $item.ExtendedProperty('System.AppUserModel.ID')
}
function Get-ProductShortcuts {
  $dirs = @([Environment]::GetFolderPath('Programs'), [Environment]::GetFolderPath('CommonPrograms'))
  @($dirs | ForEach-Object { Get-ChildItem $_ -Recurse -Filter '*.lnk' -ErrorAction SilentlyContinue } |
    Where-Object { $_.BaseName -match [regex]::Escape($brand.product_name) -or $_.BaseName -match $name.Application } |
    ForEach-Object { [ordered]@{ path = $_.FullName; aumi = (Get-ShortcutAumi $_.FullName); mtime = $_.LastWriteTime.ToString('s') } })
}
function Get-RegDefault([string] $path, [string] $value = '') {
  $k = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
  if ($k) { $k.GetValue($value) } else { $null }
}

# 1. perfil novo
# o registro de notificacao que o Windows cria para o AUMI do produto no primeiro toast tambem e do produto
$aumiName = '{0}.{1}.{1}.3.44.13-Solothurn' -f $name.Organization, $name.Application
$notifKeyPre = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\$aumiName"
if ($ResetProductData) {
  foreach ($p in $roaming, $local) { if (Test-Path $p) { Remove-Item -Recurse -Force $p } }
  foreach ($k in $regKey, $notifKeyPre) { if (Test-Path $k) { Remove-Item -Recurse -Force $k } }
}
$notifBefore = Test-Path $notifKeyPre
$pre = [ordered]@{ roaming = (Test-Path $roaming); local = (Test-Path $local); registry = (Test-Path $regKey) }
Add-Check 'A2:perfil-novo-antes' (-not ($pre.roaming -or $pre.local -or $pre.registry)) $pre
$null = Invoke-Guard -Baseline
$qgzBefore = [ordered]@{
  hkcr = Get-RegDefault 'Registry::HKEY_CLASSES_ROOT\.qgz'
  userChoice = Get-RegDefault 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.qgz\UserChoice' 'ProgId'
}
$shortcutsBefore = Get-ProductShortcuts

# 2. o produto pelo atalho
$lnk = Join-Path ([Environment]::GetFolderPath('Programs')) "$($brand.product_name).lnk"
$env:PYQGIS_STARTUP = Join-Path $PSScriptRoot 'launch_facts.py'
$env:IMAN_FACTS_OUT = $run
$t0 = Get-Date
$p = Start-Process -FilePath $lnk -PassThru
Remove-Item env:PYQGIS_STARTUP, env:IMAN_FACTS_OUT
$launch = [ordered]@{ shortcut = $lnk; pid = $p.Id }
if ($p) {
  $exited = $p.WaitForExit($TimeoutSeconds * 1000)
  if (-not $exited) { Stop-Process -Id $p.Id -Force }
  $launch.exitedClean = $exited
  $launch.seconds = [int]((Get-Date) - $t0).TotalSeconds
}
$factsFile = Join-Path $run 'launch-facts.json'
$facts = if (Test-Path $factsFile) { Get-Content $factsFile -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$launch.facts = $facts
# o caminho do executavel, gravado de dentro do processo (GetModuleFileNameW): depois que ele sai, o Process nao o da
$launch.processPath = $facts.process_exe
$exePath = Join-Path $InstalledRoot 'bin\iman-terra.exe'
Add-Check 'A5:abre-pelo-atalho' ($facts -and $facts.pid -eq $p.Id -and $launch.processPath -eq $exePath -and $launch.exitedClean) $launch
Add-Check 'A5:processo-iman-terra' ((Split-Path $launch.processPath -Leaf) -eq 'iman-terra.exe') ([ordered]@{ process = $launch.processPath })
Add-Check 'A5:vc-runtime-carregado' (@($facts.vc_runtime).Count -gt 0) ([ordered]@{ modules = $facts.vc_runtime; how = 'EnumProcessModules + VerQueryValue dentro do processo (launch_facts.py)' })

# 3. nome interno
$post = [ordered]@{
  roaming = (Test-Path $roaming); profileDefault = (Test-Path (Join-Path $roaming 'profiles\default'))
  local = (Test-Path $local); registry = (Test-Path $regKey)
  organization = $facts.organization; application = $facts.application; domain = $facts.organization_domain
  settingsDir = $facts.settings_dir; nativeSettings = $facts.native_settings; cache = $facts.cache_location; appLocalData = $facts.app_local_data
}
$okName = $post.roaming -and $post.profileDefault -and $post.local -and $facts.organization -eq $name.Organization -and
  $facts.application -eq $name.Application -and $facts.organization_domain -eq $brand.internal_organization_domain -and
  ($facts.settings_dir -replace '/', '\').StartsWith($roaming, 'OrdinalIgnoreCase') -and
  ($facts.cache_location -replace '/', '\').StartsWith($local, 'OrdinalIgnoreCase')
Add-Check 'A2:produto-perfil-cache' $okName $post
Add-Check 'A2:produto-registro' ($post.registry -or $facts.native_settings -eq "\HKEY_CURRENT_USER\Software\$($name.Organization)\$($name.Application)") ([ordered]@{ key = $regKey; exists = $post.registry; nativeSettings = $facts.native_settings })

# qgis_process: plugin marcador so no perfil novo
$marker = Join-Path $roaming 'profiles\default\python\plugins\iman_marcador_047'
New-Item -ItemType Directory -Force $marker | Out-Null
Write-LfFile (Join-Path $marker 'metadata.txt') @('[general]', 'name=iman_marcador_047', 'qgisMinimumVersion=3.0', 'description=marcador do teste 047',
  'version=0.1', 'author=Instituto IMAN', 'email=nao@usado', 'about=marcador', 'repository=nao', 'hasProcessingProvider=yes')
Write-LfFile (Join-Path $marker '__init__.py') @('def classFactory(iface):', '    return None')
$qpBat = Join-Path $InstalledRoot 'bin\qgis_process-iman-terra.bat'
$qpOut = & cmd.exe /d /c "`"$qpBat`" --json plugins" 2>$null | Out-String
$qpExit = $LASTEXITCODE
Set-Content (Join-Path $run 'qgis_process-plugins.json') $qpOut
$qpPlugins = try { @(($qpOut | ConvertFrom-Json).plugins.PSObject.Properties.Name) } catch { @() }
Remove-Item -Recurse -Force $marker
Add-Check 'A2:qgis_process-perfil-novo' ($qpExit -eq 0 -and 'iman_marcador_047' -in $qpPlugins) ([ordered]@{ exit = $qpExit; plugins = $qpPlugins; marker = $marker })

# crash handler instalado: pasta de crash do produto
$crashRoot = Join-Path $local 'crashes'
$before = @(if (Test-Path $crashRoot) { Get-ChildItem $crashRoot -Directory | ForEach-Object FullName })
$dummy = Start-Process -FilePath "$env:SystemRoot\System32\PING.EXE" -ArgumentList @('-n', '120', '127.0.0.1') -WindowStyle Hidden -PassThru
$info = Join-Path $run 'crash-info.txt'
Write-LfFile $info @("$($dummy.Id)", '0', '0', '', '', "`"$exePath`"", 'QGIS Version: 3.44.13-Solothurn', 'Relatorio sintetico do teste da fatia 047')
# o QGIS abre o crash handler herdando o proprio ambiente, o do bin\iman-terra.env: o teste reproduz isso
$saved = [Environment]::GetEnvironmentVariables('Process')
Get-Content (Join-Path $InstalledRoot 'bin\iman-terra.env') | Where-Object { $_ -match '^([^=]+)=(.*)$' } |
  ForEach-Object { [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process') }
$crash = Start-Process -FilePath (Join-Path $InstalledRoot 'apps\qgis-ltr\qgiscrashhandler.exe') -ArgumentList "`"$info`"" -PassThru
foreach ($k in @([Environment]::GetEnvironmentVariables('Process').Keys)) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k], 'Process') }
# o relatorio e gravado quando a janela "Uh-oh" aparece (como no Invoke-BrandCaptures.ps1)
$null = Wait-ProcessWindow $crash.Id { param($w) [ImanWindowCapture]::Title($w) -like 'Uh-oh*' } 60
Start-Sleep -Seconds 2
$created = @(if (Test-Path $crashRoot) { Get-ChildItem $crashRoot -Directory | Where-Object { $_.FullName -notin $before } })
if (-not $crash.HasExited) { Stop-Process -Id $crash.Id -Force }
Stop-Process -Id $dummy.Id -Force -ErrorAction SilentlyContinue
Add-Check 'A2:crashes-do-produto' ($created.Count -ge 1) ([ordered]@{ crashRoot = $crashRoot; created = @($created | ForEach-Object Name) })

# 4. atalhos
$shortcutsAfter = Get-ProductShortcuts
$startMenu = @($shortcutsAfter | Where-Object { $_.path -notlike "$([Environment]::GetFolderPath('Desktop'))*" })
Add-Check 'A3:um-atalho-com-aumi' ($startMenu.Count -eq 1 -and $startMenu[0].aumi -eq $facts.aumi -and $facts.aumi) ([ordered]@{
    before = $shortcutsBefore; after = $shortcutsAfter; processAumi = $facts.aumi })
$notifKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\$($facts.aumi)"
$fallback = @($facts.message_bar_items | Where-Object { $_ -match 'Tarefa|Task' })
Add-Check 'A3:notificacao' ($facts.notification_task_result -eq 'completed' -and $fallback.Count -eq 0 -and -not $notifBefore -and (Test-Path $notifKey)) ([ordered]@{
    task = $facts.notification_task; taskResult = $facts.notification_task_result; messageBarFallback = $fallback
    aumiKeyBefore = $notifBefore; aumiKeyAfter = (Test-Path $notifKey); key = $notifKey
    captura = 'nao: o toast e janela do Windows, nao do processo do teste' })

# 5. Abrir com
$assoc = [ordered]@{}
foreach ($ext in 'qgs', 'qgz', 'qlr') {
  $k = Get-Item -LiteralPath "HKCU:\Software\Classes\.$ext\OpenWithProgids" -ErrorAction SilentlyContinue
  $assoc[$ext] = [ordered]@{
    openWithProgids = $(if ($k) { @($k.GetValueNames()) } else { @() })
    progIdCommand = Get-RegDefault "HKCU:\Software\Classes\IMANTerra.$ext\shell\open\command"
    progIdIcon = Get-RegDefault "HKCU:\Software\Classes\IMANTerra.$ext\DefaultIcon"
  }
}
$qgzAfter = [ordered]@{
  hkcr = Get-RegDefault 'Registry::HKEY_CLASSES_ROOT\.qgz'
  userChoice = Get-RegDefault 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.qgz\UserChoice' 'ProgId'
}
$okAssoc = @('qgs', 'qgz', 'qlr' | Where-Object { "IMANTerra.$_" -notin $assoc[$_].openWithProgids -or -not $assoc[$_].progIdCommand }).Count -eq 0
Add-Check 'A7:abrir-com' $okAssoc $assoc
Add-Check 'A7:padrao-do-qgz-igual' ($qgzBefore.hkcr -eq $qgzAfter.hkcr -and $qgzBefore.userChoice -eq $qgzAfter.userChoice) ([ordered]@{ before = $qgzBefore; after = $qgzAfter })

# 6. creditos do QGIS
$credits = [ordered]@{}
foreach ($f in 'AUTHORS', 'CONTRIBUTORS', 'SPONSORS', 'DONORS', 'TRANSLATORS') {
  $a = Join-Path $InstalledRoot "apps\qgis-ltr\doc\$f"; $b = Join-Path $OfficialRoot "apps\qgis-ltr\doc\$f"
  $ha = if (Test-Path $a) { (Get-FileHash -Algorithm SHA256 $a).Hash } else { 'ausente' }
  $hb = if (Test-Path $b) { (Get-FileHash -Algorithm SHA256 $b).Hash } else { 'ausente' }
  $credits[$f] = [ordered]@{ installed = $ha; official = $hb; equal = ($ha -eq $hb) }
}
# o LICENSE do oficial e composto pelo pacote OSGeo4W (a GPL do QGIS seguida dos termos de Oracle, SZIP, ECW e
# MrSID, medido na fatia 047): a GPL do QGIS da arvore tem de estar inteira dentro dele
$licA = Join-Path $InstalledRoot 'apps\qgis-ltr\doc\LICENSE'; $licB = Join-Path $OfficialRoot 'apps\qgis-ltr\doc\LICENSE'
$textA = if (Test-Path $licA) { [IO.File]::ReadAllText($licA).Replace("`r", '').Trim() } else { '' }
$textB = if (Test-Path $licB) { [IO.File]::ReadAllText($licB).Replace("`r", '') } else { '' }
$credits['LICENSE'] = [ordered]@{ installedBytes = (Get-Item $licA -ErrorAction SilentlyContinue).Length; officialBytes = (Get-Item $licB -ErrorAction SilentlyContinue).Length
  equal = ($textA -and $textB.Contains($textA)); rule = 'a GPL do QGIS da arvore contida no LICENSE composto do oficial' }
Add-Check 'A9:creditos-iguais-ao-oficial' (@($credits.Values | Where-Object { -not $_.equal }).Count -eq 0) $credits

# 7. guarda
$g = Invoke-Guard
Add-Check 'guarda' ($g.exit -eq 0) $g.last

$result.ok = @($result.checks.Values | Where-Object { -not $_.ok }).Count -eq 0
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step "instalado $(if ($result.ok) { 'OK' } else { 'FALHOU' }): $run"
if (-not $result.ok) { exit 1 }
