<#
.SYNOPSIS
  Splash real (fatia 069, A6): a fonte efetiva da mensagem de carga do QGIS e o splash com a mensagem, perfil novo.

.DESCRIPTION
  Abre a GUI sem --nologo, com perfil descartavel e o smoke\splash_font.py (via --code), que roda antes do
  splash->finish do main.cpp e grava splash.json (fonte do QSplashScreen, familia resolvida, nomes 1 e 5 do arquivo
  que desenha pelo QRawFont, mensagem) e duas capturas do splash pelo grab: com a mensagem do QGIS e com uma mensagem
  de teste. -AppRoot mede uma copia da arvore de outro build (ANTES).
  Medicao, nao gate: nada aqui reprova. A guarda do QGIS oficial roda no fim, e o que a rodada deixar na pasta do
  produto sai (Common.ps1). Saida: $WorkRoot\smoke\splash-<rotulo>-<data>\ (splash.json, result.json, PNGs).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [string] $AppRoot,
  [string] $Label = 'depois',
  [string] $Lang = 'pt_BR',
  [int] $GuiTimeoutSeconds = 240
)
. "$PSScriptRoot\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path
$o4w = $Paths.Osgeo4w
$app = if ($AppRoot) { $AppRoot } else { Join-Path $Paths.Install 'apps\qgis-ltr' }
$guiExe = "$app\bin\qgis.exe"
if (-not (Test-Path $guiExe)) { throw "GUI ausente: $guiExe" }

& $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot -Baseline | Out-Null

$run = Join-Path $Paths.Smoke ("splash-{0}-{1}" -f $Label.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
$profiles = Join-Path $run 'profiles'
New-Item -ItemType Directory -Force $profiles | Out-Null
New-DisposableProfile $profiles ((Join-Path $run 'cache') -replace '\\', '/') 'Build'
$productData = Get-ProductDataSnapshot 'Build'
Import-QgisRuntime $o4w $app $profiles

$guiArgs = @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--noversioncheck', '--lang', $Lang,
  '--code', "`"$(Join-Path $PSScriptRoot 'smoke\splash_font.py')`"")
$env:IMAN_SPLASH_OUT = $run
$t0 = Get-Date
$p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $guiArgs
# so o processo que esta rodada abriu, pelo PID (R3 do gate do 044)
$exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }

$json = Join-Path $run 'splash.json'
$f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$result = [ordered]@{ label = $Label; run = $run; app = $app; seconds = [int]((Get-Date) - $t0).TotalSeconds
  exitedClean = $exited; written = ($null -ne $f); facts = $f }
if ($f -and $f.font) {
  $s = $f.font
  Write-Step ("splash: mensagem '{0}'; fonte {1} {2} pt peso {3}, resolvida {4} '{5}' {6} px; arquivo: {7}, {8}" -f $f.message,
    $s.family, $s.pointSizeF, $s.weight, $s.resolvedFamily, $s.resolvedStyle, $s.resolvedPixelSize, $s.fileFamily, $s.fileVersion)
} else {
  Write-Step "splash: sem fatos (splash.json ausente ou sem QSplashScreen)"
}

$restored = Restore-ProductData $productData
if ($restored) { $result.productData = $restored; Write-Step ("dados-do-produto {0}" -f ($restored | ConvertTo-Json -Compress -Depth 4)) }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
$result.guard = [ordered]@{ ok = ($LASTEXITCODE -eq 0); last = ($guard.Trim() -split "`r?`n" | Select-Object -Last 1) }
Write-Step ("guard        {0}  {1}" -f $(if ($result.guard.ok) { 'OK' } else { 'FALHOU' }), $result.guard.last)
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
