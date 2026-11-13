<#
.SYNOPSIS
  Perfis existentes sem o tema (fatia 063, A3): o tema, o tamanho da folha de estilo, o estilo do Qt e as chaves
  UI/UITheme e qgis/style do perfil, antes e depois de o alvo abrir com ele. Mede; nao corrige perfil nenhum.

.DESCRIPTION
  -ProfileState:
    New       perfil novo (so a pasta do cache de rede), numa pasta nova da rodada;
    Fixture   copia do smoke\fixtures\profile-0.4.0\IMANTerra.ini (rodada do 0.4.0 instalado, com qgis/style=fusion),
              com a pasta do cache trocada pela da rodada;
    Existing  o perfil 'iman-smoke' da pasta -ProfilesRoot, reaberto como esta. Se a pasta ainda nao tem o perfil, ele
              nasce novo ali e fica (e assim que um alvo cria o perfil que outro alvo abre depois).
  A GUI abre com smoke\profile_theme.py (via --code), que grava os fatos em profile.json e sai. As chaves do .ini sao
  lidas do arquivo antes e depois da rodada: o que mudar foi o QGIS que gravou.
  Medicao, nao gate: sai com 0 se a rodada coletou os fatos e a guarda do QGIS oficial passou. O alvo Build remove o
  que a rodada deixar na pasta do produto (A3 da 058, Common.ps1).
  Saida: $WorkRoot\smoke\profile-<alvo>-<estado>-<data>\ (profile.json, result.json).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [ValidateSet('Build', 'Official', 'Installed')] [string] $Target = 'Build',
  [ValidateSet('New', 'Fixture', 'Existing')] [string] $ProfileState = 'New',
  [string] $ProfilesRoot,
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [int] $GuiTimeoutSeconds = 180
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
if ($ProfileState -eq 'Existing' -and -not $ProfilesRoot) { throw '-ProfileState Existing pede -ProfilesRoot' }
$plainEnv = [Environment]::GetEnvironmentVariables('Process')

$run = Join-Path $Paths.Smoke ("profile-{0}-{1}-{2}" -f $Target.ToLowerInvariant(), $ProfileState.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $run | Out-Null
$profiles = if ($ProfileState -eq 'Existing') { $ProfilesRoot } else { Join-Path $run 'profiles' }
$name = Get-InternalName $Target
$userIni = Join-Path $profiles "profiles\iman-smoke\$($name.Organization)\$($name.Application).ini"
$created = $false
if (-not (Test-Path $userIni)) {
  New-Item -ItemType Directory -Force $profiles | Out-Null
  New-DisposableProfile $profiles ((Join-Path $profiles 'cache') -replace '\\', '/') $Target
  $created = $true
  if ($ProfileState -eq 'Fixture') {
    $cacheDir = (Join-Path $profiles 'cache') -replace '\\', '/'
    $seed = Get-Content (Join-Path $PSScriptRoot 'smoke\fixtures\profile-0.4.0\IMANTerra.ini') -Encoding utf8
    Write-LfFile $userIni @($seed | ForEach-Object { if ($_ -match '^directory=') { "directory=$cacheDir" } else { $_ } })
  }
}

# as duas chaves do .ini do perfil, lidas do arquivo (secao [UI] UITheme e secao [qgis] style)
function Get-IniKeys([string] $path) {
  $keys = [ordered]@{ exists = (Test-Path $path); UITheme = $null; style = $null }
  if (-not $keys.exists) { return $keys }
  $section = $null
  foreach ($line in Get-Content $path -Encoding utf8) {
    if ($line -match '^\[(.+)\]$') { $section = $Matches[1]; continue }
    if ($section -eq 'UI' -and $line -match '^UITheme=(.*)$') { $keys.UITheme = $Matches[1] }
    if ($section -eq 'qgis' -and $line -match '^style=(.*)$') { $keys.style = $Matches[1] }
  }
  $keys
}
$before = Get-IniKeys $userIni
$productData = Get-ProductDataSnapshot $Target
Import-QgisRuntime $o4w $app $profiles

$guiArgs = @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--nologo', '--noversioncheck',
  '--code', "`"$(Join-Path $PSScriptRoot 'smoke\profile_theme.py')`"")
$vars = @{ IMAN_PROFILE_OUT = $run }
if ($Target -eq 'Installed') {
  # a GUI instalada abre com o ambiente de antes do runtime (o iman-terra.exe le o bin\iman-terra.env)
  $runtimeEnv = [Environment]::GetEnvironmentVariables('Process')
  foreach ($k in $runtimeEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
  foreach ($k in $plainEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $plainEnv[$k], 'Process') }
  foreach ($k in $vars.Keys) { [Environment]::SetEnvironmentVariable($k, $vars[$k], 'Process') }
  $p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $guiArgs
  foreach ($k in @([Environment]::GetEnvironmentVariables('Process').Keys)) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
  foreach ($k in $runtimeEnv.Keys) { [Environment]::SetEnvironmentVariable($k, $runtimeEnv[$k], 'Process') }
} else {
  foreach ($k in $vars.Keys) { [Environment]::SetEnvironmentVariable($k, $vars[$k], 'Process') }
  $p = Start-Process -FilePath $guiExe -PassThru -ArgumentList $guiArgs
}
# so o processo que esta rodada abriu, pelo PID (R3 do gate do 044)
$exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }

$json = Join-Path $run 'profile.json'
$f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$result = [ordered]@{ target = $Target; profileState = $ProfileState; profileCreatedByThisRun = $created
  profilesRoot = $(if ($ProfileState -eq 'Existing') { $ProfilesRoot } else { '<rodada>\profiles' }); exitedClean = $exited
  iniBefore = $before; iniAfter = (Get-IniKeys $userIni); facts = $f }
$restored = Restore-ProductData $productData
if ($restored) { $result.productData = $restored }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
$result.guard = [ordered]@{ ok = ($LASTEXITCODE -eq 0); last = ($guard.Trim() -split "`r?`n" | Select-Object -Last 1) }
$result.ok = $null -ne $f -and -not $f.error -and $exited -and $result.guard.ok -and (-not $restored -or $restored.ok)
$result | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step ("perfil {0}/{1}: tema '{2}', folha {3}, estilo {4} ({5}); ini antes UITheme={6} style={7}; depois UITheme={8} style={9}; guarda {10}" -f
  $Target, $ProfileState, $f.themeName, $f.styleSheetLength, $f.qtStyle, $f.qtStyleBase, $before.UITheme, $before.style,
  $result.iniAfter.UITheme, $result.iniAfter.style, $(if ($result.guard.ok) { 'OK' } else { 'FALHOU' }))
Write-Step "saida: $run"
if (-not $result.ok) { exit 1 }
