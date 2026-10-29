<#
.SYNOPSIS
  Gera os blocos do THIRD_PARTY_NOTICES.md (resumo, patchset e inventario) a partir da arvore do produto, do
  inventario de licencas curado e do iman/PATCHES.md (fatia 047, L.1). -Check so confere.

.DESCRIPTION
  Fontes:
    - -Tree (padrao $WorkRoot\stage\tree, a arvore do New-RuntimeTree.ps1; ou a instalada): o etc\setup\installed.db
      da a lista de pacotes e a versao; o <pacote>.lst.gz de cada um diz se o pacote traz arquivo de licenca;
    - iman/notices/licencas-upstream.tsv: licenca, categoria e URL do upstream de cada pacote;
    - iman/PATCHES.md: os arquivos do QGIS modificados.
  Uma entrada por pacote do installed.db: os pacotes OSGeo4W e o iman-terra (o QGIS compilado). Pacote sem arquivo
  de licenca tem de ter URL do upstream; pacote sem linha no inventario curado e erro.
  Escreve so entre os marcadores "<!-- gerado: ... -->" e "<!-- gerado: fim -->" do THIRD_PARTY_NOTICES.md.
  -Check: sai com 1 se o arquivo nao estiver em dia com a arvore.
#>
[CmdletBinding()]
param([string] $WorkRoot, [string] $Tree, [switch] $Check)
. "$PSScriptRoot\..\build\Common.ps1"
if (-not $Tree) { $Tree = Join-Path $WorkRoot 'stage\tree' }
$notices = Join-Path $PSScriptRoot 'THIRD_PARTY_NOTICES.md'

# arquivo de licenca dentro do pacote: o nome diz licenca, copia ou aviso; fora fonte, teste e binario
$licenseRx = '(?i)(^|/)(licen[cs]e|copying|copyright|notice|eula|unlicense)[^/]*$'
function Get-LicenseFiles([string[]] $paths) {
  @($paths | Where-Object { $_ -notmatch '/$' -and $_ -match $licenseRx -and
      $_ -notmatch '(?i)\.(py|pyc|dll|exe|h|cpp|c|html?|png|svg|qml)$' -and $_ -notmatch '(?i)/tests?/' } |
    Sort-Object { $_.Split('/').Count }, { $_ })
}
function Read-Gz([string] $path) {
  $fs = [IO.File]::OpenRead($path)
  $gz = [IO.Compression.GZipStream]::new($fs, [IO.Compression.CompressionMode]::Decompress)
  $text = [IO.StreamReader]::new($gz).ReadToEnd(); $gz.Dispose(); $fs.Dispose()
  @($text -split "`r?`n" | Where-Object { $_ })
}
function Format-Cell([string] $s) { $s.Replace('|', '/') }

$curated = @{}
Get-Content (Join-Path $PSScriptRoot 'licencas-upstream.tsv') -Encoding utf8 | Where-Object { -not $_.StartsWith('#') } |
  ConvertFrom-Csv -Delimiter "`t" | ForEach-Object { $curated[$_.pacote] = $_ }

$db = @(Get-Content (Join-Path $Tree 'etc\setup\installed.db') | Select-Object -Skip 1 | Where-Object { $_ } |
  ForEach-Object { $n, $f, $null = $_ -split '\s+'; [pscustomobject]@{ Package = $n; File = $f } })
if (-not $db) { throw "installed.db vazio ou ausente em $Tree" }

$rows = [System.Collections.Generic.List[string]]::new()
$rows.Add('| # | Pacote | Versão | Licença | Fonte da licença |')
$rows.Add('|---:|---|---|---|---|')
$withFile = 0; $upstream = 0; $errors = @()
$i = 0
foreach ($p in ($db | Sort-Object { $_.Package -ne 'iman-terra' }, Package)) {
  $i++
  if ($p.Package -eq 'iman-terra') {
    $ver = ($p.File -replace '^iman-terra-', '') -replace '-[0-9a-f]{7,}$', ''
    $rows.Add("| $i | ``iman-terra`` | $ver (QGIS 3.44.13 recompilado e modificado, seção 2) | GPL-2.0-or-later | arquivo no pacote: ``apps/qgis-ltr/doc/LICENSE`` |")
    $withFile++
    continue
  }
  $c = $curated[$p.Package]
  if (-not $c) { $errors += "sem linha em licencas-upstream.tsv: $($p.Package)"; continue }
  $ver = $p.File -replace "^$([regex]::Escape($p.Package))-", '' -replace '\.tar\.bz2$', ''
  $lst = Join-Path $Tree "etc\setup\$($p.Package).lst.gz"
  $files = if (Test-Path $lst) { Get-LicenseFiles (Read-Gz $lst) } else { @() }
  if ($files) {
    $src = 'arquivo no pacote: ' + (($files | Select-Object -First 2 | ForEach-Object { "``$_``" }) -join ', ')
    if ($files.Count -gt 2) { $src += " e mais $($files.Count - 2)" }
    $withFile++
  } else {
    if ($c.fonte_upstream -notmatch '^https?://') { $errors += "sem arquivo no pacote e sem URL do upstream: $($p.Package)" }
    $src = "upstream: $($c.fonte_upstream)"
    $upstream++
  }
  $rows.Add("| $i | ``$($p.Package)`` | $ver | $(Format-Cell $c.licenca) | $(Format-Cell $src) |")
}
if ($errors) { $errors | ForEach-Object { Write-Host "ERRO: $_" }; exit 1 }

$summary = @(
  '| | |', '|---|---|',
  "| Entradas do inventário (seção 3) | **$($db.Count)**: $($db.Count - 1) pacotes OSGeo4W e o QGIS compilado pelo Instituto IMAN |",
  "| Pacotes com arquivo de licença dentro do próprio pacote | $withFile |",
  "| Pacotes cuja licença vem do upstream (URL na tabela) | $upstream |"
)
$patches = @(Get-Content (Join-Path $RepoRoot 'iman\PATCHES.md') -Encoding utf8 |
  Where-Object { $_ -match '^\|\s*`([^`]+)`\s*\|' } | ForEach-Object {
    $cells = $_ -split '\s\|\s'
    "- ``$([regex]::Match($_, '^\|\s*`([^`]+)`').Groups[1].Value)`` ($($cells[2].Trim()); fatia $($cells[3].Trim(' |')))"
  })

$text = [IO.File]::ReadAllText($notices)
function Set-Block([string] $name, [string[]] $lines) {
  $rx = "(?s)(<!-- gerado: $name \(iman/notices/Update-Notices\.ps1\) -->\r?\n).*?(<!-- gerado: fim -->)"
  if ($script:text -notmatch $rx) { throw "marcador do bloco '$name' ausente em $notices" }
  $script:text = [regex]::Replace($script:text, $rx, { param($m) $m.Groups[1].Value + (($lines -join "`n") + "`n") + $m.Groups[2].Value })
}
$before = $text
Set-Block 'resumo' $summary
Set-Block 'patchset' $patches
Set-Block 'inventario' $rows

if ($Check) {
  $ok = $text -eq $before
  Write-Step ("notices {0}: {1} entradas para {2} pacotes do installed.db de {3}" -f $(if ($ok) { 'em dia' } else { 'DESATUALIZADO' }), ($rows.Count - 2), $db.Count, $Tree)
  if (-not $ok) { exit 1 }
  return
}
[IO.File]::WriteAllText($notices, $text, [Text.UTF8Encoding]::new($false))
Write-Step ("THIRD_PARTY_NOTICES.md: {0} entradas ({1} com arquivo no pacote, {2} pelo upstream), {3} arquivos do patchset" -f ($rows.Count - 2), $withFile, $upstream, $patches.Count)
