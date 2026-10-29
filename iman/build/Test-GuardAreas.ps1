<#
.SYNOPSIS
  Teste das areas que a guarda ganhou na fatia 047 (A1 do briefing): cada area reprova quando o RETRATO e adulterado
  nela. O sistema nunca e alterado: o teste so le o registro e os arquivos e edita a copia do retrato.

.DESCRIPTION
  1. controle: retrato do sistema, comparacao sem adulterar -> a guarda passa;
  2. para cada area, o retrato e copiado, uma linha da area e adulterada e a guarda compara o sistema contra ele
     -> a guarda reprova.
  Sai com 0 so se o controle passar e todas as areas reprovarem. Saida em $WorkRoot\guard-areas\<data>\result.json.
#>
[CmdletBinding()]
param([string] $WorkRoot)
. "$PSScriptRoot\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path
$script = Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1'

$root = Join-Path $WorkRoot ("guard-areas\{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$guardDir = Join-Path $root 'guard'
New-Item -ItemType Directory -Force $guardDir | Out-Null

function Invoke-Guard([switch] $Baseline) {
  $all = @('-NoProfile', '-File', $script, '-WorkRoot', $WorkRoot, '-GuardDir', $guardDir)
  if ($Baseline) { $all += '-Baseline' }
  $out = & $pwshExe @all 2>&1 | Out-String
  [pscustomobject]@{ exit = $LASTEXITCODE; last = ($out.Trim() -split "`r?`n" | Select-Object -Last 1) }
}

$areas = [ordered]@{
  'hkcr-associacoes-e-progids'   = '^REG HKCR\\'
  'hkcu-software-classes'        = '^REG HKCU\\Software\\Classes\\'
  'userchoice'                   = '^REG HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\'
  'notificacoes'                 = '^REG HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Notifications\\Settings'
  'menu-iniciar-do-oficial'      = '^C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\QGIS 3\.44\.13'
  'desinstalacao-do-msi-oficial' = '^HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\{740D7A65-CBA3-1014-A0B5-B03A9B7608F5\}'
}

$null = Invoke-Guard -Baseline
$base = Join-Path $guardDir 'baseline.txt'
$pristine = Join-Path $root 'baseline-original.txt'
Copy-Item $base $pristine
$lines = @(Get-Content $pristine)

$steps = [ordered]@{}
$steps.controle = Invoke-Guard
$steps.controle | Add-Member line ''
$expect = [ordered]@{ controle = 0 }
foreach ($a in $areas.Keys) {
  $idx = 0..($lines.Count - 1) | Where-Object { $lines[$_] -match $areas[$a] } | Select-Object -First 1
  if ($null -eq $idx) { $steps[$a] = [pscustomobject]@{ exit = -1; last = 'area sem linha no retrato'; line = '' }; $expect[$a] = 1; continue }
  $tampered = $lines.Clone()
  $tampered[$idx] = $lines[$idx] + '|adulterado'
  $tampered | Set-Content -Encoding utf8 $base
  $steps[$a] = Invoke-Guard
  $steps[$a] | Add-Member line $lines[$idx]
  $expect[$a] = 1
}
Copy-Item $pristine $base -Force

$ok = $true
foreach ($k in $expect.Keys) {
  $pass = $steps[$k].exit -eq $expect[$k]
  $ok = $ok -and $pass
  Write-Step ("{0,-30} exit {1} (esperado {2}) {3}  linha: {4}" -f $k, $steps[$k].exit, $expect[$k], $(if ($pass) { 'OK' } else { 'FALHOU' }), $steps[$k].line)
}
[ordered]@{ ok = $ok; root = $root; areas = $areas; expected = $expect; steps = $steps } | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $root 'result.json')
Write-Step "teste das areas da guarda $(if ($ok) { 'OK' } else { 'FALHOU' }): $root"
if (-not $ok) { exit 1 }
