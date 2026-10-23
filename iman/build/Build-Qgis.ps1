<#
.SYNOPSIS
  Configura, compila e instala o QGIS deste repo (sem mudanca no fonte) contra a raiz OSGeo4W fixada.

.DESCRIPTION
  Flags de CMake: as de src/qgis-ltr/osgeo4w/package.sh do jef-n/OSGeo4W no commit fixado em
  Resolve-Osgeo4wLock.ps1, com tres diferencas declaradas:
    - sem CDash (BUILDNAME, SITE, SUBMIT_URL, PUSH_TO_CDASH): nao ha submissao de testes;
    - /D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR na linha de comando, no lugar da edicao dos cabecalhos <mutex>
      do MSVC que a receita faz (o runtime embarcado e o msvcp140 14.38, mais velho que o compilador 14.44);
    - CMAKE_INSTALL_PREFIX em $WorkRoot\install\apps\qgis-ltr (mesmo layout de apps\qgis-ltr do oficial).
  Retomada: sem -Clean, um build interrompido continua do ponto em que o ninja parou.
#>
[CmdletBinding()]
param([string] $WorkRoot, [switch] $Clean, [switch] $SkipInstall, [int] $Jobs = 0)
. "$PSScriptRoot\Common.ps1"

$o4w = $Paths.Osgeo4w
if (-not (Test-Path "$o4w\etc\setup\iman-lock.sha256")) { throw "raiz OSGeo4W ausente; rode Get-Osgeo4wPackages.ps1" }
New-Item -ItemType Directory -Force $Paths.Logs | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $Paths.Logs "build-$stamp.log"
$timings = [ordered]@{ started = (Get-Date).ToString('s') }

# git do sistema, resolvido antes do o4w_env (que troca o PATH): o CMake grava o commit em qgsversion.h
# ("QGIS code revision"), que identifica o commit publico do binario (BL-6)
$git = (Get-Command git.exe -ErrorAction Stop).Source

# ambiente: o4w_env, depois VS, depois ferramentas (mesma ordem da receita)
$envLines = & cmd.exe /c "`"$o4w\bin\o4w_env.bat`" >nul && set"
foreach ($l in $envLines) { if ($l -match '^([^=]+)=(.*)$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] } }
Remove-Item env:PYTHONPATH -ErrorAction SilentlyContinue
Import-VsEnvironment
Import-ToolsPath
$env:INCLUDE = "$o4w\apps\Qt5\include;$o4w\include;$env:INCLUDE"
$env:LIB = "$o4w\apps\Qt5\lib;$o4w\lib;$env:LIB"
$env:CMAKE_PREFIX_PATH = (@("$o4w\apps\Qt5\lib\cmake", "$o4w\share\cmake", "$o4w\lib\cmake", "$o4w\lib", "$o4w\cmake") |
  Where-Object { Test-Path $_ }) -join ';'

$grassBat = Get-ChildItem "$o4w\bin\grass*.bat" | Where-Object Name -match '^grass\d+\.bat$' | Select-Object -First 1
$grassPrefix = ((& cmd.exe /c "`"$($grassBat.FullName)`" --config path") | Select-Object -Last 1).Trim()
$pyHome = $env:PYTHONHOME
$pyLib = Join-Path $pyHome ("libs\{0}.lib" -f (Split-Path $pyHome -Leaf))
$sdkVer = $env:UCRTVersion.TrimEnd('\')
$msvc = Split-Path $env:VCToolsInstallDir -Leaf
Write-Step "MSVC $msvc, SDK $sdkVer, Python $pyHome, GRASS $grassPrefix"

$src = $RepoRoot
$bld = $Paths.Build
$inst = Join-Path $Paths.Install 'apps\qgis-ltr'
if ($Clean -and (Test-Path $bld)) { Write-Step "limpando $bld"; Remove-Item -Recurse -Force $bld }
New-Item -ItemType Directory -Force $bld, "$bld\apps\qgis-ltr\pdb" | Out-Null

function M([string] $p) { $p -replace '\\', '/' }
$cmake = Join-Path $Paths.Tools 'cmake\bin\cmake.exe'

$cfg = @(
    '-G', 'Ninja', '-S', (M $src), '-B', (M $bld),
    '-D', 'CMAKE_CXX_COMPILER=cl.exe', '-D', 'CMAKE_C_COMPILER=cl.exe', '-D', 'CMAKE_LINKER=link.exe',
    '-D', 'CMAKE_CXX_FLAGS_RELEASE=/MD /Z7 /MP /O2 /Ob2 /D NDEBUG /std:c++17 /permissive- /D _DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR',
    '-D', "CMAKE_PDB_OUTPUT_DIRECTORY_RELEASE=$(M "$bld\apps\qgis-ltr\pdb")",
    '-D', 'CMAKE_SHARED_LINKER_FLAGS_RELEASE=/INCREMENTAL:NO /DEBUG /OPT:REF /OPT:ICF',
    '-D', 'CMAKE_MODULE_LINKER_FLAGS_RELEASE=/INCREMENTAL:NO /DEBUG /OPT:REF /OPT:ICF',
    '-D', 'PUSH_TO_CDASH=FALSE',
    '-D', 'PEDANTIC=TRUE',
    '-D', 'WITH_QSPATIALITE=TRUE',
    '-D', 'WITH_SERVER=TRUE',
    '-D', 'SERVER_SKIP_ECW=TRUE',
    '-D', 'ENABLE_TESTS=FALSE',
    '-D', 'WITH_3D=TRUE',
    '-D', 'WITH_PDAL=TRUE',
    '-D', 'WITH_HANA=TRUE',
    '-D', 'WITH_GRASS=TRUE',
    '-D', 'WITH_GRASS8=TRUE',
    '-D', "GRASS_PREFIX8=$(M $grassPrefix)",
    '-D', 'WITH_ORACLE=TRUE',
    '-D', 'WITH_CUSTOM_WIDGETS=TRUE',
    '-D', 'CMAKE_BUILD_TYPE=Release',
    '-D', 'CMAKE_CONFIGURATION_TYPES=Release',
    '-D', 'HAS_KDE_QT5_SMALL_CAPS_FIX=TRUE',
    '-D', 'HAS_KDE_QT5_FONT_STRETCH_FIX=TRUE',
    '-D', "SETUPAPI_LIBRARY=$(M "${env:ProgramFiles(x86)}\Windows Kits\10\Lib\$sdkVer\um\x64\SetupAPI.Lib")",
    '-D', "PROJ_INCLUDE_DIR=$(M "$o4w\include")",
    '-D', "POSTGRES_INCLUDE_DIR=$(M "$o4w\include")",
    '-D', "GEOS_LIBRARY=$(M "$o4w\lib\geos_c.lib")",
    '-D', "SQLITE3_LIBRARY=$(M "$o4w\lib\sqlite3_i.lib")",
    '-D', "SPATIALITE_LIBRARY=$(M "$o4w\lib\spatialite_i.lib")",
    '-D', "SPATIALINDEX_LIBRARY=$(M "$o4w\lib\spatialindex-64.lib")",
    '-D', "Python_EXECUTABLE=$(M "$o4w\bin\python3.exe")",
    '-D', "SIP_MODULE_EXECUTABLE=$(M "$pyHome\Scripts\sip-module.exe")",
    '-D', "PYUIC_PROGRAM=$(M "$pyHome\Scripts\pyuic5.exe")",
    '-D', "PYRCC_PROGRAM=$(M "$pyHome\Scripts\pyrcc5.exe")",
    '-D', "PYTHON_INCLUDE_PATH=$(M "$pyHome\include")",
    '-D', "PYTHON_LIBRARY=$(M $pyLib)",
    '-D', "QT_LIBRARY_DIR=$(M "$o4w\lib")",
    '-D', "QT_HEADERS_DIR=$(M "$o4w\apps\qt5\include")",
    '-D', "CMAKE_INSTALL_PREFIX=$(M $inst)",
    '-D', 'CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS=TRUE',
    '-D', "FCGI_INCLUDE_DIR=$(M "$o4w\include")",
    '-D', "FCGI_LIBRARY=$(M "$o4w\lib\libfcgi.lib")",
    '-D', "QCA_INCLUDE_DIR=$(M "$o4w\apps\Qt5\include\QtCrypto")",
    '-D', "QCA_LIBRARY=$(M "$o4w\apps\Qt5\lib\qca-qt5.lib")",
    '-D', "QWT_LIBRARY=$(M "$o4w\apps\Qt5\lib\qwt.lib")",
    '-D', "QSCINTILLA_LIBRARY=$(M "$o4w\apps\Qt5\lib\qscintilla2.lib")",
    '-D', "GITCOMMAND=$(M $git)"
  )
# reconfigura quando falta o build.ninja ou quando os argumentos do CMake mudaram
$cfgHash = [BitConverter]::ToString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($cfg -join "`n"))) -replace '-'
$cfgStamp = Join-Path $bld 'iman-configure.sha256'
if (-not (Test-Path "$bld\build.ninja") -or -not (Test-Path $cfgStamp) -or (Get-Content $cfgStamp) -ne $cfgHash) {
  $t0 = Get-Date
  Write-Step 'cmake configure'
  & $cmake @cfg *>&1 | Tee-Object -FilePath $log
  if ($LASTEXITCODE) { Remove-Item -Force "$bld\build.ninja", $cfgStamp -ErrorAction SilentlyContinue; throw "cmake configure falhou (ver $log)" }
  Set-Content $cfgStamp $cfgHash
  $timings.configureSeconds = [int]((Get-Date) - $t0).TotalSeconds
}

$t0 = Get-Date
# O win_flex usa um temporario de nome fixo em %TEMP% (~flex_out_main_N): dois flex em paralelo apagam o
# arquivo um do outro ("error deleting file") ou, pior, misturam o conteudo e geram um .cpp corrompido que o
# ninja da como atualizado. As tres saidas de flex do src/core (e as de bison) sao geradas antes, em serie; o
# unico flex do src/analysis depende de qgis_core inteiro e roda depois, sozinho.
$generated = @(
  'src\core\qgsexpressionparser.cpp', 'src\core\qgsexpressionlexer.cpp',
  'src\core\qgssqlstatementparser.cpp', 'src\core\qgssqlstatementlexer.cpp',
  'src\core\qgsmeshcalcparser.cpp', 'src\core\qgsmeshcalclexer.cpp'
)
Write-Step 'flex/bison em serie'
& (Join-Path $Paths.Tools 'ninja\ninja.exe') -C $bld -j1 @generated *>&1 | Tee-Object -FilePath $log -Append | Select-Object -Last 5
if ($LASTEXITCODE) { throw "flex/bison falhou (ver $log)" }
Write-Step 'cmake --build'
$buildArgs = @('--build', (M $bld), '--config', 'Release')
if ($Jobs -gt 0) { $buildArgs += @('--parallel', "$Jobs") }
& $cmake @buildArgs *>&1 | Tee-Object -FilePath $log -Append | Select-String -Pattern 'error|FAILED|warning C4' -SimpleMatch:$false | Select-Object -Last 40
$buildExit = $LASTEXITCODE
$timings.buildSeconds = [int]((Get-Date) - $t0).TotalSeconds
if ($buildExit) { $timings | ConvertTo-Json | Set-Content (Join-Path $Paths.Logs "timings-$stamp.json"); throw "build falhou (exit $buildExit, ver $log)" }

if (-not $SkipInstall) {
  $t0 = Get-Date
  Write-Step 'cmake --install'
  & $cmake --install (M $bld) --config Release *>&1 | Out-File -Append $log
  if ($LASTEXITCODE) { throw "install falhou (ver $log)" }
  $timings.installSeconds = [int]((Get-Date) - $t0).TotalSeconds
}

$timings.finished = (Get-Date).ToString('s')
$timings.msvc = $msvc
$timings.log = $log
$timings | ConvertTo-Json | Set-Content (Join-Path $Paths.Logs "timings-$stamp.json")
$timings | ConvertTo-Json
