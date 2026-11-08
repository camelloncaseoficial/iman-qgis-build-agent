# Plugin IMAN REURB embarcado (fatia 051)

O IMAN Terra sai com o plugin IMAN REURB instalado e ligado. O plugin vem de uma **tag fixada** do repo do plugin,
nunca da copia de trabalho.

| Arquivo | O que e | Quem le |
|---|---|---|
| `plugin.lock.json` | a trava: id da pasta (`id`), nome, versao e licenca (para os notices), a tag, o commit completo para onde ela aponta e a pasta do plugin dentro do repo (`path_in_repo`) | `Export-ImanPlugin` (`iman/build/Common.ps1`), `iman/brand/build_brand.py`, `iman/notices/Update-Notices.ps1`, `iman/installer/Build-Installer.ps1`, o smoke e os testes da 051 |

## Como entra

- **Clone do plugin:** parametro da bancada. `-PluginRepo` do `Build-Qgis.ps1` e do `New-RuntimeTree.ps1`, ou a
  variavel `IMAN_PLUGIN_REPO`; padrao `..\iman-qgis-plugin-agent`, relativo a raiz do fork.
- **Exportacao:** `git archive` de `path_in_repo` no `commit` da trava (com `core.autocrlf=false`: os bytes sao os
  do commit, nao os da copia de trabalho do clone), extraido em `apps\qgis-ltr\python\plugins\<id>\`. O
  `Build-Qgis.ps1` exporta na instalacao do build, a cada install; o `New-RuntimeTree.ps1` nao copia a pasta do
  build e exporta de novo na arvore do instalador.
- **Falha alto** se o clone nao existe, se a tag nao existe, se a tag aponta para outro commit que nao o da trava, se
  falta o `LICENSE` na pasta exportada ou se o `version` do `metadata.txt` nao e o da trava.
- **Ligado por padrao:** o `build_brand.py` grava `[PythonPlugins] <id>=true` no `qgis_global_settings.ini`. A chave
  gravada pelo usuario no perfil vence a global: desligar no Gerenciador de complementos fica desligado.
- **Notices:** a linha do plugin no `THIRD_PARTY_NOTICES.md` e gerada da trava pelo `Update-Notices.ps1` (e o
  `-Check` a cobre); a tag e o commit vao para o `SOURCE_CODE.md` do pacote pelo `Build-Installer.ps1`.

## Trocar a versao do plugin

Criar a tag nova no repo do plugin, trocar `version`, `tag` e `commit` aqui, rodar `iman/notices/Update-Notices.ps1`
e commitar junto.
