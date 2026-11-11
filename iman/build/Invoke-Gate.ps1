<#
.SYNOPSIS
  Comando de gate PROPOSTO para o kind qgis-build (o oficial e registrado pelo arquiteto no crew_gate.sh).

.DESCRIPTION
  Um comando, tres verificacoes, na arvore commitada:
    0. retrato do QGIS oficial no comeco da rodada (Test-OfficialQgisUntouched.ps1 -Baseline): a guarda do smoke
       compara contra ele e prova que esta rodada nao tocou o oficial (ressalva R1 do gate 043);
    1. patchset: Test-Patchset.ps1 (todo arquivo do QGIS alterado esta em iman/PATCHES.md, e vice-versa);
    2. build incremental: Build-Qgis.ps1 sem -Clean, sem rede para dependencias (Get-Osgeo4wPackages -Offline);
    3. smoke: Invoke-Smoke.ps1 (versao, provedores, plugins, native:buffer, janela + .qgz, marca, guarda).
  Pre-requisito: a bancada ja montada uma vez por Invoke-ImanBuild.ps1. Sai com 0 so se as tres passarem.
  Cada etapa roda num pwsh filho com console proprio e oculto (CreateNoWindow), a entrada fechada e a saida repassada
  linha a linha (fatia 058, A4): o gate nao depende do console de quem o chama. O crew_gate.sh roda o gate com a
  saida num arquivo, e a rodada 1 da fatia 049 caiu no pwsh aninhado com 0xE9 ao definir o titulo do console, antes
  do build; com console proprio, a etapa nao herda o estado do console do terminal.
#>
[CmdletBinding()]
param([string] $WorkRoot)
. "$PSScriptRoot\Common.ps1"
$ErrorActionPreference = 'Continue'
$pwshExe = (Get-Process -Id $PID).Path
# o console oculto do filho nasce com a pagina de codigo OEM do sistema; e nela que a saida dele chega pelo pipe
$childEncoding = [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage)

# Uma etapa: pwsh -NoProfile -File <script> [-WorkRoot <raiz>] [extra], com console proprio; devolve o codigo de saida
function Invoke-GateStep([string] $Script, [string[]] $Extra = @()) {
  $psi = [Diagnostics.ProcessStartInfo]::new($pwshExe)
  foreach ($a in @('-NoProfile', '-NonInteractive', '-File', (Join-Path $PSScriptRoot $Script))) { $psi.ArgumentList.Add($a) }
  if ($WorkRoot) { $psi.ArgumentList.Add('-WorkRoot'); $psi.ArgumentList.Add($WorkRoot) }
  foreach ($a in $Extra) { $psi.ArgumentList.Add($a) }
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.StandardOutputEncoding = $childEncoding
  $psi.StandardErrorEncoding = $childEncoding
  $p = [Diagnostics.Process]::Start($psi)
  $p.StandardInput.Close()
  $err = $p.StandardError.ReadToEndAsync()
  while ($null -ne ($line = $p.StandardOutput.ReadLine())) { Write-Host $line }
  $p.WaitForExit()
  if ($err.Result) { Write-Host $err.Result.TrimEnd() }
  $p.ExitCode
}

$dirty = & git -C $RepoRoot status --porcelain
if ($dirty) { Write-Host 'GATE: arvore com mudanca nao commitada; o gate roda na arvore commitada'; $dirty; exit 1 }
Write-Host "GATE qgis-build em $(& git -C $RepoRoot rev-parse --short HEAD)"

if (Invoke-GateStep 'Test-OfficialQgisUntouched.ps1' @('-Baseline')) { Write-Host 'GATE FALHOU: retrato da guarda'; exit 1 }

if (Invoke-GateStep 'Test-Patchset.ps1') { Write-Host 'GATE FALHOU: patchset'; exit 1 }

if (Invoke-GateStep 'Get-Osgeo4wPackages.ps1' @('-Offline')) { Write-Host 'GATE FALHOU: dependencias'; exit 1 }

if (Invoke-GateStep 'Build-Qgis.ps1') { Write-Host 'GATE FALHOU: build'; exit 1 }

if (Invoke-GateStep 'Invoke-Smoke.ps1') { Write-Host 'GATE FALHOU: smoke'; exit 1 }

Write-Host 'GATE OK'
