<#
.SYNOPSIS
  Fonte da interface com a escolha do usuario (fatia 067, A2): um perfil descartavel, reaberto quatro vezes, no build
  desta branch ou numa copia da arvore de outro build (-AppRoot). Mede; nao corrige.

.DESCRIPTION
  Aberturas (smoke\font_choice.py, via --code), sempre com o mesmo perfil:
    1  perfil novo: mede (a); le Opcoes > Geral; escolhe Arial em Opcoes > Geral e clica OK;
    2  reaberto: mede (b, a escolha do usuario manda); le Opcoes; marca "Qt padrao" e clica OK (restaurar padrao);
    3  reaberto: mede (o que volta depois do padrao); le Opcoes; escolhe o tema Night Mapping e clica OK;
    4  reaberto: mede (Night Mapping depois da fonte escolhida); le Opcoes.
  -Case Night: o (c) do briefing num perfil novo proprio, sem fonte escolhida antes (no QGIS, o "Qt padrao" das
  Opcoes nao apaga a fonte escolhida, que mascararia o tema): 1 escolhe Night Mapping e clica OK; 2 reaberto, mede.
  Cada medida: a fonte da aplicacao e a do menu (familia, tamanho e o arquivo que desenha, pelos nomes 1 e 5 da
  tabela name), as chaves /app/fontFamily, /app/fontPointSize e UI/UITheme do perfil. As escritas no perfil sao as
  do proprio dialogo de Opcoes, pelo OK, como o usuario faria.
  Saida: $WorkRoot\smoke\font-choice-<rotulo>-<data>\ (abertura-N\choice.json e capturas, result.json). Sai com 1 se
  alguma abertura nao gravou os fatos ou a guarda do QGIS oficial falhou.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [string] $AppRoot,
  [string] $Label = 'depois',
  [string] $Other = 'Arial',
  [ValidateSet('Choice', 'Night')] [string] $Case = 'Choice',
  [int] $GuiTimeoutSeconds = 180
)
. "$PSScriptRoot\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path
$o4w = $Paths.Osgeo4w
$app = if ($AppRoot) { $AppRoot } else { Join-Path $Paths.Install 'apps\qgis-ltr' }
$guiExe = "$app\bin\qgis.exe"
if (-not (Test-Path $guiExe)) { throw "GUI ausente: $guiExe" }

$openings = if ($Case -eq 'Night') { @('measure;theme=Night Mapping'), @('measure;options') } else {
  @("measure;options;font=$Other"), @('measure;options;font=DEFAULT'), @('measure;options;theme=Night Mapping'), @('measure;options') }
$run = Join-Path $Paths.Smoke ("font-{0}-{1}-{2}" -f $(if ($Case -eq 'Night') { 'night' } else { 'choice' }), $Label.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
$profiles = Join-Path $run 'profiles'
New-Item -ItemType Directory -Force $profiles | Out-Null
New-DisposableProfile $profiles ((Join-Path $run 'cache') -replace '\\', '/') 'Build'
$productData = Get-ProductDataSnapshot 'Build'
Import-QgisRuntime $o4w $app $profiles

$result = [ordered]@{ label = $Label; app = $app; run = $run; openings = @() }
$n = 0
foreach ($steps in $openings) {
  $n++
  $out = Join-Path $run "abertura-$n"
  New-Item -ItemType Directory -Force $out | Out-Null
  $env:IMAN_FONT_OUT = $out
  $env:IMAN_FONT_STEPS = $steps
  $guiArgs = @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--nologo', '--noversioncheck',
    '--code', "`"$(Join-Path $PSScriptRoot 'smoke\font_choice.py')`"")
  $p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $guiArgs
  # so o processo que esta rodada abriu, pelo PID (R3 do gate do 044)
  $exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
  if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }
  $json = Join-Path $out 'choice.json'
  $f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
  $result.openings += [ordered]@{ n = $n; steps = $steps; exitedClean = $exited; written = ($null -ne $f); facts = $f }
  foreach ($m in @($f.measures)) {
    Write-Step ("abertura {0}: aplicacao {1} {2} pt (arquivo {3}, {4}); menu {5} {6} pt; /app/fontFamily={7}; UI/UITheme={8}" -f $n,
      $m.app.family, $m.app.pointSizeF, $m.app.file.family, $m.app.file.version, $m.menu.family, $m.menu.pointSizeF, $m.appFontFamily, $m.uiTheme)
  }
  foreach ($o in @($f.options)) { Write-Step ("abertura {0}: Opcoes > Geral: Qt padrao {1}, outra {2}, caixa '{3}', tamanho {4}" -f $n, $o.qtDefaultChecked, $o.customChecked, $o.combo, $o.size) }
  foreach ($a in @($f.actions)) { Write-Step ("abertura {0}: {1}={2}, OK {3}, gravado {4}" -f $n, $a.kind, $a.requested, $a.clickedOk, ($a.saved | ConvertTo-Json -Compress)) }
}

$restored = Restore-ProductData $productData
if ($restored) { $result.productData = $restored }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
$result.guard = [ordered]@{ ok = ($LASTEXITCODE -eq 0); last = ($guard.Trim() -split "`r?`n" | Select-Object -Last 1) }
$result.ok = @($result.openings | Where-Object { -not $_.written -or -not $_.exitedClean }).Count -eq 0 -and $result.guard.ok
$result | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step ("escolha da fonte {0}: {1} (guarda {2}): {3}" -f $Label, $(if ($result.ok) { 'medido' } else { 'INCOMPLETO' }), $(if ($result.guard.ok) { 'OK' } else { 'FALHOU' }), $run)
if (-not $result.ok) { exit 1 }
