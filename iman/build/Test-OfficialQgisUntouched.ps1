<#
.SYNOPSIS
  Guarda (BL-3 e STOP dos briefings 043, 044 e 047): prova que o build, o smoke e o instalador nao tocaram o QGIS
  oficial do usuario.

.DESCRIPTION
  -Baseline grava um retrato; sem -Baseline, compara com o retrato e sai com 1 se algo mudou.
  Retrato:
    - arquivos (caminho, tamanho, mtime) da instalacao oficial e de -DataRoots: %APPDATA%\QGIS (perfis),
      %LOCALAPPDATA%\QGIS (cache de rede e crashes), o atalho QGIS3.lnk que o WinToast valida (fatia 044) e, desde
      a 047, a pasta do oficial no Menu Iniciar de todos os usuarios;
    - chaves de registro inteiras (-RegistryKeys, reg export + sha256): HKCU\Software\QGIS, HKLM\SOFTWARE\QGIS e,
      desde a 047, a chave de desinstalacao do MSI oficial;
    - desde a 047, valor a valor (-ValueKeys, recursivo), as areas onde o instalador do produto grava ao lado do
      oficial: HKCR e HKCU\Software\Classes para .qgs, .qgz, .qlr e os ProgIDs do oficial, o UserChoice dos tres
      tipos e as configuracoes de notificacao do AUMI do oficial. Mais as chaves de HKCU\Software\Classes cujo nome
      fala de QGIS (-ClassesPattern), achadas a cada retrato. Valor ou chave com nome do proprio produto
      (-OwnNamePattern, o ProgID IMANTerra.*) fica fora: o "Abrir com" do produto nao e mudanca do oficial.
      Chave ausente e chave sem valor dao a mesma linha (SEM-VALORES).
  O retrato vale para uma rodada: o Invoke-Gate.ps1 e o Invoke-ImanBuild.ps1 o tiram de novo no comeco de cada
  rodada (ressalva R1 do gate 043), entao o uso do QGIS oficial entre rodadas nao reprova a seguinte.
  -DataRoots, -RegistryKeys, -ValueKeys, -ClassesPattern e -GuardDir existem para os testes da propria guarda
  (Test-GuardRounds.ps1 e Test-GuardAreas.ps1), que nunca alteram o sistema.
#>
[CmdletBinding()]
param(
  [string] $WorkRoot,
  [switch] $Baseline,
  [string] $OfficialRoot = 'C:\Program Files\QGIS 3.44.13',
  [string[]] $DataRoots = @((Join-Path $env:APPDATA 'QGIS'), (Join-Path $env:LOCALAPPDATA 'QGIS'),
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\QGIS3.lnk'),
    'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\QGIS 3.44.13'),
  [string[]] $RegistryKeys = @('HKCU\Software\QGIS', 'HKLM\SOFTWARE\QGIS',
    'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{740D7A65-CBA3-1014-A0B5-B03A9B7608F5}'),
  [string[]] $ValueKeys = @(
    'HKCR\.qgs', 'HKCR\.qgz', 'HKCR\.qlr', 'HKCR\QGIS Project', 'HKCR\QGIS Layer Definition',
    'HKCU\Software\Classes\.qgs', 'HKCU\Software\Classes\.qgz', 'HKCU\Software\Classes\.qlr',
    'HKCU\Software\Classes\QGIS Project', 'HKCU\Software\Classes\QGIS Layer Definition',
    'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.qgs\UserChoice',
    'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.qgz\UserChoice',
    'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.qlr\UserChoice',
    'HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings|^QGIS'),
  [string] $ClassesPattern = '(?i)qgis',
  [string] $OwnNamePattern = '^IMANTerra\.',
  [string] $GuardDir
)
. "$PSScriptRoot\Common.ps1"

$dir = if ($GuardDir) { $GuardDir } else { Join-Path $WorkRoot 'guard' }
New-Item -ItemType Directory -Force $dir | Out-Null

$hives = @{
  HKCR = [Microsoft.Win32.RegistryHive]::ClassesRoot
  HKCU = [Microsoft.Win32.RegistryHive]::CurrentUser
  HKLM = [Microsoft.Win32.RegistryHive]::LocalMachine
}

function Open-RegKey([string] $path) {
  $hive, $sub = $path -split '\\', 2
  $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey($hives[$hive], [Microsoft.Win32.RegistryView]::Registry64)
  if (-not $sub) { return $base }
  $base.OpenSubKey($sub)
}

function Format-RegValue($key, [string] $name) {
  $kind = $key.GetValueKind($name)
  $data = $key.GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
  $text = switch ($kind) {
    'Binary' { [BitConverter]::ToString([byte[]]$data) -replace '-' }
    'MultiString' { ($data -join '\0') }
    default { "$data" }
  }
  '{0}|{1}|{2}' -f $(if ($name) { $name } else { '(padrao)' }), $kind, $text
}

# Valores de uma chave e das subchaves, uma linha por valor. -Filter restringe as subchaves de primeiro nivel.
function Get-RegValueLines([string] $path, [string] $filter) {
  $out = [System.Collections.Generic.List[string]]::new()
  $walk = {
    param($key, [string] $shown, [bool] $top)
    # com -Filter a chave de topo e um conteiner do Windows: so as subchaves que casam entram
    foreach ($n in $(if ($top -and $filter) { @() } else { $key.GetValueNames() })) {
      if ($n -match $OwnNamePattern) { continue }
      $out.Add("REG $shown|" + (Format-RegValue $key $n))
    }
    foreach ($s in ($key.GetSubKeyNames() | Sort-Object)) {
      if ($s -match $OwnNamePattern) { continue }
      if ($top -and $filter -and $s -notmatch $filter) { continue }
      $child = $key.OpenSubKey($s)
      if ($child) { & $walk $child "$shown\$s" $false; $child.Close() }
    }
  }
  $k = Open-RegKey $path
  if ($k) { & $walk $k $path $true; $k.Close() }
  if (-not $out.Count) { $out.Add("REG $path|SEM-VALORES") }
  $out
}

function Get-Snapshot {
  $lines = [System.Collections.Generic.List[string]]::new()
  foreach ($root in @($OfficialRoot) + $DataRoots) {
    if (-not (Test-Path -LiteralPath $root)) { $lines.Add("ABSENT $root"); continue }
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
  $scanKeys = [System.Collections.Generic.List[string]]::new()
  $ValueKeys | ForEach-Object { $scanKeys.Add($_) }
  if ($ClassesPattern) {
    $classes = Open-RegKey 'HKCU\Software\Classes'
    foreach ($s in $classes.GetSubKeyNames()) {
      if ($s -match $ClassesPattern -and $s -notmatch $OwnNamePattern) { $scanKeys.Add("HKCU\Software\Classes\$s") }
    }
    $apps = $classes.OpenSubKey('Applications')
    if ($apps) {
      foreach ($s in $apps.GetSubKeyNames()) { if ($s -match $ClassesPattern) { $scanKeys.Add("HKCU\Software\Classes\Applications\$s") } }
      $apps.Close()
    }
    $classes.Close()
  }
  foreach ($spec in ($scanKeys | Sort-Object -Unique)) {
    $path, $filter = $spec -split '\|', 2
    foreach ($l in (Get-RegValueLines $path $filter)) { $lines.Add($l) }
  }
  $lines | Sort-Object -Unique
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
Write-Host "GUARD OK: QGIS oficial, $($DataRoots -join ', '), registro, associacoes e notificacoes do QGIS identicos ao retrato de $taken ($($now.Count) itens)"
