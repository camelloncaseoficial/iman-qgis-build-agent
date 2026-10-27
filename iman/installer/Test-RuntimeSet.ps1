<#
.SYNOPSIS
  A4 do briefing 047: o conjunto da arvore do produto, medido pelo manifesto, contra o do QGIS 3.44.13 oficial
  (so lido).

.DESCRIPTION
  -Root: a arvore a medir (padrao: a instalada, %LOCALAPPDATA%\Programs\IMAN Terra; para a montada pelo
  New-RuntimeTree.ps1, $WorkRoot\stage\tree).
    1. pacotes: etc\setup\installed.db da arvore, menos o pacote iman-terra (o nosso build), tem de ser igual ao do
       oficial menos os qgis-ltr*, nome e arquivo (versao); nenhum -devel;
    2. arquivos de cada pacote: a lista do <pacote>.lst.gz da arvore contra a do oficial (o oficial grava a saida
       verbosa do tar; compara-se so o caminho);
    3. o nosso build contra os pacotes qgis-ltr* do oficial: arquivos de apps\qgis-ltr que so um dos lados tem
       (relatado, nao reprova: e o que o laudo explica);
    4. tamanho da arvore e do oficial.
  Sai com 1 se 1 ou 2 divergirem. Saida em $WorkRoot\verify\runtime-set-<data>\ (result.json e as listas).
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [string] $Root = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13'
)
. "$PSScriptRoot\..\build\Common.ps1"

$out = Join-Path $WorkRoot ("verify\runtime-set-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $out | Out-Null

function Read-Db([string] $r) {
  $h = [ordered]@{}
  Get-Content (Join-Path $r 'etc\setup\installed.db') | Select-Object -Skip 1 | ForEach-Object {
    $n, $f, $null = $_ -split '\s+'; if ($n) { $h[$n] = $f }
  }
  $h
}
function Read-Gz([string] $path) {
  $fs = [IO.File]::OpenRead($path)
  $gz = [IO.Compression.GZipStream]::new($fs, [IO.Compression.CompressionMode]::Decompress)
  $text = [IO.StreamReader]::new($gz).ReadToEnd(); $gz.Dispose(); $fs.Dispose()
  @($text -split "`r?`n" | Where-Object { $_ })
}
# caminho de uma linha de lista: o oficial grava "-rw-r--r-- dono/grupo tamanho data hora caminho" (hardlink:
# "hrw-... caminho link to alvo")
function Get-ListPaths([string] $path) {
  Read-Gz $path | Where-Object { $_ -notmatch '^\S+\s+Creating directory:' } |
    ForEach-Object { ($_ -replace '^[-dhlrwxsStT]{10}\s+\S+\s+\d+\s+\S+\s+\S+\s+', '' -replace ' link to .*$', '').TrimEnd('/') } |
    Where-Object { $_ -and $_ -ne '.' } | Sort-Object -Unique
}

# diferenca de duas listas ("<= x" so na primeira, "=> x" so na segunda); aceita lista vazia
function Get-ListDiff([string[]] $a, [string[]] $b) {
  $sa = [Collections.Generic.HashSet[string]]::new([string[]]@($a | Where-Object { $_ }))
  $sb = [Collections.Generic.HashSet[string]]::new([string[]]@($b | Where-Object { $_ }))
  @($sa | Where-Object { -not $sb.Contains($_) } | Sort-Object | ForEach-Object { "<= $_" }) +
  @($sb | Where-Object { -not $sa.Contains($_) } | Sort-Object | ForEach-Object { "=> $_" })
}

$ours = Read-Db $Root
$official = Read-Db $OfficialRoot
$oursPk = [ordered]@{}; foreach ($k in $ours.Keys) { if ($k -ne 'iman-terra') { $oursPk[$k] = $ours[$k] } }
$offPk = [ordered]@{}; foreach ($k in $official.Keys) { if ($k -notmatch '^qgis-ltr($|-)') { $offPk[$k] = $official[$k] } }
$pkgDiff = @(Get-ListDiff @($oursPk.Keys | ForEach-Object { "$_ $($oursPk[$_])" }) @($offPk.Keys | ForEach-Object { "$_ $($offPk[$_])" }) |
  ForEach-Object { $_ -replace '^<= ', 'so-na-arvore ' -replace '^=> ', 'so-no-oficial ' })
$devel = @($ours.Keys | Where-Object { $_ -match '-devel$' })
$pkgDiff | Set-Content (Join-Path $out 'pacotes-diff.txt')

$fileDiffs = [ordered]@{}
foreach ($k in $oursPk.Keys) {
  $a = Join-Path $Root "etc\setup\$k.lst.gz"; $b = Join-Path $OfficialRoot "etc\setup\$k.lst.gz"
  if (-not (Test-Path $a) -or -not (Test-Path $b)) { $fileDiffs[$k] = @('lista ausente'); continue }
  $d = @(Get-ListDiff @(Get-ListPaths $a) @(Get-ListPaths $b))
  if ($d) { $fileDiffs[$k] = $d }
}

$offQgis = @($official.Keys | Where-Object { $_ -match '^qgis-ltr($|-)' } | ForEach-Object {
    $p = Join-Path $OfficialRoot "etc\setup\$_.lst.gz"; if (Test-Path $p) { Get-ListPaths $p } } |
  Where-Object { $_ -like 'apps/qgis-ltr/*' } | Sort-Object -Unique)
$app = Join-Path $Root 'apps\qgis-ltr'
$oursQgis = @(Get-ChildItem $app -Recurse -File | ForEach-Object { 'apps/qgis-ltr/' + ($_.FullName.Substring($app.Length + 1) -replace '\\', '/') } |
  Where-Object { $_ -notmatch '\.pyc$' } | Sort-Object)
$offFiles = @($offQgis | Where-Object { Test-Path -LiteralPath (Join-Path $OfficialRoot $_) -PathType Leaf })
$onlyOurs = @($oursQgis | Where-Object { $_ -notin $offFiles })
$onlyOfficial = @($offFiles | Where-Object { $_ -notin $oursQgis })
$onlyOurs | Set-Content (Join-Path $out 'qgis-ltr-so-no-nosso-build.txt')
$onlyOfficial | Set-Content (Join-Path $out 'qgis-ltr-so-no-oficial.txt')

function Get-TreeSize([string] $r) {
  $f = @(Get-ChildItem $r -Recurse -File -Force -ErrorAction SilentlyContinue)
  [ordered]@{ files = $f.Count; bytes = ($f | Measure-Object Length -Sum).Sum }
}

$ok = $pkgDiff.Count -eq 0 -and $devel.Count -eq 0 -and $fileDiffs.Count -eq 0
$result = [ordered]@{
  ok = $ok; root = $Root; official = $OfficialRoot
  packages = [ordered]@{ tree = $ours.Count; treeWithoutOurBuild = $oursPk.Count; official = $official.Count
    officialWithoutQgisLtr = $offPk.Count; ourBuildEntry = $ours['iman-terra']; differences = $pkgDiff; devel = $devel }
  filesPerPackage = [ordered]@{ compared = $oursPk.Count; withDifferences = $fileDiffs.Count; differences = $fileDiffs }
  ourBuildVsQgisLtr = [ordered]@{ ourFiles = $oursQgis.Count; officialFiles = $offFiles.Count
    onlyOurs = $onlyOurs; onlyOfficial = $onlyOfficial }
  size = [ordered]@{ tree = (Get-TreeSize $Root); official = (Get-TreeSize $OfficialRoot) }
}
$result | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $out 'result.json')
Write-Step ("pacotes: arvore {0} (sem o nosso build {1}), oficial {2} (sem qgis-ltr* {3}), diferencas {4}, -devel {5}" -f
  $ours.Count, $oursPk.Count, $official.Count, $offPk.Count, $pkgDiff.Count, $devel.Count)
Write-Step ("arquivos por pacote: {0} comparados, {1} com diferenca" -f $oursPk.Count, $fileDiffs.Count)
Write-Step ("nosso build x qgis-ltr*: {0} so nosso, {1} so do oficial" -f $onlyOurs.Count, $onlyOfficial.Count)
Write-Step ("tamanho: arvore {0:N2} GB ({1} arquivos), oficial {2:N2} GB ({3} arquivos)" -f ($result.size.tree.bytes / 1GB), $result.size.tree.files, ($result.size.official.bytes / 1GB), $result.size.official.files)
Write-Step "conjunto $(if ($ok) { 'OK' } else { 'FALHOU' }): $out"
if (-not $ok) { exit 1 }
