<#
.SYNOPSIS
  Baixa os pacotes do osgeo4w.lock.tsv para $WorkRoot\cache\osgeo4w, confere o sha256 e monta a raiz OSGeo4W
  isolada em $WorkRoot\osgeo4w (extracao + postinstall), sem osgeo4w-setup, sem registro e sem atalhos.

.DESCRIPTION
  sha256 vazio no lock: grava o hash do primeiro download no lock (para ser commitado).
  sha256 preenchido: o arquivo tem de bater, senao para.
  -Offline: nao toca a rede; falta de pacote no cache e erro (estado "dependencia removida do mirror").
  A raiz so e remontada quando o conjunto do lock muda (carimbo etc\setup\iman-lock.sha256).
#>
[CmdletBinding()]
param([string] $WorkRoot, [switch] $Offline, [switch] $Force, [switch] $DownloadOnly, [string] $Lock)
. "$PSScriptRoot\Common.ps1"
if ($Lock) { $LockFile = (Resolve-Path $Lock).Path }

$header = @(Get-Content $LockFile | Where-Object { $_.StartsWith('#') })
$rows = @(Get-Content $LockFile | Where-Object { -not $_.StartsWith('#') } | ConvertFrom-Csv -Delimiter "`t")
$bad = @($rows | Where-Object { -not $_.File -or $_.Rule -notin 'official', 'dated', 'latest' })
if ($bad) { throw "lock com pacote sem versao fixada: $($bad.Package -join ', ')" }

New-Item -ItemType Directory -Force $Paths.Packages | Out-Null
$mirror = $Osgeo4wMirror; $pkgDir = $Paths.Packages; $off = [bool]$Offline
$results = $rows | ForEach-Object -ThrottleLimit 8 -Parallel {
  $r = $_
  $dest = Join-Path $using:pkgDir ($r.Url -replace '/', '\')
  if (-not (Test-Path $dest)) {
    if ($using:off) { return [pscustomobject]@{ Package = $r.Package; Sha256 = ''; Error = "ausente do cache: $($r.Url)" } }
    New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
    try {
      Invoke-WebRequest "$($using:mirror)/$($r.Url)" -OutFile "$dest.part" -ErrorAction Stop
      Move-Item -Force "$dest.part" $dest
    } catch { return [pscustomobject]@{ Package = $r.Package; Sha256 = ''; Error = "download falhou: $($r.Url): $($_.Exception.Message)" } }
  }
  [pscustomobject]@{ Package = $r.Package; Sha256 = (Get-FileHash -Algorithm SHA256 $dest).Hash.ToLowerInvariant(); Error = '' }
}
$errors = @($results | Where-Object Error)
if ($errors) { $errors | ForEach-Object { Write-Warning $_.Error }; throw "$($errors.Count) pacote(s) indisponiveis" }

$byName = @{}; $results | ForEach-Object { $byName[$_.Package] = $_.Sha256 }
$filled = 0
foreach ($r in $rows) {
  $h = $byName[$r.Package]
  if (-not $r.Sha256) { $r.Sha256 = $h; $filled++ }
  elseif ($r.Sha256 -ne $h) { throw "sha256 divergente em $($r.File): lock $($r.Sha256), cache $h" }
}
if ($filled) {
  Write-LfFile $LockFile ($header + ($rows | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation -UseQuotes Never))
  Write-Step "$filled sha256 gravados em $LockFile (commitar)"
}
$total = ($rows | Measure-Object -Property Size -Sum).Sum
Write-Step ("{0} pacotes conferidos ({1:N1} MB)" -f $rows.Count, ($total / 1MB))
if ($DownloadOnly) { return }

# raiz OSGeo4W
$lockHash = (Get-FileHash -Algorithm SHA256 $LockFile).Hash
$root = $Paths.Osgeo4w
$stamp = Join-Path $root 'etc\setup\iman-lock.sha256'
if (-not $Force -and (Test-Path $stamp) -and (Get-Content $stamp) -eq $lockHash) { Write-Step "raiz $root ja corresponde ao lock"; return }
if (Test-Path $root) { Write-Step "removendo raiz anterior $root"; Remove-Item -Recurse -Force $root }
New-Item -ItemType Directory -Force (Join-Path $root 'etc\setup') | Out-Null

$db = [System.Collections.Generic.List[string]]::new(); $db.Add('INSTALLED.DB 2')
foreach ($r in $rows) {
  $tar = Join-Path $pkgDir ($r.Url -replace '/', '\')
  $list = & tar.exe -xjvf $tar -C $root 2>&1
  if ($LASTEXITCODE) { throw "tar falhou em $($r.File): $list" }
  $db.Add("$($r.Package) $($r.File) 0")
}
Set-Content -Encoding ascii (Join-Path $root 'etc\setup\installed.db') $db
Write-Step "$($rows.Count) pacotes extraidos em $root"

# postinstall: mesmo contrato do osgeo4w-setup (OSGEO4W_ROOT definido, roda e renomeia para .done)
$env:OSGEO4W_ROOT = $root
$env:OSGEO4W_ROOT_MSYS = $root -replace '\\', '/'
$env:OSGEO4W_STARTMENU = Join-Path $root 'startmenu-unused'
$env:OSGEO4W_DESKTOP = Join-Path $root 'desktop-unused'
$env:OSGEO4W_MENU_LINKS = '0'
$env:OSGEO4W_DESKTOP_LINKS = '0'
$env:OSGEO4W_SKIP_ARP_REGISTRATION = '1'
$env:PATH = "$root\bin;$env:PATH"
$post = Join-Path $root 'etc\postinstall'
$log = Join-Path $Paths.Logs 'osgeo4w-postinstall.log'
New-Item -ItemType Directory -Force $Paths.Logs | Out-Null
Set-Content $log "postinstall $(Get-Date -Format s)"
# openssl.bat e opencl.bat rodam "dllupdate -copy", que copia DLL para C:\Windows\System32: nao rodam aqui.
# As DLLs ficam no bin da raiz isolada, que vai na frente do PATH.
$skip = 'openssl.bat', 'opencl.bat'
foreach ($b in (Get-ChildItem $post -Filter *.bat | Sort-Object Name)) {
  if ($b.Name -in $skip) {
    Add-Content $log "== $($b.Name) PULADO (escreve fora da raiz)"
    Move-Item -Force $b.FullName "$($b.FullName).skipped"
    continue
  }
  $out = & cmd.exe /c "cd /d `"$root`" && call `"$($b.FullName)`"" 2>&1
  Add-Content $log "== $($b.Name) exit $LASTEXITCODE"; Add-Content $log $out
  if ($LASTEXITCODE) { Write-Warning "postinstall $($b.Name) saiu com $LASTEXITCODE (ver $log)" }
  if (Test-Path $b.FullName) { Move-Item -Force $b.FullName "$($b.FullName).done" }
}
Set-Content $stamp $lockHash
Write-Step "raiz OSGeo4W pronta em $root"
