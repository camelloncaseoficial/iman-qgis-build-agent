<#
.SYNOPSIS
  A6 do briefing 047: instalacao (atualizacao sobre a 0.3.0 da distro) e desinstalacao do IMAN Terra nesta maquina,
  com a guarda em cada etapa. So com o "sim" do sponsor na sessao (STOP do briefing).

.DESCRIPTION
  -Phase Install -Installer <setup.exe>:
    antes: retrato da guarda (pasta propria da rodada), SHA-256 de cada arquivo do perfil da distro
    (%APPDATA%\InstitutoIMAN\IMAN Terra), entradas de "Aplicativos instalados" do produto, o que existe em {app};
    instala em silencio (/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /LOG), sem elevacao;
    depois: a arvore antiga da 0.3.0 saiu e a nova esta la (com o bin\iman-terra.env do postinstall), uma entrada
    so em "Aplicativos instalados" (0.4.0), o modo de instalacao do log (sem administrador), o perfil da distro com
    o mesmo SHA-256 por arquivo, a guarda.
  -Phase Uninstall -Run <pasta da fase Install>:
    desinstala em silencio (unins000.exe); depois: a arvore, os atalhos, o ProgID e os valores do "Abrir com" sairam,
    a entrada de "Aplicativos instalados" saiu, o perfil do produto (%APPDATA%\<org>\<app>) ficou, o perfil da
    distro com o mesmo SHA-256, a guarda contra o retrato do comeco da fase Install.
  Saida em $WorkRoot\verify\install-cycle-<data>\ (result-install.json, result-uninstall.json, logs do Inno).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [Parameter(Mandatory)] [ValidateSet('Install', 'Uninstall')] [string] $Phase,
  [string] $Installer,
  [string] $Run,
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [int] $TimeoutSeconds = 1800
)
. "$PSScriptRoot\..\..\build\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path
$brand = Get-Content (Join-Path $RepoRoot 'iman\brand\brand.json') -Raw -Encoding utf8 | ConvertFrom-Json
$name = Get-InternalName 'Installed'
$distroProfile = Join-Path $env:APPDATA 'InstitutoIMAN\IMAN Terra'
$productProfile = Join-Path $env:APPDATA "$($name.Organization)\$($name.Application)"
$appId = '{7B3A9E42-1C6D-4E9F-9A21-6F2E5A1D8B34}_is1'
if ($Phase -eq 'Install') {
  if (-not $Installer -or -not (Test-Path $Installer)) { throw '-Installer <setup.exe> obrigatorio' }
  $Run = Join-Path $WorkRoot ("verify\install-cycle-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
} elseif (-not $Run -or -not (Test-Path $Run)) { throw '-Run <pasta da fase Install> obrigatorio' }
$guardDir = Join-Path $Run 'guard'
New-Item -ItemType Directory -Force $Run, $guardDir | Out-Null
$result = [ordered]@{ phase = $Phase; run = $Run; checks = [ordered]@{} }
function Add-Check([string] $id, [bool] $ok, $detail) {
  $result.checks[$id] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-30} {1}  {2}" -f $id, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 6))
}
function Invoke-Guard([switch] $Baseline) {
  $a = @('-NoProfile', '-File', (Join-Path $RepoRoot 'iman\build\Test-OfficialQgisUntouched.ps1'), '-WorkRoot', $WorkRoot, '-GuardDir', $guardDir)
  if ($Baseline) { $a += '-Baseline' }
  $o = & $pwshExe @a 2>&1 | Out-String
  [pscustomobject]@{ exit = $LASTEXITCODE; last = ($o.Trim() -split "`r?`n" | Select-Object -Last 1); diff = @($o -split "`r?`n" | Where-Object { $_ -match '^(<=|=>) ' } | Select-Object -First 20) }
}
function Get-ProfileHashes([string] $root) {
  if (-not (Test-Path $root)) { return @() }
  @(Get-ChildItem $root -Recurse -File -Force | Sort-Object FullName | ForEach-Object {
      '{0}  {1}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash, $_.FullName.Substring($root.Length + 1) })
}
function Get-UninstallEntries {
  $out = @()
  foreach ($hive in 'HKCU', 'HKLM') {
    foreach ($view in 'Registry64', 'Registry32') {
      $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey($(if ($hive -eq 'HKCU') { 'CurrentUser' } else { 'LocalMachine' }), $view)
      $k = $base.OpenSubKey('Software\Microsoft\Windows\CurrentVersion\Uninstall')
      if (-not $k) { continue }
      foreach ($s in $k.GetSubKeyNames()) {
        $e = $k.OpenSubKey($s); $dn = $e.GetValue('DisplayName')
        if ($dn -and $dn -match [regex]::Escape($brand.product_name)) {
          $out += [ordered]@{ hive = $hive; view = $view; key = $s; displayName = $dn; version = $e.GetValue('DisplayVersion'); location = $e.GetValue('InstallLocation') }
        }
      }
    }
  }
  # a mesma chave vista pelas duas vistas do HKCU e uma entrada so
  @($out | Sort-Object { "$($_.hive)|$($_.key)" } -Unique)
}
function Get-ProductShortcuts {
  @([Environment]::GetFolderPath('Programs'), [Environment]::GetFolderPath('CommonPrograms'), [Environment]::GetFolderPath('Desktop')) |
    ForEach-Object { Get-ChildItem $_ -Recurse -Filter '*.lnk' -ErrorAction SilentlyContinue } |
    Where-Object { $_.BaseName -match [regex]::Escape($brand.product_name) } | ForEach-Object FullName
}

if ($Phase -eq 'Install') {
  $null = Invoke-Guard -Baseline
  $distroBefore = Get-ProfileHashes $distroProfile
  $distroBefore | Set-Content (Join-Path $Run 'perfil-distro-antes.sha256')
  $entriesBefore = @(Get-UninstallEntries)
  $treeBefore = @(Get-ChildItem $InstalledRoot -Force -ErrorAction SilentlyContinue | ForEach-Object Name)
  $result.before = [ordered]@{ distroProfileFiles = $distroBefore.Count; entries = $entriesBefore; appTop = $treeBefore; shortcuts = @(Get-ProductShortcuts) }

  $log = Join-Path $Run 'setup.log'
  $t0 = Get-Date
  $p = Start-Process -FilePath $Installer -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/LOG=`"$log`"") -PassThru
  $done = $p.WaitForExit($TimeoutSeconds * 1000)
  $seconds = [int]((Get-Date) - $t0).TotalSeconds
  Add-Check 'A6:instalou' ($done -and $p.ExitCode -eq 0) ([ordered]@{ exitCode = $p.ExitCode; seconds = $seconds; installer = $Installer })
  $logText = if (Test-Path $log) { Get-Content $log -Raw } else { '' }
  $modeLines = @($logText -split "`r?`n" | Where-Object { $_ -match '\s(Administrative install mode|Install mode root key|Privileges required)' })
  Add-Check 'A6:sem-elevacao' ($logText -match 'Administrative install mode: No' -and $logText -notmatch 'Administrative install mode: Yes') ([ordered]@{ log = $modeLines })

  $old = @('qgis', 'launcher', 'assets', 'demo', 'notices', 'profile-template', 'startup', 'BUILD_ID.txt', 'qgis-manifest.txt')
  $oldLeft = @($old | Where-Object { Test-Path (Join-Path $InstalledRoot $_) })
  $new = [ordered]@{
    exe = Test-Path (Join-Path $InstalledRoot 'bin\iman-terra.exe'); env = Test-Path (Join-Path $InstalledRoot 'bin\iman-terra.env')
    postinstallLogTail = @(Get-Content (Join-Path $InstalledRoot 'var\log\iman-postinstall.log') -Tail 3 -ErrorAction SilentlyContinue)
    notices = @('LICENSE', 'THIRD_PARTY_NOTICES.md', 'SOURCE_CODE.md' | Where-Object { Test-Path (Join-Path $InstalledRoot $_) })
  }
  Add-Check 'A6:arvore-antiga-saiu' ($oldLeft.Count -eq 0) ([ordered]@{ before = $treeBefore; oldLeft = $oldLeft; after = @(Get-ChildItem $InstalledRoot -Force | ForEach-Object Name) })
  Add-Check 'A6:arvore-nova' ($new.exe -and $new.env -and $new.notices.Count -eq 3) $new
  $entries = @(Get-UninstallEntries)
  Add-Check 'A6:uma-entrada-0.4.0' ($entries.Count -eq 1 -and $entries[0].version -eq $brand.product_version -and $entries[0].key -eq $appId) ([ordered]@{ before = $entriesBefore; after = $entries })
  $distroAfter = Get-ProfileHashes $distroProfile
  $distroAfter | Set-Content (Join-Path $Run 'perfil-distro-depois-da-instalacao.sha256')
  Add-Check 'A6:perfil-distro-intacto' ($distroBefore.Count -gt 0 -and (($distroBefore -join "`n") -eq ($distroAfter -join "`n"))) ([ordered]@{ files = $distroAfter.Count; profile = $distroProfile })
  $g = Invoke-Guard
  Add-Check 'guarda' ($g.exit -eq 0) $g
} else {
  $distroBefore = Get-Content (Join-Path $Run 'perfil-distro-antes.sha256')
  $uninst = Join-Path $InstalledRoot 'unins000.exe'
  $log = Join-Path $Run 'uninstall.log'
  $t0 = Get-Date
  $p = Start-Process -FilePath $uninst -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/LOG=`"$log`"") -PassThru
  $null = $p.WaitForExit($TimeoutSeconds * 1000)
  # o desinstalador do Inno se copia para %TEMP% e segue de la: espera a pasta e a entrada sumirem
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline -and ((Test-Path $uninst) -or @(Get-UninstallEntries).Count)) { Start-Sleep -Seconds 5 }
  Add-Check 'A6:desinstalou' (-not (Test-Path $uninst)) ([ordered]@{ seconds = [int]((Get-Date) - $t0).TotalSeconds; leftover = @(Get-ChildItem $InstalledRoot -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object FullName) })
  Add-Check 'A6:arvore-saiu' (-not (Test-Path $InstalledRoot)) ([ordered]@{ path = $InstalledRoot; exists = (Test-Path $InstalledRoot) })
  Add-Check 'A6:atalhos-sairam' (@(Get-ProductShortcuts).Count -eq 0) ([ordered]@{ left = @(Get-ProductShortcuts) })
  $assocLeft = @()
  foreach ($ext in 'qgs', 'qgz', 'qlr') {
    $k = Get-Item -LiteralPath "HKCU:\Software\Classes\.$ext\OpenWithProgids" -ErrorAction SilentlyContinue
    if ($k -and "IMANTerra.$ext" -in $k.GetValueNames()) { $assocLeft += "HKCU\Software\Classes\.$ext\OpenWithProgids\IMANTerra.$ext" }
    if (Test-Path "HKCU:\Software\Classes\IMANTerra.$ext") { $assocLeft += "HKCU\Software\Classes\IMANTerra.$ext" }
  }
  if (Test-Path 'HKCU:\Software\Classes\Applications\iman-terra.exe') { $assocLeft += 'HKCU\Software\Classes\Applications\iman-terra.exe' }
  Add-Check 'A6:associacoes-sairam' ($assocLeft.Count -eq 0) ([ordered]@{ left = $assocLeft })
  Add-Check 'A6:entrada-saiu' (@(Get-UninstallEntries).Count -eq 0) ([ordered]@{ entries = @(Get-UninstallEntries) })
  Add-Check 'A6:perfil-do-produto-ficou' (Test-Path (Join-Path $productProfile 'profiles')) ([ordered]@{ profile = $productProfile })
  $distroAfter = Get-ProfileHashes $distroProfile
  $distroAfter | Set-Content (Join-Path $Run 'perfil-distro-depois-da-desinstalacao.sha256')
  Add-Check 'A6:perfil-distro-intacto' ((($distroBefore -join "`n") -eq ($distroAfter -join "`n"))) ([ordered]@{ files = $distroAfter.Count })
  $g = Invoke-Guard
  Add-Check 'guarda' ($g.exit -eq 0) $g
}

$result.ok = @($result.checks.Values | Where-Object { -not $_.ok }).Count -eq 0
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $Run "result-$($Phase.ToLowerInvariant()).json")
Write-Step "ciclo $Phase $(if ($result.ok) { 'OK' } else { 'FALHOU' }): $Run"
if (-not $result.ok) { exit 1 }
