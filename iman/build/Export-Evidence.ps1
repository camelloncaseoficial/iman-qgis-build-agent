<#
.SYNOPSIS
  Copia uma rodada de smoke ou de capturas para a pasta de evidencia de um laudo, sem dado pessoal da maquina.

.DESCRIPTION
  Copia os arquivos pedidos (-Include, padroes separados por virgula) de -Source para -Destination. Nos arquivos de texto (json, txt, md), o
  caminho do perfil do Windows ($env:USERPROFILE, nas formas com \ e com \\ do JSON) vira %USERPROFILE%: o laudo
  vai para um repo publico. As imagens sao copiadas como estao.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $Source,
  [Parameter(Mandatory)] [string] $Destination,
  [string] $Include = '*.json,*.txt,*.png,*.pdf'
)
. "$PSScriptRoot\Common.ps1"

New-Item -ItemType Directory -Force $Destination | Out-Null
$userProfile = $env:USERPROFILE
foreach ($f in Get-ChildItem -Path "$Source\*" -File -Include ($Include -split ',')) {
  $dest = Join-Path $Destination $f.Name
  if ($f.Extension -in '.json', '.txt', '.md') {
    $text = [IO.File]::ReadAllText($f.FullName)
    $text = $text.Replace($userProfile.Replace('\', '\\'), '%USERPROFILE%').Replace($userProfile, '%USERPROFILE%')
    [IO.File]::WriteAllText($dest, $text, [Text.UTF8Encoding]::new($false))
  } else {
    Copy-Item $f.FullName $dest -Force
  }
}
Write-Step "evidencia: $Source -> $Destination"
