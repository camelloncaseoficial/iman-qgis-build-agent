<#
.SYNOPSIS
  Gera iman/build/osgeo4w.lock.tsv: o conjunto de pacotes OSGeo4W fixado para compilar o QGIS 3.44.13.

.DESCRIPTION
  Roda uma vez, quando a base muda; o lock gerado e versionado e o build so le o lock.

  Regras de escolha de versao, nesta ordem:
    1. "official": a versao instalada no QGIS 3.44.13 oficial (etc/setup/installed.db do instalador oficial).
    2. "dated":    o tarball mais novo publicado no servidor ate o instante do pacote qgis-ltr oficial
                   (o que o build oficial tinha a mao quando compilou).
  Raizes: BUILDDEPENDS e requires de qgis-ltr-common da receita qgis-ltr do jef-n/OSGeo4W num commit fixo e, desde
  a fatia 047, todo pacote do installed.db oficial menos os qgis-ltr* (que o nosso build substitui), fechadas pelos
  "requires:" do setup.ini.
  Coluna Runtime: "official" para o pacote que esta no installed.db oficial (entra na arvore instalada do produto,
  menos os excluidos com motivo no $RuntimeExcluded do New-RuntimeTree.ps1, desde o patch de 2026-10-29 da 047),
  "build-only" para o que so serve para compilar (os -devel e os dated; nao entram, decisao 3 do D-IMAN-043).
  Sha256 ja gravado no lock anterior para o mesmo arquivo e mantido (o Get-Osgeo4wPackages.ps1 confere).

  Uso (rede, so leitura fora do diretorio de cache):
    pwsh -File iman/build/Resolve-Osgeo4wLock.ps1 -CacheRoot D:\iman-terra-build\cache
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $CacheRoot,
  [string] $OfficialInstalledDb = 'C:\Program Files\QGIS 3.44.13\etc\setup\installed.db',
  [string] $Mirror = 'https://download.osgeo.org/osgeo4w/v2',
  [string] $RecipeCommit = 'b17db5511a9a77b7a192e61b2460bf4c5890b305',
  [string] $OfficialPackage = 'qgis-ltr-3.44.13-1.tar.bz2',
  [string] $OutFile = (Join-Path $PSScriptRoot 'osgeo4w.lock.tsv'),
  # -Latest: ignora o installed.db oficial e o corte por data; pega a versao curr do setup.ini de hoje
  # (estado "o OSGeo4W andou" da matriz do briefing 043). Gera um lock para comparacao, nao o de build.
  [switch] $Latest
)
. "$PSScriptRoot\Common.ps1"

$meta = Join-Path $CacheRoot 'meta'
New-Item -ItemType Directory -Force $meta | Out-Null

# setup.ini atual: so serve para o mapa nome -> diretorio e para os requires
$iniBz2 = Join-Path $meta 'setup.ini.bz2'
Invoke-WebRequest "$Mirror/x86_64/setup.ini.bz2" -OutFile $iniBz2
$ini = Join-Path $meta 'setup.ini'
& tar.exe -xOjf $iniBz2 2>$null | Set-Content -Encoding utf8 $ini
if (-not (Test-Path $ini) -or (Get-Item $ini).Length -lt 1000) {
  # tar.exe do Windows nao le .bz2 solto; usa o python do sistema so para descompactar
  & python -I -c "import bz2,sys;open(sys.argv[2],'wb').write(bz2.decompress(open(sys.argv[1],'rb').read()))" $iniBz2 $ini
}

$dirs = @{}; $requires = @{}; $currFile = @{}
$cur = $null; $inMain = $false
foreach ($l in Get-Content $ini) {
  if ($l.StartsWith('@ ')) { $cur = $l.Substring(2).Trim(); $inMain = $true; continue }
  if (-not $cur) { continue }
  if ($l -match '^\[(prev|test)\]') { $inMain = $false; continue }
  if ($inMain -and $l -match '^requires:\s*(.*)$') { $requires[$cur] = @($Matches[1].Trim() -split '\s+' | Where-Object { $_ }) }
  if ($inMain -and $l -match '^install:\s*(\S+)' -and -not $dirs.ContainsKey($cur)) {
    $dirs[$cur] = $Matches[1].Substring(0, $Matches[1].LastIndexOf('/'))
    $currFile[$cur] = $Matches[1].Substring($Matches[1].LastIndexOf('/') + 1)
  }
}

# receita fixada
$recipe = (Invoke-WebRequest "https://raw.githubusercontent.com/jef-n/OSGeo4W/$RecipeCommit/src/qgis-ltr/osgeo4w/package.sh").Content
$buildDeps = ([regex]::Match($recipe, 'export BUILDDEPENDS="([^"]+)"').Groups[1].Value -split '\s+') | Where-Object { $_ }
$commonReq = ([regex]::Match($recipe, '(?s)\$P-common/setup\.hint.*?requires: ([^\r\n]+)').Groups[1].Value -split '\s+') |
  Where-Object { $_ -and $_ -notmatch '^\$' }

# instante do pacote oficial
$offUrl = "$Mirror/x86_64/release/qgis/qgis-ltr/$OfficialPackage"
$cutoff = [datetime]::Parse((Invoke-WebRequest $offUrl -Method Head).Headers['Last-Modified'][0]).ToUniversalTime()
if ($Latest) { $cutoff = [datetime]::UtcNow }

$official = @{}
foreach ($l in (Get-Content $OfficialInstalledDb | Select-Object -Skip 1)) {
  $n, $f, $null = $l -split '\s+'
  $official[$n] = $f
}
# o conjunto de runtime do oficial, sem os pacotes do proprio QGIS (o nosso build entra no lugar deles)
$officialRuntime = @($official.Keys | Where-Object { $_ -notmatch '^qgis-ltr($|-)' })

$previousSha = @{}
if (Test-Path $OutFile) {
  Get-Content $OutFile | Where-Object { -not $_.StartsWith('#') } | ConvertFrom-Csv -Delimiter "`t" |
    Where-Object Sha256 | ForEach-Object { $previousSha[$_.File] = $_.Sha256 }
}

# fecho pelos requires
$queue = [System.Collections.Generic.Queue[string]]::new()
$roots = @($buildDeps) + @($commonReq) + $(if ($Latest) { @() } else { $officialRuntime }) | Sort-Object -Unique
$roots | ForEach-Object { $queue.Enqueue($_) }
$seen = @{}
while ($queue.Count) {
  $p = $queue.Dequeue()
  if ($seen.ContainsKey($p)) { continue }
  $seen[$p] = $true
  foreach ($r in @($requires[$p])) { if ($r -and -not $seen.ContainsKey($r)) { $queue.Enqueue($r) } }
}

$months = @{Jan=1;Feb=2;Mar=3;Apr=4;May=5;Jun=6;Jul=7;Aug=8;Sep=9;Oct=10;Nov=11;Dec=12}
$listingCache = @{}
function Get-Listing([string] $dir) {
  if (-not $listingCache.ContainsKey($dir)) {
    $html = (Invoke-WebRequest "$Mirror/$dir/").Content
    $rows = foreach ($m in [regex]::Matches($html, '<a href="([^"/]+\.tar\.bz2)"[^>]*>[^<]*</a></td><td class="size">([^<]*)</td><td class="date">(\d{4})-(\w{3})-(\d{2}) (\d{2}):(\d{2})</td>')) {
      [pscustomobject]@{
        File = $m.Groups[1].Value
        Date = [datetime]::new([int]$m.Groups[3].Value, $months[$m.Groups[4].Value], [int]$m.Groups[5].Value, [int]$m.Groups[6].Value, [int]$m.Groups[7].Value, 0, [DateTimeKind]::Utc)
      }
    }
    $listingCache[$dir] = @($rows)
  }
  $listingCache[$dir]
}

$out = foreach ($p in ($seen.Keys | Sort-Object)) {
  if (-not $dirs.ContainsKey($p)) {
    [pscustomobject]@{ Package = $p; File = ''; Rule = 'missing-from-index'; Url = ''; Size = ''; Sha256 = ''; DatedPick = ''; Runtime = '' }
    continue
  }
  $dir = $dirs[$p]
  $esc = [regex]::Escape($p)
  $cands = Get-Listing $dir | Where-Object { $_.File -match "^$esc-\d[^/]*\.tar\.bz2$" -and $_.File -notmatch '-src\.tar\.bz2$' }
  $dated = $cands | Where-Object { $_.Date -le $cutoff } | Sort-Object Date | Select-Object -Last 1
  if ($Latest) { $file = $currFile[$p]; $rule = 'latest' }
  elseif ($official.ContainsKey($p)) { $file = $official[$p]; $rule = 'official' }
  elseif ($dated) { $file = $dated.File; $rule = 'dated' }
  else { $file = ''; $rule = 'none-before-cutoff' }
  $size = ''
  if ($file) {
    try { $size = (Invoke-WebRequest "$Mirror/$dir/$file" -Method Head).Headers['Content-Length'][0] }
    catch { $rule = "$rule-not-on-server" }
  }
  [pscustomobject]@{ Package = $p; File = $file; Rule = $rule; Url = "$dir/$file"; Size = $size
    Sha256 = $(if ($file -and $previousSha.ContainsKey($file)) { $previousSha[$file] } else { '' })
    DatedPick = $(if ($dated) { $dated.File } else { '' })
    Runtime = $(if ($official.ContainsKey($p) -and $p -notmatch '^qgis-ltr($|-)') { 'official' } else { 'build-only' }) }
}

$header = @(
  "# osgeo4w.lock.tsv gerado por Resolve-Osgeo4wLock.ps1 em $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))",
  "# mirror=$Mirror recipe=jef-n/OSGeo4W@$RecipeCommit cutoff=$($cutoff.ToString('yyyy-MM-ddTHH:mm:ssZ')) ($OfficialPackage)",
  "# Sha256 e preenchido por Get-Osgeo4wPackages.ps1 no primeiro download e conferido nos seguintes.",
  "# Runtime=official: pacote do installed.db oficial, entra na arvore instalada; build-only: so para compilar."
)
Write-LfFile $OutFile ($header + ($out | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation -UseQuotes Never))
$out | Group-Object Rule | Select-Object Name, Count | Format-Table -AutoSize
Write-Host "cutoff: $cutoff  roots: $($roots.Count)  closure: $($seen.Count)  -> $OutFile"
