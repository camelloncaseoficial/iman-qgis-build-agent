<#
.SYNOPSIS
  Guarda (BL-3 e STOP dos briefings 043 e 044): prova que o build e o smoke nao tocaram o QGIS oficial do usuario.

.DESCRIPTION
  -Baseline grava um retrato; sem -Baseline, compara com o retrato e sai com 1 se algo mudou.
  Retrato: arquivos da instalacao oficial, das arvores de perfil e de dados do QGIS (caminho, tamanho, mtime) e as
  chaves de registro HKCU\Software\QGIS e HKLM\SOFTWARE\QGIS (reg export).
  Arvores de dados: %APPDATA%\QGIS (perfis) e, desde a fatia 044, %LOCALAPPDATA%\QGIS (cache de rede e pastas de
  crash do QGIS) e o atalho QGIS3.lnk do Menu Iniciar que o WinToast valida a cada abertura: o nome interno
  QGIS/QGIS3 os compartilha com qualquer build do QGIS.
  O retrato vale para uma rodada: o Invoke-Gate.ps1 e o Invoke-ImanBuild.ps1 o tiram de novo no comeco de cada
  rodada (ressalva R1 do gate 043), entao o uso do QGIS oficial entre rodadas nao reprova a seguinte.
  -DataRoots, -RegistryKeys e -GuardDir existem para o teste da propria guarda (Test-GuardRounds.ps1), que roda
  contra arvores de teste e nunca contra o QGIS oficial.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [switch] $Baseline,
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string[]] $DataRoots = @((Join-Path $env:APPDATA 'QGIS'), (Join-Path $env:LOCALAPPDATA 'QGIS'),
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\QGIS3.lnk')),
  [string[]] $RegistryKeys = @('HKCU\Software\QGIS', 'HKLM\SOFTWARE\QGIS'),
  [string] $GuardDir
)
. "$PSScriptRoot\Common.ps1"

$dir = if ($GuardDir) { $GuardDir } else { Join-Path $WorkRoot 'guard' }
New-Item -ItemType Directory -Force $dir | Out-Null

function Get-Snapshot {
  $lines = [System.Collections.Generic.List[string]]::new()
  foreach ($root in @($OfficialRoot) + $DataRoots) {
    if (-not (Test-Path $root)) { $lines.Add("ABSENT $root"); continue }
    Get-ChildItem -LiteralPath $root -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
      $lines.Add(('{0}|{1}|{2}' -f $_.FullName, $_.Length, $_.LastWriteTimeUtc.Ticks))
    }
  }
  foreach ($key in $RegistryKeys) {
    $tmp = Join-Path $dir 'reg.tmp'
    & reg.exe export $key $tmp /y 2>$null | Out-Null
    if ($LASTEXITCODE) { $lines.Add("ABSENT $key") }
    else { $lines.Add("$key|" + (Get-FileHash -Algorithm SHA256 $tmp).Hash); Remove-Item $tmp }
  }
  $lines | Sort-Object
}

$base = Join-Path $dir 'baseline.txt'
if ($Baseline) {
  Get-Snapshot | Set-Content -Encoding utf8 $base
  Write-Step "retrato gravado: $base ($((Get-Content $base).Count) linhas)"
  return
}
if (-not (Test-Path $base)) { throw "sem retrato; rode com -Baseline antes do build" }
$taken = (Get-Item $base).LastWriteTime.ToString('s')
$now = Get-Snapshot
$diff = Compare-Object (Get-Content $base) $now
if ($diff) {
  $diff | ForEach-Object { Write-Host ("{0} {1}" -f $_.SideIndicator, $_.InputObject) }
  Write-Host "GUARD FALHOU: o QGIS oficial ou os dados dele mudaram desde o retrato de $taken ($(@($diff).Count) diferencas)"
  exit 1
}
Write-Host "GUARD OK: QGIS oficial, $($DataRoots -join ', ') e registro QGIS identicos ao retrato de $taken ($($now.Count) itens)"
