<#
.SYNOPSIS
  Instala as ferramentas de build fixadas: VS 2022 Build Tools (componentes da receita qgis-ltr) e, em
  $WorkRoot\tools, CMake, ninja e winflexbison portateis. Idempotente.

.NOTES
  A instalacao do VS pede elevacao (UAC). Rodar so com a confirmacao do sponsor (regra fixa do CLAUDE.md).
#>
[CmdletBinding()]
param([string] $WorkRoot, [switch] $SkipVs)
. "$PSScriptRoot\Common.ps1"

foreach ($name in 'cmake', 'ninja', 'winflexbison') {
  $t = $Tools[$name]
  $zip = Join-Path $Paths.ToolsZip $t.File
  $h = Get-VerifiedFile $t.Url $zip $t.Sha256
  $dest = Join-Path $Paths.Tools $name
  $stamp = Join-Path $dest '.iman-version'
  if ((Test-Path $stamp) -and ((Get-Content $stamp) -eq "$($t.Version) $h")) { Write-Step "$name $($t.Version) ja instalado"; continue }
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  $tmp = "$dest.extract"
  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
  Expand-Archive $zip $tmp
  # o zip do CMake traz uma pasta raiz; os outros dois nao
  $inner = @(Get-ChildItem $tmp)
  if ($inner.Count -eq 1 -and $inner[0].PSIsContainer) { Move-Item $inner[0].FullName $dest; Remove-Item $tmp } else { Move-Item $tmp $dest }
  Set-Content $stamp "$($t.Version) $h"
  Write-Step "$name $($t.Version) instalado em $dest"
}

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not $SkipVs -and (Test-Path $vswhere)) {
  # todos os componentes ja instalados: nada a fazer (e nenhum UAC)
  $ready = & $vswhere -products * -version '[17.0,18.0)' -requires @VsComponents -property installationPath | Select-Object -First 1
  if ($ready) {
    $msvc = (Get-ChildItem (Join-Path $ready 'VC\Tools\MSVC') | Sort-Object Name | Select-Object -Last 1).Name
    Write-Step "VS Build Tools ja completo em $ready (MSVC $msvc)"
    $SkipVs = $true
  }
}

if (-not $SkipVs) {
  $vs = Get-VsInstallPath
  $t = $Tools.vsbuildtools
  $boot = Join-Path $Paths.ToolsZip $t.File
  Get-VerifiedFile $t.Url $boot $t.Sha256 | Out-Null
  $vsArgs = @('--passive', '--norestart', '--wait', '--nocache', '--addProductLang', 'en-US')
  foreach ($c in $VsComponents) { $vsArgs += @('--add', $c) }
  if ($vs) {
    Write-Step "VS Build Tools em $vs; garantindo os componentes"
    $vsArgs = @('modify', '--installPath', $vs) + $vsArgs
  } else {
    Write-Step 'instalando VS 2022 Build Tools (pede UAC)'
  }
  $p = Start-Process -FilePath $boot -ArgumentList $vsArgs -Wait -PassThru
  # 3010 = ok, reinicio recomendado
  if ($p.ExitCode -notin 0, 3010) { throw "vs_buildtools saiu com $($p.ExitCode)" }
  $vs = Get-VsInstallPath
  if (-not $vs) { throw 'VS Build Tools nao aparece no vswhere depois da instalacao' }
  $msvc = (Get-ChildItem (Join-Path $vs 'VC\Tools\MSVC') | Sort-Object Name | Select-Object -Last 1).Name
  Write-Step "VS Build Tools: $vs, MSVC $msvc (exit $($p.ExitCode))"
  if (-not $msvc.StartsWith($ExpectedMsvc)) { Write-Warning "MSVC $msvc difere do $ExpectedMsvc do build oficial" }
}
