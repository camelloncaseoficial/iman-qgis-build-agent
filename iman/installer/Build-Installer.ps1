<#
.SYNOPSIS
  Compila o instalador do IMAN Terra (iman-terra.iss, Inno Setup 7) a partir da arvore commitada e do build dela,
  e grava ao lado do .exe o BUILD_INFO.txt (commit, versao, versao do compilador, SHA-256). Fatia 047.

.DESCRIPTION
  Recusa (exit 3) arvore com mudanca nao commitada e build que nao saiu do HEAD: o qgsversion.h do build tem de ser
  o commit atual (BL-6: o binario sai de um commit publico, identificado no pacote).
  Passos:
    1. New-RuntimeTree.ps1 monta $WorkRoot\stage\tree (-ReuseTree reaproveita se ela e do mesmo commit);
    2. iman\BUILD_INFO.txt dentro da arvore; os notices em $WorkRoot\stage\notices (o SOURCE_CODE.md com o commit);
    3. as listas de pastas da arvore para o [InstallDelete] e o [UninstallDelete];
    4. ISCC com os #define da fonte unica (brand.json) e do build; tempo e log em $WorkRoot\logs;
    5. $WorkRoot\dist\<versao>-<commit>\: o instalador e o BUILD_INFO.txt com o SHA-256 dele.
  Saida: 2 ambiente, 3 integridade, 4 compilador.
#>
[CmdletBinding()]
param([string] $WorkRoot, [switch] $ReuseTree, [string] $IsccPath)
. "$PSScriptRoot\..\build\Common.ps1"
$ErrorActionPreference = 'Stop'
$t0 = Get-Date

function Stop-Build([int] $code, [string] $msg) { Write-Host "INSTALADOR RECUSADO: $msg"; exit $code }

$dirty = & git -C $RepoRoot status --porcelain --untracked-files=all
if ($dirty) { Stop-Build 3 "arvore com mudanca nao commitada:`n$($dirty -join "`n")" }
$head = (& git -C $RepoRoot rev-parse HEAD).Trim()
$short = $head.Substring(0, 10)
$branch = (& git -C $RepoRoot rev-parse --abbrev-ref HEAD).Trim()
$qgsversion = Join-Path $Paths.Build 'qgsversion.h'
$rev = if ((Test-Path $qgsversion) -and ((Get-Content $qgsversion -Raw) -match 'QGSVERSION "([0-9a-f]+)"')) { $Matches[1] } else { '' }
if (-not $rev -or -not $head.StartsWith($rev)) { Stop-Build 3 "o build ($rev) nao e do HEAD ($short): rode Build-Qgis.ps1 nesta arvore" }

$brand = Get-Content (Join-Path $RepoRoot 'iman\brand\brand.json') -Raw -Encoding utf8 | ConvertFrom-Json
$qgisVersion = if ((Get-Content (Join-Path $Paths.Build 'qgsconfig.h') -Raw) -match '#define VERSION "([^"]+)"') { $Matches[1] } else { Stop-Build 2 'VERSION ausente do qgsconfig.h' }
# AUMI do processo: QgsWinNative::initializeMainWindow -> WinToast::configureAUMI(organizacao, aplicacao, aplicacao, Qgis::version())
$aumi = '{0}.{1}.{1}.{2}' -f $brand.internal_organization_name, $brand.internal_application_name, $qgisVersion

if (-not $IsccPath) {
  $IsccPath = @("$env:ProgramFiles\Inno Setup 7\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 7\ISCC.exe") |
    Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $IsccPath -or -not (Test-Path $IsccPath)) { Stop-Build 2 'ISCC.exe do Inno Setup 7 nao encontrado (-IsccPath)' }
$isccVersion = (Get-Item (Join-Path (Split-Path $IsccPath) 'ISCmplr.dll')).VersionInfo.ProductVersion
if ($isccVersion -notmatch '^7\.') { Stop-Build 2 "o compilador e o Inno Setup $isccVersion; o D-IMAN-030 pede o 7" }

# 1. arvore
$stage = Join-Path $WorkRoot 'stage'
$tree = Join-Path $stage 'tree'
$treeSummary = Join-Path $stage 'tree-summary.json'
$reuse = $ReuseTree -and (Test-Path $treeSummary) -and ((Get-Content $treeSummary -Raw | ConvertFrom-Json).commit -eq $short)
if (-not $reuse) {
  & (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $PSScriptRoot 'New-RuntimeTree.ps1') -WorkRoot $WorkRoot
  if ($LASTEXITCODE) { Stop-Build 2 'New-RuntimeTree.ps1 falhou' }
}
$treeInfo = Get-Content $treeSummary -Raw | ConvertFrom-Json

# 2. identidade dentro da arvore e notices
$lockSha = (Get-FileHash -Algorithm SHA256 $LockFile).Hash.ToLowerInvariant()
$info = @(
  "Produto          : $($brand.product_name) $($brand.product_version)",
  "Commit           : $head",
  "Branch           : $branch",
  "Repositorio      : https://github.com/camelloncaseoficial/iman-qgis-build-agent",
  "Base do QGIS     : final-3_44_13",
  "QGIS             : $qgisVersion (code revision $rev)",
  "AUMI             : $aumi",
  "Lock OSGeo4W     : iman/build/osgeo4w.lock.tsv sha256 $lockSha",
  "Pacotes          : $($treeInfo.packages) do conjunto oficial + iman-terra",
  "Compilador       : Inno Setup $isccVersion ($IsccPath)",
  "Gerado em        : $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
)
New-Item -ItemType Directory -Force (Join-Path $tree 'iman') | Out-Null
[IO.File]::WriteAllLines((Join-Path $tree 'iman\BUILD_INFO.txt'), $info, [Text.UTF8Encoding]::new($false))
$notices = Join-Path $stage 'notices'
if (Test-Path $notices) { Remove-Item -Recurse -Force $notices }
New-Item -ItemType Directory -Force (Join-Path $notices 'licencas') | Out-Null
$src = Join-Path $RepoRoot 'iman\notices'
# o Inno le texto sem BOM como ANSI: a licenca e mostrada na tela, vai com BOM
$bom = [Text.UTF8Encoding]::new($true)
[IO.File]::WriteAllText((Join-Path $notices 'LICENSE'), [IO.File]::ReadAllText("$src\LICENSE"), $bom)
Copy-Item "$src\THIRD_PARTY_NOTICES.md" $notices
$sourceCode = [IO.File]::ReadAllText("$src\SOURCE_CODE.md").Replace('@IMAN_COMMIT@', $head).Replace('@IMAN_PRODUCT_VERSION@', $brand.product_version)
[IO.File]::WriteAllText((Join-Path $notices 'SOURCE_CODE.md'), $sourceCode, [Text.UTF8Encoding]::new($false))
Copy-Item "$src\licencas\*.txt" (Join-Path $notices 'licencas')
& (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $RepoRoot 'iman\notices\Update-Notices.ps1') -WorkRoot $WorkRoot -Tree $tree -Check
if ($LASTEXITCODE) { Stop-Build 3 'THIRD_PARTY_NOTICES.md nao corresponde a arvore: rode iman\notices\Update-Notices.ps1 e commite' }

# 3. pastas e arquivos de topo da arvore
$top = @(Get-ChildItem $tree -Force)
$installDel = @($top | ForEach-Object { if ($_.PSIsContainer) { "Type: filesandordirs; Name: ""{app}\$($_.Name)""" } else { "Type: files; Name: ""{app}\$($_.Name)""" } })
$incInstall = Join-Path $stage 'tree-installdelete.iss'
$incUninstall = Join-Path $stage 'tree-uninstalldelete.iss'
[IO.File]::WriteAllLines($incInstall, $installDel, $bom)
[IO.File]::WriteAllLines($incUninstall, $installDel, $bom)

# 4. ISCC
$dist = Join-Path $WorkRoot ("dist\{0}-{1}" -f $brand.product_version, $short)
if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
New-Item -ItemType Directory -Force $dist, $Paths.Logs | Out-Null
$base = "Instituto-IMAN-IMAN-Terra-Setup-$($brand.product_version)-$short"
$log = Join-Path $Paths.Logs ("iscc-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$defs = [ordered]@{
  ProductName = $brand.product_name; ProductVersion = $brand.product_version; Publisher = $brand.organization_name
  ProductUrl = $brand.product_url; QgisVersion = $qgisVersion; Commit = $short; Aumi = $aumi
  TreeDir = $tree; StageDir = $stage; RepoDir = $RepoRoot; OutputDir = $dist; OutputBase = $base
  TreeDirsInclude = $incInstall; TreeDirsUninstallInclude = $incUninstall
}
$isccArgs = @($defs.Keys | ForEach-Object { "/D$_=$($defs[$_])" }) + @((Join-Path $PSScriptRoot 'iman-terra.iss'))
Write-Step "ISCC $isccVersion -> $dist\$base.exe"
$t1 = Get-Date
& $IsccPath @isccArgs *>&1 | Out-File -Encoding utf8 $log
$isccExit = $LASTEXITCODE
$isccSeconds = [int]((Get-Date) - $t1).TotalSeconds
if ($isccExit) { Get-Content $log -Tail 20 | Write-Host; Stop-Build 4 "ISCC saiu com $isccExit (ver $log)" }

# 5. identidade ao lado do instalador
$exe = Get-Item (Join-Path $dist "$base.exe")
$exeSha = (Get-FileHash -Algorithm SHA256 $exe.FullName).Hash.ToLowerInvariant()
$outInfo = $info + @(
  "Instalador       : $($exe.Name)",
  "Tamanho          : $($exe.Length) bytes",
  "SHA-256          : $exeSha",
  "Arvore           : $($treeInfo.files) arquivos, $($treeInfo.bytes) bytes",
  "ISCC             : $isccSeconds s"
)
[IO.File]::WriteAllLines((Join-Path $dist 'BUILD_INFO.txt'), $outInfo, [Text.UTF8Encoding]::new($false))
Write-Step ("instalador pronto: {0} ({1:N0} MB, ISCC {2} s, total {3} s)" -f $exe.FullName, ($exe.Length / 1MB), $isccSeconds, [int]((Get-Date) - $t0).TotalSeconds)
