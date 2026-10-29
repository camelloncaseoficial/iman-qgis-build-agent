<#
.SYNOPSIS
  P3 do patch de 2026-10-29 da fatia 047 (ressalva R3): o crash handler instalado monta a pilha de uma falha real com
  o dbghelp.dll e o symsrv.dll da arvore (apps\qgis-ltr), nao com os do sistema.

.DESCRIPTION
  1. o dbghelp.dll e o symsrv.dll em apps\qgis-ltr: versao e SHA-256 iguais aos fixados ($DebuggerRedist);
  2. abre um processo descartavel (crash_target.py no Python da arvore instalada) que falha de verdade e grava o
     arquivo de info no formato do QGIS; o caminho de simbolos e o servidor da Microsoft com o cache na pasta da
     rodada (srv*<rodada>\symbols*...), para o dbghelp usar o symsrv;
  3. abre o apps\qgis-ltr\qgiscrashhandler.exe instalado com esse arquivo, no ambiente do bin\iman-terra.env (como o
     QGIS o abre); espera a janela "Uh-oh", captura, e le de fora os modulos do processo dele (o dbghelp.dll e o
     symsrv.dll carregados, com caminho e versao);
  4. a pasta de crash nova do produto tem stack.txt com a pilha da thread que falhou (o strlen do msvcrt);
  5. fecha o crash handler e o processo descartavel pelos PIDs que recebeu; guarda no comeco e no fim.
  Saida em $WorkRoot\verify\crash-stack-<data>\ (result.json, stack.txt, report.txt, a captura). Sai com 1 se
  alguma checagem falhar.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [int] $TimeoutSeconds = 180
)
. "$PSScriptRoot\..\..\build\Common.ps1"
. "$PSScriptRoot\..\..\build\WindowCapture.ps1"
$pwshExe = (Get-Process -Id $PID).Path
$run = Join-Path $WorkRoot ("verify\crash-stack-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$guardDir = Join-Path $run 'guard'
New-Item -ItemType Directory -Force $run, $guardDir | Out-Null
$name = Get-InternalName 'Installed'
$crashRoot = Join-Path $env:LOCALAPPDATA "$($name.Organization)\$($name.Application)\crashes"
$app = Join-Path $InstalledRoot 'apps\qgis-ltr'
$result = [ordered]@{ run = $run; installedRoot = $InstalledRoot; checks = [ordered]@{} }
function Add-Check([string] $id, [bool] $ok, $detail) {
  $result.checks[$id] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-34} {1}  {2}" -f $id, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 6))
}
function Invoke-Guard([switch] $Baseline) {
  $a = @('-NoProfile', '-File', (Join-Path $RepoRoot 'iman\build\Test-OfficialQgisUntouched.ps1'), '-WorkRoot', $WorkRoot, '-GuardDir', $guardDir)
  if ($Baseline) { $a += '-Baseline' }
  $o = & $pwshExe @a 2>&1 | Out-String
  [pscustomobject]@{ exit = $LASTEXITCODE; last = ($o.Trim() -split "`r?`n" | Select-Object -Last 1) }
}

$null = Invoke-Guard -Baseline

# 1. os dois arquivos na arvore
$files = [ordered]@{}
foreach ($f in $DebuggerRedist.Keys) {
  $p = Join-Path $app $f
  $i = Get-Item $p -ErrorAction SilentlyContinue
  $files[$f] = [ordered]@{ path = $p; exists = [bool]$i; version = "$($i.VersionInfo.FileVersionRaw)"
    sha256 = $(if ($i) { (Get-FileHash -Algorithm SHA256 $p).Hash.ToLowerInvariant() }); pinned = $DebuggerRedist[$f] }
}
Add-Check 'P3:dbghelp-symsrv-na-arvore' (@($files.Values | Where-Object { -not $_.exists -or $_.sha256 -ne $_.pinned.Sha256 -or $_.version -ne $_.pinned.Version }).Count -eq 0) $files

# 2. processo descartavel que falha
$python = Get-ChildItem (Join-Path $InstalledRoot 'apps') -Directory -Filter 'Python3*' | ForEach-Object { Join-Path $_.FullName 'python.exe' } |
  Where-Object { Test-Path $_ } | Select-Object -First 1
$info = Join-Path $run 'crash-info.txt'
$symbols = "srv*$run\symbols*https://msdl.microsoft.com/download/symbols"
$target = Start-Process -FilePath $python -ArgumentList @('-I', "`"$(Join-Path $PSScriptRoot 'crash_target.py')`"", "`"$info`"", "`"$symbols`"") -WindowStyle Hidden -PassThru
$deadline = (Get-Date).AddSeconds(30)
while (-not (Test-Path $info) -and -not $target.HasExited -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 200 }
$infoLines = @(if (Test-Path $info) { Get-Content $info })
Add-Check 'P3:falha-provocada' ((Test-Path $info) -and -not $target.HasExited -and $infoLines[0] -eq "$($target.Id)") ([ordered]@{
    python = $python; pid = $target.Id; info = $infoLines })

# 3. crash handler instalado, no ambiente do produto
$before = @(if (Test-Path $crashRoot) { Get-ChildItem $crashRoot -Directory | ForEach-Object FullName })
$saved = [Environment]::GetEnvironmentVariables('Process')
Get-Content (Join-Path $InstalledRoot 'bin\iman-terra.env') | Where-Object { $_ -match '^([^=]+)=(.*)$' } |
  ForEach-Object { [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process') }
$t0 = Get-Date
$crash = Start-Process -FilePath (Join-Path $app 'qgiscrashhandler.exe') -ArgumentList "`"$info`"" -PassThru
foreach ($k in @([Environment]::GetEnvironmentVariables('Process').Keys)) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k], 'Process') }
$h = Wait-ProcessWindow $crash.Id { param($w) [ImanWindowCapture]::Title($w) -like 'Uh-oh*' } $TimeoutSeconds
$seconds = [int]((Get-Date) - $t0).TotalSeconds
$loaded = [ordered]@{}
if (-not $crash.HasExited) {
  foreach ($m in (Get-Process -Id $crash.Id).Modules | Where-Object { $_.ModuleName -in @($DebuggerRedist.Keys) }) {
    $loaded[$m.ModuleName.ToLowerInvariant()] = [ordered]@{ path = $m.FileName; version = "$($m.FileVersionInfo.FileVersionRaw)" }
  }
}
$capture = $null
if ($h) {
  Start-Sleep -Seconds 2
  $capture = if (Save-WindowImage $h (Join-Path $run 'crash-handler.png')) { 'crash-handler.png' }
}
$okLoaded = @($DebuggerRedist.Keys | Where-Object { -not $loaded[$_] -or $loaded[$_].path -ne (Join-Path $app $_) }).Count -eq 0
Add-Check 'P3:handler-usa-os-da-arvore' ([bool]$h -and $okLoaded) ([ordered]@{ window = [bool]$h; seconds = $seconds; capture = $capture; modules = $loaded
    how = 'Process.Modules do qgiscrashhandler.exe aberto pelo teste, com a janela Uh-oh aberta' })

# 4. a pilha
$created = @(if (Test-Path $crashRoot) { Get-ChildItem $crashRoot -Directory | Where-Object { $_.FullName -notin $before } })
$stack = ''
foreach ($d in $created) {
  foreach ($f in 'stack.txt', 'report.txt') {
    if (Test-Path (Join-Path $d.FullName $f)) { Copy-Item (Join-Path $d.FullName $f) $run }
  }
}
if (Test-Path (Join-Path $run 'stack.txt')) { $stack = Get-Content (Join-Path $run 'stack.txt') -Raw }
$frames = @($stack -split "`r?`n" | Where-Object { $_.Trim() })
Add-Check 'P3:pilha-montada' ($created.Count -eq 1 -and $stack -match '(?i)strlen') ([ordered]@{ crashDir = @($created | ForEach-Object FullName)
    lines = $frames.Count; first = @($frames | Select-Object -First 6) })

# 5. fecha o que abriu
if ($h) { [ImanWindowCapture]::Close($h) }
if (-not $crash.WaitForExit(30000)) { Stop-Process -Id $crash.Id -Force }
if (-not $target.HasExited) { Stop-Process -Id $target.Id -Force }
$g = Invoke-Guard
Add-Check 'guarda' ($g.exit -eq 0) $g.last

$result.ok = @($result.checks.Values | Where-Object { -not $_.ok }).Count -eq 0
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step "pilha do crash handler $(if ($result.ok) { 'OK' } else { 'FALHOU' }): $run"
if (-not $result.ok) { exit 1 }
