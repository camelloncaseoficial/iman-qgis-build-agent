<#
.SYNOPSIS
  Plugin IMAN REURB embarcado (fatia 051, T2): a pasta embarcada e a do commit da trava, arquivo a arquivo, e a
  exportacao falha alto quando a trava, a tag ou o clone nao batem (visto falhando).

.DESCRIPTION
  1. T2: git archive de path_in_repo no commit da trava (iman/plugin/plugin.lock.json), com core.autocrlf=false,
     extraido numa pasta nova; cada arquivo extraido tem o id de blob (git hash-object --no-filters) do ls-tree do
     commit (o archive e o commit, byte a byte); depois o SHA-256 de cada arquivo de <Root>\python\plugins\<id>
     contra o do archive. Arquivo a mais ou a menos reprova, salvo __pycache__ (o Python grava ao carregar o plugin:
     relatado, nao reprova).
     -Root: a pasta apps\qgis-ltr a medir (padrao: a instalacao do build, $WorkRoot\install\apps\qgis-ltr; a arvore
     do instalador e $WorkRoot\stage\tree\apps\qgis-ltr; a instalada, %LOCALAPPDATA%\Programs\IMAN Terra\apps\qgis-ltr).
  2. -SeenFailing: Export-ImanPlugin numa pasta descartavel, com a trava ou o clone trocados, tem de parar com a
     mensagem de cada caso: clone ausente, tag ausente, tag em outro commit que nao o da trava, LICENSE ausente (tag
     num commit de antes do LICENSE, num clone --shared descartavel), version do metadata.txt diferente da trava.
     Nada e escrito no clone do plugin: as tags dos casos vivem no clone descartavel.
  3. -SeenFailingBuild: o Build-Qgis.ps1 inteiro com -PluginRepo apontando para um clone descartavel em que a tag da
     trava aponta para outro commit: o build tem de parar com a mensagem do item 2 do briefing. Depois, rode o
     Build-Qgis.ps1 normal de novo (o install fica sem a pasta do plugin refeita).
  Saida em $WorkRoot\verify\plugin-embed-<data>\result.json. Sai com 1 se algo falhar.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [string] $Root,
  [string] $PluginRepo,
  [switch] $SeenFailing,
  [switch] $SeenFailingBuild
)
. "$PSScriptRoot\Common.ps1"
if (-not $Root) { $Root = Join-Path $Paths.Install 'apps\qgis-ltr' }
$lock = Get-PluginLock
$run = Join-Path $WorkRoot ("verify\plugin-embed-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $run | Out-Null
$result = [ordered]@{ run = $run; root = $Root; pluginRepo = $PluginRepo
  lock = [ordered]@{ id = $lock.id; version = $lock.version; tag = $lock.tag; commit = $lock.commit }; checks = [ordered]@{} }
function Add-Check([string] $id, [bool] $ok, $detail) {
  $result.checks[$id] = [ordered]@{ ok = $ok; detail = $detail }
  Write-Step ("{0,-30} {1}  {2}" -f $id, $(if ($ok) { 'OK' } else { 'FALHOU' }), ($detail | ConvertTo-Json -Compress -Depth 4))
}
function Get-RelFiles([string] $dir) {
  @(Get-ChildItem $dir -Recurse -File -Force | ForEach-Object { $_.FullName.Substring($dir.Length + 1) -replace '\\', '/' } | Sort-Object)
}

# 1. T2
$ref = Join-Path $run 'archive'
New-Item -ItemType Directory -Force $ref | Out-Null
$tar = Join-Path $run 'archive.tar'
& $GitExe -C $PluginRepo -c core.autocrlf=false archive --format=tar -o $tar "$($lock.commit):$($lock.path_in_repo)"
if ($LASTEXITCODE) { throw "git archive falhou em $PluginRepo" }
& $TarExe -xf $tar -C $ref
if ($LASTEXITCODE) { throw 'tar falhou' }
$refFiles = Get-RelFiles $ref
# o archive e o commit: id de blob de cada arquivo extraido igual ao do ls-tree
$tree = @{}
& $GitExe -C $PluginRepo ls-tree -r "$($lock.commit):$($lock.path_in_repo)" | ForEach-Object {
  if ($_ -match '^\d+ blob ([0-9a-f]{40})\t(.+)$') { $tree[$Matches[2]] = $Matches[1] }
}
$blobIds = @($refFiles | ForEach-Object { Join-Path $ref $_ } | & $GitExe hash-object --no-filters --stdin-paths)
$blobDiff = @(for ($i = 0; $i -lt $refFiles.Count; $i++) { if ($tree[$refFiles[$i]] -ne $blobIds[$i]) { $refFiles[$i] } })
Add-Check 'T2:archive-e-o-commit' ($refFiles.Count -gt 0 -and $refFiles.Count -eq $tree.Count -and $blobDiff.Count -eq 0) ([ordered]@{
    commit = $lock.commit; files = $refFiles.Count; lsTree = $tree.Count; blobMismatch = $blobDiff })

$dir = Join-Path $Root "python\plugins\$($lock.id)"
$have = if (Test-Path $dir) { Get-RelFiles $dir } else { @() }
$pycache = @($have | Where-Object { $_ -match '(^|/)__pycache__/' })
$haveCode = @($have | Where-Object { $_ -notmatch '(^|/)__pycache__/' })
$missing = @($refFiles | Where-Object { $_ -notin $haveCode })
$extra = @($haveCode | Where-Object { $_ -notin $refFiles })
$shaDiff = @($refFiles | Where-Object { $_ -in $haveCode } | Where-Object {
    (Get-FileHash -Algorithm SHA256 (Join-Path $ref $_)).Hash -ne (Get-FileHash -Algorithm SHA256 (Join-Path $dir $_)).Hash })
$listing = @($haveCode | ForEach-Object { '{0}  {1}' -f (Get-FileHash -Algorithm SHA256 (Join-Path $dir $_)).Hash.ToLowerInvariant(), $_ })
$listing | Set-Content -Encoding utf8 (Join-Path $run 'sha256-embarcado.txt')
Add-Check 'T2:pasta-embarcada' ((Test-Path $dir) -and $missing.Count -eq 0 -and $extra.Count -eq 0 -and $shaDiff.Count -eq 0) ([ordered]@{
    dir = $dir; files = $haveCode.Count; sha256Equal = ($haveCode.Count - $shaDiff.Count - $extra.Count); missing = $missing; extra = $extra
    shaDiff = $shaDiff; pycacheReported = $pycache.Count; license = (Test-Path (Join-Path $dir 'LICENSE')) })

# 2. visto falhando na funcao de exportacao
function New-CaseLock([string] $path, [hashtable] $over) {
  $o = [ordered]@{}; foreach ($p in $lock.PSObject.Properties) { $o[$p.Name] = $p.Value }
  foreach ($k in $over.Keys) { $o[$k] = $over[$k] }
  $o | ConvertTo-Json | Set-Content -Encoding utf8 $path
  $path
}
function Invoke-Case([string] $id, [string] $lockPath, [string] $repo, [string] $want) {
  $dest = Join-Path $run "case-$id"
  New-Item -ItemType Directory -Force $dest | Out-Null
  $msg = $null
  try { Export-ImanPlugin $dest $lockPath $repo | Out-Null } catch { $msg = $_.Exception.Message }
  $leftover = @(Get-ChildItem $dest -Force).Count
  Add-Check "falha:$id" ($msg -and $msg -match $want -and $leftover -eq 0) ([ordered]@{ message = $msg; expected = $want; filesLeftInDest = $leftover })
}
$scratch = $null
if ($SeenFailing -or $SeenFailingBuild) {
  # clone descartavel (objetos compartilhados, so leitura do clone do plugin) para as tags dos casos
  $scratch = Join-Path $run 'clone'
  & $GitExe clone --quiet --no-checkout --shared $PluginRepo $scratch
  if ($LASTEXITCODE) { throw 'clone descartavel falhou' }
  $parent = (& $GitExe -C $scratch rev-parse "$($lock.commit)^1").Trim()
}
if ($SeenFailing) {
  Invoke-Case 'clone-ausente' $PluginLockFile (Join-Path $run 'nao-existe') 'clone do plugin ausente'
  Invoke-Case 'tag-ausente' (New-CaseLock (Join-Path $run 'lock-tag.json') @{ tag = 'v0.0.0-iman-inexistente' }) $PluginRepo 'nao existe no clone'
  Invoke-Case 'trava-em-outro-commit' (New-CaseLock (Join-Path $run 'lock-commit.json') @{ commit = $parent }) $PluginRepo 'aponta para'
  $added = (& $GitExe -C $scratch log --format=%H --diff-filter=A -- "$($lock.path_in_repo)/LICENSE" | Select-Object -Last 1).Trim()
  $before = (& $GitExe -C $scratch rev-parse "$added^1").Trim()
  & $GitExe -C $scratch tag iman-caso-sem-licenca $before
  Invoke-Case 'licenca-ausente' (New-CaseLock (Join-Path $run 'lock-license.json') @{ tag = 'iman-caso-sem-licenca'; commit = $before }) $scratch 'falta o LICENSE'
  Invoke-Case 'versao-diferente' (New-CaseLock (Join-Path $run 'lock-version.json') @{ version = '9.9.9' }) $PluginRepo 'metadata.txt'
}

# 3. visto falhando no build inteiro: a tag da trava, no clone descartavel, aponta para outro commit
if ($SeenFailingBuild) {
  & $GitExe -C $scratch tag -f $lock.tag $parent | Out-Null
  $log = Join-Path $run 'build-seen-failing.log'
  & (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $PSScriptRoot 'Build-Qgis.ps1') -WorkRoot $WorkRoot -PluginRepo $scratch *>&1 | Tee-Object -FilePath $log | Out-Null
  $exit = $LASTEXITCODE
  $hit = Select-String -Path $log -Pattern 'PLUGIN: a tag \S+ aponta para [0-9a-f]{40}' | Select-Object -First 1
  Add-Check 'falha:build-tag-em-outro-commit' ($exit -ne 0 -and $hit) ([ordered]@{ exit = $exit; message = $(if ($hit) { $hit.Line.Trim() }); log = $log })
}

$result.ok = @($result.checks.Values | Where-Object { -not $_.ok }).Count -eq 0
$result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $run 'result.json')
Write-Step "plugin embarcado $(if ($result.ok) { 'OK' } else { 'FALHOU' }): $run"
if (-not $result.ok) { exit 1 }
