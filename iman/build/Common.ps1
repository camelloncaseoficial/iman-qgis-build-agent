# Configuracao comum dos scripts de build do IMAN Terra (dot-source: . "$PSScriptRoot\Common.ps1").
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
}

$Osgeo4wMirror = 'https://download.osgeo.org/osgeo4w/v2'
$LockFile = Join-Path $PSScriptRoot 'osgeo4w.lock.tsv'

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
