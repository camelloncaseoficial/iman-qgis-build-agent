<#
.SYNOPSIS
  Monta a arvore de runtime do produto (o que o instalador copia para {app}): o conjunto de pacotes OSGeo4W do QGIS
  3.44.13 oficial fixado no lock (Runtime=official), com o nosso build no lugar dos pacotes qgis-ltr*, o lancador e
  o postinstall. Fatia 047 (D-IMAN-043, decisao 3).

.DESCRIPTION
  Saida em $WorkRoot\stage\tree, refeita do zero a cada rodada, com o layout da instalacao oficial
  (C:\Program Files\QGIS 3.44.13: bin, apps, etc, share...):
    - cada pacote Runtime=official do lock, extraido do cache e conferido pelo sha256 do lock. Os
      etc\postinstall\*.bat NAO rodam aqui: rodam na maquina do usuario, na pasta instalada (iman\postinstall.cmd),
      como no osgeo4w-setup e no MSI oficial, porque gravam o caminho da instalacao;
    - etc\setup\installed.db e um <pacote>.lst.gz por pacote (a lista de arquivos), o manifesto que o
      Test-RuntimeSet.ps1 compara com o do oficial; o nosso build entra como o pacote iman-terra;
    - apps\qgis-ltr: o cmake --install de $WorkRoot\install com o que os pacotes qgis-ltr* do oficial tem, sem o
      que eles nao tem (medido na fatia 047 contra os .lst.gz do oficial):
        fora: include, lib e FindQGIS.cmake (o -devel), o servidor (o oficial o publica em qgis-ltr-server, fora do
              conjunto), os .pyc (o postinstall do oficial os apaga) e o bin\qgis.exe (vira bin\iman-terra.exe);
        dentro: os plugins Qt que o cmake --install grava no Qt da raiz de build (sqldrivers e designer, tirados de
              $WorkRoot\build\output) e o widget-plugin do PyQt (python/custom_widgets do fonte), nos lugares do
              pacote oficial;
    - bin\iman-terra.exe (o qgis.exe, decisao 11), bin\iman-terra.vars, bin\iman-terra-env.bat,
      bin\qgis_process-iman-terra.bat e iman\postinstall.cmd, de iman/installer/runtime;
    - iman\icons: os icones de tipo de arquivo derivados (iman/brand/derived).
  O VC++ que o cmake --install poe em apps\qgis-ltr\bin (o do compilador) fica, ao lado do qgis_process.exe; o do
  bin\ e o do pacote msvcrt2019 do conjunto oficial, ao lado do iman-terra.exe (decisao 9).
  Resumo em $WorkRoot\stage\tree-summary.json.
#>
[CmdletBinding()]
param([string] $WorkRoot)
. "$PSScriptRoot\..\build\Common.ps1"
$t0 = Get-Date

$tree = Join-Path $WorkRoot 'stage\tree'
$inst = Join-Path $Paths.Install 'apps\qgis-ltr'
$runtimeSrc = Join-Path $PSScriptRoot 'runtime'
$brand = Get-Content (Join-Path $RepoRoot 'iman\brand\brand.json') -Raw -Encoding utf8 | ConvertFrom-Json
if (-not (Test-Path "$inst\bin\qgis.exe")) { throw "build ausente em $inst; rode Build-Qgis.ps1" }
if ($brand.product_name -notmatch '^[\x20-\x7e]+$') { throw 'o nome do produto vai para um .bat: tem de ser ASCII' }

if (Test-Path $tree) { Write-Step "removendo $tree"; Remove-Item -Recurse -Force $tree }
$setup = Join-Path $tree 'etc\setup'
New-Item -ItemType Directory -Force $setup | Out-Null

function Write-GzLines([string] $path, [string[]] $lines) {
  $fs = [IO.File]::Create($path)
  $gz = [IO.Compression.GZipStream]::new($fs, [IO.Compression.CompressionLevel]::Optimal)
  $bytes = [Text.Encoding]::UTF8.GetBytes((($lines -join "`n") + "`n"))
  $gz.Write($bytes, 0, $bytes.Length); $gz.Dispose(); $fs.Dispose()
}

# 1. pacotes do conjunto oficial
$rows = @(Get-Content $LockFile | Where-Object { -not $_.StartsWith('#') } | ConvertFrom-Csv -Delimiter "`t" | Where-Object Runtime -eq 'official')
if (-not $rows) { throw 'lock sem pacote Runtime=official' }
$devel = @($rows | Where-Object { $_.Package -match '-devel$' })
if ($devel) { throw "pacote -devel marcado como runtime: $($devel.Package -join ', ')" }
$db = [System.Collections.Generic.List[string]]::new(); $db.Add('INSTALLED.DB 2')
foreach ($r in $rows) {
  $tar = Join-Path $Paths.Packages ($r.Url -replace '/', '\')
  if (-not (Test-Path $tar)) { throw "ausente do cache: $($r.Url); rode Get-Osgeo4wPackages.ps1" }
  $h = (Get-FileHash -Algorithm SHA256 $tar).Hash.ToLowerInvariant()
  if ($h -ne $r.Sha256) { throw "sha256 divergente em $($r.File): lock $($r.Sha256), cache $h" }
  $out = & $TarExe -xvjf $tar -C $tree 2>&1
  if ($LASTEXITCODE) { throw "tar falhou em $($r.File): $out" }
  Write-GzLines (Join-Path $setup "$($r.Package).lst.gz") @($out | ForEach-Object { "$_" -replace '^x ', '' } | Where-Object { $_ })
  $db.Add("$($r.Package) $($r.File) 0")
}
Write-Step "$($rows.Count) pacotes do conjunto oficial extraidos em $tree"

# 2. o nosso build no lugar dos qgis-ltr*
$dst = Join-Path $tree 'apps\qgis-ltr'
$xd = @('include', 'lib', 'server', 'python\qgis\server', 'resources\server') | ForEach-Object { Join-Path $inst $_ }
$xf = @('FindQGIS.cmake', 'bin\qgis.exe', 'bin\qgis_mapserv.fcgi.exe', 'bin\qgis_mapserver.exe', 'bin\qgis_server.dll',
  'python\qgis\_server.pyd', 'python\qgis\_server.pyi') | ForEach-Object { Join-Path $inst $_ }
& robocopy.exe $inst $dst /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 /XD @xd /XF @xf '*.pyc' | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy falhou ($LASTEXITCODE) de $inst" }
$extra = [ordered]@{
  'qtplugins\sqldrivers\qsqlspatialite.dll' = Join-Path $Paths.Build 'output\plugins\sqldrivers\qsqlspatialite.dll'
  'qtplugins\sqldrivers\qsqlocispatial.dll' = Join-Path $Paths.Build 'output\plugins\sqldrivers\qsqlocispatial.dll'
  'qtplugins\designer\qgis_customwidgets.dll' = Join-Path $Paths.Build 'output\bin\qgis_customwidgets.dll'
  'python\PyQt5\uic\widget-plugins\qgis_customwidgets.py' = Join-Path $RepoRoot 'python\custom_widgets\qgis_customwidgets.py'
}
foreach ($k in $extra.Keys) {
  if (-not (Test-Path $extra[$k])) { throw "ausente: $($extra[$k])" }
  New-Item -ItemType Directory -Force (Split-Path (Join-Path $dst $k)) | Out-Null
  Copy-Item $extra[$k] (Join-Path $dst $k)
}

# 3. lancador, postinstall e icones
Copy-Item "$inst\bin\qgis.exe" (Join-Path $tree 'bin\iman-terra.exe')
Copy-Item "$runtimeSrc\bin\iman-terra.vars", "$runtimeSrc\bin\qgis_process-iman-terra.bat" (Join-Path $tree 'bin')
$envBat = [IO.File]::ReadAllText("$runtimeSrc\bin\iman-terra-env.bat").Replace('@IMAN_PRODUCT_NAME@', $brand.product_name)
[IO.File]::WriteAllText((Join-Path $tree 'bin\iman-terra-env.bat'), $envBat, [Text.Encoding]::ASCII)
New-Item -ItemType Directory -Force (Join-Path $tree 'iman\icons') | Out-Null
Copy-Item "$runtimeSrc\iman\postinstall.cmd" (Join-Path $tree 'iman')
Copy-Item (Join-Path $RepoRoot 'iman\brand\derived\iman-terra-q*.ico') (Join-Path $tree 'iman\icons')

# 4. manifesto do nosso pacote
$ours = @(
  @(Get-ChildItem $dst -Recurse -File) +
  @(Get-ChildItem (Join-Path $tree 'bin') -File | Where-Object Name -match '^(iman-terra|qgis_process-iman-terra)') +
  @(Get-ChildItem (Join-Path $tree 'iman') -Recurse -File)
) | ForEach-Object { $_.FullName.Substring($tree.Length + 1) -replace '\\', '/' } | Sort-Object
Write-GzLines (Join-Path $setup 'iman-terra.lst.gz') $ours
$commit = (& git -C $RepoRoot rev-parse --short=10 HEAD).Trim()
$db.Add("iman-terra iman-terra-$($brand.product_version)-$commit 0")
[IO.File]::WriteAllLines((Join-Path $setup 'installed.db'), $db, [Text.Encoding]::ASCII)

$files = @(Get-ChildItem $tree -Recurse -File -Force)
$summary = [ordered]@{
  tree = $tree; seconds = [int]((Get-Date) - $t0).TotalSeconds
  packages = $rows.Count; ourFiles = $ours.Count
  files = $files.Count; bytes = ($files | Measure-Object Length -Sum).Sum
  commit = $commit
}
$summary | ConvertTo-Json | Set-Content (Join-Path $WorkRoot 'stage\tree-summary.json')
Write-Step ("arvore pronta: {0} pacotes + iman-terra, {1} arquivos, {2:N2} GB, {3} s" -f $rows.Count, $files.Count, ($summary.bytes / 1GB), $summary.seconds)
