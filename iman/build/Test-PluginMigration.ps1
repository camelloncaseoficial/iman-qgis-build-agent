<#
.SYNOPSIS
  Migracao do projeto REURB pelo plugin embarcado, no produto (fatia 061, T2, T3 e T4): um projeto do plugin anterior,
  aberto no IMAN Terra desta arvore, passa ao schema novo com copia de seguranca, sem perder dado, e nao migra de novo.

.DESCRIPTION
  Sempre com perfil descartavel e projeto descartavel, criado para isto pelo servico do proprio plugin (nunca dado
  real, nenhum CPF ou CNPJ: a pessoa vai sem documento). Fatos pelo smoke\migration_facts.py (via --code).
  -Phase Seed: a GUI do alvo, com o plugin que a arvore embarca, cria em <rodada>\work\reurb um projeto com um lote,
    uma pessoa e o vinculo dela ao lote. Na fatia 061 roda na instalacao do build de antes da troca da trava (plugin
    0.3.1, schema 3), antes de recompilar. Checa o schema e as contagens (1, 1, 1) e grava o GeoPackage semente.
  -Phase Migrate -SeedRun <rodada da fase Seed>: copia so o GeoPackage semente para uma pasta nova e abre a GUI duas
    vezes, cada uma reabrindo o projeto pelo caminho do botao "Reabrir projeto" do painel do plugin:
      M1 a primeira abertura migra: o schema sai do da semente para o do plugin, a copia de seguranca (<gpkg>.bak)
         fica ao lado com o SHA-256 da semente, lotes, pessoas e vinculos com as mesmas contagens, a pessoa pelo nome;
      M1 a aba Pessoas do painel esta habilitada e lista a pessoa migrada (T3; e o T2 da aba, no perfil do -ProfileState);
      M2 a segunda abertura nao migra: o schema ja e o novo antes, nenhuma copia nova, a copia de antes intacta, as
         mesmas contagens;
      T4 o plugin carregado e o do gerenciador de complementos na versao da trava (iman/plugin/plugin.lock.json),
         autor "Instituto IMAN".
  -Target Build (padrao) | Installed, como no Test-PluginBoot.ps1. -ProfileState New | Seeded (o IMANTerra.ini da
  fixture profile-0.4.0). Ao fim, a pasta do produto (A3 da 058) e a guarda. Saida em
  $WorkRoot\verify\plugin-migration-<fase>-<alvo>-<data>\ (result.json, migration-*.json, capturas do painel).
  Sai com 1 se o veredito falhar.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [Parameter(Mandatory)] [ValidateSet('Seed', 'Migrate')] [string] $Phase,
  [string] $SeedRun,
  [ValidateSet('Build', 'Installed')] [string] $Target = 'Build',
  [ValidateSet('New', 'Seeded')] [string] $ProfileState = 'New',
  [string] $InstalledRoot = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [int] $GuiTimeoutSeconds = 240
)
. "$PSScriptRoot\Common.ps1"
$pwshExe = (Get-Process -Id $PID).Path
$lock = Get-PluginLock
$personName = 'Pessoa de Teste 061'

if ($Target -eq 'Build') {
  $o4w = $Paths.Osgeo4w; $app = Join-Path $Paths.Install 'apps\qgis-ltr'; $guiExe = "$app\bin\qgis.exe"
} else {
  $o4w = $InstalledRoot; $app = Join-Path $InstalledRoot 'apps\qgis-ltr'; $guiExe = "$o4w\bin\iman-terra.exe"
}
if (-not (Test-Path $guiExe)) { throw "GUI ausente: $guiExe" }
if ($Phase -eq 'Migrate' -and (-not $SeedRun -or -not (Test-Path (Join-Path $SeedRun 'semente')))) { throw '-SeedRun <rodada da fase Seed> obrigatorio' }
$plainEnv = [Environment]::GetEnvironmentVariables('Process')

$run = Join-Path $WorkRoot ("verify\plugin-migration-{0}-{1}-{2}" -f $Phase.ToLowerInvariant(), $Target.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
$workspace = Join-Path $run 'work\reurb'
$profiles = Join-Path $run 'profiles'
New-Item -ItemType Directory -Force $workspace, $profiles | Out-Null
$cacheDir = (Join-Path $run 'cache') -replace '\\', '/'
New-DisposableProfile $profiles $cacheDir $Target
$productData = Get-ProductDataSnapshot $Target
if ($ProfileState -eq 'Seeded') {
  $name = Get-InternalName $Target
  $userIni = Join-Path $profiles "profiles\iman-smoke\$($name.Organization)\$($name.Application).ini"
  $seedIni = Get-Content (Join-Path $PSScriptRoot 'smoke\fixtures\profile-0.4.0\IMANTerra.ini') -Encoding utf8
  Write-LfFile $userIni @($seedIni | ForEach-Object { if ($_ -match '^directory=') { "directory=$cacheDir" } else { $_ } })
}
Import-QgisRuntime $o4w $app $profiles

function Get-Sha([string] $path) { if (Test-Path -LiteralPath $path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant() } }

# uma abertura da GUI com o migration_facts.py; so o processo que esta rodada abriu, pelo PID (R3 do gate do 044)
function Invoke-Gui([string] $label) {
  $guiArgs = @('--profiles-path', "`"$profiles`"", '--profile', 'iman-smoke', '--nologo', '--noversioncheck',
    '--code', "`"$(Join-Path $PSScriptRoot 'smoke\migration_facts.py')`"")
  $vars = @{ IMAN_MIG_OUT = $run; IMAN_MIG_PHASE = $(if ($Phase -eq 'Seed') { 'seed' } else { 'open' }); IMAN_MIG_PLUGIN_ID = $lock.id
    IMAN_MIG_WORKSPACE = $workspace; IMAN_MIG_LABEL = $label }
  if ($Target -eq 'Installed') {
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
  $exited = $p.WaitForExit($GuiTimeoutSeconds * 1000)
  if (-not $exited) { Stop-Process -Id $p.Id -Force; Start-Sleep 2 }
  $json = Join-Path $run "migration-$label.json"
  $f = if (Test-Path $json) { Get-Content $json -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
  [pscustomobject]@{ exited = $exited; facts = $f; errors = @(if ($f) { $f.errors.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" } }) }
}

$result = [ordered]@{ phase = $Phase; target = $Target; profileState = $ProfileState; run = $run; seedRun = $SeedRun
  lock = [ordered]@{ id = $lock.id; version = $lock.version; tag = $lock.tag; commit = $lock.commit }; checks = [ordered]@{} }
function Add-Check([string] $id, [bool] $ok, $detail) {
  $result.checks[$id] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-28} {1}  {2}" -f $id, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 5))
}
function Get-Counts($g) { [ordered]@{ lotes = $g.lotes; pessoas = $g.pessoas; lote_pessoa = $g.lote_pessoa } }

if ($Phase -eq 'Seed') {
  $g = Invoke-Gui 'semente'
  $f = $g.facts
  Add-Check 'facts' ($f -and $g.exited -and $g.errors.Count -eq 0) ([ordered]@{ exitedClean = $g.exited; errors = $g.errors })
  if ($f -and $f.after) {
    $counts = Get-Counts $f.after
    Add-Check 'S:projeto-semeado' ($counts.lotes -ge 1 -and $counts.pessoas -ge 1 -and $counts.lote_pessoa -ge 1 -and $personName -in @($f.after.person_names)) ([ordered]@{
        schemaVersion = $f.after.schema_version; counts = $counts; persons = $f.after.person_names; plugin = $f.plugin; seed = $f.seed })
    # a semente: so o GeoPackage, guardado fora da pasta de trabalho
    $seedDir = Join-Path $run 'semente'
    New-Item -ItemType Directory -Force $seedDir | Out-Null
    Copy-Item -LiteralPath $f.after.path $seedDir
    $result.seed = [ordered]@{ file = (Split-Path $f.after.path -Leaf); sha256 = (Get-Sha (Join-Path $seedDir (Split-Path $f.after.path -Leaf)))
      schemaVersion = $f.after.schema_version; counts = $counts; pluginVersion = $f.plugin.version }
  }
} else {
  $seedJson = Get-Content (Join-Path $SeedRun 'result.json') -Raw -Encoding utf8 | ConvertFrom-Json
  $seedFile = Join-Path $SeedRun "semente\$($seedJson.seed.file)"
  $seedSha = Get-Sha $seedFile
  Copy-Item -LiteralPath $seedFile $workspace
  $gpkg = Join-Path $workspace $seedJson.seed.file
  $bak = "$gpkg.bak"
  $result.seed = [ordered]@{ file = $seedJson.seed.file; sha256 = $seedSha; schemaVersion = $seedJson.seed.schemaVersion; counts = $seedJson.seed.counts
    pluginVersion = $seedJson.seed.pluginVersion; matchesSeedRun = ($seedSha -eq $seedJson.seed.sha256) }

  $g1 = Invoke-Gui 'abertura-1'
  $f1 = $g1.facts
  $bakSha1 = Get-Sha $bak
  $gpkgSha1 = Get-Sha $gpkg
  $g2 = Invoke-Gui 'abertura-2'
  $f2 = $g2.facts
  $bakSha2 = Get-Sha $bak
  Add-Check 'facts' ($f1 -and $f2 -and $g1.exited -and $g2.exited -and ($g1.errors.Count + $g2.errors.Count) -eq 0) ([ordered]@{
      exitedClean = @($g1.exited, $g2.exited); errors = @($g1.errors + $g2.errors) })
  if ($f1 -and $f1.after) {
    $seedCounts = $seedJson.seed.counts
    $c1 = Get-Counts $f1.after
    $same1 = $c1.lotes -eq $seedCounts.lotes -and $c1.pessoas -eq $seedCounts.pessoas -and $c1.lote_pessoa -eq $seedCounts.lote_pessoa
    $wantSchema = "$($f1.after.schema_version)"
    Add-Check 'M1:migrou' ($f1.read.ok -and $f1.before.schema_version -eq $seedJson.seed.schemaVersion -and [int]$wantSchema -gt [int]$seedJson.seed.schemaVersion) ([ordered]@{
        read = $f1.read; before = $f1.before.schema_version; after = $f1.after.schema_version; seed = $seedJson.seed.schemaVersion })
    Add-Check 'M1:copia-de-seguranca' ((@($f1.backupsBefore).Count -eq 0) -and (@($f1.backupsAfter) -join ',') -eq "$($seedJson.seed.file).bak" -and $bakSha1 -eq $seedSha) ([ordered]@{
        before = @($f1.backupsBefore); after = @($f1.backupsAfter); bakSha256 = $bakSha1; seedSha256 = $seedSha })
    Add-Check 'M1:dados-preservados' ($same1 -and $personName -in @($f1.after.person_names)) ([ordered]@{
        seed = $seedCounts; after = $c1; persons = $f1.after.person_names; newPessoasColumns = @($f1.after.pessoas_columns | Where-Object { $_ -notin @($f1.before.pessoas_columns) }) })
    $tab = $f1.personsTab
    Add-Check 'M1:aba-pessoas' ($tab.found -and $tab.personsEnabled -and $personName -in @($tab.tableNames) -and $tab.rows -eq $seedCounts.pessoas) $tab
  }
  if ($f2 -and $f2.after) {
    $c2 = Get-Counts $f2.after
    Add-Check 'M2:nao-migra-de-novo' ($f2.read.ok -and $f2.before.schema_version -eq $f1.after.schema_version -and $f2.after.schema_version -eq $f1.after.schema_version -and
      (@($f2.backupsAfter) -join ',') -eq (@($f1.backupsAfter) -join ',') -and $bakSha2 -eq $bakSha1 -and
      $c2.lotes -eq $c1.lotes -and $c2.pessoas -eq $c1.pessoas -and $c2.lote_pessoa -eq $c1.lote_pessoa) ([ordered]@{
        before = $f2.before.schema_version; after = $f2.after.schema_version; backups = @($f2.backupsAfter); bakSha256 = $bakSha2
        gpkgSha256AfterFirst = $gpkgSha1; counts = $c2; personsTab = $f2.personsTab })
  }
  $m = $f1.plugin
  Add-Check 'T4:gerenciador' ($m.active -and $m.version -eq $lock.version -and $m.author -eq 'Instituto IMAN' -and $m.manager.version_installed -eq $lock.version -and $m.manager.author_name -eq 'Instituto IMAN') $m
}

$restored = Restore-ProductData $productData
if ($restored) { Add-Check 'dados-do-produto' $restored.ok $restored }
$guard = & $pwshExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-OfficialQgisUntouched.ps1') -WorkRoot $WorkRoot 2>&1 | Out-String
Add-Check 'guard' ($LASTEXITCODE -eq 0) ($guard.Trim() -split "`r?`n" | Select-Object -Last 1)
$result.ok = @($result.checks.Values | Where-Object { -not $_.ok }).Count -eq 0
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step "migracao $Phase $Target/$ProfileState $(if ($result.ok) { 'OK' } else { 'FALHOU' }): $run"
if (-not $result.ok) { exit 1 }
