<#
.SYNOPSIS
  Capturas e cliques do prototipo da fatia 059 (pagina inicial e "Sobre o IMAN Terra"), no build, com perfil novo.

.DESCRIPTION
  Evidencia do laudo, fora do gate (o prototipo nao tem guarda nova nem teste de regressao, briefing 059). Uma rodada
  com guarda propria do QGIS oficial (retrato no comeco, comparacao no fim):
    1. tres projetos descartaveis (.qgz do fixture do smoke, titulos "Projeto de teste 059 A/B/C") na pasta da rodada;
    2. o build abre com perfil novo e roda smoke\capture_home.py: pagina inicial sem recentes (janela maximizada), os
       quatro cartoes clicados (cada dialogo fotografado e fechado), os tres projetos abertos e fechados (viram os
       recentes), a pagina com eles, o menu de contexto de um recente, um recente aberto pela pagina e fechado, a
       pagina em 1366x768, o menu Ajuda, o "Sobre o IMAN Terra" com a lista de terceiros no meio e o QgsAbout aberto
       pelo botao "Sobre o QGIS"; por fim, o lado a lado com as capturas da distro congelada.
  Saida: $WorkRoot\smoke\home-captures-<data>\ (PNGs, home-captures.json, summary.json). So abre, toca e fecha o
  processo que ela mesma abriu.

.EXAMPLE
  pwsh -NoProfile -File iman/build/Invoke-HomeCaptures.ps1
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [string] $DistroShots,
  [int] $GuiTimeoutSeconds = 300
)
. "$PSScriptRoot\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path
# capturas da distro congelada (referencia do lado a lado), pelo caminho relativo dos repos irmaos
if (-not $DistroShots) {
  $DistroShots = Join-Path $RepoRoot '..\z_freeze\iman-qgis-distro-agent\docs\verify\025-db23-db24\evidencia\shots'
}

$o4w = $Paths.Osgeo4w; $app = Join-Path $Paths.Install 'apps\qgis-ltr'; $guiExe = "$app\bin\qgis.exe"
$run = Join-Path $Paths.Smoke ("home-captures-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$work = Join-Path $run 'projetos'
New-Item -ItemType Directory -Force $work | Out-Null
$summary = [ordered]@{ target = 'Build'; run = $run; distroShots = $DistroShots }

& $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot -Baseline | Out-Null

$profiles = Join-Path $run 'profiles'
New-DisposableProfile $profiles (Join-Path $run 'cache') 'Build'
$productData = Get-ProductDataSnapshot 'Build'
Import-QgisRuntime $o4w $app $profiles

# projetos descartaveis: o fixture do smoke com outro titulo, cada um num .qgz ao lado do points.geojson
$fx = Join-Path $PSScriptRoot 'smoke\fixtures'
Copy-Item "$fx\points.geojson" $work
$qgs = [IO.File]::ReadAllText("$fx\smoke.qgs")
$projects = foreach ($letter in 'A', 'B', 'C') {
  $title = "Projeto de teste 059 $letter"
  $stage = Join-Path $run "qgz-$letter"
  New-Item -ItemType Directory -Force $stage | Out-Null
  $file = "projeto_de_teste_059_$($letter.ToLowerInvariant())"
  [IO.File]::WriteAllText("$stage\$file.qgs", $qgs.Replace('<title>smoke</title>', "<title>$title</title>").Replace('projectname="smoke"', "projectname=`"$title`""))
  Compress-Archive -Path "$stage\$file.qgs" -DestinationPath (Join-Path $work "$file.qgz") -Force
  (Join-Path $work "$file.qgz")
}
$env:IMAN_SMOKE_OUT = $run
$env:IMAN_HOME_PROJECTS = $projects -join ';'
$env:IMAN_DISTRO_SHOTS = (Resolve-Path $DistroShots).Path

$p = Start-Process -FilePath $guiExe -PassThru -ArgumentList @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke',
  '--nologo', '--noversioncheck', '--code', "`"$(Join-Path $PSScriptRoot 'smoke\capture_home.py')`"")
$exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }
$summary.exitedClean = $exited
$summary.facts = if (Test-Path "$run\home-captures.json") { Get-Content "$run\home-captures.json" -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }

$restored = Restore-ProductData $productData
if ($restored) { $summary.productData = $restored }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
$summary.guard = ($guard.Trim() -split "`r?`n" | Select-Object -Last 1)
$summary.guardOk = $LASTEXITCODE -eq 0
$summary.captures = @(Get-ChildItem $run -Filter '*.png' | ForEach-Object Name)
$summary | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 (Join-Path $run 'summary.json')
$errors = @(if ($summary.facts) { $summary.facts.errors.PSObject.Properties | ForEach-Object Name })
# erro de Python no registro de mensagens do QGIS durante a rodada (do produto, do plugin ou deste roteiro)
$pythonErrors = @(if ($summary.facts) { $summary.facts.message_log | Where-Object { $_.tag -match 'Python' } })
$summary.pythonErrors = $pythonErrors.Count
$summary | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 (Join-Path $run 'summary.json')
Write-Step "capturas da 059: $run (guarda $(if ($summary.guardOk) { 'OK' } else { 'FALHOU' }); passos com erro: $($errors.Count); erros de Python no registro: $($pythonErrors.Count))"
if (-not $summary.guardOk -or -not $exited -or $errors.Count -or $pythonErrors.Count -or ($restored -and -not $restored.ok)) { exit 1 }
