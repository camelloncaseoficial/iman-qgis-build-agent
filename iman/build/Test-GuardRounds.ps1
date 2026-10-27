<#
.SYNOPSIS
  Teste da guarda (A12 do briefing 044, ressalva R1 do gate 043), contra arvores de TESTE, nunca o QGIS oficial.

.DESCRIPTION
  Simula rodadas do gate com Test-OfficialQgisUntouched.ps1 apontado para uma instalacao e um perfil de teste:
    1. rodada 1: retrato no comeco, comparacao no fim, sem mudanca -> a guarda passa;
    2. entre rodadas um arquivo do perfil de teste muda (o sponsor abriu o QGIS oficial);
       rodada 2: retrato novo no comeco, comparacao no fim -> a guarda passa;
    3. rodada 3: retrato no comeco, um arquivo muda DURANTE a rodada -> a guarda reprova;
    4. controle do defeito antigo: comparar com o retrato da rodada 1 (que nunca se renovava) depois da mudanca
       entre rodadas -> a guarda reprova, como reprovava o gate do 043.
  Sai com 0 so se as quatro expectativas se cumprirem. Saida em $WorkRoot\guard-test\<data>\result.json.
#>
[CmdletBinding()]
param([string] $WorkRoot)
. "$PSScriptRoot\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path

$root = Join-Path $WorkRoot ("guard-test\{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$install = Join-Path $root 'oficial-de-teste'
$profile = Join-Path $root 'perfil-de-teste'
$guardDir = Join-Path $root 'guard'
New-Item -ItemType Directory -Force "$install\bin", "$profile\profiles\default\QGIS", $guardDir | Out-Null
Set-Content "$install\bin\qgis-ltr-bin.exe" 'binario de teste'
$ini = "$profile\profiles\default\QGIS\QGIS3.ini"
Set-Content $ini "[qgis]`nfoo=1"
$guardArgs = @('-OfficialRoot', $install, '-DataRoots', $profile, '-RegistryKeys', 'HKCU\Software\IMAN-guard-test-inexistente', '-GuardDir', $guardDir)
$script = Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1'

function Invoke-Guard([switch] $Baseline) {
  $all = @('-NoProfile', '-File', $script, '-WorkRoot', $WorkRoot) + $guardArgs
  if ($Baseline) { $all += '-Baseline' }
  $out = & $pwshExe @all 2>&1 | Out-String
  [pscustomobject]@{ exit = $LASTEXITCODE; last = ($out.Trim() -split "`r?`n" | Select-Object -Last 1) }
}
function Edit-Profile([string] $line) {
  Start-Sleep -Milliseconds 50   # garante mtime novo
  Add-Content $ini $line
}

$steps = [ordered]@{}
$null = Invoke-Guard -Baseline
$steps.round1 = Invoke-Guard
Copy-Item (Join-Path $guardDir 'baseline.txt') (Join-Path $root 'baseline-rodada1.txt')

Edit-Profile 'aberto_entre_rodadas=1'
$null = Invoke-Guard -Baseline
$steps.round2_after_change_between_rounds = Invoke-Guard

$null = Invoke-Guard -Baseline
Edit-Profile 'mudado_durante_a_rodada=1'
$steps.round3_change_during_round = Invoke-Guard

Copy-Item (Join-Path $root 'baseline-rodada1.txt') (Join-Path $guardDir 'baseline.txt') -Force
$steps.control_stale_baseline = Invoke-Guard

$expect = [ordered]@{ round1 = 0; round2_after_change_between_rounds = 0; round3_change_during_round = 1; control_stale_baseline = 1 }
$ok = $true
foreach ($k in $expect.Keys) {
  $pass = $steps[$k].exit -eq $expect[$k]
  $ok = $ok -and $pass
  Write-Step ("{0,-36} exit {1} (esperado {2}) {3}  {4}" -f $k, $steps[$k].exit, $expect[$k], $(if ($pass) { 'OK' } else { 'FALHOU' }), $steps[$k].last)
}
[ordered]@{ ok = $ok; root = $root; expected = $expect; steps = $steps } | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $root 'result.json')
Write-Step "teste da guarda $(if ($ok) { 'OK' } else { 'FALHOU' }): $root"
if (-not $ok) { exit 1 }
