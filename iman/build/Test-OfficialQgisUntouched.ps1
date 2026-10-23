<#
.SYNOPSIS
  Guarda (BL-3 e STOP do briefing 043): prova que o build e o smoke nao tocaram o QGIS oficial do usuario.

.DESCRIPTION
  -Baseline grava um retrato; sem -Baseline, compara com o retrato e sai com 1 se algo mudou.
  Retrato: arquivos da instalacao oficial (caminho, tamanho, mtime), arvore %APPDATA%\QGIS (idem) e as chaves de
  registro HKCU\Software\QGIS e HKLM\SOFTWARE\QGIS (reg export).
#>
[CmdletBinding()]
param([string] $WorkRoot, [switch] $Baseline, [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13')
. "$PSScriptRoot\Common.ps1"

$dir = Join-Path $WorkRoot 'guard'
New-Item -ItemType Directory -Force $dir | Out-Null

function Get-Snapshot {
  $lines = [System.Collections.Generic.List[string]]::new()
  foreach ($root in $OfficialRoot, (Join-Path $env:APPDATA 'QGIS')) {
    if (-not (Test-Path $root)) { $lines.Add("ABSENT $root"); continue }
    Get-ChildItem -LiteralPath $root -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
      $lines.Add(('{0}|{1}|{2}' -f $_.FullName, $_.Length, $_.LastWriteTimeUtc.Ticks))
    }
  }
  foreach ($key in 'HKCU\Software\QGIS', 'HKLM\SOFTWARE\QGIS') {
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
$now = Get-Snapshot
$diff = Compare-Object (Get-Content $base) $now
if ($diff) {
  $diff | ForEach-Object { Write-Host ("{0} {1}" -f $_.SideIndicator, $_.InputObject) }
  Write-Host "GUARD FALHOU: o QGIS oficial ou o perfil dele mudou ($(@($diff).Count) diferencas)"
  exit 1
}
Write-Host "GUARD OK: QGIS oficial, %APPDATA%\QGIS e registro QGIS identicos ao retrato ($($now.Count) itens)"
