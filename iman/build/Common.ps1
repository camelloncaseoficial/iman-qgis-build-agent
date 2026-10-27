# Configuracao comum dos scripts de build do produto (dot-source: . "$PSScriptRoot\Common.ps1").
# Tudo que e baixado ou gerado vive fora do repo, em $WorkRoot (padrao D:\iman-terra-build, ou $env:IMAN_BUILD_ROOT).

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $WorkRoot) { $WorkRoot = if ($env:IMAN_BUILD_ROOT) { $env:IMAN_BUILD_ROOT } else { 'D:\iman-terra-build' } }

$Paths = @{
  Cache    = Join-Path $WorkRoot 'cache'
  Packages = Join-Path $WorkRoot 'cache\osgeo4w'
  ToolsZip = Join-Path $WorkRoot 'cache\tools'
  Tools    = Join-Path $WorkRoot 'tools'
  Osgeo4w  = Join-Path $WorkRoot 'osgeo4w'
  Build    = Join-Path $WorkRoot 'build'
  Install  = Join-Path $WorkRoot 'install'
  Logs     = Join-Path $WorkRoot 'logs'
  Smoke    = Join-Path $WorkRoot 'smoke'
  Brand    = Join-Path $WorkRoot 'brand'
}

$Osgeo4wMirror = 'https://download.osgeo.org/osgeo4w/v2'
$LockFile = Join-Path $PSScriptRoot 'osgeo4w.lock.tsv'
# tar do Windows (bsdtar, le .tar.bz2) pelo caminho: chamado do Git Bash, o tar.exe do PATH e o GNU tar do Git, que
# le "D:\..." como host remoto (medido na fatia 047)
$TarExe = Join-Path $env:SystemRoot 'System32\tar.exe'

# Ferramentas fixadas: versao, URL e sha256 (o do CMake confere com o cmake-3.29.0-SHA-256.txt oficial;
# o do bootstrapper do VS e o que a Microsoft embute na URL de download).
$Tools = [ordered]@{
  cmake = @{ Version = '3.29.0'; File = 'cmake-3.29.0-windows-x86_64.zip'
    Url = 'https://github.com/Kitware/CMake/releases/download/v3.29.0/cmake-3.29.0-windows-x86_64.zip'
    Sha256 = '9ab28eba1ab7911a0e57ab274f5990a283fffa1d22eb711792d5562e5869f9ef' }
  ninja = @{ Version = '1.10.2'; File = 'ninja-1.10.2-win.zip'
    Url = 'https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-win.zip'
    Sha256 = 'bbde850d247d2737c5764c927d1071cbb1f1957dcabda4a130fa8547c12c695f' }
  winflexbison = @{ Version = '2.5.25'; File = 'win_flex_bison-2.5.25.zip'
    Url = 'https://github.com/lexxmark/winflexbison/releases/download/v2.5.25/win_flex_bison-2.5.25.zip'
    Sha256 = '8d324b62be33604b2c45ad1dd34ab93d722534448f55a16ca7292de32b6ac135' }
  vsbuildtools = @{ Version = '17'; File = 'vs_buildtools-17.exe'
    Url = 'https://aka.ms/vs/17/release/vs_buildtools.exe'
    Sha256 = '2a6aa7d94e38d457a4eb3930fc60056ecab06865b2eb925e5275b8473a017583' }
}

# Componentes do VS 2022 Build Tools: os mesmos de vs2022env() na receita qgis-ltr (jef-n/OSGeo4W).
$VsComponents = @(
  'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
  'Microsoft.VisualStudio.Component.Windows11SDK.26100',
  'Microsoft.VisualStudio.Component.VC.ATL'
)
$VsSdkVersion = '10.0.26100.0'
# Toolset que compilou o 3.44.13 oficial (linker 14.44, Rich header build 35225 em qgis_core.dll)
$ExpectedMsvc = '14.44'

# Arquivo versionado sempre em UTF-8 sem BOM e LF (o Set-Content do Windows grava CRLF)
function Write-LfFile([string] $path, [string[]] $lines) {
  [IO.File]::WriteAllText($path, (($lines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
}

function Write-Step([string] $msg) {
  Write-Host ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg)
}

function Get-VerifiedFile([string] $url, [string] $dest, [string] $sha256) {
  if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
    $tmp = "$dest.part"
    Invoke-WebRequest $url -OutFile $tmp
    Move-Item -Force $tmp $dest
  }
  $h = (Get-FileHash -Algorithm SHA256 $dest).Hash.ToLowerInvariant()
  if ($sha256 -and $h -ne $sha256.ToLowerInvariant()) {
    throw "sha256 divergente em ${dest}: esperado $sha256, obtido $h"
  }
  $h
}

function Get-VsInstallPath {
  $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
  if (-not (Test-Path $vswhere)) { return $null }
  & $vswhere -products * -version '[17.0,18.0)' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath |
    Select-Object -First 1
}

# Carrega no processo atual o ambiente do vcvarsall (amd64, SDK fixado).
function Import-VsEnvironment {
  $vs = Get-VsInstallPath
  if (-not $vs) { throw 'VS 2022 Build Tools nao encontrado; rode Install-BuildTools.ps1' }
  $bat = Join-Path $vs 'VC\Auxiliary\Build\vcvarsall.bat'
  $lines = & cmd.exe /c "`"$bat`" amd64 $VsSdkVersion >nul && set"
  if ($LASTEXITCODE) { throw "vcvarsall falhou ($LASTEXITCODE)" }
  foreach ($l in $lines) { if ($l -match '^([^=]+)=(.*)$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] } }
  $env:VSLANG = '1033'
}

function Import-ToolsPath {
  $env:PATH = (@(
      (Join-Path $Paths.Tools 'cmake\bin'),
      (Join-Path $Paths.Tools 'ninja'),
      (Join-Path $Paths.Tools 'winflexbison')
    ) -join ';') + ';' + $env:PATH
}

# Nome interno (organizacao e aplicacao) do alvo: o do produto vem da fonte unica (D-IMAN-043, fatia 047); o do
# QGIS oficial e QGIS/QGIS3. Da a pasta do perfil, do cache e dos crashes, o .ini dentro do perfil e a chave de
# registro HKCU\Software\<organizacao>\<aplicacao>.
function Get-InternalName([string] $Target = 'Build') {
  if ($Target -eq 'Official') { return [pscustomobject]@{ Organization = 'QGIS'; Application = 'QGIS3' } }
  $b = Get-Content (Join-Path $RepoRoot 'iman\brand\brand.json') -Raw -Encoding utf8 | ConvertFrom-Json
  [pscustomobject]@{ Organization = $b.internal_organization_name; Application = $b.internal_application_name }
}

# Perfil descartavel em $Profiles, com o cache de rede dentro dele ([cache] directory nos perfis 'default', do
# qgis_process, e 'iman-smoke', da GUI): sem isso o QGIS grava no cache padrao %LOCALAPPDATA%\<org>\<app>\cache.
# Na fatia 044 esse cache era o do QGIS oficial (nome interno QGIS3 compartilhado); desde a 047 o .ini semeado e o
# do nome interno do alvo (<org>\<app>.ini dentro do perfil), senao o QGIS nao o le.
function New-DisposableProfile([string] $Profiles, [string] $CacheDir, [string] $Target = 'Build') {
  $name = Get-InternalName $Target
  foreach ($p in 'default', 'iman-smoke') {
    $ini = Join-Path $Profiles "profiles\$p\$($name.Organization)\$($name.Application).ini"
    New-Item -ItemType Directory -Force (Split-Path $ini) | Out-Null
    Write-LfFile $ini @('[cache]', "directory=$($CacheDir -replace '\\', '/')")
  }
}

# Ambiente de runtime no processo atual: o mesmo de bin\qgis_process-qgis-ltr.bat do oficial (o4w_env, GRASS,
# apps\qgis-ltr), com o perfil em $Profiles (QGIS_CUSTOM_CONFIG_PATH; nunca %APPDATA%\QGIS).
function Import-QgisRuntime([string] $Osgeo4wRoot, [string] $AppRoot, [string] $Profiles) {
  $grassEnv = Get-ChildItem "$Osgeo4wRoot\apps\grass\grass*\etc\env.bat" -ErrorAction SilentlyContinue | Select-Object -First 1
  $cmdline = "call `"$Osgeo4wRoot\bin\o4w_env.bat`" >nul"
  if ($grassEnv) { $cmdline += " && call `"$($grassEnv.FullName)`" >nul" }
  $lines = & cmd.exe /c "$cmdline && set"
  foreach ($l in $lines) { if ($l -match '^([^=]+)=(.*)$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] } }
  $grassDir = if ($grassEnv) { Split-Path (Split-Path $grassEnv.FullName) } else { $null }
  $env:PATH = (@("$AppRoot\bin") + $(if ($grassDir) { @("$grassDir\lib", "$grassDir\bin") } else { @() }) + @($env:PATH)) -join ';'
  $env:QGIS_PREFIX_PATH = $AppRoot -replace '\\', '/'
  $env:GDAL_FILENAME_IS_UTF8 = 'YES'
  $env:VSI_CACHE = 'TRUE'
  $env:VSI_CACHE_SIZE = '1000000'
  $env:QT_PLUGIN_PATH = "$AppRoot\qtplugins;$Osgeo4wRoot\apps\qt5\plugins"
  $env:PYTHONPATH = "$AppRoot\python;$env:PYTHONPATH"
  $env:QGIS_CUSTOM_CONFIG_PATH = $Profiles
  # O WinToast cria ou regrava Start Menu\Programs\<QGIS_WIN_APP_NAME>.lnk a cada abertura (fatia 044: QGIS3.lnk;
  # fatia 047: o build criou IMANTerra.lnk). Uma pasta que nao existe faz a criacao falhar: rodado por estes
  # scripts, nenhum alvo grava atalho no Menu Iniciar (sem notificacao nativa, o que o smoke nao usa).
  $env:QGIS_WIN_APP_NAME = 'iman-sem-atalho-no-menu\iman-sem-atalho'
}
